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
const API_KEY = "";  // Change this to a secret key
const SHEET_NAME = "Records";
const SPREADSHEET_ID = ""; // Optional: set when deploying as standalone script
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
        return readRecords(map, e.parameter.type || "");
        
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
function readRecords(mapName, typeFilter) {
  const sheet = getOrCreateSheet();
  const mapRows = findMapSections(sheet, mapName);

  const wantTrial = !typeFilter || typeFilter === "trial";
  const wantMatch = !typeFilter || typeFilter === "match";

  if (!mapRows.length) {
    // Map not found, return empty records
    const empty = {map: mapName};
    if (wantTrial) empty.trial = [];
    if (wantMatch) empty.match = [];
    return jsonResponse(empty);
  }

  // Aggregate across duplicate sections of the same map and take best 3.
  let allTrial = [];
  let allMatch = [];
  for (let i = 0; i < mapRows.length; i++) {
    const section = resolveSectionStarts(sheet, mapRows[i]);
    if (wantTrial) allTrial = allTrial.concat(readSectionRecords(sheet, section.trialStart, 3));
    if (wantMatch) allMatch = allMatch.concat(readSectionRecords(sheet, section.matchStart, 3));
  }

  const result = {map: mapName};
  if (wantTrial) result.trial = pickTopRecords(allTrial, 3);
  if (wantMatch) result.match = pickTopRecords(allMatch, 3);

  return jsonResponse(result);
}

/**
 * Write or update a record
 * Data format: {map, is_match, rank, player, player_qhex, teamcolor, time, date, mt_str, ping}
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
    // Columns: A=Rank, B=Player, C=TeamColor, D=Time, E=Date, F=MatchTimeStr, G=Server, H=PlayerQHex, I=Ping
    const server = data.server || data.hostname || "";
    const playerQHex = data.player_qhex || "";
    const existingDate = sheet.getRange(recordRow, 5).getValue();
    const existingMtStr = sheet.getRange(recordRow, 6).getValue();
    const existingPing = Number(sheet.getRange(recordRow, 9).getValue());
    const incomingPing = Number(data.ping);
    let finalDate = data.date || existingDate || "";
    if (finalDate instanceof Date) {
      finalDate = Utilities.formatDate(finalDate, Session.getScriptTimeZone(), "yyyy-MM-dd'T'HH:mm:ssZ");
    } else if (finalDate !== "") {
      finalDate = String(finalDate);
    }
    const finalMtStr = (data.mt_str !== undefined && data.mt_str !== null && data.mt_str !== "")
      ? normalizeMatchTimeStr(data.mt_str)
      : normalizeMatchTimeStr(existingMtStr);
    const finalPing = (isFinite(incomingPing) && incomingPing > 0)
      ? incomingPing
      : ((isFinite(existingPing) && existingPing > 0) ? existingPing : "");
    // Force Date (E) and Time In Match (F) to plain text before writing.
    sheet.getRange(recordRow, 5, 1, 2).setNumberFormat("@");
    sheet.getRange(recordRow, 2, 1, 8).setValues([[
      data.player,
      data.teamcolor,
      newTime,
      finalDate,
      finalMtStr,
      server,
      playerQHex,
      finalPing
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
  let ss = SpreadsheetApp.getActiveSpreadsheet();
  if (!ss && SPREADSHEET_ID) {
    ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  }
  if (!ss) {
    throw new Error("No active spreadsheet. Bind this script to a sheet or set SPREADSHEET_ID.");
  }
  let sheet = ss.getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }
  
  // Check if headers exist (Cell A1 is empty)
  const firstCell = sheet.getRange(1, 1).getValue();
  if (firstCell === "") {
    // Add header row
    sheet.getRange(1, 1, 1, 9).setValues([["Map", "Name", "Color", "Record Time", "Date", "Time In Match", "Server", "Hex Name", "Ping"]]);
    sheet.getRange(1, 1, 1, 9).setFontWeight("bold");
    
    // Set min widths for Date, Server, and Hex Name (approx 30 chars = 250px)
    sheet.setColumnWidth(5, 250); // Date (Col E)
    sheet.setColumnWidth(7, 250); // Server (Col G)
    sheet.setColumnWidth(8, 250); // Hex Name (Col H)
    sheet.setColumnWidth(9, 80);  // Ping (Col I)
  }
  
  return sheet;
}

function normalizeMapKey(value) {
  if (value === null || value === undefined) return "";
  let s = String(value).trim();
  if (/^map:\s*/i.test(s)) {
    s = s.replace(/^map:\s*/i, "").trim();
  }
  return s.toLowerCase();
}

