//
//  G O O G L E S H E E T S . q c
//
// Google Sheets integration for captime records.
// Uses a published Google Apps Script as an intermediary API.
//

// Request IDs for async HTTP callbacks
float GSHEETS_REQ_READ_TRIAL  = 200;
float GSHEETS_REQ_READ_MATCH  = 201;
float GSHEETS_REQ_WRITE_TRIAL = 202;
float GSHEETS_REQ_WRITE_MATCH = 203;
float GSHEETS_REQ_VALIDATE    = 204;

// Pending request tracking
float gsheets_pending_read;    // TRUE while waiting for read response
string gsheets_pending_map;    // Map name for pending request

//
// Sanitize a string for JSON (preserve Quake colors, strip control/JSON breakers)
//
string(string s) gsheets_json_sanitize =
{
	if (s == "" || s == string_null)
		return "";
	
	string src = strzone(s);
	string result = "";
	float i, len, c;
	len = strlen(src);
	
	for (i = 0; i < len; i++)
	{
		c = str2chr(src, i);
		if (c < 0)
			c = c + 256;
		// Skip control characters (0-31) and backslash; preserve high-bit Quake colors.
		if (c >= 32 && c != 34 && c != 92)
			result = strcat(result, chr2str(c));
		else if (c == 34) // quote -> avoid breaking JSON
			result = strcat(result, "'");
	}
	
	strunzone(src);
	return result;
};

//
// Encode a string into lowercase hex bytes (preserve Quake chars)
//
string(string s) gsheets_hex_encode =
{
	if (s == "" || s == string_null)
		return "";
	
	string src = strzone(s);
	string hex = "0123456789abcdef";
	string out = "";
	float i, len, c, hi, lo;
	len = strlen(src);
	
	for (i = 0; i < len; i++)
	{
		c = str2chr(src, i);
		if (c < 0) c = c + 256;
		hi = floor(c / 16);
		lo = c - (hi * 16);
		out = strcat(out, substring(hex, hi, 1), substring(hex, lo, 1));
	}
	
	strunzone(src);
	return out;
};

float(float c) gsheets_hex_val_code =
{
	if (c >= 48 && c <= 57) return c - 48;
	if (c >= 65 && c <= 70) return c - 55;
	if (c >= 97 && c <= 102) return c - 87;
	return -1;
};

//
// Decode a lowercase/uppercase hex string into bytes
//
string(string hex) gsheets_hex_decode =
{
	if (hex == "" || hex == string_null)
		return "";
	
	string src = strzone(hex);
	string out = "";
	float len = strlen(src);
	float i;
	
	if (len - (floor(len / 2) * 2) != 0)
	{
		strunzone(src);
		return "";
	}
	
	for (i = 0; i + 1 < len; i = i + 2)
	{
		float c1 = str2chr(src, i);
		float c2 = str2chr(src, i + 1);
		if (c1 < 0) c1 = c1 + 256;
		if (c2 < 0) c2 = c2 + 256;
		
		float hi = gsheets_hex_val_code(c1);
		float lo = gsheets_hex_val_code(c2);
		if (hi < 0 || lo < 0)
		{
			out = "";
			break;
		}
		
		out = strcat(out, chr2str((hi * 16) + lo));
	}
	
	strunzone(src);
	return out;
};

//
// Check if Google Sheets integration is configured and validated
//
float() gsheets_enabled =
{
	if (clanring_googlesheetsurl == "" || clanring_googlesheetsurl == string_null)
		return FALSE;
	if (clanring_googlesheetsapikey == "" || clanring_googlesheetsapikey == string_null)
		return FALSE;
	if (!clanring_googlesheets_valid)
		return FALSE;
	return TRUE;
};

//
// Check if Google Sheets is configured (but maybe not yet validated)
//
float() gsheets_configured =
{
	if (clanring_googlesheetsurl == "" || clanring_googlesheetsurl == string_null)
		return FALSE;
	if (clanring_googlesheetsapikey == "" || clanring_googlesheetsapikey == string_null)
		return FALSE;
	return TRUE;
};

//
// Build the full URL with action and API key
//
string(string action) gsheets_build_url =
{
	return sprintf("%s?action=%s&key=%s", 
		clanring_googlesheetsurl, 
		action, 
		clanring_googlesheetsapikey);
};

//
// Validate the Google Sheets connection at server startup
// Called from clanring_exec_configs after loading clanring.cfg
//
void() gsheets_validate =
{
	if (!gsheets_configured())
	{
		dprint("Google Sheets not configured - using local files\n");
		return;
	}
	
	dprint("Validating Google Sheets connection...\n");
	
	string url = gsheets_build_url("validate");
	uri_get(url, GSHEETS_REQ_VALIDATE);
};

