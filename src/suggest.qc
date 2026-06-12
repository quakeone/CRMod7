//
// suggest.qc
//
// Explicit-list pickup team suggestion command for CRMod7.
//
// Usage:
//   cmd suggest woods r00k goat uns
//   cmd suggest wo r0 go un
//   cmd suggest deepfriednewbie=r00k FoknQuake=PZ penguin=goat unspoken=uns
//   cmd suggest list r0
//   cmd suggest alias darthnader r00k
//   cmd suggest dm list kw
//   cmd suggest ctf woods r00k goat uns
//
// Data file:
//   configs/ranks.cfg
//
// File format:
//   CTF:
//   tier 1: frenzy, kwong, muller, uns, woods
//   tier 2: civic, jbone, omicron, PZ
//   DM:
//   tier 1: frenzy, kwong, levon, muller, uns, woods
//   tier 2: civic, ef3ss, jbone, mrfancypants, omicron, PZ
//
//   Tier players share the same rating. Lower tier numbers are stronger.
//
// Legacy flat format:
//   first comma item is the canonical ranked name.
//   remaining comma items are aliases.
//   order is ranking, strongest first.
//   @alias,canonical,alias lines add aliases without changing rank order.
//
// Example:
//   @alias,goat,penguin
//   @alias,r00k,deepfriednewbie
//   @alias,PZ,FoknQuake
//

#define SUG_RANK_FILE          "configs/ranks.cfg"

#define SUG_MAX_PLAYERS        10
#define SUG_MAX_RANKS          256
#define SUG_MAX_ALIASES        1024
#define SUG_MAX_RANK_LINES     4096
#define SUG_LIST_LIMIT         20
#define SUG_COOLDOWN           10

#define SUG_FALSE              0
#define SUG_TRUE               1

#define SUG_BASE_RATING        10000
#define SUG_RATING_STEP        10
#define SUG_TIER_RATING_STEP   100

float  sug_loaded;
float  sug_rank_count;
float  sug_alias_count;
float  sug_saw_sections;
float  sug_command_output_open;

string sug_rank_name[SUG_MAX_RANKS];
string sug_rank_norm[SUG_MAX_RANKS];
float  sug_rank_rating[SUG_MAX_RANKS];

string sug_alias_name[SUG_MAX_ALIASES];
string sug_alias_norm[SUG_MAX_ALIASES];
float  sug_alias_rank[SUG_MAX_ALIASES];

float  sug_count;
entity sug_ent[SUG_MAX_PLAYERS];

string sug_visible[SUG_MAX_PLAYERS];
string sug_visible_norm[SUG_MAX_PLAYERS];
string sug_canonical[SUG_MAX_PLAYERS];
string sug_canonical_norm[SUG_MAX_PLAYERS];
float  sug_rating[SUG_MAX_PLAYERS];
float  sug_used_alias[SUG_MAX_PLAYERS];

float  sug_best_mask;
float  sug_best_diff;
float  sug_best_red_score;
float  sug_best_blue_score;

float  sug_pow2[16];

string sug_loaded_section;
string sug_target_section;
string sug_parse_section;

float(string token) Suggest_FindRankExactNorm;
float(string token) Suggest_FindAliasIndexExactNorm;
void(float team_size, string section) Suggest_PrintResult;

float(float x) Suggest_Abs =
{
	if (x < 0)
		return 0 - x;

	return x;
};

float(float c) Suggest_IsPrintable =
{
	if (c >= 32 && c <= 126)
		return SUG_TRUE;

	return SUG_FALSE;
};

float(float c) Suggest_IsColorCodeChar =
{
	if (c >= 48 && c <= 57) return SUG_TRUE;  // 0-9
	if (c >= 65 && c <= 90) return SUG_TRUE;  // A-Z
	if (c >= 97 && c <= 122) return SUG_TRUE; // a-z

	return SUG_FALSE;
};

void() Suggest_OutputBegin =
{
	if (!sug_command_output_open)
	{
		sprint(self, "\n");
		sug_command_output_open = SUG_TRUE;
	}
};

void() Suggest_OutputEnd =
{
	if (sug_command_output_open)
	{
		sprint(self, "\n");
		sug_command_output_open = SUG_FALSE;
	}
};

string(float n) Suggest_FtosGold =
{
	string s;
	string out;
	float i;
	float c;

	n = floor(n);

	if (n < 0)
	{
		out = "-";
		n = 0 - n;
	}
	else
	{
		out = "";
	}

	s = ftos(n);

	for (i = 0; i < strlen(s); i = i + 1)
	{
		c = str2chr(s, i);

		if (c >= 48 && c <= 57)
			out = strcat(out, chr2str(18 + c - 48));
		else
			out = strcat(out, chr2str(c));
	}

	return out;
};

float() Suggest_IsAdmin =
{
	if (self.style & CLANRING_ADMINISTRATOR)
		return SUG_TRUE;

	Suggest_OutputBegin();
	sprint(self, "Admin only command.\n");
	return SUG_FALSE;
};

string(string s) Suggest_StripInlineComment =
{
	float p;

	p = strstrofs(s, "//", 0);

	if (p >= 0)
		return substring(s, 0, p);

	return s;
};

string(string s) Suggest_DequakeName =
{
	string out;
	float i;
	float c;
	float nextc;

	out = "";

	for (i = 0; i < strlen(s); i = i + 1)
	{
		c = str2chr(s, i);

		// Skip common ^1/^2/^x style color code pairs.
		if (c == 94) // ^
		{
			if (i + 1 < strlen(s))
			{
				nextc = str2chr(s, i + 1);
				if (Suggest_IsColorCodeChar(nextc))
				{
					i = i + 1;
					continue;
				}
			}
		}

		// NetQuake high-bit colored chars map back to base ASCII.
		c = c & 127;

		if (!Suggest_IsPrintable(c))
			continue;

		out = strcat(out, chr2str(c));
	}

	return out;
};

string(string s) Suggest_NormalizeName =
{
	s = Suggest_DequakeName(s);
	s = strtrim(s);
	s = strtolower(s);

	return s;
};

