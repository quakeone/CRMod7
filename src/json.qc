// json.qc — JSON helpers
// -----------------------------------------------------------------------------
// Contents
//   1) Constants & Globals
//   2) String Helpers (FTE/QSS compatible)
//   3) Emit/Sink (stream routing)
//   4) Builder Core (state + primitives)
//   5) Value Writers & Convenience
//   6) Minimal Reader Helpers
//   7) Streaming Reader Helpers (no long substrings)
//   8) Utility Helpers (pct, blank checks, escaping, etc.)
//   9) Domain Helper: gametype/playmode
//  10) Public APIs: json_export_match_to_file / json_append_lastscores / utils_show_last_scores
// -----------------------------------------------------------------------------

// ============================================================================
// 1) Constants & Globals
// ============================================================================
float JSON_MAX_DEPTH = 32;
float JSON_CTX_OBJECT = 1;
float JSON_CTX_ARRAY  = 2;

string json__buf;
float  json__depth;
float  json__ctx[32];
float  json__count[32];
float  json__pretty;      // 0 = compact, 1 = pretty with two-space indents
float  json__pending_key; // 1 when an object key was just emitted
float  json__pend_depth;

// Streaming sink: declare WITHOUT initializer (FTE makes initialized globals const).
// Use an enable flag to control writes to the sink.
float json__sink_fh;
float json__sink_enabled;

string json__spaces = "                                                                "; // 64 spaces
string json__hex    = "0123456789abcdef";


// ============================================================================
// 2) String Helpers (FTE/QSS compatible)
// ============================================================================
float  str_len(string s){ return strlen(s); }
string str_sub(string s, float start, float count){ return substring(s, start, count); }
float  str_chr(string onechar){ return str2chr(onechar, 0); } // FTE sig: str2chr(s, index)
float  str_index_of(string hay, string needle, float start){ return strstrofs(hay, needle, start); }

// trim trailing spaces (right-trim)
string str_rtrim(string s)
{
    if (!s) return "";
    float n = str_len(s);
    while (n > 0)
    {
        if (str_chr(str_sub(s, n-1, 1)) == 32) n = n - 1;
        else break;
    }
    return str_sub(s, 0, n);
}

// hex escape for control chars: \u00xx
string json__u00xx(float ch)
{
    float n = ch & 255;
    float hi = (n & 240) / 16;
    float lo = (n & 15);
    return strcat("\\u00", str_sub(json__hex, hi, 1), str_sub(json__hex, lo, 1));
}

// Escape a JSON string safely
string json_escape(string s)
{
    if (!s) return "";
    float n = str_len(s);
    float i = 0;
    string out = "";
    while (i < n)
    {
        string c = str_sub(s, i, 1);
        float  v = str_chr(c);
        if (v == 34)       out = strcat(out, "\\\"");     // '"'
        else if (v == 92)  out = strcat(out, "\\\\");     // '\\'
        else if (v == 10)  out = strcat(out, "\\n");
        else if (v == 13)  out = strcat(out, "\\r");
        else if (v == 9)   out = strcat(out, "\\t");
        else if (v < 32)   out = strcat(out, json__u00xx(v));
        else               out = strcat(out, c);
        i = i + 1;
    }
    return out;
}

// Trim trailing zeros from ftos output (keep integers compact)
string json_ftos_trim(float f)
{
    string s = ftos(f);
    if (str_index_of(s, ".", 0) < 0) return s;
    float i = str_len(s) - 1;
    while (i >= 0 && str_sub(s, i, 1) == "0") { s = str_sub(s, 0, i); i = i - 1; }
    if (i >= 0 && str_sub(s, i, 1) == ".") { s = str_sub(s, 0, i); }
    return s;
}


// ============================================================================
// 3) Emit/Sink (stream routing)
// ============================================================================
void json__emit(string s)
{
    if (json__sink_enabled) fputs(json__sink_fh, s);
    else                    json__buf = strcat(json__buf, s);
}

// NOTE: some FTE setups alias 'filestream' to const; use float here.
void json_set_sink(float f){ json__sink_fh = f; json__sink_enabled = 1; }
void json_clear_sink(){ json__sink_enabled = 0; }


// ============================================================================
// 4) Builder Core (state + primitives)
// ============================================================================
void json__reset()
{
    json__buf = "";
    json__depth = 0;
    json__pending_key = 0;
    json__pend_depth = 0;
    float k = 0;
    while (k < JSON_MAX_DEPTH)
    {
        json__ctx[k] = 0;
        json__count[k] = 0;
        k = k + 1;
    }
}

void json_begin_pretty(float pretty){ json__reset(); json__pretty = pretty; }
void json_begin_compact(){ json_begin_pretty(0); }
string json_result(){ return json__buf; }

void json_begin_pretty_to_file(float f, float pretty){ json_set_sink(f); json_begin_pretty(pretty); }
void json_begin_compact_to_file(float f){ json_begin_pretty_to_file(f, 0); }

void json__indent_line()
{
    if (!json__pretty) return;
    json__emit("\n");
    float need = json__depth * 2; if (need > 64) need = 64;
    json__emit(str_sub(json__spaces, 0, need));
}

void json__push(float ctx){ json__depth = json__depth + 1; json__ctx[json__depth] = ctx; json__count[json__depth] = 0; }
void json__pop(){ json__depth = json__depth - 1; }


// ============================================================================
// 5) Value Writers & Convenience
// ============================================================================
void json_begin_object()
{
    if (json__depth > 0 && json__ctx[json__depth] == JSON_CTX_ARRAY)
    {
        if (json__count[json__depth] > 0) json__emit(",");
        json__indent_line();
        json__count[json__depth] = json__count[json__depth] + 1;
    }
    if (json__pending_key && json__pend_depth == json__depth) json__pending_key = 0;
    json__emit("{");
    json__push(JSON_CTX_OBJECT);
    if (json__pretty) json__indent_line();
}

void json_end_object()
{
    float had_items = json__count[json__depth] > 0;
    if (json__pretty && had_items)
    {
        json__emit("\n");
        float need = (json__depth - 1) * 2; if (need > 64) need = 64;
        json__emit(str_sub(json__spaces, 0, need));
    }
    json__emit("}");
    json__pop();
    if (json__depth >= 1 && json__ctx[json__depth] == JSON_CTX_OBJECT) json__count[json__depth] = json__count[json__depth] + 1;
}

