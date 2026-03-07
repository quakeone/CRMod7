//
//  G O O G L E S H E E T S . q c
//
// Google Sheets integration for captime records.
// Uses a published Google Apps Script as an intermediary API.
//

// Request IDs for async HTTP callbacks
float GSHEETS_REQ_READ_TRIAL  = 200;
float GSHEETS_REQ_READ_LOOKUP = 201;
float GSHEETS_REQ_WRITE_TRIAL = 202;
float GSHEETS_REQ_WRITE_MATCH = 203;
float GSHEETS_REQ_VALIDATE    = 204;
float GSHEETS_REQ_READ_MATCH  = 205;
float GSHEETS_REQ_LOOKUP_MATCH = 206;

// Pending request tracking
float gsheets_pending_read;    // TRUE while waiting for read response
string gsheets_pending_map;    // Map name for pending request
float gsheets_last_read_used_google; // TRUE when current map records came from gsheets response
float gsheets_current_map_trial_loaded; // TRUE when current map trial records loaded from Sheets
float gsheets_current_map_match_loaded; // TRUE when current map match records loaded from Sheets
float gsheets_lookup_pending;  // TRUE while waiting for lookup-map response
entity gsheets_lookup_client;  // requester for lookup-map response
string gsheets_lookup_map;     // requested lookup map
string gsheets_lookup_trial_lines; // formatted trial output waiting for match request

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
// TRUE once a read has been issued for the current map (pending or completed)
//
float() gsheets_read_started_current_map =
{
	if (!gsheets_configured())
		return FALSE;
	if (gsheets_pending_map == "" || gsheets_pending_map == string_null)
		return FALSE;
	if (gsheets_pending_map != mapname)
		return FALSE;
	return TRUE;
};

//
// TRUE while a read is currently in flight for the current map
//
float() gsheets_read_inflight_current_map =
{
	if (!gsheets_read_started_current_map())
		return FALSE;
	if (!gsheets_pending_read)
		return FALSE;
	return TRUE;
};

//
// TRUE when current-map trial records are loaded and ready from Google Sheets.
// Returns TRUE when Sheets is not configured (local records are authoritative then).
//
float() gsheets_trial_records_ready_current_map =
{
	if (!gsheets_configured())
		return TRUE;
	if (!gsheets_read_started_current_map())
		return FALSE;
	if (gsheets_read_inflight_current_map())
		return FALSE;
	if (!gsheets_current_map_trial_loaded)
		return FALSE;
	return TRUE;
};

//
// TRUE when current-map match records are loaded and ready from Google Sheets.
// Returns TRUE when Sheets is not configured (local records are authoritative then).
//
float() gsheets_match_records_ready_current_map =
{
	if (!gsheets_configured())
		return TRUE;
	if (!gsheets_read_started_current_map())
		return FALSE;
	if (gsheets_read_inflight_current_map())
		return FALSE;
	if (!gsheets_current_map_match_loaded)
		return FALSE;
	return TRUE;
};

//
// Source label for current in-memory CTF captime records
//
string() gsheets_captimes_source_title =
{
	if (gsheets_configured()
		&& gsheets_pending_map != "" && gsheets_pending_map != string_null
		&& gsheets_pending_map == mapname
		&& !gsheets_pending_read
		&& gsheets_last_read_used_google)
		return "CTF Capture Records (Google Sheet)";
	return "CTF Capture Records (Local Records)";
};