float(string text_norm, string prefix_norm) Suggest_NormPrefix =
{
	float plen;

	plen = strlen(prefix_norm);

	if (plen <= 0)
		return SUG_FALSE;

	if (strlen(text_norm) < plen)
		return SUG_FALSE;

	if (substring(text_norm, 0, plen) == prefix_norm)
		return SUG_TRUE;

	return SUG_FALSE;
};

float(string token) Suggest_FileTokenIsSafe =
{
	if (token == "")
		return SUG_FALSE;

	if (strstrofs(token, ",", 0) >= 0)
		return SUG_FALSE;

	if (strstrofs(token, "//", 0) >= 0)
		return SUG_FALSE;

	// A trailing colon would be misparsed as a section header on reload.
	if (strstrofs(token, ":", 0) >= 0)
		return SUG_FALSE;

	// An equals sign would make the alias untypeable as a player token.
	if (strstrofs(token, "=", 0) >= 0)
		return SUG_FALSE;

	return SUG_TRUE;
};

string(string section) Suggest_CanonicalSection =
{
	section = strtolower(section);

	if (section == "ctf")
		return "ctf";

	if (section == "dm")
		return "dm";

	return "";
};

float(string section) Suggest_IsSectionName =
{
	if (Suggest_CanonicalSection(section) != "")
		return SUG_TRUE;

	return SUG_FALSE;
};

string() Suggest_DefaultSection =
{
	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		return "ctf";

	return "dm";
};

string(string section) Suggest_OtherSection =
{
	section = Suggest_CanonicalSection(section);

	if (section == "ctf")
		return "dm";

	if (section == "dm")
		return "ctf";

	return "";
};

string(string section) Suggest_SectionDisplayName =
{
	section = strtolower(section);

	if (section == "ctf")
		return "CTF";

	if (section == "dm")
		return "DM";

	return section;
};

float(string work) Suggest_ParseSectionHeader =
{
	string section;
	float colon;

	colon = strstrofs(work, ":", 0);

	if (colon < 0)
		return SUG_FALSE;

	if (colon != strlen(work) - 1)
		return SUG_FALSE;

	section = strtrim(substring(work, 0, colon));
	section = Suggest_CanonicalSection(section);

	if (section == "" && substring(strtolower(strtrim(substring(work, 0, colon))), 0, 4) == "tier")
		return SUG_FALSE;

	sug_saw_sections = SUG_TRUE;
	sug_parse_section = section;

	return SUG_TRUE;
};

float() Suggest_LineIsInTargetSection =
{
	if (!sug_saw_sections)
		return SUG_TRUE;

	if (sug_parse_section == sug_target_section)
		return SUG_TRUE;

	return SUG_FALSE;
};

void() Suggest_Init =
{
	sug_pow2[0] = 1;
	sug_pow2[1] = 2;
	sug_pow2[2] = 4;
	sug_pow2[3] = 8;
	sug_pow2[4] = 16;
	sug_pow2[5] = 32;
	sug_pow2[6] = 64;
	sug_pow2[7] = 128;
	sug_pow2[8] = 256;
	sug_pow2[9] = 512;
	sug_pow2[10] = 1024;
	sug_pow2[11] = 2048;
	sug_pow2[12] = 4096;
	sug_pow2[13] = 8192;
	sug_pow2[14] = 16384;
	sug_pow2[15] = 32768;
};

float(float mask, float bit) Suggest_HasBit =
{
	if (mask & sug_pow2[bit])
		return SUG_TRUE;

	return SUG_FALSE;
};

float(float mask) Suggest_BitCount =
{
	float i;
	float c;

	c = 0;

	for (i = 0; i < SUG_MAX_PLAYERS; i = i + 1)
	{
		if (Suggest_HasBit(mask, i))
			c = c + 1;
	}

	return c;
};

void() Suggest_ClearRanks =
{
	float i;

	for (i = 0; i < sug_rank_count; i = i + 1)
	{
		if (sug_rank_name[i] != "") strunzone(sug_rank_name[i]);
		if (sug_rank_norm[i] != "") strunzone(sug_rank_norm[i]);

		sug_rank_name[i] = "";
		sug_rank_norm[i] = "";
		sug_rank_rating[i] = 0;
	}

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (sug_alias_name[i] != "") strunzone(sug_alias_name[i]);
		if (sug_alias_norm[i] != "") strunzone(sug_alias_norm[i]);

		sug_alias_name[i] = "";
		sug_alias_norm[i] = "";
		sug_alias_rank[i] = -1;
	}

	sug_rank_count = 0;
	sug_alias_count = 0;
	sug_saw_sections = SUG_FALSE;
	sug_parse_section = "";
	sug_loaded = SUG_FALSE;
	sug_loaded_section = "";
};

float(string canonical, float rating) Suggest_AddRankWithRating =
{
	string norm;
	float idx;
	float aliasidx;

	canonical = strtrim(canonical);
	norm = Suggest_NormalizeName(canonical);

	if (canonical == "" || norm == "")
		return -1;

	aliasidx = Suggest_FindAliasIndexExactNorm(canonical);

	if (aliasidx >= 0)
	{
		dprint("Suggest: duplicate ranked name ignored: ");
		dprint(canonical);
		dprint("\n");
		return -1;
	}

	if (sug_rank_count >= SUG_MAX_RANKS)
	{
		dprint("Suggest: rank table full\n");
		return -1;
	}

	idx = sug_rank_count;

	sug_rank_name[idx] = strzone(canonical);
	sug_rank_norm[idx] = strzone(norm);
	sug_rank_rating[idx] = rating;

	sug_rank_count = sug_rank_count + 1;

	return idx;
};

float(string canonical) Suggest_AddRank =
{
	return Suggest_AddRankWithRating(canonical, SUG_BASE_RATING - (sug_rank_count * SUG_RATING_STEP));
};