void json_begin_array()
{
    if (json__depth > 0 && json__ctx[json__depth] == JSON_CTX_ARRAY)
    {
        if (json__count[json__depth] > 0) json__emit(",");
        json__indent_line();
        json__count[json__depth] = json__count[json__depth] + 1;
    }
    if (json__pending_key && json__pend_depth == json__depth) json__pending_key = 0;
    json__emit("[");
    json__push(JSON_CTX_ARRAY);
    if (json__pretty) json__indent_line();
}

void json_end_array()
{
    float had_items = json__count[json__depth] > 0;
    if (json__pretty && had_items)
    {
        json__emit("\n");
        float need = (json__depth - 1) * 2; if (need > 64) need = 64;
        json__emit(str_sub(json__spaces, 0, need));
    }
    json__emit("]");
    json__pop();
    if (json__depth >= 1 && json__ctx[json__depth] == JSON_CTX_OBJECT) json__count[json__depth] = json__count[json__depth] + 1;
}

void json__array_prepare_value(){ if (json__count[json__depth] > 0) json__emit(","); json__indent_line(); }

void json_key(string key)
{
    if (json__ctx[json__depth] != JSON_CTX_OBJECT) return;
    if (json__count[json__depth] > 0) json__emit(",");
    json__indent_line();
    json__emit(strcat("\"", json_escape(key), "\":"));
    if (json__pretty) json__emit(" ");
    json__pending_key = 1; json__pend_depth = json__depth;
}

void json_string(string v)
{
    if (json__ctx[json__depth] == JSON_CTX_ARRAY) { json__array_prepare_value(); json__count[json__depth] = json__count[json__depth] + 1; }
    else if (json__pending_key && json__pend_depth == json__depth) { json__pending_key = 0; json__count[json__depth] = json__count[json__depth] + 1; }
    json__emit(strcat("\"", json_escape(v), "\""));
}

void json_number(float v)
{
    if (json__ctx[json__depth] == JSON_CTX_ARRAY) { json__array_prepare_value(); json__count[json__depth] = json__count[json__depth] + 1; }
    else if (json__pending_key && json__pend_depth == json__depth) { json__pending_key = 0; json__count[json__depth] = json__count[json__depth] + 1; }
    json__emit(json_ftos_trim(v));
}

void json_bool(float truthy)
{
    if (json__ctx[json__depth] == JSON_CTX_ARRAY) { json__array_prepare_value(); json__count[json__depth] = json__count[json__depth] + 1; }
    else if (json__pending_key && json__pend_depth == json__depth) { json__pending_key = 0; json__count[json__depth] = json__count[json__depth] + 1; }
    json__emit(truthy ? "true" : "false");
}

void json_null()
{
    if (json__ctx[json__depth] == JSON_CTX_ARRAY) { json__array_prepare_value(); json__count[json__depth] = json__count[json__depth] + 1; }
    else if (json__pending_key && json__pend_depth == json__depth) { json__pending_key = 0; json__count[json__depth] = json__count[json__depth] + 1; }
    json__emit("null");
}

// convenience
void json_kv_string(string k, string v){ json_key(k); json_string(v); }
void json_kv_number(string k, float v){ json_key(k); json_number(v); }
void json_kv_bool  (string k, float b){ json_key(k); json_bool(b); }
void json_kv_null  (string k){ json_key(k); json_null(); }


// ============================================================================
// 6) Minimal Reader Helpers (optional; handy elsewhere)
// ============================================================================
string json_minify(string s)
{
    if (!s) return "";
    float i = 0, n = str_len(s);
    float in_str = 0, esc = 0;
    string out = "";
    while (i < n)
    {
        string c = str_sub(s, i, 1); float v = str_chr(c);
        if (in_str)
        {
            out = strcat(out, c);
            if (esc) esc = 0; else if (v == 92) esc = 1; else if (v == 34) in_str = 0;
            i = i + 1; continue;
        }
        if (v == 34) { in_str = 1; out = strcat(out, c); i = i + 1; continue; }
        if (v == 32 || v == 9 || v == 10 || v == 13) { i = i + 1; continue; }
        out = strcat(out, c); i = i + 1;
    }
    return out;
}

float json__it_next;
string json_array_next_object(string arr, float pos)
{
    json__it_next = -1; if (!arr) return "";
    float n = str_len(arr); float i = pos; float depth = 0, in_str = 0, esc = 0;
    while (i < n)
    {
        string c = str_sub(arr, i, 1); float v = str_chr(c);
        if (in_str){ if (esc) esc = 0; else if (v == 92) esc = 1; else if (v == 34) in_str = 0; i = i + 1; continue; }
        if (v == 34) { in_str = 1; i = i + 1; continue; }
        if (v == 91) { depth = depth + 1; i = i + 1; continue; }
        if (v == 93) { depth = depth - 1; i = i + 1; continue; }
        if (v == 123 && depth == 1)
        {
            float start = i; float d = 1; i = i + 1;
            while (i < n && d > 0)
            {
                c = str_sub(arr, i, 1); v = str_chr(c);
                if (in_str){ if (esc) esc = 0; else if (v == 92) esc = 1; else if (v == 34) in_str = 0; i = i + 1; continue; }
                if (v == 34) { in_str = 1; i = i + 1; continue; }
                if (v == 123) d = d + 1; else if (v == 125) d = d - 1; i = i + 1;
            }
            float end = i; json__it_next = end; return str_sub(arr, start, end - start);
        }
        i = i + 1;
    }
    return "";
}

string json_trim(string s)
{
    if (!s) return "";
    float a = 0, b = strlen(s);
    string ch;
    while (a < b)
    {
        ch = substring(s, a, 1);
        if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") a = a + 1;
        else break;
    }
    while (b > a)
    {
        ch = substring(s, b - 1, 1);
        if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") b = b - 1;
        else break;
    }
    return substring(s, a, b - a);
}

