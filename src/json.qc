// json.qc - JSON helpers
// -----------------------------------------------------------------------------
// Every place in the mod that writes or reads JSON should go through here.
//
// Contents
//   1) Constants & Globals
//   2) String Helpers (escaping / number formatting)
//   3) Emit/Sink (stream routing)
//   4) Builder Core (state + primitives)
//   5) Value Writers & Convenience
//   6) Reader Helpers (object/array lookup on an in-memory string)
//   7) Span Reader Helpers (work on [start,end) offsets; no long substrings)
//   8) Utility Helpers (pct, blank checks, file escaping, etc.)
//   9) Domain Helper: gametype/playmode
//  10) Public APIs: json_export_match_to_file / json_append_lastscores / utils_show_last_scores
//
// Writing:
//   json_begin_compact();               // or json_begin_pretty(1) / json_begin_compact_to_file(fh)
//   json_begin_object();
//     json_kv_string("map", mapname);
//     json_kv_number("time", 12.5);
//   json_end_object();
//   string payload = strzone(json_result());   // result is only valid until the next json_begin_*
//
// Reading:
//   json_obj_get_string(obj, "key", "default")   // top-level key of an object, unescaped
//   json_obj_get_float / json_obj_get_bool / json_obj_get_raw (raw value text, e.g. a nested array)
//   json_array_next_object(arr, pos) + json__it_next  // iterate objects inside an array
// -----------------------------------------------------------------------------

void(string payload) match_post_json;
void(string payload) match_post_json_deferred;

// ============================================================================
// 1) Constants & Globals
// ============================================================================
float JSON_MAX_DEPTH = 32;
float JSON_CTX_OBJECT = 1;
float JSON_CTX_ARRAY  = 2;

string json__buf;
float  json__buf_zoned;   // json__buf is a zoned copy (safe from tempstring recycling)
float  json__depth;
float  json__overflow;    // nesting levels beyond JSON_MAX_DEPTH (ignored, never indexed)
float  json__ctx[32];
float  json__count[32];
float  json__pretty;      // 0 = compact, 1 = pretty with two-space indents
float  json__pending_key; // 1 when an object key was just emitted
float  json__pend_depth;
float  json__str_open;    // TRUE while a json_string_open() value is being written

// Streaming sink: declare WITHOUT initializer (FTE makes initialized globals const).
// Use an enable flag to control writes to the sink.
float json__sink_fh;
float json__sink_enabled;

// Longest escape is \u00xx (6 bytes per input char). Escaping at most this many
// chars at a time keeps every result under the 1024-byte tempstring limit of
// QSS-family engines (160 * 6 = 960).
float JSON_ESCAPE_CHUNK = 160;

string json__spaces = "                                                                "; // 64 spaces
string json__hex    = "0123456789abcdef";


// ============================================================================
// 2) String Helpers (escaping / number formatting)
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
        if (str2chr(s, n - 1) == 32) n = n - 1;
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

// TRUE if s holds a C0 control char other than \t \n \r.
// Uses str2chr only, so it creates no tempstrings.
float json__has_ctl(string s)
{
    float n = strlen(s), i, v;
    for (i = 0; i < n; i = i + 1)
    {
        v = str2chr(s, i);
        if (v > 0 && v < 32 && v != 9 && v != 10 && v != 13) return TRUE;
    }
    return FALSE;
}

// Escape a string for use inside a JSON string literal (without the quotes).
// Quake high-bit characters (128-255) pass through unchanged.
string json_escape(string s)
{
    if (!s) return "";
    s = strreplace("\\", "\\\\", s);   // backslash first so later escapes aren't doubled
    s = strreplace("\"", "\\\"", s);
    s = strreplace("\n", "\\n", s);
    s = strreplace("\r", "\\r", s);
    s = strreplace("\t", "\\t", s);
    if (!json__has_ctl(s)) return s;

    // Rare: other control chars (e.g. ESC in ANSI colour codes) -> \u00xx
    float v;
    string c;
    for (v = 1; v < 32; v = v + 1)
    {
        if (v == 9 || v == 10 || v == 13) continue;
        c = chr2str(v);
        if (strstrofs(s, c, 0) >= 0) s = strreplace(c, json__u00xx(v), s);
    }
    return s;
}

// TRUE for ordinary numbers, FALSE for NaN / +-inf (which JSON can't represent).
float json__finite(float v) { return (v - v) == 0; }

// Trim trailing zeros from ftos output (keep integers compact)
string json_ftos_trim(float f)
{
    string s = ftos(f);
    if (str_index_of(s, ".", 0) < 0) return s;
    if (str_index_of(s, "e", 0) >= 0) return s;  // exponent form: leave as-is
    float i = str_len(s);
    while (i > 0 && str2chr(s, i - 1) == 48) i = i - 1;   // '0'
    if (i > 0 && str2chr(s, i - 1) == 46) i = i - 1;      // '.'
    return str_sub(s, 0, i);
}


// ============================================================================
// 3) Emit/Sink (stream routing)
// ============================================================================
void json__emit(string s)
{
    if (json__sink_enabled) { fputs(json__sink_fh, s); return; }

    // Keep the in-memory buffer zoned so engines that recycle tempstrings
    // can't overwrite it while a document is being built.
    string t = strcat(json__buf, s);
    if (json__buf_zoned) strunzone(json__buf);
    json__buf = strzone(t);
    json__buf_zoned = TRUE;
}

// NOTE: some FTE setups alias 'filestream' to const; use float here.
void json_set_sink(float f){ json__sink_fh = f; json__sink_enabled = 1; }
void json_clear_sink(){ json__sink_enabled = 0; }