float(float rankidx, string alias) Suggest_AddAlias =
{
	string norm;
	float aliasidx;

	alias = strtrim(alias);
	norm = Suggest_NormalizeName(alias);

	if (alias == "" || norm == "")
		return SUG_FALSE;

	aliasidx = Suggest_FindAliasIndexExactNorm(alias);

	if (aliasidx >= 0)
	{
		if (sug_alias_rank[aliasidx] != rankidx)
		{
			dprint("Suggest: alias collision ignored: ");
			dprint(alias);
			dprint("\n");
		}

		return SUG_FALSE;
	}

	if (sug_alias_count >= SUG_MAX_ALIASES)
	{
		dprint("Suggest: alias table full\n");
		return SUG_FALSE;
	}

	sug_alias_name[sug_alias_count] = strzone(alias);
	sug_alias_norm[sug_alias_count] = strzone(norm);
	sug_alias_rank[sug_alias_count] = rankidx;

	sug_alias_count = sug_alias_count + 1;

	return SUG_TRUE;
};

float(string token) Suggest_FindAliasIndexExactNorm =
{
	string norm;
	float i;

	norm = Suggest_NormalizeName(token);

	if (norm == "")
		return -1;

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (sug_alias_norm[i] == norm)
			return i;
	}

	return -1;
};

void(string line) Suggest_ParseAliasDirective =
{
	string work;
	string ranked;
	string alias;
	float comma;
	float rankidx;

	work = substring(line, 7, strlen(line) - 7);
	work = strtrim(work);

	comma = strstrofs(work, ",", 0);

	if (comma < 0)
	{
		dprint("Suggest: bad alias directive\n");
		return;
	}

	ranked = strtrim(substring(work, 0, comma));
	alias = strtrim(substring(work, comma + 1, strlen(work) - comma - 1));

	if (ranked == "" || alias == "")
	{
		dprint("Suggest: bad alias directive\n");
		return;
	}

	rankidx = Suggest_FindRankExactNorm(ranked);

	if (rankidx < 0)
	{
		dprint("Suggest: alias directive target not found: ");
		dprint(ranked);
		dprint("\n");
		return;
	}

	Suggest_AddAlias(rankidx, alias);
};

float(string work) Suggest_ParseTierLine =
{
	string lower;
	string head;
	string names;
	string token;
	float colon;
	float tier;
	float rating;
	float comma;
	float rankidx;

	colon = strstrofs(work, ":", 0);

	if (colon < 0)
		return SUG_FALSE;

	head = strtrim(substring(work, 0, colon));
	lower = strtolower(head);

	if (substring(lower, 0, 4) != "tier")
		return SUG_FALSE;

	if (strlen(lower) > 4)
		tier = stof(strtrim(substring(lower, 4, strlen(lower) - 4)));
	else
		tier = 0;

	if (tier <= 0)
	{
		dprint("Suggest: bad tier line: ");
		dprint(work);
		dprint("\n");
		return SUG_TRUE;
	}

	names = strtrim(substring(work, colon + 1, strlen(work) - colon - 1));
	rating = SUG_BASE_RATING - ((tier - 1) * SUG_TIER_RATING_STEP);

	while (names != "")
	{
		comma = strstrofs(names, ",", 0);

		if (comma >= 0)
		{
			token = substring(names, 0, comma);
			names = substring(names, comma + 1, strlen(names) - comma - 1);
		}
		else
		{
			token = names;
			names = "";
		}

		token = strtrim(token);

		if (token == "")
			continue;

		rankidx = Suggest_AddRankWithRating(token, rating);

		if (rankidx >= 0)
			Suggest_AddAlias(rankidx, token);
	}

	return SUG_TRUE;
};

void(string line) Suggest_ParseRankLine =
{
	string work;
	string token;
	float comma;
	float rankidx;
	float first;

	work = Suggest_StripInlineComment(line);
	work = strtrim(work);

	if (work == "")
		return;

	if (substring(work, 0, 2) == "//")
		return;

	if (Suggest_ParseSectionHeader(work))
		return;

	if (!Suggest_LineIsInTargetSection())
		return;

	if (substring(work, 0, 7) == "@alias,")
	{
		Suggest_ParseAliasDirective(work);
		return;
	}

	if (Suggest_ParseTierLine(work))
		return;

	first = SUG_TRUE;
	rankidx = -1;

	while (work != "")
	{
		comma = strstrofs(work, ",", 0);

		if (comma >= 0)
		{
			token = substring(work, 0, comma);
			work = substring(work, comma + 1, strlen(work) - comma - 1);
		}
		else
		{
			token = work;
			work = "";
		}

		token = strtrim(token);

		if (token == "")
			continue;

		if (first)
		{
			rankidx = Suggest_AddRank(token);

			if (rankidx >= 0)
				Suggest_AddAlias(rankidx, token);

			first = SUG_FALSE;
		}
		else
		{
			if (rankidx >= 0)
				Suggest_AddAlias(rankidx, token);
		}
	}
};

float(string section) Suggest_LoadRanks =
{
	filestream f;
	string line;
	float lines;

	section = Suggest_CanonicalSection(section);

	if (section == "")
		section = Suggest_DefaultSection();

	Suggest_ClearRanks();
	sug_target_section = section;

	f = fopen(SUG_RANK_FILE, FILE_READ);

	if (f < 0)
	{
		dprint("Suggest: could not open ", SUG_RANK_FILE, "\n");
		return SUG_FALSE;
	}

	// Some engines return a falsey string for blank lines too, so do not
	// treat a falsey fgets result as EOF. The cap prevents an EOF spin.
	for (lines = 0; lines < SUG_MAX_RANK_LINES; lines = lines + 1)
	{
		line = fgets(f);

		if (line)
			Suggest_ParseRankLine(line);
	}

	fclose(f);

	sug_loaded = SUG_TRUE;
	sug_loaded_section = section;

	dprint("Suggest: loaded ");
	dprint(Suggest_SectionDisplayName(section));
	dprint(" ");
	dprint(ftos(sug_rank_count));
	dprint(" ranks, ");
	dprint(ftos(sug_alias_count));
	dprint(" aliases\n");

	return SUG_TRUE;
};