//
// Read captime records for current map from Google Sheets
//
void() gsheets_read_capture_stats =
{
	
	dprint(sprintf("Reading captimes from Google Sheets for %s...\n", mapname));
	
	// Store map name for callback
	if (gsheets_pending_map != "" && gsheets_pending_map != string_null)
		strunzone(gsheets_pending_map);
	gsheets_pending_map = strzone(mapname);
	gsheets_pending_read = TRUE;
	
	// Reset records before loading
	reset_records(0);
	reset_records(2);
	
	string url = sprintf("%s?action=read&map=%s&key=%s",
		clanring_googlesheetsurl,
		mapname,
		clanring_googlesheetsapikey);
	
	uri_get(url, GSHEETS_REQ_READ_TRIAL);
};

//
// Write a new record to Google Sheets
// rank: 1, 2, or 3
// is_match: TRUE for match record, FALSE for trial record
//
void(float is_match, float rank, string player, float teamcolor, 
     float captime, string rec_date, string mt_str) gsheets_write_record =
{
	if (!gsheets_enabled())
		return;
	
	dprint(sprintf("Writing captime to Google Sheets: %s %s rank %g time %g\n",
		mapname, is_match ? "match" : "trial", rank, captime));
	
	// Build JSON payload (include server hostname)
	string hostname_raw = cvar_string("hostname");
	string hostname_z = "";
	if (hostname_raw != "" && hostname_raw != string_null)
		hostname_z = strzone(hostname_raw);
	dprint(sprintf("Writing to Google Sheets: hostname='%s'\n", hostname_z));
	string hostname_url = uri_escape(utils_dequake_for_discord(hostname_z ? hostname_z : ""));
	if (hostname_url != "") hostname_url = strzone(hostname_url);
	string player_qhex = gsheets_hex_encode(player);
	if (player_qhex != "") player_qhex = strzone(player_qhex);
	string map_safe = gsheets_json_sanitize(mapname);
	if (map_safe != "") map_safe = strzone(map_safe);
	string player_safe = gsheets_json_sanitize(utils_dequake_for_discord(player));
	if (player_safe != "") player_safe = strzone(player_safe);
	string rec_date_safe = gsheets_json_sanitize(rec_date);
	if (rec_date_safe != "") rec_date_safe = strzone(rec_date_safe);
	string mt_str_safe = gsheets_json_sanitize(mt_str ? mt_str : "");
	if (mt_str_safe != "") mt_str_safe = strzone(mt_str_safe);
	string hostname_safe = gsheets_json_sanitize(utils_dequake_for_discord(hostname_z ? hostname_z : ""));
	if (hostname_safe != "") hostname_safe = strzone(hostname_safe);
	string date_url = uri_escape(rec_date_safe ? rec_date_safe : "");
	if (date_url != "") date_url = strzone(date_url);
	
	string url = sprintf("%s?action=write&key=%s%s%s%s%s",
		clanring_googlesheetsurl,
		clanring_googlesheetsapikey,
		hostname_url != "" ? "&server=" : "",
		hostname_url != "" ? hostname_url : "",
		date_url != "" ? "&date=" : "",
		date_url != "" ? date_url : "");
	if (url != "") url = strzone(url);
	string json_head = sprintf(
		"{\"map\":\"%s\",\"is_match\":%s,\"rank\":%g,\"player\":\"%s\",\"player_qhex\":\"%s\",\"teamcolor\":%g,\"time\":%g,",
		map_safe,
		is_match ? "true" : "false",
		rank,
		player_safe,
		player_qhex ? player_qhex : "",
		teamcolor,
		captime
	);
	string json_tail = sprintf(
		"\"date\":\"%s\",\"mt_str\":\"%s\",\"server\":\"%s\"}",
		rec_date_safe,
		mt_str_safe,
		hostname_safe
	);
	string json = strcat(json_head, json_tail);
	if (json != "") json = strzone(json);
	
	if (map_safe != "") strunzone(map_safe);
	if (player_safe != "") strunzone(player_safe);
	if (rec_date_safe != "") strunzone(rec_date_safe);
	if (mt_str_safe != "") strunzone(mt_str_safe);
	if (hostname_safe != "") strunzone(hostname_safe);
	if (hostname_z != "") strunzone(hostname_z);
	if (hostname_url != "") strunzone(hostname_url);
	if (player_qhex != "") strunzone(player_qhex);
	if (date_url != "") strunzone(date_url);
	
	float reqid = is_match ? GSHEETS_REQ_WRITE_MATCH : GSHEETS_REQ_WRITE_TRIAL;
	uri_get(url, reqid, "application/json", json);
	
	if (json != "") strunzone(json);
	if (url != "") strunzone(url);
};

//
// Parse JSON response for records
// Expects: {"map":"xxx","trial":[{...}],"match":[{...}]}
//
void(string body) gsheets_parse_records =
{
	// Simple JSON parsing - find trial and match arrays
	float pos, end;
	string chunk;
	
	// Parse trial records
	pos = strstrofs(body, "\"trial\":[", 0);
	if (pos >= 0)
	{
		pos += 9; // Skip past "trial":[
		end = strstrofs(body, "]", pos);
		if (end > pos)
		{
			chunk = substring(body, pos, end - pos);
			gsheets_parse_record_array(chunk, 0); // recordset 0 = trial
		}
	}
	
	// Parse match records
	pos = strstrofs(body, "\"match\":[", 0);
	if (pos >= 0)
	{
		pos += 9; // Skip past "match":[
		end = strstrofs(body, "]", pos);
		if (end > pos)
		{
			chunk = substring(body, pos, end - pos);
			gsheets_parse_record_array(chunk, 2); // recordset 2 = match
		}
	}
};

