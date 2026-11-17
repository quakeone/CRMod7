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

float(string value, float hash) gsheets_signature_add =
{
	float i;
	float c;

	for (i = 0; i < strlen(value); i = i + 1)
	{
		c = str2chr(value, i);
		if (c < 0)
			c = c + 256;
		hash = mod((hash * 33) + c, 16777213);
	}
	return hash;
};

float() gsheets_config_signature =
{
	float hash;

	if (!gsheets_configured())
		return 0;

	hash = gsheets_signature_add(clanring_googlesheetsurl, 5381);
	hash = gsheets_signature_add("|", hash);
	hash = gsheets_signature_add(clanring_googlesheetsapikey, hash);
	if (hash == 0)
		hash = 1;
	return hash;
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
	float signature;

	if (!gsheets_configured())
	{
		dprint("Google Sheets not configured - using local files\n");
		return;
	}
	
	signature = gsheets_config_signature();
	if (signature && cvar("cr_gsheets_validated_sig") == signature)
	{
		clanring_googlesheets_valid = TRUE;
		dprint("Google Sheets validation cached for this configuration\n");
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
	string date_url = uri_escape(rec_date ? rec_date : "");
	if (date_url != "") date_url = strzone(date_url);
	
	string url = sprintf("%s?action=write&key=%s%s%s%s%s",
		clanring_googlesheetsurl,
		clanring_googlesheetsapikey,
		hostname_url != "" ? "&server=" : "",
		hostname_url != "" ? hostname_url : "",
		date_url != "" ? "&date=" : "",
		date_url != "" ? date_url : "");
	if (url != "") url = strzone(url);
	json_begin_compact();
	json_begin_object();
		json_kv_string("map", mapname);
		json_kv_bool("is_match", is_match);
		json_kv_number("rank", rank);
		json_kv_string("player", utils_dequake_for_discord(player));
		json_kv_string("player_qhex", player_qhex);
		json_kv_number("teamcolor", teamcolor);
		json_kv_number("time", captime);
		if (ping > 0)
			json_kv_number("ping", floor(ping + 0.5));
		json_kv_string("date", rec_date);
		json_kv_string("mt_str", mt_str);
		json_kv_string("server", utils_dequake_for_discord(hostname_z));
	json_end_object();
	string json = strzone(json_result());
	
	if (hostname_z != "") strunzone(hostname_z);
	if (hostname_url != "") strunzone(hostname_url);
	if (player_qhex != "") strunzone(player_qhex);
	if (date_url != "") strunzone(date_url);
	
	float reqid = is_match ? GSHEETS_REQ_WRITE_MATCH : GSHEETS_REQ_WRITE_TRIAL;
	uri_get(url, reqid, "application/json", json);
	
	strunzone(json);
	if (url != "") strunzone(url);
};

//
// Error detector for Apps Script responses: anything that doesn't start as a
// JSON object, or an object with a top-level "error" key ({error: "..."}).
// The object may be incomplete: QSS-family engines can clip long responses,
// and the record readers still use every complete record before the cut.
//
float(string body) gsheets_body_has_error =
{
	if (!json_starts_object(body))
		return TRUE;
	return json_obj_has(body, "error");
};

//
// Parse JSON response for records
// Expects: {"map":"xxx","trial":[{...}],"match":[{...}]}
//
void(string body) gsheets_parse_records =
{
	string chunk;

	// Parse trial records
	chunk = json_obj_get_raw(body, "trial");
	if (chunk != "")
		gsheets_parse_record_array(chunk, 0); // recordset 0 = trial

	// Parse match records
	chunk = json_obj_get_raw(body, "match");
	if (chunk != "")
		gsheets_parse_record_array(chunk, 2); // recordset 2 = match
};

//
// Format top-3 lines from a JSON record array chunk (objects only)
//
string(string arr, float include_mt, string empty_msg) gsheets_format_top3_from_array =
{
	arr = strzone(arr); // protect from tempstring recycling

	float pos = 0;
	float count = 0;
	string out = "";
	string obj, player_qhex, player_json, player, decoded;
	string rec_date, mt_str, meta, prefix, line;
	float teamcolor, captime, ping;

	while (count < 3)
	{
		obj = json_array_next_object(arr, pos);
		if (obj == "")
			break;
		pos = json__it_next;
		obj = strzone(obj);

		player_qhex = json_obj_get_string(obj, "player_qhex", "");
		player_json = json_obj_get_string(obj, "player", "");
		player = "";
		if (player_qhex != "")
		{
			decoded = gsheets_hex_decode(player_qhex);
			if (decoded != "" && strlen(decoded) >= 2)
				player = decoded;
		}
		if (player == "")
			player = player_json;
		teamcolor = json_obj_get_float(obj, "teamcolor", 0);
		captime = json_obj_get_float(obj, "time", 0);
		rec_date = json_obj_get_string(obj, "date", "");
		mt_str = json_obj_get_string(obj, "mt_str", "");
		ping = json_obj_get_float(obj, "ping", 0);

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
	string chunk;

	chunk = json_obj_get_raw(body, key);
	if (chunk == "")
		return strcat(empty_msg, "\n");
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
	float rank = 0;
	string obj;

	while (TRUE)
	{
		obj = json_array_next_object(arr, pos);
		if (obj == "")
			break;
		pos = json__it_next;
		obj = strzone(obj);

		// Extract fields from object
		string player_qhex = json_obj_get_string(obj, "player_qhex", "");
		string player_json = json_obj_get_string(obj, "player", "");
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
		float teamcolor = json_obj_get_float(obj, "teamcolor", 0);
		float captime = json_obj_get_float(obj, "time", 0);
		string rec_date = json_obj_get_string(obj, "date", "");
		string mt_str = json_obj_get_string(obj, "mt_str", "");
		float ping = json_obj_get_float(obj, "ping", 0);

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

		rank++;
		if (rank >= PLAYER_RECORDS_MAX_COUNT)
			break;
	}

	strunzone(arr);
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

	body_map = json_obj_get_string(body, "map", "");
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
			if (status == 200 && json_obj_get_string(body, "status", "") == "ok")
			{
				clanring_googlesheets_valid = TRUE;
				cvar_set("cr_gsheets_validated_sig", ftos(gsheets_config_signature()));
				dprint("Google Sheets validation successful\n");
			}
			else
			{
				clanring_googlesheets_valid = FALSE;
				cvar_set("cr_gsheets_validated_sig", "0");
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