function normalizeMatchTimeStr(value) {
  if (value === null || value === undefined || value === "") return "";
  if (value instanceof Date) {
    // Sheets interprets the QC's M:SS as H:MM, shifting units by one.
    // Recover: Date hours = original minutes, Date minutes = original seconds.
    const h = value.getHours();
    const m = value.getMinutes();
    const s = value.getSeconds();
    if (s > 0) {
      // Has seconds component: likely a correctly stored H:MM:SS value
      return h + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }
    // Shifted M:SS -> H:MM:00: recover original M:SS
    return h + ":" + String(m).padStart(2, "0");
  }
  const s = String(value).trim();
  if (s === "") return "";

  // Handle accidental Date.toString() values, keep only mm:ss-like part.
  const mt = s.match(/\b(\d{1,2}):(\d{2})(?::\d{2})?\b/);
  if (mt && /GMT|UTC|Standard Time|Daylight Time/.test(s)) {
    const mm = Number(mt[1]);
    const ss = Number(mt[2]);
    if (isFinite(mm) && isFinite(ss) && ss >= 0 && ss < 60) {
      return `${mm}:${String(ss).padStart(2, "0")}`;
    }
  }
  return s;
}

function normalizeRecordTime(value) {
  if (value === null || value === undefined || value === "") return 0;

  if (typeof value === "number") {
    return isFinite(value) ? value : 0;
  }

  if (value instanceof Date) {
    // Time-only cells are often returned as Date objects anchored to 1899-12-30.
    return (value.getHours() * 3600)
      + (value.getMinutes() * 60)
      + value.getSeconds()
      + (value.getMilliseconds() / 1000);
  }

  const s = String(value).trim();
  if (s === "") return 0;

  const n = Number(s);
  if (isFinite(n)) return n;

  // Accept M:SS(.xx) and H:MM:SS(.xx)
  const parts = s.split(":");
  if (parts.length === 2) {
    const mm = Number(parts[0]);
    const ss = Number(parts[1]);
    if (isFinite(mm) && isFinite(ss)) return (mm * 60) + ss;
  } else if (parts.length === 3) {
    const hh = Number(parts[0]);
    const mm = Number(parts[1]);
    const ss = Number(parts[2]);
    if (isFinite(hh) && isFinite(mm) && isFinite(ss)) return (hh * 3600) + (mm * 60) + ss;
  }

  return 0;
}

function resolveSectionStarts(sheet, mapRow) {
  // Default offsets for standard section layout.
  let trialStart = mapRow + 2;
  let matchStart = mapRow + 6;

  // Be tolerant of legacy sections where TRIAL/MATCH rows shifted.
  const lastRow = sheet.getLastRow();
  const scanCount = Math.min(30, Math.max(0, lastRow - mapRow));
  if (scanCount > 0) {
    const labels = sheet.getRange(mapRow + 1, 1, scanCount, 1).getValues();
    let trialHeader = -1;
    let matchHeader = -1;

    for (let i = 0; i < labels.length; i++) {
      const raw = labels[i][0];
      const text = (raw === null || raw === undefined) ? "" : String(raw).trim();
      const up = text.toUpperCase();
      const rowNum = mapRow + 1 + i;

      if (up === "TRIAL" && trialHeader < 0) {
        trialHeader = rowNum;
        continue;
      }
      if (up === "MATCH" && matchHeader < 0) {
        matchHeader = rowNum;
        continue;
      }

      // Stop scanning when we hit the next map marker.
      if (i > 0) {
        const nk = normalizeMapKey(raw);
        if (nk !== "" && up !== "TRIAL" && up !== "MATCH" && up !== "1" && up !== "2" && up !== "3") {
          break;
        }
      }
    }

    if (trialHeader > 0) trialStart = trialHeader + 1;
    if (matchHeader > 0) matchStart = matchHeader + 1;
  }

  return {trialStart, matchStart};
}