// ============================================================================
// 4) Builder Core (state + primitives)
// ============================================================================
void json__reset()
{
    if (json__buf_zoned) strunzone(json__buf);
    json__buf = "";
    json__buf_zoned = FALSE;
    json__depth = 0;
    json__overflow = 0;
    json__str_open = FALSE;
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

// In-memory builders always detach any file sink left over from a file export.
void json_begin_pretty(float pretty){ json_clear_sink(); json__reset(); json__pretty = pretty; }
void json_begin_compact(){ json_begin_pretty(0); }
// Valid until the next json_begin_*; strzone() it if you need to keep it.
string json_result(){ return json__buf; }

void json_begin_pretty_to_file(float f, float pretty){ json_begin_pretty(pretty); json_set_sink(f); }
void json_begin_compact_to_file(float f){ json_begin_pretty_to_file(f, 0); }

void json__indent_to(float depth)
{
    if (!json__pretty) return;
    json__emit("\n");
    float need = depth * 2; if (need > 64) need = 64;
    if (need > 0) json__emit(str_sub(json__spaces, 0, need));
}
void json__indent_line(){ json__indent_to(json__depth); }

void json__push(float ctx)
{
    json__depth = json__depth + 1;
    json__ctx[json__depth] = ctx;
    json__count[json__depth] = 0;
}


// ============================================================================
// 5) Value Writers & Convenience
// ============================================================================
void json__array_prepare_value(){ if (json__count[json__depth] > 0) json__emit(","); json__indent_line(); }

// Called before every value (scalar, object or array): writes the separator
// when inside an array and counts the value toward its parent container.
// Returns FALSE when the value must be dropped (inside an over-depth container).
float json__before_value()
{
    if (json__overflow > 0) return FALSE;
    if (json__ctx[json__depth] == JSON_CTX_ARRAY)
    {
        json__array_prepare_value();
        json__count[json__depth] = json__count[json__depth] + 1;
    }
    else if (json__pending_key && json__pend_depth == json__depth)
    {
        json__pending_key = 0;
        json__count[json__depth] = json__count[json__depth] + 1;
    }
    return TRUE;
}

// A container nested deeper than JSON_MAX_DEPTH is written as a single null;
// everything inside it, up to its matching end, is dropped.
void json__begin_container(string opener, float ctx)
{
    if (json__overflow > 0) { json__overflow = json__overflow + 1; return; }
    json__before_value();
    if (json__depth >= JSON_MAX_DEPTH - 1)
    {
        json__emit("null");
        json__overflow = 1;
        return;
    }
    json__emit(opener);
    json__push(ctx);
}

void json__end_container(string closer)
{
    if (json__overflow > 0) { json__overflow = json__overflow - 1; return; }
    if (json__depth <= 0) return;   // unbalanced end: nothing open, ignore
    if (json__pretty && json__count[json__depth] > 0) json__indent_to(json__depth - 1);
    json__emit(closer);
    json__depth = json__depth - 1;
}

void json_begin_object(){ json__begin_container("{", JSON_CTX_OBJECT); }
void json_end_object()  { json__end_container("}"); }
void json_begin_array() { json__begin_container("[", JSON_CTX_ARRAY); }
void json_end_array()   { json__end_container("]"); }

void json_key(string key)
{
    if (json__overflow > 0) return;
    if (json__ctx[json__depth] != JSON_CTX_OBJECT) return;
    if (json__count[json__depth] > 0) json__emit(",");
    json__indent_line();
    json__emit(strcat("\"", json_escape(key), "\":"));
    if (json__pretty) json__emit(" ");
    json__pending_key = 1; json__pend_depth = json__depth;
}

// Pre-formatted JSON token (number, true/false/null, or an already-built fragment).
void json_raw(string token){ if (json__before_value()) json__emit(token); }

// Emit s escaped, a bounded chunk at a time (no quotes).
void json__emit_escaped(string s)
{
    if (!s) return;
    float i = 0, L = strlen(s), chunk;
    while (i < L)
    {
        chunk = L - i; if (chunk > JSON_ESCAPE_CHUNK) chunk = JSON_ESCAPE_CHUNK;
        json__emit(json_escape(substring(s, i, chunk)));
        i = i + chunk;
    }
}

// String value written in pieces, for text too long to hold in one string:
//   json_key("content"); json_string_open(); json_string_part(a); json_string_part(b); json_string_close();
void json_string_open()     { json__str_open = json__before_value(); if (json__str_open) json__emit("\""); }
void json_string_part(string s){ if (json__str_open) json__emit_escaped(s); }
void json_string_close()    { if (json__str_open) json__emit("\""); json__str_open = FALSE; }

void json_string(string v){ json_string_open(); json_string_part(v); json_string_close(); }
void json_null()          { json_raw("null"); }
void json_bool(float truthy){ json_raw(truthy ? "true" : "false"); }

void json_number(float v)
{
    if (!json__finite(v)) { json_null(); return; }
    json_raw(json_ftos_trim(v));
}

// Up to 9 significant digits; calibration inputs must retain float precision
// to reproduce a frozen rating.
void json_precise_number(float v)
{
    if (!json__finite(v)) { json_null(); return; }
    json_raw(sprintf("%.9g", v));
}

// convenience
void json_kv_string(string k, string v){ json_key(k); json_string(v); }
void json_kv_number(string k, float v){ json_key(k); json_number(v); }
void json_kv_precise_number(string k, float v){ json_key(k); json_precise_number(v); }
void json_kv_bool  (string k, float b){ json_key(k); json_bool(b); }
void json_kv_null  (string k){ json_key(k); json_null(); }
void json_kv_raw   (string k, string token){ json_key(k); json_raw(token); }


// ============================================================================
// 6) Reader Helpers (object/array lookup on an in-memory string)
// ============================================================================
// These scanners use str2chr() for every character test, so they create no
// tempstrings while walking the input. Value lookups only consider the
// object's own (depth 1) keys; nested objects/arrays are skipped whole.

float json__skip_ok;        // FALSE when the last json__skip_value hit end-of-input
float json__vs, json__ve;   // value span [vs, ve) from the last successful json__find_key

float json__is_ws(float v){ return (v == 32 || v == 9 || v == 10 || v == 13); }

float json__skip_ws(string s, float i, float n)
{
    while (i < n && json__is_ws(str2chr(s, i))) i = i + 1;
    return i;
}

// i points at an opening quote; returns the index just past the closing quote.
float json__skip_string(string s, float i, float n)
{
    float v;
    i = i + 1;
    while (i < n)
    {
        v = str2chr(s, i);
        if (v == 92) { i = i + 2; continue; }   // '\' + escaped char
        i = i + 1;
        if (v == 34) return i;                  // closing '"'
    }
    json__skip_ok = FALSE;
    return n;
}

// i points at the first char of a value; returns the index just past it.
float json__skip_value(string s, float i, float n)
{
    float v, depth;
    json__skip_ok = TRUE;
    if (i >= n) { json__skip_ok = FALSE; return n; }

    v = str2chr(s, i);
    if (v == 34) return json__skip_string(s, i, n);

    if (v == 123 || v == 91)   // '{' or '['
    {
        depth = 0;
        while (i < n)
        {
            v = str2chr(s, i);
            if (v == 34) { i = json__skip_string(s, i, n); continue; }
            if (v == 123 || v == 91) depth = depth + 1;
            else if (v == 125 || v == 93) { depth = depth - 1; if (depth <= 0) return i + 1; }
            i = i + 1;
        }
        json__skip_ok = FALSE;
        return n;
    }

    // bare token: number / true / false / null
    while (i < n)
    {
        v = str2chr(s, i);
        if (v == 44 || v == 125 || v == 93 || json__is_ws(v)) break;
        i = i + 1;
    }
    return i;
}

// Compare s[a, a+len) to key without allocating.
float json__span_equals(string s, float a, float len, string key)
{
    if (strlen(key) != len) return FALSE;
    float j;
    for (j = 0; j < len; j = j + 1)
        if (str2chr(s, a + j) != str2chr(key, j)) return FALSE;
    return TRUE;
}

// Find a top-level key in the object that starts at/after o0 (leading
// whitespace allowed) and ends before o1. On success sets json__vs/json__ve
// to the raw value span (quotes included for strings) and returns TRUE.
// Keys are compared as written (keys containing escapes won't match).
float json__find_key(string s, float o0, float o1, string key)
{
    float i, v, k0, k1, vend;

    i = json__skip_ws(s, o0, o1);
    if (i >= o1 || str2chr(s, i) != 123) return FALSE;  // '{'
    i = i + 1;

    while (i < o1)
    {
        i = json__skip_ws(s, i, o1);
        if (i >= o1) return FALSE;
        v = str2chr(s, i);
        if (v == 125) return FALSE;                 // '}' end of object
        if (v == 44) { i = i + 1; continue; }       // ','
        if (v != 34) return FALSE;                  // malformed: key must be quoted

        k0 = i + 1;
        i  = json__skip_string(s, i, o1);
        k1 = i - 1;                                 // index of closing quote

        i = json__skip_ws(s, i, o1);
        if (i >= o1 || str2chr(s, i) != 58) return FALSE;  // ':'
        i = json__skip_ws(s, i + 1, o1);
        if (i >= o1) return FALSE;

        vend = json__skip_value(s, i, o1);
        if (json__span_equals(s, k0, k1 - k0, key))
        {
            json__vs = i;
            json__ve = vend;
            return TRUE;
        }
        if (vend <= i) vend = i + 1;
        i = vend;
    }
    return FALSE;
}

float json__hexval(float v)
{
    if (v >= 48 && v <= 57)  return v - 48;        // 0-9
    if (v >= 97 && v <= 102) return v - 87;        // a-f
    if (v >= 65 && v <= 70)  return v - 55;        // A-F
    return -1;
}

// Decode the inside of a JSON string literal, s[v0, v0+vlen).
// Fast path (no backslashes) returns a single substring; otherwise copies
// unescaped runs in chunks and decodes \" \\ \/ \b \f \n \r \t \u00XX.
string json_unescape_span(string s, float v0, float vlen)
{
    float n = v0 + vlen;
    float i = strstrofs(s, "\\", v0);
    if (i < 0 || i >= n) return substring(s, v0, vlen);

    string out = "";
    float start = v0, v, code, h, k;
    while (i >= 0 && i < n)
    {
        if (i > start) out = strcat(out, substring(s, start, i - start));
        if (i + 1 >= n) { start = n; break; }
        v = str2chr(s, i + 1);
        start = i + 2;
        if      (v == 110) out = strcat(out, "\n");  // n
        else if (v == 114) out = strcat(out, "\r");  // r
        else if (v == 116) out = strcat(out, "\t");  // t
        else if (v == 98)  out = strcat(out, chr2str(8));   // b
        else if (v == 102) out = strcat(out, chr2str(12));  // f
        else if (v == 117 && i + 5 < n)              // uXXXX
        {
            code = 0;
            for (k = 0; k < 4; k = k + 1)
            {
                h = json__hexval(str2chr(s, i + 2 + k));
                if (h < 0) { code = -1; break; }
                code = code * 16 + h;
            }
            if (code < 0)               out = strcat(out, "u");   // malformed: keep text
            else if (code > 0 && code < 256) out = strcat(out, chr2str(code));
            else if (code >= 256)       out = strcat(out, "?");   // outside Quake charset
            if (code >= 0) start = i + 6;
        }
        else out = strcat(out, chr2str(v));          // \" \\ \/ and anything else
        i = strstrofs(s, "\\", start);
    }
    if (start < n) out = strcat(out, substring(s, start, n - start));
    return out;
}

string json_trim(string s)
{
    if (!s) return "";
    float a = 0, b = strlen(s);
    while (a < b && json__is_ws(str2chr(s, a))) a = a + 1;
    while (b > a && json__is_ws(str2chr(s, b - 1))) b = b - 1;
    return substring(s, a, b - a);
}

string json_minify(string s)
{
    if (!s) return "";
    float i = 0, n = str_len(s), v, e;
    string out = "";
    while (i < n)
    {
        v = str2chr(s, i);
        if (v == 34)
        {
            e = json__skip_string(s, i, n);
            out = strcat(out, substring(s, i, e - i));
            i = e; continue;
        }
        if (json__is_ws(v)) { i = i + 1; continue; }
        out = strcat(out, substring(s, i, 1)); i = i + 1;
    }
    return out;
}

// TRUE if s (ignoring surrounding whitespace) is one complete JSON object.
float json_is_object(string s)
{
    if (!s) return FALSE;
    float n = strlen(s);
    float i = json__skip_ws(s, 0, n);
    if (i >= n || str2chr(s, i) != 123) return FALSE;
    float e = json__skip_value(s, i, n);
    if (!json__skip_ok) return FALSE;
    return json__skip_ws(s, e, n) >= n;
}

// TRUE if s (ignoring leading whitespace) begins a JSON object. Unlike
// json_is_object this accepts input cut off before its closing brace, which
// some engines do to long HTTP responses.
float json_starts_object(string s)
{
    if (!s) return FALSE;
    float n = strlen(s);
    float i = json__skip_ws(s, 0, n);
    return (i < n && str2chr(s, i) == 123);
}

// TRUE if obj has the top-level key (any value, including null).
float json_obj_has(string obj, string key)
{
    if (!obj) return FALSE;
    string OBJ = strzone(obj);
    float found = json__find_key(OBJ, 0, strlen(OBJ), key);
    strunzone(OBJ);
    return found;
}

// Raw text of a top-level value (e.g. "[...]", "{...}", "12", "\"str\""), or "" if missing.
string json_obj_get_raw(string obj, string key)
{
    if (!obj) return "";
    string OBJ = strzone(obj);   // protect the input from tempstring recycling
    string out = "";
    if (json__find_key(OBJ, 0, strlen(OBJ), key))
        out = substring(OBJ, json__vs, json__ve - json__vs);
    strunzone(OBJ);
    return out;
}

// String value of a top-level key, unescaped. Non-string values are returned
// as their raw text (numbers, true/false, nested objects/arrays). A missing
// key or a JSON null returns defval.
string json_obj_get_string(string obj, string key, string defval)
{
    if (!obj) return defval;
    string OBJ = strzone(obj);   // protect the input from tempstring recycling
    string out = defval;
    float vs, ve;

    if (json__find_key(OBJ, 0, strlen(OBJ), key))
    {
        vs = json__vs; ve = json__ve;
        if (str2chr(OBJ, vs) == 34)
        {
            // drop the quotes (the closing one is missing on truncated input)
            float inner = ve - vs - 1;
            if (json__skip_ok) inner = inner - 1;
            out = json_unescape_span(OBJ, vs + 1, inner);
        }
        else if (!json__span_equals(OBJ, vs, ve - vs, "null"))
            out = substring(OBJ, vs, ve - vs);
    }
    strunzone(OBJ);
    return out;
}

float json_obj_get_float(string obj, string key, float defval)
{
    string tok = json_obj_get_string(obj, key, "");
    if (tok == "") return defval;
    return stof(tok);
}

float json_obj_get_bool(string obj, string key, float defval)
{
    string t = json_obj_get_string(obj, key, "");
    if (t == "true" || t == "1") return 1;
    if (t == "false" || t == "0") return 0;
    return defval;
}

// Iterate objects in an array: pass pos = 0 for the first call (arr starts
// with '['), then pos = json__it_next. Returns "" when there are no more.
// Non-object elements are skipped.
float json__it_next;
string json_array_next_object(string arr, float pos)
{
    json__it_next = -1;
    if (!arr) return "";
    float n = strlen(arr), i = pos, v, e;

    if (pos <= 0)
    {
        i = json__skip_ws(arr, 0, n);
        if (i < n && str2chr(arr, i) == 91) i = i + 1;   // step inside '['
    }

    while (i < n)
    {
        i = json__skip_ws(arr, i, n);
        if (i >= n) break;
        v = str2chr(arr, i);
        if (v == 93) break;                     // ']' end of array
        if (v == 44) { i = i + 1; continue; }   // ','
        e = json__skip_value(arr, i, n);
        if (v == 123 && json__skip_ok)
        {
            json__it_next = e;
            return substring(arr, i, e - i);
        }
        if (e <= i) e = i + 1;
        i = e;
    }
    return "";
}

// Number of elements in a top-level array.
float json_array_len(string arr)
{
    if (!arr) return 0;
    float n = strlen(arr), i, v, e, count = 0;
    i = json__skip_ws(arr, 0, n);
    if (i >= n || str2chr(arr, i) != 91) return 0;
    i = i + 1;
    while (i < n)
    {
        i = json__skip_ws(arr, i, n);
        if (i >= n) break;
        v = str2chr(arr, i);
        if (v == 93) break;
        if (v == 44) { i = i + 1; continue; }
        e = json__skip_value(arr, i, n);
        count = count + 1;
        if (e <= i) e = i + 1;
        i = e;
    }
    return count;
}

// Index of the bracket that closes the '{' or '[' at open_pos, or -1.
float json_match_close(string s, float open_pos)
{
    float n = strlen(s), v;
    if (open_pos < 0 || open_pos >= n) return -1;
    v = str2chr(s, open_pos);
    if (v != 123 && v != 91) return -1;
    float e = json__skip_value(s, open_pos, n);
    if (!json__skip_ok) return -1;
    return e - 1;
}


// ============================================================================
// 7) Span Reader Helpers (work on [start,end) offsets; no long substrings)
// ============================================================================
float js_it_next, js_obj_start, js_obj_end, js_val_start, js_val_len;

// Find the next {...} span at or after pos (outside strings).
float js_array_next_span(string s, float pos)
{
    float n = strlen(s), i = pos, v;
    while (i < n)
    {
        v = str2chr(s, i);
        if (v == 34) { i = json__skip_string(s, i, n); continue; }
        if (v == 123) break;
        i = i + 1;
    }
    if (i >= n) return 0;
    js_obj_start = i;
    js_obj_end = json__skip_value(s, i, n);
    js_it_next = js_obj_end;
    return 1;
}

// key:"value" lookup inside the object [o0,o1). Sets js_val_start/js_val_len
// to the string contents (without quotes).
float js_obj_find_qstring_span(string s, float o0, float o1, string key)
{
    if (!json__find_key(s, o0, o1, key)) return 0;
    if (str2chr(s, json__vs) != 34) return 0;
    js_val_start = json__vs + 1;
    js_val_len   = json__ve - js_val_start;
    if (json__skip_ok) js_val_len = js_val_len - 1;   // exclude closing quote
    return 1;
}

// VERY tolerant fallback for damaged objects: find "key" anywhere, then the
// next ':' and opening quote, then the value.
float js_obj_find_qstring_span_fallback(string s, float o0, float o1, string key)
{
    string pat = strcat("\"", key, "\"");
    float plen = strlen(pat);
    float i = o0, hit, k;

    while (i < o1)
    {
        hit = strstrofs(s, pat, i);
        if (hit < 0 || hit + plen > o1) return 0;

        i = json__skip_ws(s, hit + plen, o1);
        if (!(i < o1 && str2chr(s, i) == 58)) { i = hit + 1; continue; }   // ':'
        i = json__skip_ws(s, i + 1, o1);
        if (!(i < o1 && str2chr(s, i) == 34)) { i = hit + 1; continue; }   // '"'

        json__skip_ok = TRUE;
        k = json__skip_string(s, i, o1);
        js_val_start = i + 1;
        js_val_len   = k - js_val_start;
        if (json__skip_ok) js_val_len = js_val_len - 1;   // exclude closing quote
        return 1;
    }
    return 0;
}

// copy short quoted string (decode escapes) -> zoned
string js_qstring_copy(string s, float v0, float vlen)
{
    return strzone(json_unescape_span(s, v0, vlen));
}

// Look up a string field in the object [o0,o1) (strict, then tolerant).
// Always returns a zoned string ("" when missing); caller must strunzone it.
string js_obj_get_zoned(string s, float o0, float o1, string key)
{
    if (js_obj_find_qstring_span(s, o0, o1, key) || js_obj_find_qstring_span_fallback(s, o0, o1, key))
        return js_qstring_copy(s, js_val_start, js_val_len);
    return strzone("");
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
        if (!json__is_ws(str2chr(s, i))) return FALSE;
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
    return strstrofs(s, ":", 0) >= 0;
}

string json_fix_minutes(string ds)
{
    if (!json_has_colon(ds)) return strcat(ds, ":00");
    return ds;
}

// Stream an escaped string into an open file in small chunks, so long values
// never have to fit in a single tempstring.
void json_write_escaped_to_file(float wf, string s)
{
    if (!s) return;
    float i = 0, L = strlen(s), chunk;
    while (i < L)
    {
        chunk = L - i; if (chunk > JSON_ESCAPE_CHUNK) chunk = JSON_ESCAPE_CHUNK;
        fputs(wf, json_escape(substring(s, i, chunk)));
        i = i + chunk;
    }
}

// Write "key":"value" (no separators) to an open file.
void json_write_kv_string_to_file(float wf, string k, string v)
{
    fputs(wf, "\""); json_write_escaped_to_file(wf, k); fputs(wf, "\":\"");
    json_write_escaped_to_file(wf, v); fputs(wf, "\"");
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

// Build the current match JSON document using the active builder.
// Call this inside json_begin_* context helpers.
void() json_emit_match_document =
{
    // === Desired schema: { "match": { ... } } ==============================
    local float f;  // scratch
    local entity t, p;
    local string date   = strftime(TRUE, "%Y-%m-%d %H:%M:%S");
    local string sgtype = json_get_gametype_playmode();
    local string hname  = infokey(world, "hostname");

    json_begin_object();
      json_key("match"); json_begin_object();
        json_kv_string("date",       date);
        json_kv_string("hostname",   hname);
        json_kv_string("map",        clanring_current_mapname());
        json_kv_string("gamemode",   sgtype);
        json_kv_number("match size", clanring_maxteams);
        json_kv_number("team size",  stats_matchtype);
        json_kv_number("timelimit",  stats_timelimit);
        json_kv_number("deathmatch", deathmatch);
        json_kv_number("teamplay", teamplay);
        json_kv_number("hook_enabled", !(clanring_playmode & CLANRING_NO_HOOK));
        json_kv_number("runes_enabled", qper_is_ctf() && !clanring_sv_pak0_only && ((clanring_playmode & CLANRING_RUNES) != 0));
        json_key("qper"); json_begin_object();
          json_kv_string("version",   QPER_VERSION);
          json_kv_string("cohort",    qper_display_cohort());
          json_kv_precise_number("reference", qper_display_reference());
          json_kv_precise_number("reference_minutes", qper_display_reference_mins());
          json_kv_precise_number("reference_provisional", qper_reference_provisional());
          json_kv_precise_number("reference_minimum_minutes", QPER_REF_PROVISIONAL_MINS);
          json_kv_precise_number("average_players", qper_average_players());
          json_kv_precise_number("players_at_end", qper_population_players);
          json_kv_precise_number("peak_players", qper_population_peak);
          json_kv_precise_number("population_secs", qper_population_clock());
          json_kv_precise_number("three_plus_secs", qper_population_three_secs);
          if (qper_is_ffa()) json_kv_string("population_bucket", qper_population_bucket());
          json_kv_string("profile", qper_is_ffa() ? "ffa" : "core");
        json_end_object();

        // ---- Teams ---------------------------------------------------------
        json_key("teams"); json_begin_array();
          t = clanring_sentinel.next_team;
          while (t && t != world)
          {
            json_begin_object();
              json_kv_string("name",  t.netname);
              local float roster_count = 0;
              p = t.next_player;
              while (p && p != world) { if (p.next_team == t && p.join_time > 0) roster_count++; p = p.next_player; }
              json_kv_number("participating_players", roster_count);
              json_kv_string("color", str_rtrim(strings_get_teamname3(t.height)));

              // team summary (vectors)
              json_key("team_summary"); json_begin_object();
                json_key("quad_ring"); json_begin_array(); json_number(t.dest2_x); json_number(t.dest2_y); json_number(t.dest2_z); json_end_array();
                json_key("rl_lg_gl");  json_begin_array(); json_number(t.dest1_x); json_number(t.dest1_y); json_number(t.dest1_z); json_end_array();
                json_key("sng_ng_mh"); json_begin_array(); json_number(t.pos1_x);  json_number(t.pos1_y);  json_number(t.pos1_z);  json_end_array();
                json_key("ra_ya_ga");  json_begin_array(); json_number(t.dest_x);  json_number(t.dest_y);  json_number(t.dest_z);  json_end_array();
                json_kv_number("rlpak_plus",  t.mangle_y);
                json_kv_number("rlpak_minus", t.mangle_z);
                f = 0; if (clanring_sentinel.cnt > 0) f = floor((1000 * t.mangle_x) / clanring_sentinel.cnt) / 10;
                json_kv_number("control_pct", f);
              json_end_object();

              // players in this team
              json_key("players"); json_begin_array();
                p = t.next_player;
                while (p && p != world)
                {
                  if (p.next_team != t) { p = p.next_player; continue; }
                  // pre-compute metrics
                  local float deaths = p.mangle_z;
                  local float kdr_val = (deaths > 0) ? floor(p.true_kills / deaths)
                                     : ((deaths == 0 && p.true_kills == 0) ? 0 : p.true_kills);
                  local float bullet_eff = json_pct(p.dest2_x, p.dest1_x);
                  local float nails_eff  = json_pct(p.dest2_y, p.dest1_y);
                  local float rockets_eff= json_pct(p.dest_y,  p.dest_x);
                  local float lg_eff     = json_pct(p.dest2_z, p.dest1_z);
                  local float gl_eff     = json_pct(p.stats_gl_frac, p.stats_gl_tot);
                  local float tot_fired_inc_gl = (p.dest1_x + p.dest1_y + p.dest1_z + p.dest_x + p.stats_gl_tot);
                  local float tot_done_inc_gl  = (p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y + p.stats_gl_frac);
                  local float total_eff        = json_pct(tot_done_inc_gl, tot_fired_inc_gl);
                  local float kpm = 0;
                  if (p.join_time > 0) { local float secs = time - p.join_time; if (secs > 1) kpm = (p.true_kills * 60) / secs; }
                  kpm = floor(kpm * 10) / 10;
                  local float qd_eff = json_pct(p.clanring_qdwep_x, p.clanring_qdwep_y);
                  local float pt_eff = json_pct(p.clanring_ptwep_x, p.clanring_ptwep_y);
                  local float tot_enemy = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y;
                  local float tot_done  = tot_enemy + p.clanring_badstats_y + p.clanring_badstats_z;
                  local float self_pct  = json_pct(p.clanring_badstats_y,  tot_done);
                  local float team_pct  = json_pct(p.clanring_badstats_z,  tot_done);
                  local float per_val = 0.1; if (p.join_time > 0){ local float s2 = time - p.join_time; if (s2 > 1) per_val = Q1_PER_Calc_Eff(p) / max(1, s2 / 60); if (per_val < 0.1) per_val = 0.1; }

                  json_begin_object();
                    json_kv_string("name", p.netname);
                    json_kv_string("team", strings_get_colour(p.height));

                    json_kv_number("score",  p.frags);
                    json_kv_number("kills",  p.true_kills);
                    if (stats_weapon_carrier_kills_enabled())
                    {
                        json_kv_number("rl_carrier_kills", p.stats_rl_carrier_kills);
                        json_kv_number("lg_carrier_kills", p.stats_lg_carrier_kills);
                    }
                    json_kv_number("deaths", deaths);
                    json_kv_number("kdr",    kdr_val);

                    json_kv_number("avenges",         p.stats_avenge_teammate);
                    json_kv_number("self_kills",      p.mangle_x);
                    json_kv_number("team_kills",      p.mangle_y);
                    json_kv_number("discharge_kills", p.stats_discharge_kills);
                    json_kv_number("damage_taken",    p.dmg_taken);
                    json_kv_number("damage_given",    p.dmg_given);
                    json_kv_number("enemy_weapon_dmg",p.ewep);

                    json_kv_number("bullet_eff",    bullet_eff);
                    json_kv_number("nails_eff",     nails_eff);
                    json_kv_number("rockets_eff",   rockets_eff);
                    json_kv_number("lightning_eff", lg_eff);
                    json_kv_number("grenade_eff",   gl_eff);
                    json_kv_number("total_eff",     total_eff);
                    json_kv_number("kpm",           kpm);

                    json_kv_number("quads",            p.clanring_qdwep_z);
                    json_kv_number("quad_time",        p.totalquad);
                    json_kv_number("quad_weapon_eff",  qd_eff);
                    json_kv_number("quad_enemy_kills", p.clanring_qdkill_x);
                    json_kv_number("quad_self_kills",  p.clanring_qdkill_z);
                    json_kv_number("quad_team_kills",  p.clanring_qdkill_y);

                    json_kv_number("pents",            p.clanring_ptwep_z);
                    json_kv_number("pent_weapon_eff",  pt_eff);
                    json_kv_number("pent_enemy_kills", p.clanring_ptkill_x);
                    json_kv_number("pent_team_kills",  p.clanring_ptkill_y);

                    json_kv_number("rl_paks_given", p.clanring_badstats_x);
                    json_kv_number("self_dmg_pct",  self_pct);
                    json_kv_number("team_dmg_pct",  team_pct);
                    json_kv_number("bore_deaths",   p.clanring_badstats_bores);
                    json_kv_number("lava_deaths",   p.clanring_badstats2_x);
                    json_kv_number("axe_deaths",    p.clanring_badstats2_y);
                    json_kv_number("fall_deaths",   p.clanring_badstats2_z);
                    if (stats_badstats_has_walkover_categories())
                    {
                        json_kv_number("spawn_walkovers", p.clanring_badstats_spawnwalk);
                        json_kv_number("tele_exit_walkovers", p.clanring_badstats_telewalk);
                    }

                    json_kv_number("def_teammate", p.stats_defense_teammate);
                    json_kv_number("def_backpack", p.stats_defense_backpack);
                    json_kv_number("def_powerup",  p.stats_defense_powerup);
                    json_kv_number("def_weapon",   p.stats_defense_weapon);
                    json_kv_number("def_armor",    p.stats_defense_armor);

                    json_key("items_taken"); json_begin_object();
                      json_kv_number("ssg", p.stats_item_ssg);
                      json_kv_number("ng",  p.stats_item_ng);
                      json_kv_number("sng", p.stats_item_sng);
                      json_kv_number("gl",  p.stats_item_gl);
                      json_kv_number("rl",  p.stats_item_rl);
                      json_kv_number("lg",  p.stats_item_lg);
                      json_kv_number("shells",  p.stats_item_shells);
                      json_kv_number("nails",   p.stats_item_nails);
                      json_kv_number("rockets", p.stats_item_rockets);
                      json_kv_number("cells",   p.stats_item_cells);
                      json_kv_number("health",  p.stats_item_health);
                      json_kv_number("mega",    p.stats_item_mega);
                      json_kv_number("biosuit", p.stats_item_biosuit);
                      json_kv_number("ga",      p.stats_item_greenarmor);
                      json_kv_number("ya",      p.stats_item_yellowarmor);
                      json_kv_number("ra",      p.stats_item_redarmor);
                      json_kv_number("backpacks", p.stats_item_backpacks);
                    json_end_object();

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
                        json_kv_number("fc_assists_return", p.fcassists_return);
                        json_kv_number("fc_assists_frag",   p.fcassists_frag);
                      json_end_object();
                    }

                    json_kv_number("per",         round2d(qper_rating(p)));
                    json_kv_number("per_v1",      per_val);
                    json_key("qper"); json_begin_object();
                      json_kv_precise_number("active_secs",   qper_active_secs(p));
                      json_kv_precise_number("contribution",  qper_contribution(p));
                      json_kv_precise_number("provisional",   qper_is_provisional(p));
                      json_kv_precise_number("reference", qper_player_reference(p));
                      json_kv_precise_number("reference_minutes", p.qper_final_valid ? p.qper_final_reference_mins : qper_reference_mins());
                      json_kv_precise_number("kill_credit", p.qper_kill_credit);
                      json_kv_precise_number("capture_credit", p.qper_cap_credit);
                      json_kv_precise_number("steal_credit", p.qper_steal_credit);
                      json_kv_precise_number("prior_points", 15 * (1 - qper_own_weight(p)));
                      json_kv_precise_number("assist_credit", p.qper_assist_credit);
                      json_key("raw_inputs"); json_begin_object();
                        json_kv_precise_number("damage", p.dmg_given);
                        json_kv_precise_number("carrier_damage", p.ewep);
                        json_kv_precise_number("kill_credit", p.qper_kill_credit);
                        json_kv_precise_number("capture_credit", p.qper_cap_credit);
                        json_kv_precise_number("steal_credit", p.qper_steal_credit);
                        json_kv_precise_number("returns", p.freturns);
                        json_kv_precise_number("defenses", p.fdefenses);
                        json_kv_precise_number("carrier_defenses", p.fcdefenses);
                        json_kv_precise_number("quads", p.clanring_qdwep_z);
                        json_kv_precise_number("pents", p.clanring_ptwep_z);
                        json_kv_precise_number("rings", p.stats_item_ring);
                        json_kv_precise_number("red_armor", p.stats_item_redarmor);
                        json_kv_precise_number("yellow_armor", p.stats_item_yellowarmor);
                        json_kv_precise_number("mega", p.stats_item_mega);
                        json_kv_precise_number("rl_pickups", p.stats_item_rl);
                        json_kv_precise_number("lg_pickups", p.stats_item_lg);
                        json_kv_precise_number("quad_support", p.stats_quad_secure);
                        json_kv_precise_number("enemy_deaths", p.mangle_z);
                        json_kv_precise_number("self_deaths", p.mangle_x);
                        json_kv_precise_number("teamkills", p.mangle_y);
                        json_kv_precise_number("quad_teamkills", p.stats_teamkill_quad);
                        json_kv_precise_number("team_damage", p.qper_team_damage);
                        json_kv_precise_number("weapon_loss", p.clanring_badstats_x);
                      json_end_object();
                      json_key("telemetry"); json_begin_object();
                        json_kv_precise_number("team_damage", p.qper_team_damage);
                        json_kv_precise_number("kill_pool_full", p.qper_kill_pool_full);
                        json_kv_precise_number("kill_pool_awarded", p.qper_kill_pool_awarded);
                        json_kv_precise_number("spawn_exempt", p.qper_spawn_exempt);
                        json_kv_precise_number("spawn_lt1", p.qper_spawn_lt1);
                        json_kv_precise_number("spawn_1to2", p.qper_spawn_1to2);
                        json_kv_precise_number("spawn_2to4", p.qper_spawn_2to4);
                        json_kv_precise_number("spawn_ge4", p.qper_spawn_ge4);
                        json_kv_precise_number("spawn_deaths_lt1", p.qper_spawn_deaths_lt1);
                        json_kv_precise_number("spawn_deaths_1to2", p.qper_spawn_deaths_1to2);
                        json_kv_precise_number("spawn_deaths_2to4", p.qper_spawn_deaths_2to4);
                        json_kv_precise_number("spawn_deaths_ge4", p.qper_spawn_deaths_ge4);
                        json_kv_precise_number("weapon_donations", p.qper_weapon_donations);
                        json_kv_precise_number("weapon_donations_received", p.qper_weapon_donations_received);
                        json_kv_precise_number("pack_recoveries", p.qper_pack_recoveries);
                        json_kv_precise_number("pack_concessions", p.qper_pack_concessions);
                        json_kv_precise_number("access_rl_secs", p.qper_access_rl_secs);
                        json_kv_precise_number("access_lg_secs", p.qper_access_lg_secs);
                        json_kv_precise_number("armed_secs", p.qper_armed_secs);
                        json_kv_precise_number("acquire_world", p.qper_acquire_world);
                        json_kv_precise_number("acquire_pack", p.qper_acquire_pack);
                        json_kv_precise_number("acquire_donation", p.qper_acquire_donation);
                        json_kv_precise_number("ammo_supplied_shells", p.qper_ammo_supplied_shells);
                        json_kv_precise_number("ammo_supplied_nails", p.qper_ammo_supplied_nails);
                        json_kv_precise_number("ammo_supplied_rockets", p.qper_ammo_supplied_rockets);
                        json_kv_precise_number("ammo_supplied_cells", p.qper_ammo_supplied_cells);
                        json_kv_precise_number("enemy_axe", p.qper_enemy_axe);
                        json_kv_precise_number("enemy_sg", p.qper_enemy_sg);
                        json_kv_precise_number("enemy_ssg", p.qper_enemy_ssg);
                        json_kv_precise_number("enemy_ng", p.qper_enemy_ng);
                        json_kv_precise_number("enemy_sng", p.qper_enemy_sng);
                        json_kv_precise_number("enemy_gl", p.qper_enemy_gl);
                        json_kv_precise_number("enemy_rl", p.qper_enemy_rl);
                        json_kv_precise_number("enemy_lg", p.qper_enemy_lg);
                        json_kv_precise_number("enemy_other", p.qper_enemy_other);
                        json_kv_precise_number("team_axe", p.qper_team_axe);
                        json_kv_precise_number("team_sg", p.qper_team_sg);
                        json_kv_precise_number("team_ssg", p.qper_team_ssg);
                        json_kv_precise_number("team_ng", p.qper_team_ng);
                        json_kv_precise_number("team_sng", p.qper_team_sng);
                        json_kv_precise_number("team_gl", p.qper_team_gl);
                        json_kv_precise_number("team_rl", p.qper_team_rl);
                        json_kv_precise_number("team_lg", p.qper_team_lg);
                        json_kv_precise_number("team_other", p.qper_team_other);
                        json_kv_precise_number("quad_secs", p.qper_quad_secs);
                        json_kv_precise_number("quad_damage", p.qper_quad_damage);
                        json_kv_precise_number("pent_secs", p.qper_pent_secs);
                        json_kv_precise_number("pent_damage", p.qper_pent_damage);
                        json_kv_precise_number("ring_secs", p.qper_ring_secs);
                        json_kv_precise_number("ring_damage", p.qper_ring_damage);
                        json_kv_precise_number("resistance_secs", p.qper_resistance_secs);
                        json_kv_precise_number("resistance_damage", p.qper_resistance_damage);
                        json_kv_precise_number("strength_secs", p.qper_strength_secs);
                        json_kv_precise_number("strength_damage", p.qper_strength_damage);
                        json_kv_precise_number("haste_secs", p.qper_haste_secs);
                        json_kv_precise_number("haste_damage", p.qper_haste_damage);
                        json_kv_precise_number("regen_secs", p.qper_regen_secs);
                        json_kv_precise_number("regen_damage", p.qper_regen_damage);
                      json_end_object();
                      json_key("terms"); json_begin_object();
                        for (f = 0; f < QPER_TERMS; f = f + 1)
                          json_kv_precise_number(qper_term_key(f), qper_term(p, f));
                      json_end_object();
                    json_end_object();
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
};

void(string entry) json_append_lastscores =
{
    float rf, wf;
    string s = "", line;
    float CAP_OLD = 12;          // keep this many previous entries
    float OBJ_MAX = 896;        // max bytes per single JSON object we will build/parse
    float READ_TAIL_MAX = 880;  // fallback tail clamp (old behavior)

    // Reused locals (QuakeC has function-scope locals; no shadowing)
    float o0, o1;
    string ttxt, tmap, tmode, thost, tdate;
    float si;

    // ---------- Collect metadata ----------
    string mapn = clanring_current_mapname(); if (!mapn || mapn == "") mapn = "unknown";

    string mode = infokey(world, "mode");
    if (!mode || mode == "")
    {
        if      (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) mode = "CTF";
        else if (clanring_playmode & CLANRING_CA_MODE)           mode = "CA";
        else if (clanring_playmode & CLANRING_RA_MODE)           mode = "RA";
        else if (clanring_playmode & CLANRING_DMM4_MODE)         mode = "DMM4";
        else if (clanring_playmode & CLANRING_WIPEOUT_MODE)      mode = "WIPEOUT";
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)      mode = "AIRSHOT";
        else if (clanring_playmode & CLANRING_HH_MODE)           mode = "HH";
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

    // ---------- Read existing file (keep last CAP_OLD), TRUE STREAM PARSE ----------
    string p_txt[12], p_map[12], p_mode[12], p_host[12], p_date[12];
    float keep = 0;

    rf = fopen("json/lastscores.json", FILE_READ);
    if (rf < 0) rf = fopen("lastscores.json", FILE_READ);
    if (rf >= 0)
    {
        float seen_total = 0;
        float bytes_total = 0;

        // streaming object build state
        string obj = "";
        float started = 0;
        float depth = 0;
        float in_str = 0;
        float esc = 0;
        float overflow = 0;
        float obj_len = 0;

        while (1)
        {
            line = fgets(rf);
            if (line == "") break;

            // Stabilize fgets tempstring before per-char work
            string zline = strzone(line);
            bytes_total = bytes_total + strlen(zline);

            float li = 0, ln = strlen(zline);
            while (li < ln)
            {
                string ch = substring(zline, li, 1);

                // If we're inside an object, append bytes (unless overflowed).
                if (started)
                {
                    if (!overflow)
                    {
                        obj = strcat(obj, ch);
                        obj_len = obj_len + 1;
                        if (obj_len > OBJ_MAX) overflow = 1;
                    }
                }

                // tracking string literal state
                if (in_str)
                {
                    if (esc) esc = 0;
                    else if (ch == "\\") esc = 1;    // escape
                    else if (ch == "\"") in_str = 0; // closing quote
                    li = li + 1; continue;
                }
                if (ch == "\"") { in_str = 1; li = li + 1; continue; }

                // object boundaries
                if (ch == "{")
                {
                    if (!started)
                    {
                        started = 1;
                        depth = 1;
                        overflow = 0;
                        obj_len = 1;
                        obj = "{";
                    }
                    else depth = depth + 1;

                    li = li + 1;
                    continue;
                }
                if (ch == "}" && started)
                {
                    depth = depth - 1;
                    if (depth <= 0)
                    {
                        // object complete
                        started = 0;
                        depth = 0;
                        seen_total = seen_total + 1;

                        if (!overflow)
                        {
                            string zobj = strzone(obj);
                            o0 = 0; o1 = strlen(zobj);

                            // always zoned ("" when missing); freed below or when rewritten
                            ttxt  = js_obj_get_zoned(zobj, o0, o1, "text");
                            tmap  = js_obj_get_zoned(zobj, o0, o1, "map");
                            tmode = js_obj_get_zoned(zobj, o0, o1, "mode");
                            thost = js_obj_get_zoned(zobj, o0, o1, "host");
                            tdate = js_obj_get_zoned(zobj, o0, o1, "date");

                            if (ttxt != "")
                            {
                                if (keep < CAP_OLD)
                                {
                                    p_txt[keep]  = ttxt;  p_map[keep]  = tmap;
                                    p_mode[keep] = tmode; p_host[keep] = thost; p_date[keep] = tdate;
                                    keep = keep + 1;
                                }
                                else
                                {
                                    // free oldest, shift left, append newest
                                    strunzone(p_txt[0]);  strunzone(p_map[0]);  strunzone(p_mode[0]);
                                    strunzone(p_host[0]); strunzone(p_date[0]);

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
                                strunzone(ttxt);
                                strunzone(tmap);
                                strunzone(tmode);
                                strunzone(thost);
                                strunzone(tdate);
                            }

                            strunzone(zobj);
                        }

                        // reset builder
                        obj = "";
                        obj_len = 0;
                        overflow = 0;
                    }

                    li = li + 1;
                    continue;
                }

                li = li + 1;
            }

            strunzone(zline);
        }

        fclose(rf);

        // ---- Fallback if stream parse saw nothing but file had content ----
        if (seen_total == 0 && bytes_total > 0)
        {
            float rf2 = fopen("json/lastscores.json", FILE_READ);
            if (rf2 < 0) rf2 = fopen("lastscores.json", FILE_READ);
            if (rf2 >= 0)
            {
                float tail_trimmed = 0;
                string zs = strzone(""); // zoned tail buffer

                while (1)
                {
                    line = fgets(rf2);
                    if (line == "") break;

                    string tmp = strcat(zs, line);
                    float Ltmp = strlen(tmp);
                    if (Ltmp > READ_TAIL_MAX)
                    {
                        tmp = substring(tmp, Ltmp - READ_TAIL_MAX, READ_TAIL_MAX);
                        tail_trimmed = 1;
                    }

                    tmp = strzone(tmp);
                    strunzone(zs);
                    zs = tmp;
                }
                fclose(rf2);

                s = zs; // stable zoned tail

                if (tail_trimmed)
                {
                    // drop the partial object at the front of the tail
                    float fi = strstrofs(zs, "{", 0);
                    if (fi > 0)
                    {
                        s = strzone(substring(zs, fi, strlen(zs) - fi));
                        strunzone(zs);
                    }
                }

                float pos = 0;
                while (js_array_next_span(s, pos))
                {
                    o0 = js_obj_start; o1 = js_obj_end;

                    // always zoned ("" when missing); freed below or when rewritten
                    ttxt  = js_obj_get_zoned(s, o0, o1, "text");
                    tmap  = js_obj_get_zoned(s, o0, o1, "map");
                    tmode = js_obj_get_zoned(s, o0, o1, "mode");
                    thost = js_obj_get_zoned(s, o0, o1, "host");
                    tdate = js_obj_get_zoned(s, o0, o1, "date");

                    if (ttxt != "")
                    {
                        if (keep < CAP_OLD)
                        {
                            p_txt[keep]  = ttxt;  p_map[keep]  = tmap;
                            p_mode[keep] = tmode; p_host[keep] = thost; p_date[keep] = tdate;
                            keep = keep + 1;
                        }
                        else
                        {
                            strunzone(p_txt[0]);  strunzone(p_map[0]);  strunzone(p_mode[0]);
                            strunzone(p_host[0]); strunzone(p_date[0]);

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
                        strunzone(ttxt);
                        strunzone(tmap);
                        strunzone(tmode);
                        strunzone(thost);
                        strunzone(tdate);
                    }

                    pos = js_it_next;
                }

                strunzone(s);
            }
        }
    }

    // ---------- Rewrite full array (cap <= 10) ----------
    wf = fopen("json/lastscores.json", FILE_WRITE);
    if (wf < 0) wf = fopen("lastscores.json", FILE_WRITE);
    if (wf < 0)
    {
        dprint("*** ERROR: cannot write lastscores.json\n");
        float qi;
        for (qi = 0; qi < keep; qi = qi + 1)
        {
            strunzone(p_txt[qi]); strunzone(p_map[qi]); strunzone(p_mode[qi]);
            strunzone(p_host[qi]); strunzone(p_date[qi]);
        }
        strunzone(z_map); strunzone(z_mode); strunzone(z_host);
        strunzone(z_entry); strunzone(z_date);
        return;
    }

    // IMPORTANT: write one object per line so fgets() in QC never hits STRINGTEMP_LENGTH
    fputs(wf, "[\n");

    float idxw;
    float wrote_any = 0;

    // Old entries first
    for (idxw = 0; idxw < keep; idxw = idxw + 1)
    {
        if (wrote_any)
            fputs(wf, ",\n");
        wrote_any = 1;

        fputs(wf, "{");

        if (p_date[idxw] != "")
        {
            json_write_kv_string_to_file(wf, "date", p_date[idxw]); fputs(wf, ",");
        }
        json_write_kv_string_to_file(wf, "map",  p_map[idxw]);  fputs(wf, ",");
        json_write_kv_string_to_file(wf, "mode", p_mode[idxw]); fputs(wf, ",");
        json_write_kv_string_to_file(wf, "host", p_host[idxw]); fputs(wf, ",");
        json_write_kv_string_to_file(wf, "text", p_txt[idxw]);  fputs(wf, "}");

        // free as we go
        strunzone(p_txt[idxw]); strunzone(p_map[idxw]); strunzone(p_mode[idxw]);
        strunzone(p_host[idxw]); strunzone(p_date[idxw]);
    }

    // Append newest (if any); total entries now <= CAP_OLD + 1
    if (!json_is_blank(z_entry))
    {
        if (wrote_any)
            fputs(wf, ",\n");
        wrote_any = 1;

        fputs(wf, "{");
        json_write_kv_string_to_file(wf, "date", z_date);  fputs(wf, ",");
        json_write_kv_string_to_file(wf, "map",  z_map);   fputs(wf, ",");
        json_write_kv_string_to_file(wf, "mode", z_mode);  fputs(wf, ",");
        json_write_kv_string_to_file(wf, "host", z_host);  fputs(wf, ",");
        json_write_kv_string_to_file(wf, "text", z_entry); fputs(wf, "}");
    }

    fputs(wf, "\n]");
    fclose(wf);

    // Free inputs
    strunzone(z_map); strunzone(z_mode); strunzone(z_host);
    strunzone(z_entry); strunzone(z_date);
};


// 1) Build JSON to an in-memory string (auto-compact if pretty is too large)

// 2) Write JSON to a file (STREAM builder to file; avoids QC string cap)
void(string path, float pretty) json_export_match_to_file =
{
    if (!path || path == "")
    {
        dprint("json_export_match_to_file: empty path\n");
        bprint("[matchpost] save-json: ERROR (empty path)\n");
        return;
    }

    local filestream f = fopen(path, FILE_WRITE);
    if (f < 0)
    {
        dprint(sprintf("json_export_match_to_file: open failed '%s'\n", path));
        bprint(sprintf("[matchpost] save-json: ERROR (open failed '%s')\n", path));
        return;
    }

    bprint(sprintf("[matchpost] save-json: writing '%s' (stream)\n", path));

    // Stream the document straight into 'f' (avoids the QC string cap).
    json_begin_pretty_to_file(f, pretty);
    json_emit_match_document();

    // We streamed everything to 'f'; just detach the sink before closing.
    json_clear_sink();
    fclose(f);

    bprint(sprintf("[matchpost] save-json: wrote '%s'\n", path));
};


// 3) Post the current match JSON (send the file via '@')
void(float pretty, float deferred) json_post_current_match =
{
    local string rel_write = "json/match_last.json";
    local string rel_read  = "data/json/match_last.json";

    // Build the JSON (compact) to our normal write location.
    json_export_match_to_file(rel_write, pretty);

    // Show what we wrote.
    bprint(sprintf("[matchpost] wrote rel(write)='%s'\n", rel_write));

    // Resolve to likely absolute candidates for the engine to fopen().
    local string gdir = cvar_string("fs_gamedir");
    local string bdir = cvar_string("fs_basedir");
    local string mod  = cvar_string("game");

    bprint(sprintf("[matchpost] cvars: fs_gamedir='%s' fs_basedir='%s' game='%s'\n",
                   gdir ? gdir : "", bdir ? bdir : "", mod ? mod : ""));

    // Candidate list (most engines actually write file into <gamedir>/data/)
    local string cand[8]; local float n = 0;
    if (gdir && gdir != "")
    {
        cand[n++] = strcat(gdir, "/data/", rel_write); // <gdir>/data/json/...
        cand[n++] = strcat(gdir, "/",     rel_write);  // <gdir>/json/...
    }
    if (bdir && bdir != "" && mod && mod != "")
    {
        cand[n++] = strcat(bdir, "/", mod, "/data/", rel_write);
        cand[n++] = strcat(bdir, "/", mod, "/",     rel_write);
    }
    if (mod && mod != "")
    {
        cand[n++] = strcat(mod, "/data/", rel_write);
        cand[n++] = strcat(mod, "/",      rel_write);
    }

    // Fall back to the bare rel_read (works only if CWD is game root).
    cand[n++] = rel_read;

    // Try each candidate: if QC can fopen() it, ask the engine to POST it.
    bprint(sprintf("[matchpost] payload mode=%s (build-to-file -> post file)\n",
                   deferred ? "deferred" : "immediate"));

    local float i;
    for (i = 0; i < n; i = i + 1)
    {
        local string p = cand[i];
        if (!p || p == "") continue;

        // QC-side proof the file exists & is readable.
        local float fh = fopen(p, FILE_READ);
        if (fh < 0)
        {
            dprint(sprintf("[matchpost] QC fopen failed: '%s'\n", p));
            continue;
        }

        // Optional: preview up to 160 bytes (helps confirm we found the right file)
        {
            local string head = "", line;
            while (strlen(head) < 160) { line = fgets(fh); if (line == "") break; head = strcat(head, line); }
            bprint(sprintf("[matchpost] try '%s' head=%g bytes\n", p, strlen(head)));
            if (strlen(head) > 0) bprint(sprintf("[matchpost] head preview: %s\n", substring(head, 0, 160)));
        }
        fclose(fh);

        // Hand the engine an @absolute (or at least QC-verified) path.
        if (deferred) match_post_json_deferred(strcat("@", p));
        else          match_post_json        (strcat("@", p));
        return; // stop after first good candidate
    }

    // If we got here, none of the candidates opened in QC.
    bprint("[matchpost] ERROR: no candidate file path could be opened; POST aborted.\n");
};


// 4) Convenience: post and optionally save a local copy
void(float pretty, float save_copy, string path, float deferred) json_post_and_maybe_save =
{
    
        bprint(sprintf("[matchpost] maybe-save: save_copy=%g path='%s' pretty=%g deferred=%g\n",
                   save_copy, path, pretty, deferred));
    
    if (save_copy && path && path != "")
    {
        bprint(sprintf("[matchpost] maybe-save: requested path='%s' (pretty=%g)\n", path, pretty));
        json_export_match_to_file(path, pretty);
    }
    else if (save_copy)
    {
        dprint("json_post_and_maybe_save: no path; skipping save_copy\n");
        bprint("[matchpost] maybe-save: skipping (no path)\n");
    }
    json_post_current_match(pretty, deferred);
};

void () utils_show_last_scores =
{
    float f = fopen("json/lastscores.json", FILE_READ);
    if (f < 0) f = fopen("lastscores.json", FILE_READ);

    sprint(self, "\n");
    if (f < 0) { sprint(self, "[no lastscores found]\n"); return; }

    // TRUE streaming parse (avoid QC ~1KB string cap)
    float OBJ_MAX = 896;    // must stay under STRINGTEMP_LENGTH (~1024)
    string line;

    // reused locals (QC has function-scope locals; no shadowing)
    float o0, o1;

    float seen_total = 0;
    float overflowed_objs = 0;

    // streaming object build state
    string obj = "";
    float started = 0;
    float depth = 0;
    float in_str = 0;
    float esc = 0;
    float overflow = 0;
    float obj_len = 0;

    while (1)
    {
        line = fgets(f);
        if (line == "") break;

        // stabilize fgets tempstring
        string zline = strzone(line);
        float li = 0, ln = strlen(zline);

        while (li < ln)
        {
            string ch = substring(zline, li, 1);

            // if we're inside an object, append bytes with OBJ_MAX guard
            if (started)
            {
                if (!overflow && obj_len < OBJ_MAX)
                    obj = strcat(obj, ch);

                obj_len = obj_len + 1;
                if (obj_len > OBJ_MAX)
                    overflow = 1;
            }

            // string literal state
            if (in_str)
            {
                if (esc) esc = 0;
                else if (ch == "\\") esc = 1;
                else if (ch == "\"") in_str = 0;
                li = li + 1; continue;
            }
            if (ch == "\"") { in_str = 1; li = li + 1; continue; }

            // object boundaries outside strings
            if (ch == "{")
            {
                if (!started)
                {
                    started = 1;
                    depth = 1;
                    overflow = 0;
                    obj_len = 1;
                    obj = "{";
                }
                else depth = depth + 1;

                li = li + 1; continue;
            }

            if (ch == "}" && started)
            {
                depth = depth - 1;
                if (depth <= 0)
                {
                    // object complete
                    started = 0;
                    depth = 0;
                    seen_total = seen_total + 1;

                    if (overflow)
                    {
                        // don't try to render truncated JSON
                        overflowed_objs = overflowed_objs + 1;
                    }
                    else
                    {
                        string zobj = strzone(obj);
                        o0 = 0; o1 = strlen(zobj);

                        // ---- Find spans inside this single object ----
                        float t_found = 0, t0 = 0, tl = 0;
                        if (js_obj_find_qstring_span(zobj, o0, o1, "text")) { t_found = 1; t0 = js_val_start; tl = js_val_len; }
                        else if (js_obj_find_qstring_span_fallback(zobj, o0, o1, "text")) { t_found = 1; t0 = js_val_start; tl = js_val_len; }

                        // ---- Copy short values (decoded, always zoned) ----
                        string tdate = js_obj_get_zoned(zobj, o0, o1, "date");
                        string tmap  = js_obj_get_zoned(zobj, o0, o1, "map");
                        string tmode = js_obj_get_zoned(zobj, o0, o1, "mode");

                        // ---- Friendly "when" label ----
                        string when = "Unknown Date";
                        if (strlen(tdate) >= 10)
                        {
                            string dpart = substring(tdate, 0, 10);
                            float y = stof(substring(dpart, 6, 4));
                            float m = stof(substring(dpart, 0, 2));
                            float d = stof(substring(dpart, 3, 2));

                            float hh = 0, mm = 0;
                            if (strlen(tdate) >= 16)
                            {
                                string tpart = substring(tdate, 11, 5);
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
                        sprint(self, strcat(format_match_header(when, strlen(tmap) ? tmap : "unknown",
                                                               strlen(tmode) ? tmode : "dm"), "\n"));

                        // ---- Body ("text") ----
                        if (t_found)
                        {
                            sprint(self, "Score: ");

                            string ttext = js_qstring_copy(zobj, t0, tl);
                            {
                                // chunked sprint to avoid long-string truncation
                                float off = 0, L = strlen(ttext);
                                while (off < L)
                                {
                                    float nout = (L - off > 128) ? 128 : (L - off);
                                    sprint(self, substring(ttext, off, nout));
                                    off = off + nout;
                                }
                                strunzone(ttext);
                            }
                            sprint(self, "\n");
                        }
                        else sprint(self, "(no text)\n");

                        sprint(self, "\n"); // blank line between entries

                        strunzone(tdate);
                        strunzone(tmap);
                        strunzone(tmode);

                        strunzone(zobj);
                    }

                    // reset builder
                    obj = ""; obj_len = 0; overflow = 0;
                }

                li = li + 1; continue;
            }

            li = li + 1;
        }

        strunzone(zline);
    }

    fclose(f);

    if (seen_total == 0)
        sprint(self, "[no lastscores found]\n");
    else if (overflowed_objs > 0)
        sprint(self, sprintf("[note] %g lastscores entries were too large to display (> %g bytes)\n",
                             overflowed_objs, OBJ_MAX));
};