float(string section) Suggest_EnsureRanksLoaded =
{
	section = Suggest_CanonicalSection(section);

	if (section == "")
		section = Suggest_DefaultSection();

	if (sug_loaded && sug_loaded_section == section)
		return SUG_TRUE;

	return Suggest_LoadRanks(section);
};

float(string token) Suggest_FindRankExactNorm =
{
	string norm;
	float i;

	norm = Suggest_NormalizeName(token);

	if (norm == "")
		return -1;

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (sug_alias_norm[i] == norm)
			return sug_alias_rank[i];
	}

	return -1;
};

float(string token) Suggest_FindRankPartialNorm =
{
	string norm;
	float i;
	float found;
	float matches;

	norm = Suggest_NormalizeName(token);

	if (norm == "")
		return -1;

	found = Suggest_FindRankExactNorm(token);
	if (found >= 0)
		return found;

	found = -1;
	matches = 0;

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (Suggest_NormPrefix(sug_alias_norm[i], norm))
		{
			if (found != sug_alias_rank[i])
			{
				found = sug_alias_rank[i];
				matches = matches + 1;
			}
		}
	}

	if (matches == 1)
		return found;

	if (matches > 1)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: \"", token, "\" matches multiple ranked names. Type more letters.\n");
		return -2;
	}

	return -1;
};

float(entity e) Suggest_EntityIsClient =
{
	if (e == world)
		return SUG_FALSE;

	if (e.netname == "")
		return SUG_FALSE;

	if (e.classname == "player")
		return SUG_TRUE;

	return SUG_FALSE;
};

entity(string token) Suggest_FindConnectedPlayer =
{
	entity e;
	entity found;
	string token_norm;
	string name_norm;
	float matches;

	token_norm = Suggest_NormalizeName(token);

	if (token_norm == "")
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: empty player token.\n");
		return world;
	}

	found = world;
	matches = 0;

	e = find(world, classname, "player");
	while (e)
	{
		if (Suggest_EntityIsClient(e))
		{
			name_norm = Suggest_NormalizeName(e.netname);

			if (name_norm == token_norm)
			{
				found = e;
				matches = matches + 1;
			}
		}

		e = find(e, classname, "player");
	}

	if (matches == 1)
		return found;

	if (matches > 1)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: \"", token, "\" matches multiple connected players exactly.\n");
		return world;
	}

	found = world;
	matches = 0;

	e = find(world, classname, "player");
	while (e)
	{
		if (Suggest_EntityIsClient(e))
		{
			name_norm = Suggest_NormalizeName(e.netname);

			if (Suggest_NormPrefix(name_norm, token_norm))
			{
				found = e;
				matches = matches + 1;
			}
		}

		e = find(e, classname, "player");
	}

	if (matches == 1)
		return found;

	if (matches > 1)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: \"", token, "\" matches multiple connected players. Type more letters.\n");
		return world;
	}

	Suggest_OutputBegin();
	sprint(self, "Cannot suggest: \"", token, "\" did not match any connected player.\n");
	return world;
};

void() Suggest_ClearWorkingSet =
{
	float i;

	sug_count = 0;

	for (i = 0; i < SUG_MAX_PLAYERS; i = i + 1)
	{
		if (sug_visible_norm[i] != "") strunzone(sug_visible_norm[i]);

		sug_ent[i] = world;
		sug_visible[i] = "";
		sug_visible_norm[i] = "";
		sug_canonical[i] = "";
		sug_canonical_norm[i] = "";
		sug_rating[i] = 0;
		sug_used_alias[i] = 0;
	}

	sug_best_mask = 0;
	sug_best_diff = 999999;
	sug_best_red_score = 0;
	sug_best_blue_score = 0;
};

float(entity ent, float rankidx, float used_alias) Suggest_AddPlayer =
{
	if (sug_count >= SUG_MAX_PLAYERS)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: maximum is ", Suggest_FtosGold(10),
		       " players for ", Suggest_FtosGold(5), "v", Suggest_FtosGold(5), ".\n");
		return SUG_FALSE;
	}

	sug_ent[sug_count] = ent;
	sug_visible[sug_count] = ent.netname;
	sug_visible_norm[sug_count] = strzone(Suggest_NormalizeName(ent.netname));
	sug_canonical[sug_count] = sug_rank_name[rankidx];
	sug_canonical_norm[sug_count] = sug_rank_norm[rankidx];
	sug_rating[sug_count] = sug_rank_rating[rankidx];
	sug_used_alias[sug_count] = used_alias;

	sug_count = sug_count + 1;

	return SUG_TRUE;
};

float() Suggest_CheckDuplicates =
{
	float i;
	float j;

	for (i = 0; i < sug_count; i = i + 1)
	{
		for (j = i + 1; j < sug_count; j = j + 1)
		{
			if (sug_ent[i] == sug_ent[j])
			{
				Suggest_OutputBegin();
				sprint(self, "Cannot suggest: duplicate player \"", sug_visible[i], "\".\n");
				return SUG_FALSE;
			}

			if (sug_canonical_norm[i] == sug_canonical_norm[j])
			{
				Suggest_OutputBegin();
				sprint(self, "Cannot suggest: ");
				sprint(self, sug_visible[i], " and ", sug_visible[j]);
				sprint(self, " both resolve to ", sug_canonical[i], ".\n");
				return SUG_FALSE;
			}
		}
	}

	return SUG_TRUE;
};