//
// Read captime records for an arbitrary map (for cmd captimes <map>)
// Returns TRUE if async request was dispatched.
//
float(string lookup_map, entity requester) gsheets_read_capture_stats_lookup =
{
	if (!gsheets_configured())
		return FALSE;
	if (!requester || requester == world)
		return FALSE;
	if (lookup_map == "" || lookup_map == string_null)
		return FALSE;
	if (gsheets_lookup_pending)
		return FALSE;

	if (gsheets_lookup_map != "" && gsheets_lookup_map != string_null)
		strunzone(gsheets_lookup_map);
	gsheets_lookup_map = strzone(lookup_map);
	gsheets_lookup_client = requester;
	gsheets_lookup_pending = TRUE;

	string url = sprintf("%s?action=read&map=%s&type=trial&key=%s",
		clanring_googlesheetsurl,
		lookup_map,
		clanring_googlesheetsapikey);

	uri_get(url, GSHEETS_REQ_READ_LOOKUP);
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
	gsheets_last_read_used_google = FALSE;
	gsheets_current_map_trial_loaded = FALSE;
	gsheets_current_map_match_loaded = FALSE;
	
	// Reset records before loading
	reset_records(0);
	reset_records(2);
	
	string url = sprintf("%s?action=read&map=%s&type=trial&key=%s",
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
     float captime, string rec_date, string mt_str, float ping) gsheets_write_record =
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
	string json = sprintf(
		"{\"map\":\"%s\",\"is_match\":%s,\"rank\":%g,\"player\":\"%s\",\"player_qhex\":\"%s\",\"teamcolor\":%g,\"time\":%g",
		map_safe,
		is_match ? "true" : "false",
		rank,
		player_safe,
		player_qhex ? player_qhex : "",
		teamcolor,
		captime
	);
	if (ping > 0)
		json = strcat(json, sprintf(",\"ping\":%g", floor(ping + 0.5)));
	json = strcat(json, sprintf(",\"date\":\"%s\",\"mt_str\":\"%s\",\"server\":\"%s\"}", rec_date_safe, mt_str_safe, hostname_safe));
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
// Find the matching close bracket ']' for an already-opened '[',
// skipping nested brackets and quoted strings.
// 'start' should point to the first char inside the '['.
// Returns the index of the matching ']', or -1 if not found.
//
float(string body, float start) gsheets_find_array_end =
{
	float depth = 1;
	float i = start;
	float len = strlen(body);
	float cc;

	while (i < len && depth > 0)
	{
		cc = str2chr(body, i);
		if (cc == 34) // '"'
		{
			// Skip quoted string
			i = i + 1;
			while (i < len)
			{
				cc = str2chr(body, i);
				if (cc == 92) { i = i + 2; continue; } // backslash
				if (cc == 34) break; // '"'
				i = i + 1;
			}
		}
		else if (cc == 91) // '['
			depth = depth + 1;
		else if (cc == 93) // ']'
			depth = depth - 1;
		if (depth > 0)
			i = i + 1;
	}

	if (depth == 0)
		return i;
	return -1;
};

//
// Find the matching close brace '}' for an already-opened '{',
// skipping nested braces and quoted strings.
// 'start' should point to the first char inside the '{'.
// Returns the index of the matching '}', or -1 if not found.
//
float(string body, float start) gsheets_find_object_end =
{
	float depth = 1;
	float i = start;
	float len = strlen(body);
	float cc;

	while (i < len && depth > 0)
	{
		cc = str2chr(body, i);
		if (cc == 34) // '"'
		{
			// Skip quoted string
			i = i + 1;
			while (i < len)
			{
				cc = str2chr(body, i);
				if (cc == 92) { i = i + 2; continue; } // backslash
				if (cc == 34) break; // '"'
				i = i + 1;
			}
		}
		else if (cc == 123) // '{'
			depth = depth + 1;
		else if (cc == 125) // '}'
			depth = depth - 1;
		if (depth > 0)
			i = i + 1;
	}

	if (depth == 0)
		return i;
	return -1;
};

//
// Whitespace helper for lightweight JSON parsing
//
float(float cc) gsheets_is_json_ws =
{
	if (cc == 32 || cc == 10 || cc == 13 || cc == 9) // space, \n, \r, \t
		return TRUE;
	return FALSE;
};

//
// Quick error detector for Apps Script JSON responses
//
float(string body) gsheets_body_has_error =
{
	if (body == "" || body == string_null)
		return TRUE;
	if (strstrofs(body, "\"error\"", 0) >= 0)
		return TRUE;
	return FALSE;
};

//
// Parse JSON response for records
// Expects: {"map":"xxx","trial":[{...}],"match":[{...}]}
//
void(string body) gsheets_parse_records =
{
	float pos, end;
	string chunk;

	// Parse trial records
	pos = strstrofs(body, "\"trial\"", 0);
	if (pos >= 0)
	{
		pos = strstrofs(body, "[", pos);
		if (pos >= 0)
		{
			pos += 1; // first char inside '['
			end = gsheets_find_array_end(body, pos);
			if (end > pos)
			{
				chunk = substring(body, pos, end - pos);
				gsheets_parse_record_array(chunk, 0); // recordset 0 = trial
			}
		}
	}

	// Parse match records
	pos = strstrofs(body, "\"match\"", 0);
	if (pos >= 0)
	{
		pos = strstrofs(body, "[", pos);
		if (pos >= 0)
		{
			pos += 1; // first char inside '['
			end = gsheets_find_array_end(body, pos);
			if (end > pos)
			{
				chunk = substring(body, pos, end - pos);
				gsheets_parse_record_array(chunk, 2); // recordset 2 = match
			}
		}
	}
};

//
// Format top-3 lines from a JSON record array chunk (objects only)
//
string(string arr, float include_mt, string empty_msg) gsheets_format_top3_from_array =
{
	arr = strzone(arr); // protect from tempstring recycling

	float pos = 0;
	float obj_start, obj_end;
	float count = 0;
	string out = "";
	string obj, player_qhex, player_json, player, decoded;
	string rec_date, mt_str, meta, prefix, line;
	float teamcolor, captime, ping;

	while (count < 3)
	{
		obj_start = strstrofs(arr, "{", pos);
		if (obj_start < 0)
			break;

		obj_end = gsheets_find_object_end(arr, obj_start + 1);
		if (obj_end < 0)
			break;

		obj = strzone(substring(arr, obj_start, obj_end - obj_start + 1));

		player_qhex = gsheets_json_get_string(obj, "player_qhex");
		player_json = gsheets_json_get_string(obj, "player");
		player = "";
		if (player_qhex != "")
		{
			decoded = gsheets_hex_decode(player_qhex);
			if (decoded != "" && strlen(decoded) >= 2)
				player = decoded;
		}
		if (player == "")
			player = player_json;
		teamcolor = gsheets_json_get_number(obj, "teamcolor");
		captime = gsheets_json_get_number(obj, "time");
		rec_date = gsheets_json_get_string(obj, "date");
		mt_str = gsheets_json_get_string(obj, "mt_str");
		ping = gsheets_json_get_number(obj, "ping");

		strunzone(obj);

		if (player != "" && captime > 0)
		{
			if (count == 0) prefix = "\1";
			else if (count == 1) prefix = "\2";
			else prefix = "\3";

			line = sprintf("%s  %s %s %s", prefix, utils_get_time(captime), get_team_letter(teamcolor), player);
			meta = format_rec_meta(rec_date, mt_str, ping > 0 ? ping : -1, include_mt);
			if (meta != "")
				line = strcat(line, meta);
			out = strcat(out, line, "\n");
			count = count + 1;
		}

		pos = obj_end + 1;
	}

	strunzone(arr);

	if (out == "")
		return strcat(empty_msg, "\n");
	return out;
};

//
// Locate trial/match array in response body and format top-3 lines
//
string(string body, string key, float include_mt, string empty_msg) gsheets_format_top3_from_body =
{
	float pos, end;
	string chunk;

	pos = strstrofs(body, sprintf("\"%s\"", key), 0);
	if (pos < 0)
		return strcat(empty_msg, "\n");
	pos = strstrofs(body, "[", pos);
	if (pos < 0)
		return strcat(empty_msg, "\n");
	pos = pos + 1;
	end = gsheets_find_array_end(body, pos);
	if (end <= pos)
		return strcat(empty_msg, "\n");

	chunk = substring(body, pos, end - pos);
	return gsheets_format_top3_from_array(chunk, include_mt, empty_msg);
};

//
// Parse a JSON array of record objects
// recordset: 0 for trial (playerrecord), 2 for match (playerrecord2)
//
void(string arr, float recordset) gsheets_parse_record_array =
{
	arr = strzone(arr); // protect from tempstring recycling

	// Parse each object in the array
	float pos = 0;
	float obj_start, obj_end;
	float rank = 0;

	while (TRUE)
	{
		obj_start = strstrofs(arr, "{", pos);
		if (obj_start < 0)
			break;

		obj_end = gsheets_find_object_end(arr, obj_start + 1);
		if (obj_end < 0)
			break;

		string obj = strzone(substring(arr, obj_start, obj_end - obj_start + 1));

		// Extract fields from object
		string player_qhex = gsheets_json_get_string(obj, "player_qhex");
		string player_json = gsheets_json_get_string(obj, "player");
		string player = "";
		if (player_qhex != "")
		{
			string decoded = gsheets_hex_decode(player_qhex);
			// Guard against legacy sheets where ping could be read from the qhex column.
			if (decoded != "" && strlen(decoded) >= 2)
				player = decoded;
		}
		if (player == "")
			player = player_json;
		float teamcolor = gsheets_json_get_number(obj, "teamcolor");
		float captime = gsheets_json_get_number(obj, "time");
		string rec_date = gsheets_json_get_string(obj, "date");
		string mt_str = gsheets_json_get_string(obj, "mt_str");
		float ping = gsheets_json_get_number(obj, "ping");

		strunzone(obj);

		if (player != "" && captime > 0)
		{
			// Set metadata globals for check_player_*_record functions
			if (crx_meta_date != "") strunzone(crx_meta_date);
			crx_meta_date = strzone(rec_date);
			crx_meta_mt_remain = -1; // not stored in gsheets; use mt_str instead
			if (crx_meta_mt_str != "") strunzone(crx_meta_mt_str);
			crx_meta_mt_str = strzone(mt_str);
			if (ping > 0)
				crx_meta_ping = ping;
			else
				crx_meta_ping = -1;

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

	strunzone(arr);
};

//
// JSON helper: extract string value for a key
//
string(string json, string key) gsheets_json_get_string =
{
	string pattern = sprintf("\"%s\"", key);
	float pos = strstrofs(json, pattern, 0);
	if (pos < 0)
		return "";

	pos += strlen(pattern);

	// Skip whitespace before colon
	while (pos < strlen(json) && gsheets_is_json_ws(str2chr(json, pos)))
		pos++;
	if (str2chr(json, pos) != 58) // ':'
		return "";
	pos++;

	// Skip whitespace after colon
	while (pos < strlen(json) && gsheets_is_json_ws(str2chr(json, pos)))
		pos++;
	if (str2chr(json, pos) != 34) // '"'
		return "";
	pos++;

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
	string pattern = sprintf("\"%s\"", key);
	float pos = strstrofs(json, pattern, 0);
	if (pos < 0)
		return 0;

	pos += strlen(pattern);

	// Skip whitespace before colon
	while (pos < strlen(json) && gsheets_is_json_ws(str2chr(json, pos)))
		pos++;
	if (str2chr(json, pos) != 58) // ':'
		return 0;
	pos++;

	// Skip whitespace after colon
	while (pos < strlen(json) && gsheets_is_json_ws(str2chr(json, pos)))
		pos++;

	// Accept quoted numbers too, e.g. "time":"2.56"
	if (str2chr(json, pos) == 34) // '"'
	{
		pos++;
		float endq = strstrofs(json, "\"", pos);
		if (endq < 0)
			return 0;
		return stof(substring(json, pos, endq - pos));
	}

	// Find end of number (next comma, brace, or bracket)
	float end = pos;
	float cc;
	while (end < strlen(json))
	{
		cc = str2chr(json, end);
		if (cc == 44 || cc == 125 || cc == 93) // ',', '}', ']'
			break;
		end++;
	}

	return stof(substring(json, pos, end - pos));
};

//
// Best-effort stale-response check: if body has a map field and it does not
// match the requested map, ignore this callback.
//
float(string body, string wanted_map) gsheets_response_matches_map =
{
	string body_map;

	if (wanted_map == "" || wanted_map == string_null)
		return TRUE;

	body_map = gsheets_json_get_string(body, "map");
	if (body_map == "" || body_map == string_null)
		return TRUE; // Cannot verify; accept.

	if (strtolower(body_map) == strtolower(wanted_map))
		return TRUE;
	return FALSE;
};

//
// Handle HTTP response callbacks for Google Sheets requests
// Called from URI_Get_Callback in utils.qc
//
void(float reqid, float status, string body) gsheets_callback =
{
	body = strzone(body); // protect from tempstring recycling during parsing

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
				dprint(sprintf("Google Sheets validation failed (status %g)\n", status));
				if (body != "")
					dprint(sprintf("Response: %s\n", body));
			}
			break;
		}
		
			case GSHEETS_REQ_READ_TRIAL:
			{
				if (!gsheets_response_matches_map(body, gsheets_pending_map))
				{
					dprint(sprintf("Google Sheets trial read ignored for stale map response (wanted %s)\n", gsheets_pending_map));
					break;
				}

				if (status == 200 && !gsheets_body_has_error(body))
				{
					gsheets_current_map_trial_loaded = TRUE;
					dprint(sprintf("Google Sheets trial read successful for %s\n", gsheets_pending_map));
					gsheets_parse_records(body);
				}
				else
				{
					gsheets_current_map_trial_loaded = FALSE;
					dprint(sprintf("Google Sheets trial read failed (status %g)\n", status));
					if (body != "")
						dprint(sprintf("Response: %s\n", body));
				}
				gsheets_last_read_used_google = (gsheets_current_map_trial_loaded || gsheets_current_map_match_loaded);

				// Fire match request separately to stay under QC string length limit
				string match_url = sprintf("%s?action=read&map=%s&type=match&key=%s",
					clanring_googlesheetsurl,
					gsheets_pending_map,
					clanring_googlesheetsapikey);
				uri_get(match_url, GSHEETS_REQ_READ_MATCH);
				break;
			}

			case GSHEETS_REQ_READ_MATCH:
			{
				if (!gsheets_response_matches_map(body, gsheets_pending_map))
				{
					dprint(sprintf("Google Sheets match read ignored for stale map response (wanted %s)\n", gsheets_pending_map));
					break;
				}

				gsheets_pending_read = FALSE;

				if (status == 200 && !gsheets_body_has_error(body))
				{
					gsheets_current_map_match_loaded = TRUE;
					dprint(sprintf("Google Sheets match read successful for %s\n", gsheets_pending_map));
					gsheets_parse_records(body);
				}
				else
				{
					gsheets_current_map_match_loaded = FALSE;
					dprint(sprintf("Google Sheets match read failed (status %g)\n", status));
					if (body != "")
						dprint(sprintf("Response: %s\n", body));
				}
				gsheets_last_read_used_google = (gsheets_current_map_trial_loaded || gsheets_current_map_match_loaded);
				break;
			}

			case GSHEETS_REQ_READ_LOOKUP:
			{
				string trial_lines;

				if (!gsheets_lookup_client || gsheets_lookup_client == world)
				{
					if (gsheets_lookup_map != "" && gsheets_lookup_map != string_null)
						strunzone(gsheets_lookup_map);
					gsheets_lookup_map = "";
					gsheets_lookup_pending = FALSE;
					break;
				}

				if (status == 200 && !gsheets_body_has_error(body))
				{
					trial_lines = gsheets_format_top3_from_body(body, "trial", FALSE, "No capture times set");
				}
				else
				{
					dprint(sprintf("Google Sheets lookup failed for %s (status %g)\n", gsheets_lookup_map, status));
					if (body != "")
						dprint(sprintf("Google Sheets lookup failed body: %s\n", body));
					trial_lines = "No capture times set\n";
				}

				// Store trial output and fire match request
				if (gsheets_lookup_trial_lines != "" && gsheets_lookup_trial_lines != string_null)
					strunzone(gsheets_lookup_trial_lines);
				gsheets_lookup_trial_lines = strzone(trial_lines);

				string lookup_match_url = sprintf("%s?action=read&map=%s&type=match&key=%s",
					clanring_googlesheetsurl,
					gsheets_lookup_map,
					clanring_googlesheetsapikey);
				uri_get(lookup_match_url, GSHEETS_REQ_LOOKUP_MATCH);
				break;
			}

			case GSHEETS_REQ_LOOKUP_MATCH:
			{
				string match_lines, title;

				gsheets_lookup_pending = FALSE;

				if (!gsheets_lookup_client || gsheets_lookup_client == world)
				{
					if (gsheets_lookup_map != "" && gsheets_lookup_map != string_null)
						strunzone(gsheets_lookup_map);
					gsheets_lookup_map = "";
					if (gsheets_lookup_trial_lines != "" && gsheets_lookup_trial_lines != string_null)
						strunzone(gsheets_lookup_trial_lines);
					gsheets_lookup_trial_lines = "";
					break;
				}

				if (status == 200 && !gsheets_body_has_error(body))
				{
					match_lines = gsheets_format_top3_from_body(body, "match", TRUE, "No match capture times set");
				}
				else
				{
					dprint(sprintf("Google Sheets lookup match failed for %s (status %g)\n", gsheets_lookup_map, status));
					match_lines = "No match capture times set\n";
				}

				title = strcat("CTF Capture Records (Google Sheet)\n\n", sprintf("\bTime Trial Leaders\b for %s:\n", gsheets_lookup_map));
				sprint(gsheets_lookup_client, title, gsheets_lookup_trial_lines, "\n\bMatch Times\b:\n", match_lines, "\n");

				if (gsheets_lookup_trial_lines != "" && gsheets_lookup_trial_lines != string_null)
					strunzone(gsheets_lookup_trial_lines);
				gsheets_lookup_trial_lines = "";

				if (gsheets_lookup_map != "" && gsheets_lookup_map != string_null)
					strunzone(gsheets_lookup_map);
				gsheets_lookup_map = "";
				gsheets_lookup_client = world;
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

	strunzone(body);
};