string json_obj_get_string(string obj, string key, string defval)
{
    if (!obj) { return defval; }

    // Clone into stable memory so tempstrings in this function can't corrupt it.
    string OBJ = strzone(obj);

    float n = strlen(OBJ);
    float i = 0;
    float depth = 0;
    float in_str = 0;
    float esc = 0;
    float expect_key = 0; // at depth==1, are we positioned where a key should start?

    while (i < n)
    {
        string c = substring(OBJ, i, 1);
        float  v = str2chr(c, 0);

        // Inside some string literal — skip with escape handling
        if (in_str)
        {
            if (esc) { esc = 0; }
            else if (v == 92) { esc = 1; }     // '\'
            else if (v == 34) { in_str = 0; }  // closing '"'
            i = i + 1;
            continue;
        }

        // Track structural depth & key positions
        if (v == 123) // '{'
        {
            depth = depth + 1;
            if (depth == 1) expect_key = 1; // after '{' a key is expected
            i = i + 1;
            continue;
        }
        if (v == 125) // '}'
        {
            depth = depth - 1;
            if (depth < 1) expect_key = 0;
            i = i + 1;
            continue;
        }
        if (v == 44) // ','
        {
            if (depth == 1) expect_key = 1;
            i = i + 1;
            continue;
        }

        // Start of a quoted thing
        if (v == 34)
        {
            // Only treat as a KEY when we're exactly at depth==1 and expecting a key.
            if (depth == 1 && expect_key)
            {
                // read key literal
                float j = i + 1;
                float esc2 = 0;
                string keybuf = "";
                while (j < n)
                {
                    string c2 = substring(OBJ, j, 1);
                    float  v2 = str2chr(c2, 0);
                    j = j + 1;

                    if (esc2) { esc2 = 0; keybuf = strcat(keybuf, c2); continue; }
                    if (v2 == 92) { esc2 = 1; continue; } // '\'
                    if (v2 == 34) break;                  // closing '"'
                    keybuf = strcat(keybuf, c2);
                }
                i = j; // after closing key quote

                // skip whitespace
                while (i < n)
                {
                    v = str2chr(substring(OBJ, i, 1), 0);
                    if (v == 32 || v == 9 || v == 10 || v == 13) i = i + 1; else break;
                }

                // expect colon
                if (i < n && str2chr(substring(OBJ, i, 1), 0) == 58) // ':'
                {
                    i = i + 1;
                    expect_key = 0; // now a value is next

                    // skip whitespace before value
                    while (i < n)
                    {
                        v = str2chr(substring(OBJ, i, 1), 0);
                        if (v == 32 || v == 9 || v == 10 || v == 13) i = i + 1; else break;
                    }

                    if (keybuf == key)
                    {
                        // Quoted value?
                        if (i < n && str2chr(substring(OBJ, i, 1), 0) == 34)
                        {
                            i = i + 1;
                            string out = "";
                            float esc3 = 0;
                            while (i < n)
                            {
                                string c3 = substring(OBJ, i, 1);
                                float  v3 = str2chr(c3, 0);
                                i = i + 1;

                                if (esc3)
                                {
                                    esc3 = 0;
                                    if (v3 == 34) out = strcat(out, "\"");
                                    else if (v3 == 92) out = strcat(out, "\\");
                                    else if (v3 == 110) out = strcat(out, "\n");
                                    else if (v3 == 114) out = strcat(out, "\r");
                                    else if (v3 == 116) out = strcat(out, "\t");
                                    else out = strcat(out, c3);
                                    continue;
                                }
                                if (v3 == 92) { esc3 = 1; continue; } // '\'
                                if (v3 == 34) break;                   // closing '"'
                                out = strcat(out, c3);
                            }
                            strunzone(OBJ);
                            return out;
                        }
                        else
                        {
                            // Unquoted token: read until ',' or '}', return trimmed
                            float start = i;
                            while (i < n)
                            {
                                v = str2chr(substring(OBJ, i, 1), 0);
                                if (v == 44 || v == 125) break; // ',' or '}'
                                i = i + 1;
                            }
                            string raw = substring(OBJ, start, i - start);
                            string trimmed = json_trim(raw);
                            strunzone(OBJ);
                            return trimmed;
                        }
                    }
                    else
                    {
                        // Not our key — continue scanning; the value will be skipped by the flow above.
                        continue;
                    }
                }
                else
                {
                    // Not actually a key position (e.g., we hit a value string by mistake).
                    expect_key = 0;
                    continue;
                }
            }

            // Quoted thing but not a key (value or nested): skip as string
            in_str = 1;
            i = i + 1;
            continue;
        }

        // Default advance
        i = i + 1;
    }

    strunzone(OBJ);
    return defval;
}

float json_obj_get_float(string obj, string key, float defval)
{
    string tok = json_obj_get_string(obj, key, ""); if (!tok) return defval; return stof(tok);
}

float json_obj_get_bool(string obj, string key, float defval)
{
    string tok = json_obj_get_string(obj, key, ""); if (!tok) return defval; string t = tok;
    if (str_len(t) >= 2 && str_sub(t, 0, 1) == "\"" && str_sub(t, str_len(t)-1, 1) == "\"") t = str_sub(t, 1, str_len(t)-2);
    if (t == "true" || t == "1") return 1; if (t == "false" || t == "0") return 0; return defval;
}

float json_array_len(string arr)
{
    if (!arr) return 0; float n = str_len(arr); float i = 0, depth = 0, in_str = 0, esc = 0, count = 0;
    while (i < n)
    {
        string c = str_sub(arr, i, 1); float v = str_chr(c);
        if (in_str){ if (esc) esc = 0; else if (v == 92) esc = 1; else if (v == 34) in_str = 0; i = i + 1; continue; }
        if (v == 34) { in_str = 1; i = i + 1; continue; }
        if (v == 91) { depth = depth + 1; i = i + 1; continue; }
        if (v == 93) { depth = depth - 1; i = i + 1; continue; }
        if (depth == 1 && (v == 123 || (v != 44 && v != 32 && v != 9)))
        {
            count = count + 1;
            if (v != 123){ while (i < n){ v = str_chr(str_sub(arr, i, 1)); if (v == 44 || v == 93) break; i = i + 1; } }
        }
        i = i + 1;
    }
    return count;
}


// ============================================================================
// 7) Streaming Reader Helpers (no long substrings)
// ============================================================================
float js_it_next, js_obj_start, js_obj_end, js_val_start, js_val_len;

// Iterate next {...} span in a top-level array
float js_array_next_span(string s, float pos)
{
    float n = strlen(s), i = pos, in_str = 0, esc = 0;

    // find '{' outside strings
    for (; i < n; i = i + 1)
    {
        string c = substring(s, i, 1);
        if (in_str) { if (esc) { esc = 0; continue; } if (c == "\\") { esc = 1; continue; } if (c == "\"") { in_str = 0; } continue; }
        if (c == "\"") { in_str = 1; continue; }
        if (c == "{") break;
    }
    if (i >= n) return 0;
    js_obj_start = i;

    // match '}'
    float depth = 1; i = i + 1; in_str = 0; esc = 0;
    for (; i < n; i = i + 1)
    {
        string c = substring(s, i, 1);
        if (in_str) { if (esc) { esc = 0; continue; } if (c == "\\") { esc = 1; continue; } if (c == "\"") { in_str = 0; } continue; }
        if (c == "\"") { in_str = 1; continue; }
        if (c == "{") depth = depth + 1;
        else if (c == "}") { depth = depth - 1; if (depth <= 0) { i = i + 1; break; } }
    }
    js_obj_end = i;
    js_it_next = i;
    return 1;
}