float(string token) Suggest_ParsePlayerToken =
{
	float eqpos;
	string left;
	string right;
	entity ent;
	float rankidx;
	float used_alias;

	eqpos = strstrofs(token, "=", 0);

	if (eqpos >= 0)
	{
		left = substring(token, 0, eqpos);
		right = substring(token, eqpos + 1, strlen(token) - eqpos - 1);

		left = strtrim(left);
		right = strtrim(right);

		if (left == "" || right == "")
		{
			Suggest_OutputBegin();
			sprint(self, "Cannot suggest: bad alias token \"", token, "\". Use current=ranked.\n");
			return SUG_FALSE;
		}

		ent = Suggest_FindConnectedPlayer(left);
		if (ent == world)
			return SUG_FALSE;

		rankidx = Suggest_FindRankPartialNorm(right);

		if (rankidx == -2)
			return SUG_FALSE;

		if (rankidx < 0)
		{
			Suggest_OutputBegin();
			sprint(self, "Cannot suggest: alias target \"", right, "\" was not found in ranked list.\n");
			return SUG_FALSE;
		}

		return Suggest_AddPlayer(ent, rankidx, SUG_TRUE);
	}

	ent = Suggest_FindConnectedPlayer(token);
	if (ent == world)
		return SUG_FALSE;

	rankidx = Suggest_FindRankPartialNorm(ent.netname);

	if (rankidx == -2)
		return SUG_FALSE;

	if (rankidx < 0)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: \"", token, "\" matched \"", ent.netname);
		sprint(self, "\", but no rank was found. Try ", token, "=rankedname.\n");
		return SUG_FALSE;
	}

	used_alias = (Suggest_NormalizeName(ent.netname) != sug_rank_norm[rankidx]);

	return Suggest_AddPlayer(ent, rankidx, used_alias);
};

float(float mask) Suggest_MaskRating =
{
	float i;
	float total;

	total = 0;

	for (i = 0; i < sug_count; i = i + 1)
	{
		if (Suggest_HasBit(mask, i))
			total = total + sug_rating[i];
	}

	return total;
};

float() Suggest_TotalRating =
{
	float i;
	float total;

	total = 0;

	for (i = 0; i < sug_count; i = i + 1)
		total = total + sug_rating[i];

	return total;
};

void(float team_size) Suggest_FindBestSplit =
{
	float maxmask;
	float mask;
	float red;
	float blue;
	float diff;
	float total;

	sug_best_mask = 0;
	sug_best_diff = 999999;
	sug_best_red_score = 0;
	sug_best_blue_score = 0;

	maxmask = sug_pow2[sug_count];
	total = Suggest_TotalRating();

	for (mask = 0; mask < maxmask; mask = mask + 1)
	{
		if (!Suggest_HasBit(mask, 0))
			continue;

		if (Suggest_BitCount(mask) != team_size)
			continue;

		red = Suggest_MaskRating(mask);
		blue = total - red;
		diff = Suggest_Abs(red - blue);

		if (diff < sug_best_diff)
		{
			sug_best_diff = diff;
			sug_best_mask = mask;
			sug_best_red_score = red;
			sug_best_blue_score = blue;
		}
	}
};

float(entity ent, float rankidx) Suggest_AddPlayerSilent =
{
	if (sug_count >= SUG_MAX_PLAYERS)
		return SUG_FALSE;

	sug_ent[sug_count] = ent;
	sug_visible[sug_count] = ent.netname;
	sug_visible_norm[sug_count] = strzone(Suggest_NormalizeName(ent.netname));
	sug_canonical[sug_count] = sug_rank_name[rankidx];
	sug_canonical_norm[sug_count] = sug_rank_norm[rankidx];
	sug_rating[sug_count] = sug_rank_rating[rankidx];
	sug_used_alias[sug_count] = (sug_visible_norm[sug_count] != sug_canonical_norm[sug_count]);

	sug_count = sug_count + 1;

	return SUG_TRUE;
};

float() Suggest_WorkingSetHasDuplicateCanonical =
{
	float i;
	float j;

	for (i = 0; i < sug_count; i = i + 1)
	{
		for (j = i + 1; j < sug_count; j = j + 1)
		{
			if (sug_canonical_norm[i] == sug_canonical_norm[j])
				return SUG_TRUE;
		}
	}

	return SUG_FALSE;
};

float(entity team) Suggest_CurrentTeamRating =
{
	float i;
	float total;

	total = 0;

	for (i = 0; i < sug_count; i = i + 1)
	{
		if (sug_ent[i].next_team == team)
			total = total + sug_rating[i];
	}

	return total;
};

float(entity team) Suggest_CurrentTeamCount =
{
	float i;
	float total;

	total = 0;

	for (i = 0; i < sug_count; i = i + 1)
	{
		if (sug_ent[i].next_team == team)
			total = total + 1;
	}

	return total;
};

float(entity player) Suggest_PlayerEligibleForCountdown =
{
	if (!Suggest_EntityIsClient(player))
		return SUG_FALSE;

	if (!(player.style & CLANRING_CONNECTED))
		return SUG_FALSE;

	if (player.style & CLANRING_OBSERVER)
		return SUG_FALSE;

	if (!(player.style & CLANRING_READY))
		return SUG_FALSE;

	if (player.next_team == world)
		return SUG_FALSE;

	return SUG_TRUE;
};

void() Suggest_MaybePrintCountdownHint =
{
	entity player;
	entity team_a;
	entity team_b;
	string section;
	float rankidx;
	float team_size;
	float current_a_score;
	float current_b_score;
	float current_diff;
	float team_a_count;
	float team_b_count;

	if (cvar("cr_suggest_countdown_hint") <= 0)
		return;

	if (!(clanring_playmode & CLANRING_MATCH_MODE))
		return;

	if (mode_is_arena())
		return;

	if (!teamplay)
		return;

	section = Suggest_DefaultSection();

	if (!Suggest_EnsureRanksLoaded(section))
		return;

	if (sug_rank_count <= 0)
		return;

	if (sug_pow2[0] != 1)
		Suggest_Init();

	Suggest_ClearWorkingSet();

	team_a = world;
	team_b = world;

	player = clanring_sentinel.next_player;
	while (player)
	{
		if (Suggest_PlayerEligibleForCountdown(player))
		{
			if (team_a == world)
			{
				team_a = player.next_team;
			}
			else if (player.next_team != team_a)
			{
				if (team_b == world)
					team_b = player.next_team;
				else if (player.next_team != team_b)
					return;
			}

			rankidx = Suggest_FindRankExactNorm(player.netname);

			if (rankidx < 0)
				return;

			if (!Suggest_AddPlayerSilent(player, rankidx))
				return;
		}

		player = player.next_player;
	}

	if (team_a == world || team_b == world)
		return;

	if (sug_count != 4 && sug_count != 6 && sug_count != 8 && sug_count != 10)
		return;

	if (Suggest_WorkingSetHasDuplicateCanonical())
		return;

	team_size = sug_count / 2;
	team_a_count = Suggest_CurrentTeamCount(team_a);
	team_b_count = Suggest_CurrentTeamCount(team_b);
	current_a_score = Suggest_CurrentTeamRating(team_a);
	current_b_score = Suggest_CurrentTeamRating(team_b);
	current_diff = Suggest_Abs(current_a_score - current_b_score);

	Suggest_FindBestSplit(team_size);

	if ((team_a_count == team_size) && (team_b_count == team_size) && (sug_best_diff >= current_diff))
		return;

	bprint("\n");
	bprint("\bTeam balance hint\b: current ", team_a.netname, " [",
	       Suggest_FtosGold(current_a_score), "] vs ", team_b.netname, " [");
	bprint(Suggest_FtosGold(current_b_score), "], diff ",
	       Suggest_FtosGold(current_diff), ".\n");
	bprint("A better ranked split is available before match start:\n");
	Suggest_PrintResult(team_size, section);
	bprint("\n");
};

