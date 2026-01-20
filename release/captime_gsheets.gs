/**
 * Google Apps Script for CRMod7 Captime Records
 * 
 * Deploy as a Web App:
 * 1. In Apps Script editor, go to Deploy > New deployment
 * 2. Select "Web app" 
 * 3. Execute as: "Me"
 * 4. Who has access: "Anyone"
 * 5. Copy the deployment URL for your clanring.cfg
 * 
 * Configuration:
 * - Set API_KEY to a secret string
 * - SHEET_NAME is the tab name for records
 */

// ============ CONFIGURATION ============
const API_KEY = "SET_API_KEY";  // Change this to a secret key
const SHEET_NAME = "Records";
// ========================================

function doGet(e) {
  return handleRequest(e);
}

function doPost(e) {
  return handleRequest(e);
}

function handleRequest(e) {
  try {
    // Validate API key
    if (!e.parameter || e.parameter.key !== API_KEY) {
      return jsonResponse({error: "Invalid API key"}, 403);
    }
    
    const action = e.parameter.action;
    const map = e.parameter.map;
    
    switch(action) {
      case "validate":
        return jsonResponse({status: "ok", version: 1});
        
      case "read":
        if (!map) return jsonResponse({error: "Missing map parameter"}, 400);
        return readRecords(map);
        
      case "write":
        if (!e.postData || !e.postData.contents) {
          return jsonResponse({error: "Missing POST data"}, 400);
        }
        const data = JSON.parse(e.postData.contents);
        data.server = data.server || data.hostname || (e.parameter ? e.parameter.server : "") || "";
        data.date = data.date || (e.parameter ? e.parameter.date : "") || "";
        data.mt_str = data.mt_str || (e.parameter ? e.parameter.mt_str : "") || "";
        return writeRecord(data);
        
      default:
        return jsonResponse({error: "Invalid action"}, 400);
    }
  } catch (err) {
    return jsonResponse({error: err.message}, 500);
  }
}

/**
 * Read all records for a specific map
 */
function readRecords(mapName) {
  const sheet = getOrCreateSheet();
  const mapRow = findMapSection(sheet, mapName);
  
  if (mapRow < 0) {
    // Map not found, return empty records
    return jsonResponse({map: mapName, trial: [], match: []});
  }
  
  // Trial records: rows mapRow+1 through mapRow+3 (after TRIAL header)
  // Match records: rows mapRow+5 through mapRow+7 (after MATCH header)
  const trial = readSectionRecords(sheet, mapRow + 2, 3);
  const match = readSectionRecords(sheet, mapRow + 6, 3);
  
  return jsonResponse({map: mapName, trial: trial, match: match});
}

/**
 * Write or update a record
 * Data format: {map, is_match, rank, player, player_qhex, teamcolor, time, date, mt_str}
 */
function writeRecord(data) {
  if (!data.map || !data.player || data.rank < 1 || data.rank > 3) {
    return jsonResponse({error: "Invalid record data"}, 400);
  }
  
  const sheet = getOrCreateSheet();
  const lock = LockService.getScriptLock();
  
  try {
    lock.waitLock(10000); // Wait up to 10 seconds for lock
    
    let mapRow = findMapSection(sheet, data.map);
    
    if (mapRow < 0) {
      // Create new map section
      mapRow = createMapSection(sheet, data.map);
    }
    
    // Calculate row for this record
    // Trial: mapRow+1 is "TRIAL" header, ranks are +2,+3,+4
    // Match: mapRow+5 is "MATCH" header, ranks are +6,+7,+8
    const sectionOffset = data.is_match ? 5 : 1;
    const recordRow = mapRow + sectionOffset + data.rank;
    
    // Read existing record to compare times
    const newTime = Number(data.time);
    const existingTime = Number(sheet.getRange(recordRow, 4).getValue());
    
    // Only update if new time is faster (lower) or slot is empty
    if (!isFinite(newTime) || newTime <= 0) {
      return jsonResponse({error: "Invalid time"}, 400);
    }
    if (!isFinite(existingTime) || existingTime === 0 || newTime < existingTime) {
      // Columns: A=Rank, B=Player, C=TeamColor, D=Time, E=Date, F=MatchTimeStr, G=Server, H=PlayerQHex
      const server = data.server || data.hostname || "";
      const playerQHex = data.player_qhex || "";
      const existingDate = sheet.getRange(recordRow, 5).getValue();
      const existingMtStr = sheet.getRange(recordRow, 6).getValue();
      const finalDate = data.date || existingDate || "";
      const finalMtStr = data.mt_str || existingMtStr || "";
      sheet.getRange(recordRow, 2, 1, 7).setValues([[
        data.player,
        data.teamcolor,
        newTime,
        finalDate,
        finalMtStr,
        server,
        playerQHex
      ]]);
      
      return jsonResponse({status: "updated", rank: data.rank, map: data.map, server: server, time: newTime});
    }
    
    return jsonResponse({status: "unchanged", reason: "existing time is faster"});
    
  } finally {
    lock.releaseLock();
  }
}