// Strict key:"value" scan inside [o0,o1)
float js_obj_find_qstring_span(string s, float o0, float o1, string key)
{
    float i = o0, n = o1, in_str = 0, esc = 0;

    while (i < n)
    {
        string c = substring(s, i, 1);
        if (in_str)
        {
            if (esc) { esc = 0; i = i + 1; continue; }
            if (c == "\\") { esc = 1; i = i + 1; continue; }
            if (c == "\"") { in_str = 0; i = i + 1; continue; }
            i = i + 1; continue;
        }
        if (c == "\"")
        {
            // read key
            float k0 = i + 1, j = k0, e2 = 0;
            for (; j < n; j = j + 1)
            {
                string d = substring(s, j, 1);
                if (e2) { e2 = 0; continue; }
                if (d == "\\") { e2 = 1; continue; }
                if (d == "\"") break;
            }
            string found = substring(s, k0, j - k0);
            i = j + 1;

            // skip to colon
            for (; i < n; i = i + 1) { string x = substring(s,i,1); if (x == ":") { i = i + 1; break; } }

            // skip ws
            while (i < n)
            {
                string ws = substring(s, i, 1);
                if (ws == " " || ws == "\t" || ws == "\r" || ws == "\n") { i = i + 1; continue; }
                break;
            }

            if (found == key && i < n && substring(s, i, 1) == "\"")
            {
                float v0 = i + 1, k = v0, esc3 = 0;
                for (; k < n; k = k + 1)
                {
                    string ch = substring(s, k, 1);
                    if (esc3) { esc3 = 0; continue; }
                    if (ch == "\\") { esc3 = 1; continue; }
                    if (ch == "\"") break;
                }
                js_val_start = v0;
                js_val_len   = k - v0;
                return 1;
            }
            continue;
        }
        i = i + 1;
    }
    return 0;
}

// VERY tolerant fallback: find \"key\" then the next : and next opening quote, then value
float js_obj_find_qstring_span_fallback(string s, float o0, float o1, string key)
{
    string pat = strcat("\"", key, "\"");
    float n = strlen(s);
    float i = o0;

    // naive search for "key"
    while (1)
    {
        // find first quote of the pattern
        float p = i;
        float hit = -1;
        while (p < o1)
        {
            // quick check on first char
            if (substring(s, p, 1) == "\"")
            {
                float ok = 1, t = 0;
                for (t = 0; t < strlen(pat); t = t + 1)
                {
                    if (p + t >= o1) { ok = 0; break; }
                    if (substring(s, p + t, 1) != substring(pat, t, 1)) { ok = 0; break; }
                }
                if (ok) { hit = p; break; }
            }
            p = p + 1;
        }
        if (hit < 0) return 0;

        // move after pattern
        i = hit + strlen(pat);

        // skip spaces/tabs/newlines
        while (i < o1)
        {
            string ch = substring(s, i, 1);
            if (ch == " " || ch == "\t" || ch == "\r" || ch == "\n") { i = i + 1; continue; }
            break;
        }
        // require colon
        if (!(i < o1 && substring(s, i, 1) == ":")) { i = i + 1; continue; }
        i = i + 1;

        // skip ws
        while (i < o1)
        {
            string ch2 = substring(s, i, 1);
            if (ch2 == " " || ch2 == "\t" || ch2 == "\r" || ch2 == "\n") { i = i + 1; continue; }
            break;
        }

        // require opening quote
        if (!(i < o1 && substring(s, i, 1) == "\"")) { i = i + 1; continue; }

        // read value until closing quote (respect escapes)
        float v0 = i + 1, k = v0, esc = 0;
        for (; k < o1; k = k + 1)
        {
            string ch3 = substring(s, k, 1);
            if (esc) { esc = 0; continue; }
            if (ch3 == "\\") { esc = 1; continue; }
            if (ch3 == "\"") break;
        }
        js_val_start = v0;
        js_val_len   = k - v0;
        return 1;
    }
}

// copy short quoted string (decode common escapes)
string js_qstring_copy(string s, float v0, float vlen)
{
    float i = v0, n = v0 + vlen, esc = 0;
    string out = "";
    while (i < n)
    {
        string c = substring(s, i, 1);
        if (!esc && c == "\\") { esc = 1; i = i + 1; continue; }
        if (esc)
        {
            if (c == "n") out = strcat(out, "\n");
            else if (c == "r") out = strcat(out, "\r");
            else if (c == "t") out = strcat(out, "\t");
            else if (c == "\"") out = strcat(out, "\"");
            else if (c == "\\") out = strcat(out, "\\");
            else out = strcat(out, c);
            esc = 0; i = i + 1; continue;
        }
        out = strcat(out, c);
        i = i + 1;
    }
    return strzone(out);
}

// stream-print long string (decode escapes) without building big temps
void js_qstring_bprint(string s, float v0, float vlen)
{
    float i = v0, n = v0 + vlen, esc = 0;
    while (i < n)
    {
        string c = substring(s, i, 1);
        if (!esc && c == "\\") { esc = 1; i = i + 1; continue; }
        if (esc)
        {
            if (c == "n") bprint("\n");
            else if (c == "r") bprint("\r");
            else if (c == "t") bprint("\t");
            else if (c == "\"") bprint("\"");
            else if (c == "\\") bprint("\\");
            else bprint(c);
            esc = 0; i = i + 1; continue;
        }
        bprint(c);
        i = i + 1;
    }
}


// ============================================================================
// 8) Utility Helpers (pct, blank checks, escaping, etc.)
// ============================================================================
float (float frac, float tot) json_pct =
{
    if (tot <= 0) return 0;
    if (frac > tot) return 100;
    return floor(100 * frac / tot);
};

float json_is_blank(string s)
{
    if (!s) return TRUE;
    float n = strlen(s), i;
    for (i = 0; i < n; i = i + 1)
    {
        string ch = substring(s, i, 1);
        if (ch != " " && ch != "\t" && ch != "\n" && ch != "\r")
            return FALSE;
    }
    return TRUE;
}

string json_safe_or(string s, string fb)
{
    if (json_is_blank(s)) return fb;
    return s;
}