void(float i) Suggest_PrintPlayerName =
{
	if (sug_used_alias[i] && sug_visible_norm[i] != sug_canonical_norm[i])
		bprint(sug_visible[i], "=", sug_canonical[i]);
	else
		bprint(sug_visible[i]);
};

void(float mask, float want_red) Suggest_PrintTeamList =
{
	float i;
	float first;
	float in_red;

	first = SUG_TRUE;

	for (i = 0; i < sug_count; i = i + 1)
	{
		in_red = Suggest_HasBit(mask, i);

		if (in_red == want_red)
		{
			if (!first)
				bprint(", ");

			Suggest_PrintPlayerName(i);
			first = SUG_FALSE;
		}
	}
};

void() Suggest_PrintAliasesUsed =
{
	float i;
	float any;
	float first;

	any = SUG_FALSE;

	for (i = 0; i < sug_count; i = i + 1)
	{
		if (sug_used_alias[i] && sug_visible_norm[i] != sug_canonical_norm[i])
			any = SUG_TRUE;
	}

	if (!any)
		return;

	bprint("Aliases used: ");

	first = SUG_TRUE;

	for (i = 0; i < sug_count; i = i + 1)
	{
		if (sug_used_alias[i] && sug_visible_norm[i] != sug_canonical_norm[i])
		{
			if (!first)
				bprint(", ");

			bprint(sug_visible[i], "=", sug_canonical[i]);
			first = SUG_FALSE;
		}
	}

	bprint("\n");
};

void(float team_size, string section) Suggest_PrintResult =
{
	bprint("Suggested ", Suggest_SectionDisplayName(section), " ",
	       Suggest_FtosGold(team_size), "v", Suggest_FtosGold(team_size), ":\n");

	bprint("Red  [", Suggest_FtosGold(sug_best_red_score), "]: ");
	Suggest_PrintTeamList(sug_best_mask, SUG_TRUE);
	bprint("\n");

	bprint("Blue [", Suggest_FtosGold(sug_best_blue_score), "]: ");
	Suggest_PrintTeamList(sug_best_mask, SUG_FALSE);
	bprint("\n");

	bprint("Diff: ", Suggest_FtosGold(sug_best_diff), "\n");

	Suggest_PrintAliasesUsed();
};

float(string a, string b) Suggest_StringCompare =
{
	float i;
	float alen;
	float blen;
	float c1;
	float c2;

	alen = strlen(a);
	blen = strlen(b);

	for (i = 0; i < alen && i < blen; i = i + 1)
	{
		c1 = str2chr(a, i);
		c2 = str2chr(b, i);

		if (c1 < c2)
			return -1;

		if (c1 > c2)
			return 1;
	}

	if (alen < blen)
		return -1;

	if (alen > blen)
		return 1;

	return 0;
};

void(float rankidx) Suggest_PrintRankLine =
{
	float i;
	float first;

	sprint(self, "  ", sug_rank_name[rankidx]);

	first = SUG_TRUE;

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (sug_alias_rank[i] != rankidx)
			continue;

		if (sug_alias_norm[i] == sug_rank_norm[rankidx])
			continue;

		if (first)
		{
			sprint(self, " aliases: ");
			first = SUG_FALSE;
		}
		else
		{
			sprint(self, ", ");
		}

		sprint(self, sug_alias_name[i]);
	}

	sprint(self, "\n");
};

float(float rankidx, string prefix_norm) Suggest_RankMatchesPrefix =
{
	float i;

	if (prefix_norm == "")
		return SUG_TRUE;

	if (Suggest_NormPrefix(sug_rank_norm[rankidx], prefix_norm))
		return SUG_TRUE;

	for (i = 0; i < sug_alias_count; i = i + 1)
	{
		if (sug_alias_rank[i] != rankidx)
			continue;

		if (Suggest_NormPrefix(sug_alias_norm[i], prefix_norm))
			return SUG_TRUE;
	}

	return SUG_FALSE;
};