/**
 * Get or create the records sheet
 */
function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }
  
  // Check if headers exist (Cell A1 is empty)
  const firstCell = sheet.getRange(1, 1).getValue();
  if (firstCell === "") {
    // Add header row
    sheet.getRange(1, 1, 1, 8).setValues([["Map", "Name", "Color", "Record Time", "Date", "Time In Match", "Server", "Hex Name"]]);
    sheet.getRange(1, 1, 1, 8).setFontWeight("bold");
    
    // Set min widths for Date, Server, and Hex Name (approx 30 chars = 250px)
    sheet.setColumnWidth(5, 250); // Date (Col E)
    sheet.setColumnWidth(7, 250); // Server (Col G)
    sheet.setColumnWidth(8, 250); // Hex Name (Col H)
  }
  
  return sheet;
}

/**
 * Find the starting row of a map section
 * Returns -1 if not found
 */
function findMapSection(sheet, mapName) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 1) return -1;
  
  const range = sheet.getRange(1, 1, lastRow, 1);
  const data = range.getValues();
  const marker = mapName;
  let changed = false;
  
  for (let i = 0; i < data.length; i++) {
    const raw = data[i][0];
    if (typeof raw === "string" && raw.startsWith("MAP: ")) {
      const trimmed = raw.substring(5);
      if (trimmed !== raw) {
        data[i][0] = trimmed;
        changed = true;
      }
      if (trimmed === marker) {
        if (changed) range.setValues(data);
        return i + 1; // Convert to 1-indexed row number
      }
    } else if (raw === marker) {
      if (changed) range.setValues(data);
      return i + 1; // Convert to 1-indexed row number
    }
  }
  
  if (changed) range.setValues(data);
  return -1;
}

/**
 * Create a new map section with proper structure
 * Returns the row number of the MAP: header
 */
function createMapSection(sheet, mapName) {
  const lastRow = Math.max(sheet.getLastRow(), 1);
  
  // Add 2 blank rows before new section (unless it's the first map)
  let startRow = lastRow + 1;
  if (lastRow > 1) {
    startRow = lastRow + 3; // 2 blank rows + 1
  } else {
    // If only headers exist (Row 1), skip Row 2 and start at Row 3
    startRow = 3;
  }
  
  // Build the section structure:
  // Row 0: "mapname"
  // Row 1: "TRIAL"
  // Row 2-4: Rank 1, 2, 3 (trial)
  // Row 5: "MATCH"
  // Row 6-8: Rank 1, 2, 3 (match)
  const sectionData = [
    [mapName, "", "", "", "", "", "", ""],
    ["TRIAL", "", "", "", "", "", "", ""],
    ["1", "", "", "", "", "", "", ""],
    ["2", "", "", "", "", "", "", ""],
    ["3", "", "", "", "", "", "", ""],
    ["MATCH", "", "", "", "", "", "", ""],
    ["1", "", "", "", "", "", "", ""],
    ["2", "", "", "", "", "", "", ""],
    ["3", "", "", "", "", "", "", ""]
  ];
  
  sheet.getRange(startRow, 1, 9, 8).setValues(sectionData);
  
  // Bold the headers
  sheet.getRange(startRow, 1).setFontWeight("bold");
  sheet.getRange(startRow + 1, 1).setFontWeight("bold");
  sheet.getRange(startRow + 5, 1).setFontWeight("bold");
  
  return startRow;
}

/**
 * Read records from a section (3 rows starting at startRow)
 */
function readSectionRecords(sheet, startRow, count) {
  const records = [];
  
  try {
    const data = sheet.getRange(startRow, 1, count, 8).getValues();
    
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      // Check if record has a player name (column B, index 1)
      if (row[1] && row[1] !== "") {
        records.push({
          player: row[1],
          player_qhex: row[7] || "",
          teamcolor: row[2] || 0,
          time: row[3] || 0,
          date: row[4] || "",
          mt_str: row[5] || "",
          server: row[6] || ""
        });
      }
    }
  } catch (e) {
    // Return empty if range is invalid
  }
  
  return records;
}

/**
 * Create JSON response
 */
function jsonResponse(obj, statusCode) {
  const output = ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
  return output;
}

/**
 * Test function - run this manually to verify the script works
 */
function testScript() {
  // Create a test map entry
  const testData = {
    map: "test_map",
    is_match: false,
    rank: 1,
    player: "TestPlayer",
    teamcolor: 4,
    time: 15.5,
    date: "2026-01-19",
    mt_str: ""
  };
  
  const result = writeRecord(testData);
  Logger.log("Write result: " + result.getContent());
  
  // Read it back
  const readResult = readRecords("test_map");
  Logger.log("Read result: " + readResult.getContent());
}