float json_has_colon(string s)
{
    if (!s) return FALSE;
    float n = strlen(s), i;
    for (i = 0; i < n; i = i + 1)
        if (substring(s, i, 1) == ":") return TRUE;
    return FALSE;
}

string json_fix_minutes(string ds)
{
    if (!json_has_colon(ds)) return strcat(ds, ":00");
    return ds;
}

string _hex_digit(float v) { return substring("0123456789abcdef", v & 15, 1); }

void json_write_escaped_to_file(float wf, string s)
{
    float i = 0, L = strlen(s);
    while (i < L)
    {
        string c = substring(s, i, 1);
        float  code = str2chr(c, 0);

        if (c == "\"")       fputs(wf, "\\\"");
        else if (c == "\\")  fputs(wf, "\\\\");
        else if (code == 10) fputs(wf, "\\n");
        else if (code == 13) fputs(wf, "\\r");
        else if (code == 9)  fputs(wf, "\\t");
        else if (code < 32)
        {
            float hi = floor(code / 16);
            float lo = code - hi * 16;
            fputs(wf, "\\u00"); fputs(wf, _hex_digit(hi)); fputs(wf, _hex_digit(lo));
        }
        else fputs(wf, c);

        i = i + 1;
    }
}


// ============================================================================
// 9) Domain Helper: gametype/playmode
// ============================================================================
// "gametype playmode" string
string () json_get_gametype_playmode =
{
    local string gtype = infokey(world, "gametype");
    local string pmode = infokey(world, "playmode");
    if (!gtype) gtype = ""; if (!pmode) pmode = "";
    return strcat(gtype, ((gtype != "" && pmode != "") ? " " : ""), pmode);
};


// ============================================================================
// 10) Public APIs
// ============================================================================