void(float args, float cmdidx) Suggest_List_f =
{
	string prefix;
	string prefix_norm;
	float i;
	float best;
	float shown;
	float total;
	string last_norm;

	if (args > cmdidx + 2)
	{
		sprint(self, "usage: cmd suggest [ctf|dm] list [prefix]\n");
		return;
	}

	prefix = "";

	if (args >= cmdidx + 2)
		prefix = argv(cmdidx + 1);

	prefix_norm = Suggest_NormalizeName(prefix);
	shown = 0;
	total = 0;
	last_norm = "";

	if (prefix_norm == "")
		sprint(self, "Suggest ", Suggest_SectionDisplayName(sug_loaded_section), " players:\n");
	else
		sprint(self, "Suggest ", Suggest_SectionDisplayName(sug_loaded_section), " players matching \"", prefix, "\":\n");

	for (i = 0; i < sug_rank_count; i = i + 1)
	{
		if (!Suggest_RankMatchesPrefix(i, prefix_norm))
			continue;

		total = total + 1;
	}

	if (total <= 0)
	{
		sprint(self, "  no matches\n");
		return;
	}

	while (shown < SUG_LIST_LIMIT && shown < total)
	{
		best = -1;

		for (i = 0; i < sug_rank_count; i = i + 1)
		{
			if (!Suggest_RankMatchesPrefix(i, prefix_norm))
				continue;

			if (last_norm != "" && Suggest_StringCompare(sug_rank_norm[i], last_norm) <= 0)
				continue;

			if (best < 0 || Suggest_StringCompare(sug_rank_norm[i], sug_rank_norm[best]) < 0)
				best = i;
		}

		if (best < 0)
			break;

		Suggest_PrintRankLine(best);
		last_norm = sug_rank_norm[best];
		shown = shown + 1;
	}

	if (total > SUG_LIST_LIMIT)
	{
		sprint(self, "  showing first ", Suggest_FtosGold(SUG_LIST_LIMIT),
		       " of ", Suggest_FtosGold(total));
		sprint(self, "; type more letters to narrow it down\n");
	}
};

float(float rankidx, string alias, string section) Suggest_AppendAliasToFile =
{
	filestream f;

	f = fopen(SUG_RANK_FILE, FILE_APPEND);

	if (f < 0)
		return SUG_FALSE;

	fputs(f, "\n");
	fputs(f, Suggest_SectionDisplayName(section));
	fputs(f, ":\n@alias,");
	fputs(f, sug_rank_name[rankidx]);
	fputs(f, ",");
	fputs(f, alias);
	fputs(f, "\n");
	fclose(f);

	return SUG_TRUE;
};

void(float args, float cmdidx, string section) Suggest_Alias_f =
{
	string alias;
	string ranked;
	float rankidx;
	float aliasidx;

	if (!Suggest_IsAdmin())
		return;

	if (args != cmdidx + 3)
	{
		sprint(self, "usage: cmd suggest [ctf|dm] alias <alias> <ranked>\n");
		sprint(self, "example: cmd suggest ctf alias r00kie rook\n");
		return;
	}

	alias = strtrim(argv(cmdidx + 1));
	ranked = strtrim(argv(cmdidx + 2));

	if (!Suggest_FileTokenIsSafe(alias))
	{
		sprint(self, "Cannot suggest: alias cannot be empty or contain , : = or comment text.\n");
		return;
	}

	rankidx = Suggest_FindRankPartialNorm(ranked);

	if (rankidx == -2)
		return;

	if (rankidx < 0)
	{
		sprint(self, "Cannot suggest: ranked player \"", ranked, "\" was not found.\n");
		return;
	}

	aliasidx = Suggest_FindAliasIndexExactNorm(alias);

	if (aliasidx >= 0)
	{
		if (sug_alias_rank[aliasidx] == rankidx)
			sprint(self, "Suggest alias already exists: ", alias, "=", sug_rank_name[rankidx], "\n");
		else
			sprint(self, "Cannot suggest: alias already belongs to ", sug_rank_name[sug_alias_rank[aliasidx]], ".\n");

		return;
	}

	if (sug_alias_count >= SUG_MAX_ALIASES)
	{
		sprint(self, "Cannot suggest: alias table full.\n");
		return;
	}

	if (!Suggest_AppendAliasToFile(rankidx, alias, section))
	{
		sprint(self, "Cannot suggest: could not write ", SUG_RANK_FILE, "\n");
		return;
	}

	Suggest_AddAlias(rankidx, alias);
	sprint(self, "Suggest ", Suggest_SectionDisplayName(section), " alias added: ", alias, "=", sug_rank_name[rankidx], "\n");
};

void(string section) Suggest_Reload_f =
{
	if (!Suggest_IsAdmin())
		return;

	if (!Suggest_LoadRanks(section))
	{
		sprint(self, "Cannot suggest: could not reload ", SUG_RANK_FILE, "\n");
		return;
	}

	sprint(self, "Suggest ", Suggest_SectionDisplayName(section), " ranks reloaded: ");
	sprint(self, Suggest_FtosGold(sug_rank_count), " ranks, ",
	       Suggest_FtosGold(sug_alias_count), " aliases\n");
};

string() Suggest_PlayerCountsGold =
{
	return strcat(Suggest_FtosGold(4), ", ", Suggest_FtosGold(6), ", ",
	              Suggest_FtosGold(8), ", or ", Suggest_FtosGold(10));
};

string() Suggest_PlayerCountsPipeGold =
{
	return strcat(Suggest_FtosGold(4), "|", Suggest_FtosGold(6), "|",
	              Suggest_FtosGold(8), "|", Suggest_FtosGold(10));
};

string(float n) Suggest_TeamSizeGold =
{
	return strcat(Suggest_FtosGold(n), "v", Suggest_FtosGold(n));
};

string() Suggest_TeamSizesGold =
{
	return strcat(Suggest_TeamSizeGold(2), ", ", Suggest_TeamSizeGold(3),
	              ", ", Suggest_TeamSizeGold(4), ", or ", Suggest_TeamSizeGold(5));
};

string() Suggest_TeamRangeGold =
{
	return strcat(Suggest_TeamSizeGold(2), " to ", Suggest_TeamSizeGold(5));
};

void() Suggest_Usage =
{
	sprint(self, "\bSuggest pickup teams\b\n");
	sprint(self, "  \bcmd suggest\b [ctf|dm] <", Suggest_PlayerCountsPipeGold(),
	       " player names>\n");
	sprint(self, "  \bcmd suggest\b [ctf|dm] list [prefix]\n");
	sprint(self, "  \bcmd suggest\b [ctf|dm] alias <alias> <ranked>  \badmin\b\n");
	sprint(self, "  \bcmd suggest\b [ctf|dm] reload                  \badmin\b\n");
	sprint(self, "\n\bExamples\b:\n");
	sprint(self, "  cmd suggest woods r00k goat uns\n");
	sprint(self, "  cmd suggest ctf deepfriednewbie FoknQuake penguin unspoken\n");
	sprint(self, "  cmd suggest dm list kw\n");
	sprint(self, "  cmd suggest dm alias newname kwong\n");
};