function pickTopRecords(records, limit) {
  const filtered = [];
  const seen = {};

  for (let i = 0; i < records.length; i++) {
    const rec = records[i];
    const t = Number(rec.time);
    if (!isFinite(t) || t <= 0) continue;
    filtered.push(rec);
  }

  filtered.sort((a, b) => Number(a.time) - Number(b.time));

  const out = [];
  for (let i = 0; i < filtered.length; i++) {
    const rec = filtered[i];
    const key = [
      rec.player || "",
      String(rec.teamcolor),
      String(Number(rec.time)),
      rec.date || "",
      rec.mt_str || "",
      rec.server || "",
      String(rec.ping || "")
    ].join("|");
    if (seen[key]) continue;
    seen[key] = true;
    out.push(rec);
    if (out.length >= limit) break;
  }

  return out;
}

/**
 * Find the starting row of a map section
 * Returns -1 if not found
 */
function findMapSection(sheet, mapName) {
  const rows = findMapSections(sheet, mapName);
  if (!rows.length) return -1;
  return rows[rows.length - 1];
}

/**
 * Find all matching map section rows for a map name
 */
function findMapSections(sheet, mapName) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 1) return [];
  
  const range = sheet.getRange(1, 1, lastRow, 1);
  const data = range.getValues();
  const marker = normalizeMapKey(mapName);
  let changed = false;
  const rows = [];
  
  for (let i = 0; i < data.length; i++) {
    const raw = data[i][0];
    const normalized = normalizeMapKey(raw);
    if (normalized === marker) {
      rows.push(i + 1); // Convert to 1-indexed row number
    }
    if (typeof raw === "string" && /^map:\s*/i.test(raw)) {
      const cleaned = raw.replace(/^map:\s*/i, "").trim();
      if (cleaned !== raw) {
        data[i][0] = cleaned;
        changed = true;
      }
    }
  }
  
  if (changed) range.setValues(data);
  return rows;
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
    [mapName, "", "", "", "", "", "", "", ""],
    ["TRIAL", "", "", "", "", "", "", "", ""],
    ["1", "", "", "", "", "", "", "", ""],
    ["2", "", "", "", "", "", "", "", ""],
    ["3", "", "", "", "", "", "", "", ""],
    ["MATCH", "", "", "", "", "", "", "", ""],
    ["1", "", "", "", "", "", "", "", ""],
    ["2", "", "", "", "", "", "", "", ""],
    ["3", "", "", "", "", "", "", "", ""]
  ];
  
  sheet.getRange(startRow, 1, 9, 9).setValues(sectionData);

  // Force Date (E) + Time In Match (F) to plain text.
  sheet.getRange(startRow, 5, 9, 2).setNumberFormat("@");

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
    const data = sheet.getRange(startRow, 1, count, 9).getValues();
    
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      // Check if record has a player name (column B, index 1)
      if (row[1] && row[1] !== "") {
        // Sheets may auto-convert ISO strings to Date objects; convert back
        let dateVal = row[4] || "";
        if (dateVal instanceof Date) {
          dateVal = Utilities.formatDate(dateVal, Session.getScriptTimeZone(), "yyyy-MM-dd'T'HH:mm:ssZ");
        } else if (dateVal !== "") {
          dateVal = String(dateVal);
        }
        const teamColorVal = Number(row[2]);
        const timeVal = normalizeRecordTime(row[3]);
        const mtStrVal = normalizeMatchTimeStr(row[5]);
        let qhexVal = row[7] ? String(row[7]).trim() : "";
        let pingRaw = row[8];
        // Backward compatibility: older sheets had Ping in column H (index 7), no Hex Name column.
        if ((pingRaw === "" || pingRaw === null || pingRaw === undefined) && qhexVal !== "" && /^-?\d+(\.\d+)?$/.test(qhexVal)) {
          pingRaw = qhexVal;
          qhexVal = "";
        }
        const pingVal = Number(pingRaw);
        records.push({
          player: String(row[1]),
          player_qhex: qhexVal,
          teamcolor: isFinite(teamColorVal) ? teamColorVal : 0,
          time: isFinite(timeVal) ? timeVal : 0,
          date: dateVal,
          mt_str: mtStrVal,
          server: row[6] ? String(row[6]) : "",
          ping: (isFinite(pingVal) && pingVal > 0) ? pingVal : ""
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
    mt_str: "",
    ping: 42
  };
  
  const result = writeRecord(testData);
  Logger.log("Write result: " + result.getContent());
  
  // Read it back
  const readResult = readRecords("test_map");
  Logger.log("Read result: " + readResult.getContent());
}