// Main: write a super-detailed match JSON
void () json_export_match_to_file =
{
    float f; entity t, p;
    string date   = strftime(TRUE, "%Y-%m-%d %H:%M:%S");
    string sgtype = json_get_gametype_playmode();
    string hname  = infokey(world, "hostname");

    f = fopen("json/match_test.json", FILE_WRITE);
    if (f < 0) { dprint("*** ERROR creating json file!\n"); return; }

    json_begin_compact_to_file(f);

    json_begin_object();
      json_key("match"); json_begin_object();
        json_kv_string("date",       date);
        json_kv_string("hostname",   hname);
        json_kv_string("map",        mapname);
        json_kv_string("gamemode",   sgtype);
        json_kv_number("match size", clanring_maxteams);
        json_kv_number("team size",  stats_matchtype);
        json_kv_number("timelimit",  stats_timelimit);

        json_key("teams"); json_begin_array();
          t = clanring_sentinel.next_team;
          while (t && t != world)
          {
            json_begin_object();
              json_kv_string("name", t.netname);
              // add clean (unpadded) team color
              json_kv_string("color", str_rtrim(strings_get_teamname3(t.height)));

              // --- team summary (stats_show_teamstats mirrored) ---
              json_key("team_summary"); json_begin_object();
                json_key("quad_ring"); json_begin_array(); json_number(t.dest2_x); json_number(t.dest2_y); json_number(t.dest2_z); json_end_array();
                json_key("rl_lg_gl");  json_begin_array(); json_number(t.dest1_x); json_number(t.dest1_y); json_number(t.dest1_z); json_end_array();
                json_key("sng_ng_mh"); json_begin_array(); json_number(t.pos1_x);  json_number(t.pos1_y);  json_number(t.pos1_z);  json_end_array();
                json_key("ra_ya_ga");  json_begin_array(); json_number(t.dest_x);  json_number(t.dest_y);  json_number(t.dest_z);  json_end_array();
                json_kv_number("rlpak_plus",  t.mangle_y);
                json_kv_number("rlpak_minus", t.mangle_z);
                local float control = 0; if (clanring_sentinel.cnt > 0) control = floor((1000 * t.mangle_x) / clanring_sentinel.cnt) / 10; // one decimal
                json_kv_number("control_pct", control);
              json_end_object();

              json_key("players"); json_begin_array();
                p = t.next_player;
                while (p && p != world)
                {
                  // Only include players that actually belong to team 't'.
                  // Some builds link extra players into t.next_player; skip those.
                  if (p.next_team != t) { p = p.next_player; continue; }
                  // --- Pre-compute ---
                  float deaths = p.mangle_z;
                  float kdr_val = (deaths > 0) ? floor(p.true_kills / deaths)
                                 : ((deaths == 0 && p.true_kills == 0) ? 0 : p.true_kills);

                  float bullet_eff = json_pct(p.dest2_x, p.dest1_x);
                  float nails_eff  = json_pct(p.dest2_y, p.dest1_y);
                  float rockets_eff= json_pct(p.dest_y,  p.dest_x);
                  float lg_eff     = json_pct(p.dest2_z, p.dest1_z);
                  float gl_eff     = json_pct(p.stats_gl_frac, p.stats_gl_tot);

                  float tot_fired_inc_gl = (p.dest1_x + p.dest1_y + p.dest1_z + p.dest_x + p.stats_gl_tot);
                  float tot_done_inc_gl  = (p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y + p.stats_gl_frac);
                  float total_eff        = json_pct(tot_done_inc_gl, tot_fired_inc_gl);

                  float kpm = 0;
                  if (p.join_time > 0)
                  {
                    float secs = time - p.join_time;
                    if (secs > 1) kpm = (p.true_kills * 60) / secs;
                  }
                  // Optional: round to 1 decimal
                  kpm = floor(kpm * 10) / 10;

                  float qd_eff = json_pct(p.clanring_qdwep_x, p.clanring_qdwep_y);
                  float pt_eff = json_pct(p.clanring_ptwep_x, p.clanring_ptwep_y);

                  float tot_enemy = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y;
                  float tot_done  = tot_enemy + p.clanring_badstats_y + p.clanring_badstats_z;
                  float self_pct  = json_pct(p.clanring_badstats_y, tot_done);
                  float team_pct  = json_pct(p.clanring_badstats_z, tot_done);

                  float per_val = 0; if (p.join_time > 0){ float s2 = time - p.join_time; if (s2 > 1) per_val = Q1_PER_Calc_Raw(p) / (s2 / 60); }

                  json_begin_object();
                    // identity
                    json_kv_string("name", p.netname);
                    json_kv_string("team", strings_get_colour(p.height));

                    // core
                    json_kv_number("score",  p.frags);
                    json_kv_number("kills",  p.true_kills);
                    json_kv_number("deaths", deaths);
                    json_kv_number("kdr",    kdr_val);

                    // killstats
                    json_kv_number("avenges",         p.stats_avenge_teammate);
                    json_kv_number("self_kills",      p.mangle_x);
                    json_kv_number("team_kills",      p.mangle_y);
                    json_kv_number("discharge_kills", p.stats_discharge_kills);
                    json_kv_number("damage_taken",    p.dmg_taken);
                    json_kv_number("damage_given",    p.dmg_given);
                    json_kv_number("enemy_weapon_dmg",p.ewep);

                    // weapon efficiency (incl. GL) + KPM
                    json_kv_number("bullet_eff",    bullet_eff);
                    json_kv_number("nails_eff",     nails_eff);
                    json_kv_number("rockets_eff",   rockets_eff);
                    json_kv_number("lightning_eff", lg_eff);
                    json_kv_number("grenade_eff",   gl_eff);
                    json_kv_number("total_eff",     total_eff);
                    json_kv_number("kpm",           kpm);

                    // Quad
                    json_kv_number("quads",            p.clanring_qdwep_z);
                    json_kv_number("quad_time",        p.totalquad);
                    json_kv_number("quad_weapon_eff",  qd_eff);
                    json_kv_number("quad_enemy_kills", p.clanring_qdkill_x);
                    json_kv_number("quad_self_kills",  p.clanring_qdkill_z);
                    json_kv_number("quad_team_kills",  p.clanring_qdkill_y);

                    // Pent
                    json_kv_number("pents",            p.clanring_ptwep_z);
                    json_kv_number("pent_weapon_eff",  pt_eff);
                    json_kv_number("pent_enemy_kills", p.clanring_ptkill_x);
                    json_kv_number("pent_team_kills",  p.clanring_ptkill_y);

                    // Bad stuff
                    json_kv_number("rl_paks_given", p.clanring_badstats_x);
                    json_kv_number("self_dmg_pct",  self_pct);
                    json_kv_number("team_dmg_pct",  team_pct);
                    json_kv_number("lava_deaths",   p.clanring_badstats2_x);
                    json_kv_number("axe_deaths",    p.clanring_badstats2_y);
                    json_kv_number("fall_deaths",   p.clanring_badstats2_z);

                    // Defense
                    json_kv_number("def_teammate", p.stats_defense_teammate);
                    json_kv_number("def_backpack", p.stats_defense_backpack);
                    json_kv_number("def_powerup",  p.stats_defense_powerup);
                    json_kv_number("def_weapon",   p.stats_defense_weapon);
                    json_kv_number("def_armor",    p.stats_defense_armor);

                    // Items taken
                    json_key("items_taken"); json_begin_object();
                      // weapons
                      json_kv_number("ssg", p.stats_item_ssg);
                      json_kv_number("ng",  p.stats_item_ng);
                      json_kv_number("sng", p.stats_item_sng);
                      json_kv_number("gl",  p.stats_item_gl);
                      json_kv_number("rl",  p.stats_item_rl);
                      json_kv_number("lg",  p.stats_item_lg);
                      // ammo
                      json_kv_number("shells",  p.stats_item_shells);
                      json_kv_number("nails",   p.stats_item_nails);
                      json_kv_number("rockets", p.stats_item_rockets);
                      json_kv_number("cells",   p.stats_item_cells);
                      // pickups
                      json_kv_number("health",  p.stats_item_health);
                      json_kv_number("mega",    p.stats_item_mega);
                      json_kv_number("biosuit", p.stats_item_biosuit);
                      json_kv_number("ga",      p.stats_item_greenarmor);
                      json_kv_number("ya",      p.stats_item_yellowarmor);
                      json_kv_number("ra",      p.stats_item_redarmor);
                      json_kv_number("backpacks", p.stats_item_backpacks);
                    json_end_object();

                    // CTF block
                    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
                    {
                      json_key("ctf"); json_begin_object();
                        json_kv_number("flag_pickups", p.fpickups);
                        json_kv_number("flag_time",    p.fctime);
                        json_kv_number("captures",     p.fcaptures);
                        if (p.captime != 1200) json_kv_number("best_cap_time", p.captime); else json_kv_null("best_cap_time");
                        json_kv_number("defenses",     p.fdefenses);
                        json_kv_number("returns",      p.freturns);
                        json_kv_number("fc_defenses",  p.fcdefenses);
                        json_kv_number("fc_assists",   p.fcassists);
                        json_kv_number("fc_kills",     p.fcfrags);
                        json_kv_number("carry_time",   p.fcarries_time);
                      json_end_object();
                    }

                    // Efficiency rating per minute
                    json_kv_number("per", per_val);

                    // Misc
                    json_kv_number("direct_hits", p.direct_hit);
                  json_end_object();

                  p = p.next_player;
                }
              json_end_array();
            json_end_object();

            t = t.next_team;
          }
        json_end_array();
      json_end_object();
    json_end_object();

    json_clear_sink();
    fclose(f);
}