//
// Parse a JSON array of record objects
// recordset: 0 for trial (playerrecord), 2 for match (playerrecord2)
//
void(string arr, float recordset) gsheets_parse_record_array =
{
	// Parse each object in the array
	float pos = 0;
	float obj_start, obj_end;
	float rank = 0;
	
	while (TRUE)
	{
		obj_start = strstrofs(arr, "{", pos);
		if (obj_start < 0)
			break;
		
		obj_end = strstrofs(arr, "}", obj_start);
		if (obj_end < 0)
			break;
		
		string obj = substring(arr, obj_start, obj_end - obj_start + 1);
		
		// Extract fields from object
		string player_qhex = gsheets_json_get_string(obj, "player_qhex");
		string player = "";
		if (player_qhex != "")
			player = gsheets_hex_decode(player_qhex);
		if (player == "")
			player = gsheets_json_get_string(obj, "player");
		float teamcolor = gsheets_json_get_number(obj, "teamcolor");
		float captime = gsheets_json_get_number(obj, "time");
		string rec_date = gsheets_json_get_string(obj, "date");
		string mt_str = gsheets_json_get_string(obj, "mt_str");
		
		if (player != "" && captime > 0)
		{
			// Set metadata globals for check_player_*_record functions
			if (crx_meta_date != "") strunzone(crx_meta_date);
			crx_meta_date = strzone(rec_date);
			if (crx_meta_mt_str != "") strunzone(crx_meta_mt_str);
			crx_meta_mt_str = strzone(mt_str);
			
			if (recordset == 2)
				check_player_low_record2(captime, teamcolor, player);
			else
				check_player_low_record(captime, teamcolor, player);
		}
		
		pos = obj_end + 1;
		rank++;
		if (rank >= PLAYER_RECORDS_MAX_COUNT)
			break;
	}
};

//
// JSON helper: extract string value for a key
//
string(string json, string key) gsheets_json_get_string =
{
	string pattern = sprintf("\"%s\":\"", key);
	float pos = strstrofs(json, pattern, 0);
	if (pos < 0)
		return "";
	
	pos += strlen(pattern);
	float end = strstrofs(json, "\"", pos);
	if (end < 0)
		return "";
	
	return substring(json, pos, end - pos);
};

//
// JSON helper: extract number value for a key
//
float(string json, string key) gsheets_json_get_number =
{
	string pattern = sprintf("\"%s\":", key);
	float pos = strstrofs(json, pattern, 0);
	if (pos < 0)
		return 0;
	
	pos += strlen(pattern);
	// Skip whitespace
	while (substring(json, pos, 1) == " ")
		pos++;
	
	// Find end of number (next comma, brace, or bracket)
	float end = pos;
	string c;
	while (end < strlen(json))
	{
		c = substring(json, end, 1);
		if (c == "," || c == "}" || c == "]")
			break;
		end++;
	}
	
	return stof(substring(json, pos, end - pos));
};

//
// Handle HTTP response callbacks for Google Sheets requests
// Called from URI_Get_Callback in utils.qc
//
void(float reqid, float status, string body) gsheets_callback =
{
	switch (reqid)
	{
		case GSHEETS_REQ_VALIDATE:
		{
			if (status == 200 && strstrofs(body, "\"status\":\"ok\"", 0) >= 0)
			{
				clanring_googlesheets_valid = TRUE;
				dprint("Google Sheets validation successful\n");
			}
			else
			{
				clanring_googlesheets_valid = FALSE;
				dprint(sprintf("Google Sheets validation failed (status %g) - falling back to local files\n", status));
				if (body != "")
					dprint(sprintf("Response: %s\n", body));
			}
			break;
		}
		
		case GSHEETS_REQ_READ_TRIAL:
		{
			gsheets_pending_read = FALSE;
			
			if (status == 200)
			{
				dprint(sprintf("Google Sheets read successful for %s\n", gsheets_pending_map));
				gsheets_parse_records(body);
			}
			else
			{
				dprint(sprintf("Google Sheets read failed (status %g) - falling back to local files\n", status));
				// Fallback to local files
				read_player_stats(sprintf("%s_captimes.crx", gsheets_pending_map), RECORD_LOW, 0);
				read_player_stats(sprintf("%s_captimes_match.crx", gsheets_pending_map), RECORD_LOW, 2);
			}
			break;
		}
		
		case GSHEETS_REQ_WRITE_TRIAL:
		case GSHEETS_REQ_WRITE_MATCH:
		{
			if (status == 200)
			{
				dprint(sprintf("Google Sheets write successful: %s\n", body));
			}
			else
			{
				dprint(sprintf("Google Sheets write failed (status %g): %s\n", status, body));
			}
			break;
		}
	}
};