void() Suggest_PrintMissingPlayersError =
{
	sprint(self, "Cannot suggest: include ", Suggest_PlayerCountsGold(),
	       " player names.\n");
	sprint(self, "Suggest uses that number for ", Suggest_TeamSizesGold(), ".\n");
	Suggest_Usage();
};

float() Suggest_CheckCooldown =
{
	float remain;

	if (self.style & CLANRING_ADMINISTRATOR)
		return SUG_TRUE;

	if (time < self.next_suggest_time)
	{
		remain = ceil(self.next_suggest_time - time);

		if (remain < 1)
			remain = 1;

		Suggest_OutputBegin();
		sprint(self, "Please wait ", Suggest_FtosGold(remain), " seconds before using suggest again.\n");
		return SUG_FALSE;
	}

	return SUG_TRUE;
};

void(float player_args) Suggest_PrintPlayerCountError =
{
	if (player_args < 4)
	{
		sprint(self, "Cannot suggest: this is designed for ",
		       Suggest_TeamRangeGold(), " pickups.\n");
		sprint(self, "Enter ", Suggest_PlayerCountsGold(), " players; found ",
		       Suggest_FtosGold(player_args), ".\n");
		return;
	}

	if (player_args > 10)
	{
		sprint(self, "Cannot suggest: this is designed for ",
		       Suggest_TeamRangeGold(), " pickups.\n");
		sprint(self, "Maximum is ", Suggest_FtosGold(10), " players; found ",
		       Suggest_FtosGold(player_args), ".\n");
		return;
	}

	sprint(self, "Cannot suggest: this is designed for even team sizes.\n");
	sprint(self, "Enter ", Suggest_PlayerCountsGold(), " players; found ",
	       Suggest_FtosGold(player_args), ".\n");
};

void(float args) Suggest_f =
{
	float i;
	float team_size;
	float player_args;
	float cmdidx;
	float first_player;
	float explicit_section;
	string section;
	string other;
	string subcmd;

	if (sug_pow2[0] != 1)
		Suggest_Init();

	sug_command_output_open = SUG_FALSE;

	if (args < 2)
	{
		Suggest_OutputBegin();
		Suggest_PrintMissingPlayersError();
		Suggest_OutputEnd();
		return;
	}

	section = Suggest_DefaultSection();
	explicit_section = SUG_FALSE;
	cmdidx = 1;

	subcmd = strtolower(argv(cmdidx));

	if (Suggest_IsSectionName(subcmd))
	{
		section = Suggest_CanonicalSection(subcmd);
		explicit_section = SUG_TRUE;
		cmdidx = cmdidx + 1;

		if (args <= cmdidx)
		{
			Suggest_OutputBegin();
			Suggest_PrintMissingPlayersError();
			Suggest_OutputEnd();
			return;
		}

		subcmd = strtolower(argv(cmdidx));
	}

	if (subcmd == "help")
	{
		Suggest_OutputBegin();
		Suggest_Usage();
		Suggest_OutputEnd();
		return;
	}

	if (subcmd == "reload")
	{
		Suggest_OutputBegin();
		Suggest_Reload_f(section);
		Suggest_OutputEnd();
		return;
	}

	if (!Suggest_EnsureRanksLoaded(section))
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: could not load ", SUG_RANK_FILE, "\n");
		Suggest_OutputEnd();
		return;
	}

	if (sug_rank_count <= 0 && !explicit_section)
	{
		other = Suggest_OtherSection(section);

		if (other != "" && Suggest_LoadRanks(other) && sug_rank_count > 0)
		{
			Suggest_OutputBegin();
			sprint(self, "Note: no ", Suggest_SectionDisplayName(section),
			       " ranks in ", SUG_RANK_FILE, "; using ",
			       Suggest_SectionDisplayName(other), " ranks instead.\n");
			section = other;
		}
	}

	if (sug_rank_count <= 0)
	{
		Suggest_OutputBegin();
		sprint(self, "Cannot suggest: ", SUG_RANK_FILE, " has no ",
		       Suggest_SectionDisplayName(section), " ranks.\n");

		if (explicit_section)
		{
			sprint(self, "Try \"cmd suggest ", Suggest_OtherSection(section),
			       " list\".\n");
		}

		Suggest_OutputEnd();
		return;
	}

	if (subcmd == "list" || subcmd == "find")
	{
		Suggest_OutputBegin();
		Suggest_List_f(args, cmdidx);
		Suggest_OutputEnd();
		return;
	}

	if (subcmd == "alias" || subcmd == "addalias")
	{
		Suggest_OutputBegin();
		Suggest_Alias_f(args, cmdidx, section);
		Suggest_OutputEnd();
		return;
	}

	first_player = cmdidx;
	player_args = args - first_player;

	if (player_args < 4 || player_args > 10 ||
	    (player_args != 4 && player_args != 6 && player_args != 8 && player_args != 10))
	{
		Suggest_OutputBegin();
		Suggest_PrintPlayerCountError(player_args);
		Suggest_OutputEnd();
		return;
	}

	if (!Suggest_CheckCooldown())
	{
		Suggest_OutputEnd();
		return;
	}

	Suggest_ClearWorkingSet();

	team_size = player_args / 2;

	for (i = first_player; i < args; i = i + 1)
	{
		if (!Suggest_ParsePlayerToken(argv(i)))
		{
			Suggest_OutputEnd();
			return;
		}
	}

	if (!Suggest_CheckDuplicates())
	{
		Suggest_OutputEnd();
		return;
	}

	// Only a successful suggestion broadcasts, so only it consumes the cooldown.
	self.next_suggest_time = time + SUG_COOLDOWN;

	Suggest_FindBestSplit(team_size);
	Suggest_OutputEnd();
	bprint("\n");
	Suggest_PrintResult(team_size, section);
	bprint("\n");
};