void(string entry) json_append_lastscores =
{
    float rf, wf;
    string s = "", line;
    float CAP_OLD = 7; // keep this many previous entries; new one makes total <= 8

    // ---------- Collect metadata ----------
    string mapn = mapname; if (!mapn || mapn == "") mapn = "unknown";

    string mode = infokey(world, "mode");
    if (!mode || mode == "")
    {
        if      (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) mode = "CTF";
        else if (clanring_playmode & CLANRING_CA_MODE)           mode = "CA";
        else if (clanring_playmode & CLANRING_RA_MODE)           mode = "RA";
        else if (clanring_playmode & CLANRING_DMM4_MODE)         mode = "DMM4";
        else if (clanring_playmode & CLANRING_WIPEOUT_MODE)      mode = "WIPEOUT";
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)      mode = "AIRSHOT";
        else                                                     mode = "DM";
    }

    string host = infokey(world, "hostname"); if (!host || host == "") host = "unknown";

    // Date string (NO COLON): "MM-DD-YYYY HH.MM"
    string date_tmp = strftime(TRUE, "%m-%d-%Y %H.%M");
    if (!date_tmp || date_tmp == "") date_tmp = strftime(TRUE, "%m-%d-%Y %H");
    {
        float has_dot = FALSE, k, Ld = strlen(date_tmp);
        for (k = 0; k < Ld; k = k + 1) { if (substring(date_tmp,k,1) == ".") { has_dot = TRUE; break; } }
        if (!has_dot) date_tmp = strcat(date_tmp, ".00");
    }

    // ---------- CRITICAL: zone ALL inputs immediately ----------
    string z_map   = strzone(mapn);
    string z_mode  = strzone(mode);
    string z_host  = strzone(host);
    string z_entry = strzone(entry);
    string z_date  = strzone(date_tmp);

    // ---------- Read existing file (keep last 7), NO minify ----------
    string p_txt[7], p_map[7], p_mode[7], p_host[7], p_date[7];
    float keep = 0;

    rf = fopen("json/lastscores.json", FILE_READ);
    if (rf < 0) rf = fopen("lastscores.json", FILE_READ);
    if (rf >= 0)
    {
        while (1) { line = fgets(rf); if (line == "") break; s = strcat(s, line); }
        fclose(rf);

        s = strzone(s);

        float pos = 0;

        while (js_array_next_span(s, pos))
        {
            float o0 = js_obj_start, o1 = js_obj_end;

            string ttxt  = ""; string tmap  = ""; string tmode = ""; string thost = ""; string tdate = "";

            if (js_obj_find_qstring_span(s, o0, o1, "text") || js_obj_find_qstring_span_fallback(s, o0, o1, "text"))
                ttxt  = js_qstring_copy(s, js_val_start, js_val_len);
            if (js_obj_find_qstring_span(s, o0, o1, "map")  || js_obj_find_qstring_span_fallback(s, o0, o1, "map"))
                tmap  = js_qstring_copy(s, js_val_start, js_val_len);
            if (js_obj_find_qstring_span(s, o0, o1, "mode") || js_obj_find_qstring_span_fallback(s, o0, o1, "mode"))
                tmode = js_qstring_copy(s, js_val_start, js_val_len);
            if (js_obj_find_qstring_span(s, o0, o1, "host") || js_obj_find_qstring_span_fallback(s, o0, o1, "host"))
                thost = js_qstring_copy(s, js_val_start, js_val_len);
            if (js_obj_find_qstring_span(s, o0, o1, "date") || js_obj_find_qstring_span_fallback(s, o0, o1, "date"))
                tdate = js_qstring_copy(s, js_val_start, js_val_len);

            if (ttxt && ttxt != "")
            {
                if (keep < CAP_OLD)
                {
                    p_txt[keep]  = ttxt;  p_map[keep]  = tmap;
                    p_mode[keep] = tmode; p_host[keep] = thost; p_date[keep] = tdate;
                    keep = keep + 1;
                }
                else
                {
                    // free oldest, shift left generically, append newest at end
                    float si;
                    strunzone(p_txt[0]);  strunzone(p_map[0]);  strunzone(p_mode[0]);  strunzone(p_host[0]);  strunzone(p_date[0]);
                    for (si = 0; si < CAP_OLD - 1; si = si + 1)
                    {
                        p_txt[si]  = p_txt[si+1];
                        p_map[si]  = p_map[si+1];
                        p_mode[si] = p_mode[si+1];
                        p_host[si] = p_host[si+1];
                        p_date[si] = p_date[si+1];
                    }
                    p_txt[CAP_OLD-1]  = ttxt;
                    p_map[CAP_OLD-1]  = tmap;
                    p_mode[CAP_OLD-1] = tmode;
                    p_host[CAP_OLD-1] = thost;
                    p_date[CAP_OLD-1] = tdate;
                }
            }
            else
            {
                // discard zoned empties (were not kept)
                if (ttxt)  strunzone(ttxt);
                if (tmap)  strunzone(tmap);
                if (tmode) strunzone(tmode);
                if (thost) strunzone(thost);
                if (tdate) strunzone(tdate);
            }

            pos = js_it_next;
        }

        strunzone(s);
    }

    // ---------- Rewrite full array (cap <= 8) ----------
    wf = fopen("json/lastscores.json", FILE_WRITE);
    if (wf < 0) wf = fopen("lastscores.json", FILE_WRITE);
    if (wf < 0)
    {
        dprint("*** ERROR: cannot write lastscores.json\n");
        float qi; for (qi = 0; qi < keep; qi = qi + 1) { strunzone(p_txt[qi]); strunzone(p_map[qi]); strunzone(p_mode[qi]); strunzone(p_host[qi]); strunzone(p_date[qi]); }
        strunzone(z_map); strunzone(z_mode); strunzone(z_host); strunzone(z_entry); strunzone(z_date);
        return;
    }

    // Manually write array & objects so we can stream-escape "text"
    fputs(wf, "[");
    float idxw;
    for (idxw = 0; idxw < keep; idxw = idxw + 1)
    {
        if (idxw > 0) fputs(wf, ",");
        fputs(wf, "{");

        // Short keys first (robust for older readers)
        if (p_date[idxw] && p_date[idxw] != "") { fputs(wf, "\"date\":\""); json_write_escaped_to_file(wf, p_date[idxw]); fputs(wf, "\","); }
        fputs(wf, "\"map\":\"");  json_write_escaped_to_file(wf, p_map[idxw]);  fputs(wf, "\",");
        fputs(wf, "\"mode\":\""); json_write_escaped_to_file(wf, p_mode[idxw]); fputs(wf, "\",");
        fputs(wf, "\"host\":\""); json_write_escaped_to_file(wf, p_host[idxw]); fputs(wf, "\",");
        fputs(wf, "\"text\":\""); json_write_escaped_to_file(wf, p_txt[idxw]);  fputs(wf, "\"}");

        // free as we go
        strunzone(p_txt[idxw]); strunzone(p_map[idxw]); strunzone(p_mode[idxw]); strunzone(p_host[idxw]); strunzone(p_date[idxw]);
    }

    if (z_entry && z_entry != "") // append newest; total entries now <= CAP_OLD + 1 (8)
    {
        if (keep > 0) fputs(wf, ",");
        fputs(wf, "{");
        fputs(wf, "\"date\":\""); json_write_escaped_to_file(wf, z_date); fputs(wf, "\",");
        fputs(wf, "\"map\":\"");  json_write_escaped_to_file(wf, z_map);  fputs(wf, "\",");
        fputs(wf, "\"mode\":\""); json_write_escaped_to_file(wf, z_mode); fputs(wf, "\",");
        fputs(wf, "\"host\":\""); json_write_escaped_to_file(wf, z_host); fputs(wf, "\",");
        fputs(wf, "\"text\":\""); json_write_escaped_to_file(wf, z_entry); fputs(wf, "\"}");
    }

    fputs(wf, "]");
    fclose(wf);

    // Free inputs
    strunzone(z_map); strunzone(z_mode); strunzone(z_host); strunzone(z_entry); strunzone(z_date);
};

void () utils_show_last_scores =
{
    float f = fopen("json/lastscores.json", FILE_READ);
    if (f < 0) f = fopen("lastscores.json", FILE_READ);

    sprint(self, "\n");
    if (f < 0) { sprint(self, "[no lastscores found]\n"); return; }

    // Load entire file (keep original bytes; DO NOT json_minify here)
    string s = "", line;
    while (1) { line = fgets(f); if (line == "") break; s = strcat(s, line); }
    fclose(f);
    s = strzone(s); // keep buffer stable against tempstring churn

    float pos = 0;

    while (js_array_next_span(s, pos))
    {
        float o0 = js_obj_start, o1 = js_obj_end;

        // ---- Find each key and snapshot spans ----
        float d_found = 0, d0 = 0, dl = 0;
        if (js_obj_find_qstring_span(s, o0, o1, "date")) { d_found = 1; d0 = js_val_start; dl = js_val_len; }
        else if (js_obj_find_qstring_span_fallback(s, o0, o1, "date")) { d_found = 1; d0 = js_val_start; dl = js_val_len; }

        float m_found = 0, m0 = 0, ml = 0;
        if (js_obj_find_qstring_span(s, o0, o1, "map")) { m_found = 1; m0 = js_val_start; ml = js_val_len; }
        else if (js_obj_find_qstring_span_fallback(s, o0, o1, "map")) { m_found = 1; m0 = js_val_start; ml = js_val_len; }

        float mo_found = 0, mo0 = 0, mol = 0;
        if (js_obj_find_qstring_span(s, o0, o1, "mode")) { mo_found = 1; mo0 = js_val_start; mol = js_val_len; }
        else if (js_obj_find_qstring_span_fallback(s, o0, o1, "mode")) { mo_found = 1; mo0 = js_val_start; mol = js_val_len; }

        float t_found = 0, t0 = 0, tl = 0;
        if (js_obj_find_qstring_span(s, o0, o1, "text")) { t_found = 1; t0 = js_val_start; tl = js_val_len; }
        else if (js_obj_find_qstring_span_fallback(s, o0, o1, "text")) { t_found = 1; t0 = js_val_start; tl = js_val_len; }

        // ---- Copy short values (decoded) ----
        string tdate = ""; if (d_found) tdate = js_qstring_copy(s, d0, dl);
        string tmap  = ""; if (m_found) tmap  = js_qstring_copy(s, m0, ml);
        string tmode = ""; if (mo_found) tmode = js_qstring_copy(s, mo0, mol);

        // ---- Friendly "when" label ----
        // Expect tdate as "MM-DD-YYYY HH:MM" or "MM-DD-YYYY HH.MM"
        string when = "Unknown Date";
        if (tdate && strlen(tdate) >= 10)
        {
            string dpart = substring(tdate, 0, 10); // MM-DD-YYYY
            float y = stof(substring(dpart, 6, 4));
            float m = stof(substring(dpart, 0, 2));
            float d = stof(substring(dpart, 3, 2));

            float hh = 0, mm = 0;
            if (strlen(tdate) >= 16)
            {
                string tpart = substring(tdate, 11, 5); // HH:MM or HH.MM
                string sep = substring(tpart, 2, 1);
                hh = stof(substring(tpart, 0, 2));
                if (sep == ":" || sep == ".") mm = stof(substring(tpart, 3, 2));
            }

            float nowY = stof(strftime(TRUE, "%Y"));
            float nowM = stof(strftime(TRUE, "%m"));
            float nowD = stof(strftime(TRUE, "%d"));
            float nowH = stof(strftime(TRUE, "%H"));
            float nowMin = stof(strftime(TRUE, "%M"));

            if (nowY == y && nowM == m && nowD == d)
            {
                float deltaMin = (nowH * 60 + nowMin) - (hh * 60 + mm);
                if (deltaMin < 0) deltaMin = 0;

                if (deltaMin == 0)      when = "Just Now";
                else if (deltaMin == 1) when = "1 Minute Ago";
                else if (deltaMin == 2) when = "2 Minutes Ago";
                else if (deltaMin < 60) when = strcat(ftos(deltaMin), " Minutes Ago");
                else
                {
                    float dh = floor(deltaMin / 60);
                    if (dh == 1) when = "1 Hour Ago";
                    else         when = strcat(ftos(dh), " Hours Ago");
                }
            }
            else
            {
                float days = (nowY - y) * 365 + (nowM - m) * 30 + (nowD - d);
                if (days < 0) days = 0;

                if (days == 0)      when = tdate;
                else if (days == 1) when = "1 Day Ago";
                else if (days < 7)  when = strcat(ftos(days), " Days Ago");
                else if (days < 14) when = "1 Week Ago";
                else if (days < 21) when = "2 Weeks Ago";
                else if (days < 30) { float w = floor(days / 7); when = strcat(ftos(w), " Weeks Ago"); }
                else if (days < 60) when = "1 Month Ago";
                else if (days < 365)
                {
                    float mo = floor(days / 30);
                    when = (mo == 1) ? "1 Month Ago" : strcat(ftos(mo), " Months Ago");
                }
                else if (days < 730)  when = "1 Year Ago";
                else if (days < 1095) when = "2 Years Ago";
                else
                {
                    float yr = floor(days / 365);
                    when = (yr == 1) ? "1 Year Ago" : strcat(ftos(yr), " Years Ago");
                }
            }
        }

        // ---- Header ----
        sprint(self, strcat(format_match_header(when, strlen(tmap) ? tmap : "unknown", strlen(tmode) ? tmode : "dm"), "\n"));

        // ---- Body ("text") ----
        if (t_found)
        {
            // Prefix first body line (the score line) with "Score: "
            sprint(self, "Score: ");

            // Decode and print ONLY to this client
            string ttext = js_qstring_copy(s, t0, tl);
            if (ttext)
            {
                sprint(self, ttext);
                strunzone(ttext);
            }

            if (tl <= 0 || substring(s, t0 + tl - 1, 1) != "\n") sprint(self, "\n");
        }
        else
        {
            sprint(self, "(no text)\n");
        }

        // >>> Extra blank line between entries (and after the last one)
        sprint(self, "\n");

        // Cleanup small zoned strings
        if (tdate) strunzone(tdate);
        if (tmap)  strunzone(tmap);
        if (tmode) strunzone(tmode);

        pos = js_it_next;
    }

    strunzone(s);
};
