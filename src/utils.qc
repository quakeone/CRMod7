//
// Utils.qc
//
// This file contains a bunch of useful definitions and utilities.
//
// All code by J.P. Grossman unless otherwise commented.
//
float () match_prewar;
float () mode_is_arena;
float() stats_weapon_carrier_kills_enabled;
void() utils_update_server_time;
void() utils_save_disconnect_log;
// from strings.qc
string(float v) strings_ftos_gold;
string(float code) utils_qf_chr;
// --- prototypes needed by name overlay watcher ---
float (string a, string b) utils_str_eq;
void  (entity ent, string c_name) updatename;
void  (void () dofunc) utils_do_players;
void  (void () dofunc, string item_name) utils_do_item;
void  () afk_name;
void  () utils_refresh_overlay_if_renamed;   // <-- updated
//(FIXME: replace with just centerprint or bprint)
// Overloaded centerprints
void (entity client, string s, ...) centerprint2 = #73; 
void (entity client, string s, ...) centerprint3 = #73; 
void (entity client, string s, ...) centerprint4 = #73; 
void (entity client, string s, ...) centerprint5 = #73; 
void (entity client, string s, ...) centerprint6 = #73; 
void (entity client, string s, ...) centerprint7 = #73; 
// Overloaded sprints
void (entity client, string s, ...) sprint2= #24; 
void (entity client, string s, ...) sprint3= #24; 
void (entity client, string s, ...) sprint4= #24; 
void (entity client, string s, ...) sprint5= #24; 
void (entity client, string s, ...) sprint6= #24; 
void (entity client, string s, ...) sprint7 = #24; 

// Overloaded bprints
void (string s, ...) bprint2 = #23; 
void (string s, ...) bprint3 = #23; 
void (string s, ...) bprint4 = #23; 
void (string s, ...) bprint5 = #23; 
void (string s, ...) bprint6 = #23; 
void (string s, ...) bprint7 = #23; 

void() utils_sync_external_ents_dir =
{
    local float altents_enabled;

    altents_enabled = (cvar("gamecfg")) & CLANRING_ALTERNATIVE_ENTS;

    if (altents_enabled)
    {
        if ((cvar("samelevel")) & CLANRING_CAPTURE_THE_FLAG)
            cvar_set("external_ents_dir", "ctf_alt");
        else
            cvar_set("external_ents_dir", "dm_alt");
    }
    else
    {
        if ((cvar("samelevel")) & CLANRING_CAPTURE_THE_FLAG)
            cvar_set("external_ents_dir", "ctf");
        else
            cvar_set("external_ents_dir", "");
    }
};

void() clanring_clear_player_runes;

float() stats_badstats_has_walkover_categories =
{
    local float teamsize;

    if (!(clanring_playmode & CLANRING_MATCH_MODE))
        return FALSE;
    if (mode_is_arena())
        return FALSE;
    if (clanring_playmode & CLANRING_HH_MODE)
        return FALSE;
    if (!teamplay)
        return FALSE;

    teamsize = stats_matchtype;
    if (clanring_maxsize > teamsize)
        teamsize = clanring_maxsize;
    return (teamsize > 1);
};

float(string classname) badstats_class_affects_walkover_cache =
{
    if (classname == "info_player_deathmatch") return TRUE;
    if (classname == "info_teleport_destination") return TRUE;
    return FALSE;
};

void() badstats_invalidate_walkover_cache =
{
    badstats_walkover_spawn_head = world;
    badstats_walkover_tele_head = world;
    badstats_walkover_cache_ready = FALSE;
};

float() utils_show_nextmap_console_info =
{
    if (clanring_playmode & CLANRING_HH_MODE)
        return TRUE;

    if (clanring_playmode & CLANRING_RA_MODE)
        return TRUE;

    if (!(clanring_playmode & CLANRING_NORMAL_MODE))
        return FALSE;

    if (clanring_playmode & (CLANRING_CAPTURE_THE_FLAG
                           | CLANRING_MATCH_MODE
                           | CLANRING_PRACTICE_MODE
                           | CLANRING_CA_MODE
                           | CLANRING_WIPEOUT_MODE
                           | CLANRING_DMM4_MODE
                           | CLANRING_AIRSHOT_MODE))
        return FALSE;

    return TRUE;
};

void() badstats_cache_link_spawn =
{
    self.clanring_walkover_cache_next = badstats_walkover_spawn_head;
    badstats_walkover_spawn_head = self;
};

void() badstats_cache_link_tele =
{
    self.clanring_walkover_cache_next = badstats_walkover_tele_head;
    badstats_walkover_tele_head = self;
};

void() badstats_rebuild_walkover_cache =
{
    badstats_invalidate_walkover_cache();
    utils_do_item(badstats_cache_link_spawn, "info_player_deathmatch");
    utils_do_item(badstats_cache_link_tele, "info_teleport_destination");
    badstats_walkover_cache_ready = TRUE;
};

void() badstats_ensure_walkover_cache =
{
    if (!badstats_walkover_cache_ready)
        badstats_rebuild_walkover_cache();
};

void() clanring_refresh_pak0_only =
{
    registercvar("sv_pak0_only", "0");
    clanring_sv_pak0_only = (cvar("sv_pak0_only") != 0);
};

float() clanring_can_probe_assets =
{
    if (checkextension("DP_QC_WHICHPACK")) return TRUE;
    if (checkextension("FTE_QC_WHICHPACK")) return TRUE;
    return FALSE;
};

float(string s, string prefix) clanring_startswith =
{
    local float n;

    n = strlen(prefix);
    if (strlen(s) < n)
        return FALSE;

    return (substring(s, 0, n) == prefix);
};

float(string path) clanring_known_non_pak0_asset =
{
    if (path == "") return FALSE;

    if (clanring_startswith(path, "crx/")) return TRUE;
    if (clanring_startswith(path, "ra/")) return TRUE;
    if (clanring_startswith(path, "hhsounds/")) return TRUE;
    if (clanring_startswith(path, "rune/")) return TRUE;
    if (clanring_startswith(path, "progs/h_mdls/")) return TRUE;

    if (path == "misc/basekey.wav") return TRUE;
    if (path == "misc/flagtk.wav") return TRUE;
    if (path == "misc/flagcap.wav") return TRUE;
    if (path == "boss2/pop2.wav") return TRUE;
    if (path == "blob/land1.wav") return TRUE;
    if (path == "hknight/slash1.wav") return TRUE;
    if (path == "enforcer/sight3.wav") return TRUE;
    if (path == "items/armsh1.wav") return TRUE;
    if (path == "weapons/chain1.wav") return TRUE;
    if (path == "weapons/chain2.wav") return TRUE;
    if (path == "weapons/chain3.wav") return TRUE;
    if (path == "weapons/bounce2.wav") return TRUE;

    if (path == "progs/flag.mdl") return TRUE;
    if (path == "progs/star.mdl") return TRUE;
    if (path == "progs/bit.mdl") return TRUE;
    if (path == "progs/v_star.mdl") return TRUE;
    if (path == "progs/end2.mdl") return TRUE;
    if (path == "progs/end3.mdl") return TRUE;
    if (path == "progs/end4.mdl") return TRUE;

    return FALSE;
};

float(string path) clanring_asset_is_pak0 =
{
    local string pkg;
    local string lookup;
    local float n;

    if (path == "")
        return FALSE;

    if (clanring_known_non_pak0_asset(path))
        return FALSE;

    if (!clanring_can_probe_assets())
        return TRUE;

    n = strlen(path);
    pkg = whichpack(path);
    if ((!pkg || pkg == "") && n >= 4 && substring(path, n - 4, 4) == ".wav")
    {
        lookup = strcat("sound/", path);
        pkg = whichpack(lookup);
    }
    if (!pkg || pkg == "")
        return FALSE;

    n = strlen(pkg);
    if (n >= 8 && substring(pkg, n - 8, 8) == "pak0.pak")
        return TRUE;

    if (strstrofs(pkg, "/pak0.pak", 0) >= 0)
        return TRUE;
    if (strstrofs(pkg, "\\pak0.pak", 0) >= 0)
        return TRUE;

    return FALSE;
};

string(string full, string fallback) clanring_compat_sound_path =
{
    if (!clanring_sv_pak0_only)
        return full;

    if (clanring_asset_is_pak0(full))
        return full;

    if (fallback != "" && clanring_asset_is_pak0(fallback))
        return fallback;

    return "";
};

string(string full, string fallback) clanring_compat_model_path =
{
    if (!clanring_sv_pak0_only)
        return full;

    if (clanring_asset_is_pak0(full))
        return full;

    if (fallback != "" && clanring_asset_is_pak0(fallback))
        return fallback;

    return "";
};

void(string full, string fallback) clanring_precache_compat_sound =
{
    local string path;

    path = clanring_compat_sound_path(full, fallback);
    if (path != "")
        precache_sound(path);
    else if (clanring_sv_pak0_only && full != "")
        dprint(sprintf("[pak0] skipping sound %s\n", full));
};

void(string full, string fallback) clanring_precache_compat_model =
{
    local string path;

    path = clanring_compat_model_path(full, fallback);
    if (path != "")
        precache_model(path);
    else if (clanring_sv_pak0_only && full != "")
        dprint(sprintf("[pak0] skipping model %s\n", full));
};

void(entity target, float chan, string full, string fallback, float vol, float attn) clanring_play_compat_sound =
{
    local string path;

    path = clanring_compat_sound_path(full, fallback);
    if (path != "")
        sound(target, chan, path, vol, attn);
};

void(entity target, string full, string fallback) clanring_stuffcmd_compat_play =
{
    local string path;

    path = clanring_compat_sound_path(full, fallback);
    if (path != "")
        stuffcmd(target, strcat("play ", path, "\n"));
};

float() clanring_use_custom_hook_assets =
{
    return (!clanring_sv_pak0_only)
        && (((clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM)) || mode_is_arena());
};

float() clanring_use_custom_ctf_flag_assets =
{
    return (!clanring_sv_pak0_only) && (clanring_state & CLANRING_TEAM_CAPTURE_CUSTOM);
};

string() clanring_hook_projectile_model =
{
    if (clanring_use_custom_hook_assets())
        return "progs/star.mdl";
    return "progs/v_spike.mdl";
};

string() clanring_hook_chain_model =
{
    if (clanring_use_custom_hook_assets())
        return "progs/bit.mdl";
    return "progs/s_spike.mdl";
};

string() clanring_hook_weapon_model =
{
    if (clanring_use_custom_hook_assets())
        return "progs/v_star.mdl";
    return "progs/v_axe.mdl";
};

string() clanring_vote_pass_sound =
{
    return clanring_compat_sound_path("misc/runekey.wav", "misc/medkey.wav");
};

string() clanring_flag_drop_sound =
{
    return clanring_compat_sound_path("misc/basekey.wav", "misc/medkey.wav");
};

string() clanring_shard_model =
{
    return clanring_compat_model_path("progs/armshr.mdl", "progs/armor.mdl");
};

string() clanring_shard_sound =
{
    return clanring_compat_sound_path("items/armsh1.wav", "");
};

string() clanring_vial_model =
{
    return clanring_compat_model_path("progs/h_mdls/pd_vial.mdl", "maps/b_bh10.bsp");
};

void() clanring_clear_player_runes =
{
    if (self == world)
        return;

    if (self.player_flag & ITEM_RUNE4_FLAG)
        self.max_health = 100;

    self.player_flag = self.player_flag - (self.player_flag & ITEM_RUNE_MASK);
    self.items2 = self.items2 - (self.items2 & (IT2_SIGIL1 | IT2_SIGIL2 | IT2_SIGIL3 | IT2_SIGIL4));
    self.regen_time = 0;
};

void() clanring_apply_pak0_only_mode =
{
    if (!clanring_sv_pak0_only)
        return;

    clanring_playmode = clanring_playmode - (clanring_playmode & (CLANRING_RUNES | CLANRING_RUNETOSS));
    utils_do_players(clanring_clear_player_runes);
    utils_do_item(SUB_Remove, "item_rune");
};

//
// Functions for printing to console
//
// Caution:  when printing multiple strings to the same line, use cprint
//           for the first string(s) and localcmd for subsequent strings.
//
// example:
//
// cprint3("my ", "name ", "is ");
// localcmd2("bob", "\n");
//
void (string s1, string s2) localcmd2 =
{
    localcmd(s1);
    localcmd(s2);
};

void (string s1, string s2, string s3) localcmd3 =
{
    localcmd(s1);
    localcmd(s2);
    localcmd(s3);
};

void (string s1, string s2, string s3, string s4) localcmd4 =
{
    localcmd(s1);
    localcmd(s2);
    localcmd(s3);
    localcmd(s4);
};

void (string s1, string s2, string s3, string s4, string s5) localcmd5 =
{
    localcmd(s1);
    localcmd(s2);
    localcmd(s3);
    localcmd(s4);
    localcmd(s5);
};

void (string s1, string s2, string s3, string s4, string s5, string s6) localcmd6 =
{
    localcmd(s1);
    localcmd(s2);
    localcmd(s3);
    localcmd(s4);
    localcmd(s5);
    localcmd(s6);
};

void (string s1, string s2, string s3, string s4, string s5, string s6, string s7) localcmd7 =
{
    localcmd(s1);
    localcmd(s2);
    localcmd(s3);
    localcmd(s4);
    localcmd(s5);
    localcmd(s6);
    localcmd(s7);
};

void (string s1) cprint =
{
	print(s1);
	//localcmd2("echo ", s1);
};

void (string s1, string s2) cprint2 =
{
	print(s1, s2);
	//localcmd3("echo ", s1, s2);
};

void (string s1, string s2, string s3) cprint3 =
{
	print(s1, s2, s3);
	//localcmd4("echo ", s1, s2, s3);
};

void (string s1, string s2, string s3, string s4) cprint4 =
{
	print(s1, s2, s3, s4);
	//localcmd5("echo ", s1, s2, s3, s4);
};

void (string s1, string s2, string s3, string s4, string s5) cprint5 =
{
	print(s1, s2, s3, s4, s5);
	//localcmd6("echo ", s1, s2, s3, s4, s5);
};

void (string s1, string s2, string s3, string s4, string s5, string s6) cprint6 =
{
	print(s1, s2, s3, s4, s5, s6);
	//localcmd7("echo ", s1, s2, s3, s4, s5, s6);
};

void (string s1, string s2, string s3, string s4, string s5, string s6, string s7) cprint7 =
{
	print(s1, s2, s3, s4, s5, s6, s7);
	//localcmd7("echo ", s1, s2, s3, s4, s5, s6);
	//localcmd(s7);
};

void (string s1, string s2, string s3, string s4, string s5, string s6, string s7, string s8) cprint8 =
{
	print(s1, s2, s3, s4, s5, s6, s7, s8);
// 	localcmd7("echo ", s1, s2, s3, s4, s5, s6);
// 	localcmd2(s7, s8);
};

void (string s1) announce =
{
	//cprint3("\"", s1, "\"\n");
	bprint2(s1, "\n");
};

void (string s1, string s2) announce2 =
{
	//cprint4("\"", s1, s2, "\"\n");
	bprint3(s1, s2, "\n");
};

void (string s1, string s2, string s3) announce3 =
{
	//cprint5("\"", s1, s2, s3, "\"\n");
	bprint4 (s1, s2, s3, "\n");
};

void (string s1, string s2, string s3, string s4) announce4 =
{
	//cprint6("\"", s1, s2, s3, s4, "\"\n");
	bprint5(s1, s2, s3, s4, "\n");
};

void (string s1, string s2, string s3, string s4, string s5) announce5 =
{
	//cprint7("\"", s1, s2, s3, s4, s5, "\"\n");
	bprint6(s1, s2, s3, s4, s5, "\n");
};

void (string s1, string s2, string s3, string s4, string s5, string s6) announce6 =
{
	//cprint8("\"", s1, s2, s3, s4, s5, s6, "\"\n");
	bprint7 (s1, s2, s3, s4, s5, s6, "\n");
};

void (string s1, string s2) oprint2 =
{
	local entity o;

	o = find(world, classname, "player");
	while (o)
	{
		if ((o.style & CLANRING_CONNECTED) && (o.style & CLANRING_OBSERVER) && (o.oflags & OBSERVER_COMMENTARY))
			sprint2(o, s1, s2);
		o = find(o, classname, "player");
	}
};

void (string s1, string s2, string s3) oprint3 =
{
	local entity o;

	o = find(world, classname, "player");
	while (o)
	{
		if ((o.style & CLANRING_CONNECTED) && (o.style & CLANRING_OBSERVER) && (o.oflags & OBSERVER_COMMENTARY))
			sprint3(o, s1, s2, s3);
		o = find(o, classname, "player");
	}
};

void (string s1, string s2, string s3, string s4) oprint4 =
{
	local entity o;

	o = find(world, classname, "player");
	while (o)
	{
		if ((o.style & CLANRING_CONNECTED) && (o.style & CLANRING_OBSERVER) && (o.oflags & OBSERVER_COMMENTARY))
			sprint4(o, s1, s2, s3, s4);
		o = find(o, classname, "player");
	}
};

void (string s1, string s2, string s3, string s4, string s5) oprint5 =
{
	local entity o;

	o = find(world, classname, "player");
	while (o)
	{
		if ((o.style & CLANRING_CONNECTED) && (o.style & CLANRING_OBSERVER) && (o.oflags & OBSERVER_COMMENTARY))
			sprint5(o, s1, s2, s3, s4, s5);
		o = find(o, classname, "player");
	}
};

void (string s1, string s2, string s3, string s4, string s5, string s6) oprint6 =
{
	local entity o;

	o = find(world, classname, "player");
	while (o)
	{
		if ((o.style & CLANRING_CONNECTED) && (o.style & CLANRING_OBSERVER) && (o.oflags & OBSERVER_COMMENTARY))
			sprint6(o, s1, s2, s3, s4, s5, s6);
		o = find(o, classname, "player");
	}
};

float () mode_clan_arena =
{
	if ((clanring_playmode & CLANRING_CA_MODE) && (!(clanring_playmode & CLANRING_WIPEOUT_MODE)))
		return TRUE;
	return FALSE;
}

void (entity ent, float clientshirt, float clientpants) setcolour =
{		
	local float client;

	if (ent.style & CLANRING_CONNECTED)
	{
		client = (ent.colormap - 1);
		if ((client > 15)||(client < 0))
		{
			print("ERROR: setcolour: invalid client slot\n"); //output to console for debugging.
			return;
		}
		clientshirt = bound(0,clientshirt,13);  // disallow colors 14/15
		clientpants = bound(0,clientpants,13);
		msg_entity = ent;
		WriteByte(MSG_ALL, SVC_UPDATECOLORS);
		WriteByte(MSG_ALL, client);
   		WriteByte(MSG_ALL, (clientshirt * 16 + clientpants));

		//setcolors(ent, (clientshirt * 16 + clientpants));//builtin #401; /* Part of DP_SV_SETCOLOR
   	}
};

void (string status) updatenameoverload =
{
	local string temp = strpad(16, substring(self.netname, 0, 15));
	temp = strcat(temp, status);
	if (self.name_ready) strunzone(self.name_ready);
	self.name_ready = strzone(temp);
}

// --- Name overlay maintenance -----------------------------------------
// If a player renamed after we applied an overlay (AFK/Ready/Dead/etc),
// rebuild name_ready so the base name matches the new netname, but
// keep the existing status suffix intact. Uses 'self' (for utils_do_players).
void() utils_refresh_overlay_if_renamed =
{
    local string oldprefix, newprefix, suffix;
    local float L;

    if (self == world) return;
    if (!self.name_ready) return;                // no overlay active

    // oldprefix = the first 16 chars we originally padded from the old name
    L = strlen(self.name_ready);
    if (L < 16) return;                          // malformed / nothing to do
    oldprefix = substring(self.name_ready, 0, 16);

    // recompute what the prefix *should* be for the current netname
    newprefix = strpad(16, substring(self.netname, 0, 15));

    // if they match, nothing changed
    if (utils_str_eq(oldprefix, newprefix)) return;

    // carry over whatever suffix we previously appended (status text)
    suffix = substring(self.name_ready, 16, L - 16);

    // rebuild overlay and push it
    strunzone(self.name_ready);
    self.name_ready = strzone(strcat(newprefix, suffix));
    updatename(self, self.name_ready);
};

// Thinker that keeps overlays in sync with renames.
void() utils_namewatch_think =
{
    utils_do_players(utils_refresh_overlay_if_renamed);
    self.nextthink = time + 1;        // tick once per second
    self.think = utils_namewatch_think;
};

void (entity ent, string c_name) updatename =
{
	local float client;

	if (ent.style & CLANRING_CONNECTED)
	{
		client = (ent.colormap - 1);

		if ((client > 15)||(client < 0))
		{
			print("ERROR: updatename: invalid client slot\n"); //output to console for debugging.
			return;
		}
		msg_entity	= ent;
		WriteByte	(MSG_ALL, SVC_UPDATENAME);
		WriteByte	(MSG_ALL, client);
		WriteString	(MSG_ALL, c_name);	
	}	
};

void () clear_name =
{			
    if (self.style & CLANRING_AFK_CLIENT)
    {
        afk_name();
        return;
    }

    if (self.name_ready) { strunzone(self.name_ready); self.name_ready = string_null; }
    if (self.style & CLANRING_CONNECTED)
        updatename(self,self.netname);		
};

void (entity who) wait_name =
{
	local string text;
	local string temp;
	local entity oldself;

	if (who.style & CLANRING_AFK_CLIENT)
	{
		oldself = self;
		self = who;
		afk_name();
		self = oldself;
		return;
	}

	text = " \bwaiting\b";
	temp = strpad(16, who.netname);
	temp = strcat(temp, text);
	if (who.name_ready) strunzone(who.name_ready);
	who.name_ready = strzone(temp);
	updatename(who,who.name_ready);
};

void () ready_name =
{		
	local string text;

	if (self.style & CLANRING_AFK_CLIENT)
	{
		afk_name();
		return;
	}
	
	if (self.style & CLANRING_CONNECTED)
	{		
		if (!(clanring_state & CLANRING_MATCH_STARTED))
		{
			text = "\bReady";
			updatenameoverload(text);
			updatename(self,self.name_ready);	
		}
	}
};

void () afk_name =
{
	local string text, tm = "";
	local float t, m;

	t = (time - self.afk_time);
	m = max(0, floor(t / 60));
	tm = ftos(m);

	// Keep the suffix short enough for the scoreboard status column:
	// ready players show "Ready AFK" without a timer, dead is never shown.
	text = "\bAFK\b";

	if ((self.style & CLANRING_READY) && (!(clanring_state & CLANRING_MATCH_STARTED)) && (!(clanring_state & CLANRING_MATCH_OVER)))
		text = "\bReady AFK\b";
	else if (m < 1)
		text = strcat(text, " brb");
	else
	{
		if (clanring_afk_timeout > 0 && ((clanring_afk_timeout / 60) - m) < 2)
			tm = redify(tm);
		text = sprintf("%s %sm", text, tm);
	}
	updatenameoverload(text);
	updatename(self,self.name_ready);
};

void () dead_name =
{
	local string text;

	if (self.style & CLANRING_AFK_CLIENT)
	{
		afk_name();	
		return;
	}
		
	text = "\bdead";
	updatenameoverload(text);
	updatename(self,self.name_ready);
};

void (string s) changelevel =
{
	if (clanring_levelcount != -1)
	{
		print("changelevel: still checking levels.cfg\n");
		return;
	}

	utils_update_server_time();  // Update persistent time
	utils_save_disconnect_log();  // Save to file before map change

	if (s == "")
	{
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			localcmd("changelevel ctf1\n");
		else
			localcmd("changelevel dm3\n");
	}
	else
		localcmd3("changelevel ", s, "\n");
};

void (entity client, float t) utils_sprint_stat_time =
{	
	local float minutes;
	local float seconds;
	local float csec;
	local string temp;

	minutes = floor(t/60);
	seconds = floor((((t/60)-minutes)*60));
	csec    = floor((((((t/60)-minutes)*60)-seconds)*100));

	//--------------------
	temp = ftos(minutes);
	if ((minutes < 10))
	{
	      	sprint(client,"0");
	}
	sprint(client,temp);
	//--------------------
	sprint(client,":");
	//--------------------
	temp = ftos(seconds);
	if ((seconds < 10))
	{
		sprint(client,"0");
	}
	sprint(client,temp);
	//--------------------
	sprint(client,":");
	//--------------------
	temp = ftos(csec);
	if ((csec < 10))
	{
		sprint(client,"0");
	}	
	sprint(client,temp);	
	//--------------------
};
void (float f) utils_cprint_int2 =
{
	local float n;
	local string s;

	n = rint (f);
	if (n < 10)
		cprint("0");
	s = ftos(n);
	cprint(s);
};
void (float t) utils_cprint_time =
{
	local float minutes;
	local float seconds;
	local float csec;
	
	minutes = floor((t/60));
	seconds = floor((((t/60)-minutes)*60));
	csec    = floor((((((t/60)-minutes)*60)-seconds)*100));
	//--------------------
	utils_cprint_int2 (minutes);
	//--------------------
	cprint(":");
	//--------------------
	utils_cprint_int2 (seconds);
	//--------------------
	cprint(":");
	//--------------------
	utils_cprint_int2 (csec);
	//--------------------
};

//	
// G E T   T I M E   w it h   M I L L I S E C O N D S
//
// Returns a string of t in mm:ss.mmm format, t is seconds
//
string (float t) utils_get_time =
{
	local float total;
	local float minutes;
	local float seconds;
	local float msec;
	local string temp;
	local string tmin="",tsec="",tmsec="";

	if (t < 0) t = 0;

	// Round to milliseconds using integer math so carries are correct.
	total   = floor(t * 1000 + 0.5);
	minutes = floor(total / 60000);
	seconds = floor((total - minutes * 60000) / 1000);
	msec    = total - minutes * 60000 - seconds * 1000;

	temp = ftos(minutes);
	if ((minutes < 10))
		tmin = sprintf("0%s", temp);
	else
		tmin = temp;

	temp = ftos(seconds);
	if ((seconds < 10))
		tsec = sprintf("0%s", temp);
	else
		tsec = temp;

	temp = ftos(msec);
	if (msec < 10)
		tmsec = sprintf("00%s", temp);
	else if (msec < 100)
		tmsec = sprintf("0%s", temp);
	else
		tmsec = temp;

	return sprintf("%s:%s.%s", tmin, tsec, tmsec);
};

// Print time with minimal leading zeros for diffs (e.g., "2.500" or "1:23.456")
// Uses strings_ftos_gold() for consistent gold coloring.
void(float t) utils_bprint_time_splitcolor =
{
    local float total, mins, secs, ms;
    local float tens, ones;
    local float hundreds;

    if (t < 0) t = 0;

    // round to milliseconds
    total = floor(t * 1000 + 0.5);
    mins  = floor(total / 60000);
    secs  = floor((total - mins * 60000) / 1000);
    ms    = total - mins * 60000 - secs * 1000;

    // Only show minutes if non-zero
    if (mins > 0)
    {
        // minutes (no leading zero for tens) - all gold
        tens = floor(mins / 10);
        ones = mins - tens * 10;

        if (tens > 0) bprint(strings_ftos_gold(tens));
        bprint(strings_ftos_gold(ones));

        // punctuation stays white
        bprint(":");
    }

    // seconds (with leading zero only if minutes are showing) - all gold
    tens = floor(secs / 10);
    ones = secs - tens * 10;

    if (mins > 0 || tens > 0)
    {
        bprint(strings_ftos_gold(tens));
    }
    bprint(strings_ftos_gold(ones));

    // punctuation stays white
    bprint(".");

    // milliseconds (always three digits) - all gold
    hundreds = floor(ms / 100);
    tens = floor((ms - hundreds * 100) / 10);
    ones = ms - hundreds * 100 - tens * 10;

    bprint(strings_ftos_gold(hundreds));
    bprint(strings_ftos_gold(tens));
    bprint(strings_ftos_gold(ones));
};

// Print MM:SS.MMM with all digits in white (for capture times and records).
// No color codes, plain white text.
void(float t) utils_bprint_time_plain =
{
    local float total, mins, secs, ms;
    local float tens, ones;
    local float hundreds;

    if (t < 0) t = 0;

    // round to milliseconds
    total = floor(t * 1000 + 0.5);
    mins  = floor(total / 60000);
    secs  = floor((total - mins * 60000) / 1000);
    ms    = total - mins * 60000 - secs * 1000;

    // minutes (two digits) - all white
    tens = floor(mins / 10);
    ones = mins - tens * 10;
    bprint(ftos(tens));
    bprint(ftos(ones));

    // punctuation stays white
    bprint(":");

    // seconds (two digits) - all white
    tens = floor(secs / 10);
    ones = secs - tens * 10;
    bprint(ftos(tens));
    bprint(ftos(ones));

    // punctuation stays white
    bprint(".");

    // milliseconds (three digits) - all white
    hundreds = floor(ms / 100);
    tens = floor((ms - hundreds * 100) / 10);
    ones = ms - hundreds * 100 - tens * 10;
    bprint(ftos(hundreds));
    bprint(ftos(tens));
    bprint(ftos(ones));
};

// Prints a signed delta with red sign and gold numbers (e.g., " +00:02.110" or " -00:00.450")
void (float dt) utils_bprint_signed_time_diff =
{
    if (dt >= 0)
        bprint(redify("+"));  // Red plus sign
    else {
        bprint(redify("-"));  // Red minus sign
        dt = 0 - dt;
    }
    utils_bprint_time_splitcolor(dt);  // Gold numbers
};

// ----------------------------------------------------------------------
//
//  B P R I N T  F L O A T
//
//  Broadcasts a float followed by a CR.
//
void (float f) utils_bprint_float =
{
    local string s;

    s = ftos(f);
    bprint2(s, "\n");
};

//
//  P R I N T  F L O A T
//
//  Prints a float followed by CR to 'self'.
//
void (float f) utils_print_float =
{
    local string s;

    s = ftos(f);
    sprint2(self, s, "\n");
};

//
//  P R I N T  F L O A T N
//
//  Prints a float with up to n decimal digits followed by CR to self
//
void (float f, float n) utils_print_floatn = 
{
	local string s;
	local float temp;
	local float factor;

	temp = floor(f);
	if (f == temp)
	{
		utils_print_float(f);
		return;
	}
	s = ftos(temp);
	sprint2(self, s, ".");
	f = f - temp;
	factor = 1;
	while (n)
	{
		factor = 10 * factor;
		n = n - 1;
	}
	f = floor(factor * f + 0.5);
	while (factor)
	{
		factor = floor(factor / 10);
		temp = floor(f / factor);
		f = f - temp * factor;
		if (!f)
			factor = 0;
		s = ftos(temp);
		sprint(self, s);
	}
	sprint(self, "\n");
};

//
//  P R I N T  I N T 3
//
//  Prints a 3 character integer to 'self'.
//
void (float f) utils_print_int3 =
{
    local float n;
    local string s;

    n = rint(f);
    if (n < 0)
    {
        if (n < -99)
            sprint(self, "-99");
        else if (n > -10)
            sprint(self, " ");
    }
    else
    {
        if (n < 100)
            sprint(self, " ");
        if (n < 10)
            sprint(self, " ");
    }
    s = ftos(n);
    sprint(self, s);
};


//
//  P R I N T  I N T 3  G O L D
//
//  Prints a gold 3 character integer to 'self'.
//
void (float f) utils_print_int3_gold =
{
	local float n, d, temp;
	local string s;


	n = rint(f);
	temp = d = floor(n / 100);
	n = n - d * 100;
	if (d)
		s = strings_ftos_gold(d);
	else
		s = " ";
	sprint(self, s);

	d = floor(n / 10);
	n = n - d * 10;
	if (temp || d)
		s = strings_ftos_gold(d);
	else 
		s = " ";
	sprint(self, s);

	s = strings_ftos_gold(n);
	sprint(self, s);
};

/*
float () get_top_color =
{
	local float tc;

	tc = floor((self.cl[CL_COLORS] / %1) / 16);

	return tc;
};
*/
void (float f) utils_print_damage_gold =
{
   	local float n;
   	local float d;
   	local float temp;
   	local string s;

   	n = rint(f);

//-- f>10000
   	d = floor(n / 10000);
   	temp = floor(n / 10000);
   	s = " ";
   	if (d) s = strings_ftos_gold(d);
        else if (f >= 10000)  s=utils_qf_chr(18);
	n = n - (d * 10000);
  	sprint(self, s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 1000) s=utils_qf_chr(18);
     	n = n - (d * 1000);
  	sprint(self, s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 100)  s=utils_qf_chr(18);
   	n = n - (d * 100);
  	sprint(self, s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) 	s = strings_ftos_gold(d);
   	else if (f >= 10) s=utils_qf_chr(18);
           n = n - (d * 10);     
   	sprint(self, s);
   	
// < 10   	
   	s = strings_ftos_gold(n);
   	sprint(self, s);
};

void (float f) utils_bprint_damage_gold =
{
   	local float n;
   	local float d;
   	local float temp;
   	local string s;

   	n = rint(f);

//-- f>10000
   	d = floor(n / 10000);
   	temp = floor(n / 10000);
   	s = " ";
   	if (d) s = strings_ftos_gold(d);
        else if (f >= 10000)  s=utils_qf_chr(18);
	n = n - (d * 10000);
  	bprint(s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 1000) s=utils_qf_chr(18);
     	n = n - (d * 1000);
  	bprint(s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 100)  s=utils_qf_chr(18);
   	n = n - (d * 100);
  	bprint(s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) 	s = strings_ftos_gold(d);
   	else if (f >= 10) s=utils_qf_chr(18);
           n = n - (d * 10);     
   	bprint(s);
   	
// < 10   	
   	s = strings_ftos_gold(n);
   	bprint(s);
};

void (float f) utils_cprint_damage =
{
   	local float n;
   	local float d;
   	local float temp;
   	local string s;

   	n = rint(f);

//-- f>10000
   	d = floor(n / 10000);
   	temp = floor(n / 10000);
   	s = " ";
   	if (d) s = ftos(d);
        else if (f >= 10000)  s="0";
	n = n - (d * 10000);
  	cprint(s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d) s = ftos(d);
           else if (f >= 1000) s="0";
     	n = n - (d * 1000);
  	cprint(s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d) s = ftos(d);
           else if (f >= 100)  s="0";
   	n = n - (d * 100);
  	cprint(s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) s = ftos(d);
   	else if (f >= 10) s="0";
           n = n - (d * 10);     
  	cprint(s);
   	
// < 10   	
   	s = ftos(d);
  	cprint(s);
};

//
//  C P R I N T  I N T 3
//
//  Prints a 3 character integer to the console.
//
void (float f) utils_cprint_int3 =
{
    local float n;
    local string s;

    n = rint(f);
    if (n < 0)
    {
        if (n < -99)
            cprint("-99");
        else if (n > -10)
            cprint(" ");
    }
    else
    {
        if (n < 100)
            cprint(" ");
        if (n < 10)
            cprint(" ");
    }
    s = ftos(n);
    cprint(s);
};


//
//  M I N
//
float (float a, float b) utils_min =
{
    if (a < b)
        return a;
    return b;
};

//
//  M A X
//
float (float a, float b) utils_max =
{
    if (a > b)
        return a;
    return b;
};

//
//  M I N 3
//
float (float a, float b, float c) utils_min3 =
{
    local float d;
    if (a < b)
        d = a;
    else
        d = b;
    if (d < c)
        return d;
    return c;
};


//
//  M A K E  S C H E D U L E D  E V E N T
//
//  Creates a new dynamic entity which will call the given
//  think function after the given amout of time; the entity's
//  owner is 'self'.
//
entity (void() think_function, float think_time) utils_make_scheduled_event =
{
    local entity temp;
    temp = spawn();
    temp.classname = "scheduled_event_entity";
    temp.owner = self;
    temp.nextthink = time + think_time;
    temp.think = think_function;
    return temp;
};

//
//  S E T  C V A R
//
//  Set the console variable 'var' to 'value'.
//
void (string s, float value) utils_set_cvar =
{
    local string temp;

    temp = ftos(value);
    cvar_set(s, temp);
};

//
//  D O  I T E M
//
//  Do something to all items of the given type.  For each item,
//  'dofunc()' is called with 'self' pointing to the item.
//
void (void () dofunc, string item_name) utils_do_item =
{
    local entity oldself;

    oldself = self;
    self = find(world, classname, item_name);
    while (self)
    {
        dofunc();
        self = find(self, classname, item_name);
    }
    self = oldself;
};

//
//  D O  I T E M S
//
//  Do the same thing to all respawnable items.
//
void (void () dofunc) utils_do_items =
{
    utils_do_item(dofunc, "item_health");
    utils_do_item(dofunc, "item_armor1");
    utils_do_item(dofunc, "item_armor2");
    utils_do_item(dofunc, "item_armorInv");
    utils_do_item(dofunc, "item_shells");
    utils_do_item(dofunc, "item_spikes");
    utils_do_item(dofunc, "item_rockets");
    utils_do_item(dofunc, "item_cells");
    utils_do_item(dofunc, "weapon_nailgun");
    utils_do_item(dofunc, "weapon_supernailgun");
    utils_do_item(dofunc, "weapon_supershotgun");
    utils_do_item(dofunc, "weapon_rocketlauncher");
    utils_do_item(dofunc, "weapon_grenadelauncher");
    utils_do_item(dofunc, "weapon_lightning");
    utils_do_item(dofunc, "item_sigil");
    utils_do_item(dofunc, "item_artifact_invulnerability");
    utils_do_item(dofunc, "item_artifact_envirosuit");
    utils_do_item(dofunc, "item_artifact_invisibility");
    utils_do_item(dofunc, "item_artifact_super_damage");
};

//
//  D O  W E A P O N S
//
//  Do the same thing to all respawnable weapons.
//
void (void () dofunc) utils_do_weapons =
{
    utils_do_item(dofunc, "weapon_nailgun");
    utils_do_item(dofunc, "weapon_supernailgun");
    utils_do_item(dofunc, "weapon_supershotgun");
    utils_do_item(dofunc, "weapon_rocketlauncher");
    utils_do_item(dofunc, "weapon_grenadelauncher");
    utils_do_item(dofunc, "weapon_lightning");
};

void (void () dofunc) utils_do_ammo =
{
    utils_do_item(dofunc, "item_shells");
    utils_do_item(dofunc, "item_spikes");
    utils_do_item(dofunc, "item_rockets");
    utils_do_item(dofunc, "item_cells");
}

//
//  D O  P R O J E C T I L E S
//
//  Do the same thing to all rockets, grenades and nails.
//
void (void () dofunc) utils_do_projectiles = 
{
	utils_do_item(dofunc, "missile");
	utils_do_item(dofunc, "grenade");
	utils_do_item(dofunc, "spike");
};

void (void () dofunc) utils_do_hook =
{
	utils_do_item(dofunc, "hook_chain_link");
	utils_do_item(dofunc, "hook_entity");
};

void (void () dofunc) utils_do_flags =
{
	utils_do_item(dofunc, "item_flag_team1");
	utils_do_item(dofunc, "item_flag_team2");
};

void (void () dofunc) utils_do_match_spawns =
{
    utils_do_item(dofunc, "info_player_deathmatch");
    utils_do_item(dofunc, "info_player_team1");
    utils_do_item(dofunc, "info_player_team2");
	utils_do_item(dofunc, "info_teleport_destination");
};

void () reset_frags =
{
	if (self.next_team == world)
		self.frags = -99;
	else
		self.frags = 0;
};

void () reset_color_white =
{
	if (self.style & CLANRING_CONNECTED)
	{
		setcolour(self, 0, 0);
		stuffcmd(self, ";color 0;\n");
	}
};

void (void () dofunc) utils_do_arena_players =
{
	local entity oldself;

	oldself = self;
	self = find(world, classname, "player");
	while (self)
	{
		if ((self.style & CLANRING_CONNECTED) && (self.next_team))
			dofunc ();
		self = find(self, classname, "player");
	}
	self = oldself;
};

//
//  D O  P L A Y E R S
//
//  Do the same thing to all connected players.  For each player,
//  'dofunc()' is called with 'self' pointing to the player.
//
void (void () dofunc) utils_do_players =
{
    local entity oldself;

    oldself = self;
    self = find(world, classname, "player");
    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
            dofunc();
        self = find(self, classname, "player");
    }
    self = oldself;
};

void (entity whodat, void() dofunc) utils_do_player =
{
    local entity oldself;

    oldself = self;
    self = whodat;
    dofunc();
    self = oldself;
};

/*
void (void () dofunc) utils_do_players_event =
{
    local entity oldself;

    oldself = self;
    self = find(world, classname, "player");
    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
		utils_make_scheduled_event(dofunc,0.1);
        self = find(self, classname, "player");
    }
    self = oldself;
};
*/
//
//  S T O F
//
//  Convert a string to a float.
//

float (string s) utils_stof =
{
	return (stof(s));
};

// CRMOD
//  V I S I B L E
//    by Paul Baker
//
//    returns 1 if the entity a can see entity b.
//
float (entity a, entity b) utils_visible =
{
	traceline (a.origin, b.origin, TRUE, a);	// see through other monsters
	
	if (trace_inopen && trace_inwater)
		return FALSE;			// sight line crossed contents

	if (trace_fraction == 1)
		return TRUE;
	return FALSE;
};

//
//  N E W  V I S I B L E
//     by Paul Baker
//
//  Corrected and optimized by J.P.
//
//  Return TRUE if entity a can 'see' entity b.
//
float (entity a, entity b) utils_new_visible =
{
	local float dist;
	local float crosswater;

	// First trace as far as we can, keeping track of crosswater
	crosswater = 0;
	trace_ent = a;
	trace_fraction = 0;
	while ((trace_ent != world) && (trace_fraction < 1.0))
	{
		traceline(trace_ent.origin, b.origin, TRUE, trace_ent);
		if (trace_inopen && trace_inwater)
			crosswater = 1;
	}

	// If we can see all the way to the player, return 4 - crosswater
	if (trace_fraction == 1.0)
		return (4 - crosswater);

	// If the player is right on the other side of the wall, return 2 - crosswater
    dist = vlen(trace_endpos - b.origin);
	if (dist < 200)
		return (2 - crosswater);

	// Otherwise, player is not visible at all
	return 0;
};

// CRMOD
//  T O G G L E  O F L A G
//    by Paul Baker
//
//  Toggles the specified flag in self.oflags
//
void (float flag, string name) utils_toggle_oflag =
{
	if (self.oflags & flag)
	{
		self.oflags = self.oflags - (self.oflags & flag);
		sprint2(self, name, " disabled\n");
	}
	else
	{
		self.oflags = (self.oflags | flag);
		sprint2(self, name, " enabled\n");
	}
};

//
//  T O G G L E  F L A G
//
//  Toggles the specified flag in self.style
//
void (float flag, string name) utils_toggle_flag =
{
	if (self.style & flag)
	{
		self.style = self.style - (self.style & flag);
		sprint2(self, name, " disabled\n");
	}
	else
	{
		self.style = self.style | flag;
		sprint2(self, name, " enabled\n");
	}
};

//
//  T O G G L E  S F L A G
//
//  Toggles the specified flag in clanring_playmode
//
void (float flag, string name) utils_toggle_sflag =
{
	if (clanring_playmode & flag)
	{
		clanring_playmode = clanring_playmode - (clanring_playmode & flag);
		announce2(name, " disabled");
	}
	else
	{
		clanring_playmode = (clanring_playmode | flag);
		announce2(name, " enabled");
	}
	utils_set_cvar ("samelevel", clanring_playmode);
};

// R00k
//  T O G G L E  G F L A G
//
//  Toggles the specified flag in clanring_gameconfig
//
void (float flag, string name) utils_toggle_gflag =
{
	if (clanring_gameconfig & flag)
	{
		clanring_gameconfig = clanring_gameconfig - (clanring_gameconfig & flag);
		bprint(name, " disabled\n");
		print(name, " disabled\n");
	}
	else
	{
		clanring_gameconfig = (clanring_gameconfig | flag);
		bprint(name, " enabled\n");
		print(name, " enabled\n");
	}
	utils_set_cvar("gamecfg", clanring_gameconfig);
};

//
//  I L L E G A L  N A M E
//
//  Returns TRUE if the client name is illegal, FALSE otherwise.
//
//TODO: when a player connects, save their name to .oldname, if they try to change it to an illegal name then revert it back for them instead of kicking?

float (string cname) utils_illegal_name =
{
	if ((cname == "") || (cname == "unconnected")) return TRUE;
	else if (cname == " ") return TRUE;
	else if (cname == "  ") return TRUE;
	else if (cname == "   ") return TRUE;
	else if (cname == "    ") return TRUE;
	else if (cname == "     ") return TRUE;
	else if (cname == "      ") return TRUE;
	else if (cname == "       ") return TRUE;
	else if (cname == "        ") return TRUE;
	else if (cname == "         ") return TRUE;
	else if (cname == "          ") return TRUE;
	else if (cname == "           ") return TRUE;
	else if (cname == "            ") return TRUE;
	else if (cname == "             ") return TRUE;
	else if (cname == "              ") return TRUE;
	else if (cname == "               ") return TRUE;
	else return FALSE;
};

// entity (float whichteam) find_team_entity =
// {
// 	local entity e;
	
// 	e = clanring_sentinel.next_team;

// 	while (e)
// 	{
// 		if (e.height == whichteam)
// 		{
// 			return e;
// 		}
// 		e = e.next_team;
// 	}
// 	return world;
// };

// returns true if the maparg matches a name in the warp list
float(string maparg) found_in_warp_list =
{
	float index, mapfound = FALSE;

	if (maparg == "")
		return FALSE;

	for (index = 1 ; index < (WARP_CATEGORY_SIZE * WARP_MAPLIST_SIZE) ; index += 1)
	{
		if (warpmap[index].name != "" && warpmap[index].name == maparg)
		{
			mapfound = index;
			break;
		}
	}
	return mapfound;
};

float(string section) levels_cfg_is_section =
{
	return ((section == "-ctf-") || (section == "-ca-") || (section == "-dm-") || (section == "-ra-") || (section == "-hh-"));
};

string(float gametype) levels_cfg_section_for_gametype =
{
	if (gametype == 1)
		return "-ctf-";
	else if (gametype == 2 || gametype == 6)
		return "-ca-";
	else if (gametype == 3 || gametype == 4 || gametype == 5 || gametype == 7)
		return "-ra-";
	else if (gametype == 8)
		return "-hh-";
	else if (gametype == -2)
	{
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			return "-ctf-";
		return "-dm-";
	}
	else if (gametype < 0)
	{
		if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			return "-ctf-";
		else if (clanring_playmode & CLANRING_CA_MODE)
			return "-ca-";
		else if ((clanring_playmode & CLANRING_RA_MODE) || (clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
			return "-ra-";
		else if (clanring_playmode & CLANRING_HH_MODE)
			return "-hh-";
	}

	return "-dm-";
};

float(string section) levels_cfg_random_map_from_section =
{
	local filestream f;
	local string line;
	local float argc, found_section, mapcount, mapnum, selected_mapnum;

	f = fopen("configs/levels.cfg", FILE_READ);
	if (f < 0)
		return FALSE;

	while ((line = fgets(f)))
	{
		argc = tokenize(line);
		if (!argc) continue;
		if (argv(0) == "//" || argv(0) == "#") continue;

		if (!found_section)
		{
			if (argv(0) == section)
				found_section = TRUE;
			continue;
		}

		if (levels_cfg_is_section(argv(0)))
			break;

		mapnum = found_in_warp_list(argv(0));
		if (mapnum)
		{
			mapcount = mapcount + 1;
			if ((random() * mapcount) < 1)
				selected_mapnum = mapnum;
		}
	}

	fclose(f);
	return selected_mapnum;
};

float(float gametype) levels_cfg_random_map_for_gametype =
{
	local string section;
	local float mapnum;

	section = levels_cfg_section_for_gametype(gametype);
	mapnum = levels_cfg_random_map_from_section(section);

	if (!mapnum && section == "-hh-")
		mapnum = levels_cfg_random_map_from_section("-dm-");

	return mapnum;
};

// used to determine mode from client command
float(string modearg) get_mode_from_string =
{
	if (modearg == "match")
		return 2;
	else if (modearg == "practice")
		return 1;
	else if (modearg == "normal")
		return 0;
	else
		return -1;
};

//-------------------------------------------------------------------
// PROQUAKE BUILT-IN FEATURES
//-------------------------------------------------------------------
float MOD_PROQUAKE    = 1;

void (float to, float f) WriteBytePQ =
{	
	WriteByte(to, (16 + (f / 16)));
	WriteByte(to, (16 + (f & 15)));
};

void (float to, float f)WriteShortPQ =
{	
	local float i;

	i = floor(f / 4096);
	WriteBytePQ (to, i * 16 + (f & 3840 / 256));
	WriteBytePQ (to, f & 255);	
};
	
void (float tm) pqc_erase_team =
{	
	local entity oldself;

    oldself = self;
    self = find(world, classname, "player");

    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
        {
			msg_entity = self;
			if (self.csqc_enabled)
			{
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST , PQC_ERASE_TEAM);
				WriteByte(MSG_MULTICAST, tm);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{
				WriteByte (MSG_ONE, SVC_STUFFCMD);
				WriteByte (MSG_ONE, MOD_PROQUAKE);
				WriteByte (MSG_ONE, PQC_ERASE_TEAM);
				WriteByte (MSG_ONE, 16 + tm);
				WriteString (MSG_ONE, string_null);
			}
		}
		self = find(self, classname, "player");
	}
	self = oldself;
};

void (float c) pqc_new_team =
{	
	local entity oldself;

    oldself = self;
    self = find(world, classname, "player");

    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
        {
			msg_entity = self;
			if (self.csqc_enabled)
			{
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST , PQC_NEW_TEAM);
				WriteByte(MSG_MULTICAST, c);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{
				WriteByte (MSG_ONE, SVC_STUFFCMD);
				WriteByte (MSG_ONE, MOD_PROQUAKE);
				WriteByte (MSG_ONE, PQC_NEW_TEAM);
				WriteByte (MSG_ONE, 16 + c & 15); // pants
				WriteByte (MSG_ONE, 16 + c / 16); // shirt
				WriteString (MSG_ONE, string_null);
			}
		}
		self = find(self, classname, "player");
	}
	self = oldself;
};

void (float tm, float tf) pqc_team_frags =
{	
	local entity oldself;

    oldself = self;
    self = find(world, classname, "player");

    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
        {
			if (self.csqc_enabled)
			{
				msg_entity = self;
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST , PQC_TEAM_FRAGS);
				WriteByte(MSG_MULTICAST, tm);
				WriteShort(MSG_MULTICAST, tf);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{
				if (tf < 0)
					tf = tf + 65536;
				msg_entity = self;				
				WriteByte (MSG_ONE, SVC_STUFFCMD);
				WriteByte (MSG_ONE, MOD_PROQUAKE);
				WriteByte (MSG_ONE, PQC_TEAM_FRAGS);
				WriteByte (MSG_ONE, 16 + tm);	// team
				WriteShortPQ (MSG_ONE, tf);	// frags
				WriteString (MSG_ONE, string_null);
			}
		}
        self = find(self, classname, "player");
    }
    self = oldself;
};

void(float m, float s)pqc_match_time =
{
	local entity oldself;

    oldself = self;
    self = find(world, classname, "player");
    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
        {
			msg_entity = self;

			if (self.csqc_enabled == 1)
			{
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST, PQC_MATCH_TIME);
				WriteByte(MSG_MULTICAST, m);
				WriteByte(MSG_MULTICAST, s);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{			 	
				if ((self.client == "ezQuake")||(self.client == "FTE")/*(|| (self.client == "QSS-M"))*/)
				{
					if (!(clanring_state & CLANRING_MATCH_STARTED))//Prior to match start use timer to display countdown.
					{
						WriteByte(MSG_MULTICAST, SVC_UPDATESTAT);
						WriteByte(MSG_MULTICAST, 18);// STAT_MATCHSTARTTIME
						WriteLong(MSG_MULTICAST, (time + s)*1000);
						multicast('0 0 0', MULTICAST_ONE_R);
					}
				}
				else
				{
					WriteByte(MSG_MULTICAST , SVC_STUFFCMD);
					WriteByte(MSG_MULTICAST , MOD_PROQUAKE);
					WriteByte(MSG_MULTICAST , PQC_MATCH_TIME);
					WriteBytePQ(MSG_MULTICAST , m);
					WriteBytePQ(MSG_MULTICAST , s);
					WriteString(MSG_MULTICAST , string_null);
					multicast('0 0 0', MULTICAST_ONE_R);
				}
			}
		}
        self = find(self, classname, "player");
    }
    self = oldself;
};

void(float total_seconds) pqc_ffa_time_remaining =
{
	local entity oldself;
	local float m;
	local float s;

	if (total_seconds < 0)
		total_seconds = 0;

	total_seconds = rint(total_seconds);
	m = floor(total_seconds / 60);
	s = total_seconds - (m * 60);

	oldself = self;
	self = find(world, classname, "player");
	while (self)
	{
		if (self.style & CLANRING_CONNECTED)
		{
			msg_entity = self;

			if (self.csqc_enabled == 1)
			{
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST, PQC_MATCH_TIME);
				WriteByte(MSG_MULTICAST, m);
				WriteByte(MSG_MULTICAST, s);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{
				if ((self.client == "ezQuake") || (self.client == "FTE"))
				{
					WriteByte(MSG_MULTICAST, SVC_UPDATESTAT);
					WriteByte(MSG_MULTICAST, 18);// STAT_MATCHSTARTTIME
					WriteLong(MSG_MULTICAST, (time + total_seconds) * 1000);
					multicast('0 0 0', MULTICAST_ONE_R);
				}
				else
				{
					WriteByte(MSG_MULTICAST, SVC_STUFFCMD);
					WriteByte(MSG_MULTICAST, MOD_PROQUAKE);
					WriteByte(MSG_MULTICAST, PQC_MATCH_TIME);
					WriteBytePQ(MSG_MULTICAST, m);
					WriteBytePQ(MSG_MULTICAST, s);
					WriteString(MSG_MULTICAST, string_null);
					multicast('0 0 0', MULTICAST_ONE_R);
				}
			}
		}
		self = find(self, classname, "player");
	}
	self = oldself;
};

// Send a countdown to one player's ProQuake timer.  Arena/Wipeout timers are
// contextual, so broadcasting the value (as match timers do) would give other
// players and spectators the wrong countdown.
void(entity player, float total_seconds) pqc_player_time_remaining =
{
	local float m;
	local float s;

	if ((player == world) || !(player.style & CLANRING_CONNECTED))
		return;

	if (total_seconds < 0)
		total_seconds = 0;

	total_seconds = ceil(total_seconds);
	m = floor(total_seconds / 60);
	s = total_seconds - (m * 60);
	msg_entity = player;

	if (player.csqc_enabled == 1)
	{
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, PQC_MATCH_TIME);
		WriteByte(MSG_MULTICAST, m);
		WriteByte(MSG_MULTICAST, s);
		multicast('0 0 0', MULTICAST_ONE_R);
	}
	else if ((player.client == "ezQuake") || (player.client == "FTE"))
	{
		WriteByte(MSG_MULTICAST, SVC_UPDATESTAT);
		WriteByte(MSG_MULTICAST, 18);// STAT_MATCHSTARTTIME
		WriteLong(MSG_MULTICAST, (time + total_seconds) * 1000);
		multicast('0 0 0', MULTICAST_ONE_R);
	}
	else
	{
		WriteByte(MSG_MULTICAST, SVC_STUFFCMD);
		WriteByte(MSG_MULTICAST, MOD_PROQUAKE);
		WriteByte(MSG_MULTICAST, PQC_MATCH_TIME);
		WriteBytePQ(MSG_MULTICAST, m);
		WriteBytePQ(MSG_MULTICAST, s);
		WriteString(MSG_MULTICAST, string_null);
		multicast('0 0 0', MULTICAST_ONE_R);
	}
};

void ()pqc_match_reset =
{
	local entity oldself;

	// Keep HUD teamscores visible after match end; defer clearing until players ready up
	if (clanring_state & CLANRING_MATCH_OVER)
		return;

    oldself = self;
    self = find(world, classname, "player");
    while (self)
    {
        if (self.style & CLANRING_CONNECTED)
        {
			if (self.csqc_enabled)
			{
			//	dimension_send = 1;	
				msg_entity = self;
				WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
				WriteByte(MSG_MULTICAST , PQC_MATCH_RESET);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
			else
			{
			//	dimension_send = 2;
				msg_entity = self;
				WriteByte(MSG_MULTICAST , SVC_STUFFCMD);
				WriteByte(MSG_MULTICAST , MOD_PROQUAKE);
				WriteByte(MSG_MULTICAST , PQC_MATCH_RESET);
				WriteString(MSG_MULTICAST , string_null);
				multicast('0 0 0', MULTICAST_ONE_R);
			}
		}
        self = find(self, classname, "player");
    }
    self = oldself;
};

float (entity e) client_ping =
{	
	local float ping;

	ping = stof(infokey(e,INFOKEY_P_PING));
	return ping * 1000;			// R00k: whoops!
};

// U P D A T E  P I N G  T I M E S
//
// when we use SVC_UPDATENAME to put 'READY' on the scoreboard, all other elements become immutable
// so, this specifically updates the ping element; for Proquake compatible clients.

void () pqc_ping_times =
{	
	local entity e;
	local float i, ping;

	msg_entity = self;

	WriteByte(MSG_ONE, SVC_STUFFCMD);
	WriteByte(MSG_ONE, MOD_PROQUAKE);
	WriteByte(MSG_ONE, PQC_PING_TIMES);

	e = world;
	for (i = 0; i < 16; i = i + 1)
	{		
		e = nextent (e);		
		if ((e.classname == "player") && (e.style & CLANRING_CONNECTED) && e.ping_time)
		{
			ping = e.ping_time;
			WriteShortPQ (MSG_ONE, ping + (i * 4096));
		}
	}

	WriteShortPQ (MSG_ONE, 0);
	WriteString(MSG_ONE, string_null);
};

float () ammo_is_infinite =
{
	if ((clanring_playmode & CLANRING_PRACTICE_MODE) || (match_prewar()) || (clanring_playmode & CLANRING_DMM4_MODE) || (clanring_playmode & CLANRING_AIRSHOT_MODE))
		return TRUE;
	return FALSE;
};

float () ffa_start_lock_delay =
{
	local float delay;

	delay = cvar("cr_ffa_start_delay");
	if (delay < 0)
		return 0;
	return delay;
};

//
//  Count clients currently in the game (not observers). Used to skip the
//  FFA start-lock when there is nobody to wait for.
//
float () ffa_start_lock_playercount =
{
	local entity p;
	local float n;

	n = 0;
	p = find(world, classname, "player");
	while (p)
	{
		if (!(p.style & CLANRING_OBSERVER))
			n = n + 1;
		p = find(p, classname, "player");
	}
	return n;
};

float () ffa_start_lock_mode =
{
	if (clanring_playmode & CLANRING_MATCH_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_PRACTICE_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_WIPEOUT_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_DMM4_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_AIRSHOT_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_CA_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_RA_MODE)
		return FALSE;

	if (!(clanring_playmode & CLANRING_NORMAL_MODE) && !(clanring_playmode & CLANRING_HH_MODE))
		return FALSE;

	// Nobody to wait for: skip the start-lock with a lone player.
	if (ffa_start_lock_playercount() < 2)
		return FALSE;

	if (clanring_ffa_start_lock_config_ready && cvar("teamplay") > 0)
	{
		if (!((clanring_playmode & CLANRING_NORMAL_MODE) && (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)))
			return FALSE;
	}

	return TRUE;
};

void () ffa_start_lock_refresh =
{
	local float delay;

	clanring_ffa_start_lock_until = 0;
	delay = ffa_start_lock_delay();
	if (delay <= 0)
		return;
	if (!ffa_start_lock_mode())
		return;
	clanring_ffa_start_lock_until = clanring_ffa_start_lock_start_time + delay;
	if (clanring_ffa_start_lock_until <= time)
		clanring_ffa_start_lock_until = 0;
};

float () ffa_start_lock_active =
{
	ffa_start_lock_refresh();
	if (clanring_ffa_start_lock_until <= time)
		return FALSE;
	return TRUE;
};

float () ffa_join_brightfield_mode =
{
	if (mode_is_arena())
		return FALSE;
	if (clanring_playmode & CLANRING_MATCH_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_PRACTICE_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_WIPEOUT_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_DMM4_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_AIRSHOT_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_CA_MODE)
		return FALSE;
	if (clanring_playmode & CLANRING_RA_MODE)
		return FALSE;

	if (cvar("teamplay") > 0)
	{
		if (!((clanring_playmode & CLANRING_NORMAL_MODE) && (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)))
			return FALSE;
	}

	if (clanring_playmode & CLANRING_HH_MODE)
		return TRUE;
	if (clanring_playmode & CLANRING_NORMAL_MODE)
		return TRUE;
	return FALSE;
};

void () ffa_join_brightfield_clear =
{
	if (self.ffa_join_brightfield_until <= 0)
		return;

	self.effects = self.effects - (self.effects & EF_BRIGHTFIELD);
	self.ffa_join_brightfield_until = 0;
};

void () ffa_join_brightfield_start =
{
	if (!self.ffa_join_brightfield_pending)
		return;
	if (!ffa_join_brightfield_mode())
		return;
	if ((self.style & CLANRING_OBSERVER) || self.deadflag || self.health <= 0)
		return;

	self.ffa_join_brightfield_pending = FALSE;
	self.ffa_join_brightfield_until = time + 3;
	self.effects = self.effects | EF_BRIGHTFIELD;
};

void () ffa_join_brightfield_update =
{
	if (self.ffa_join_brightfield_until <= 0)
		return;
	if (!ffa_join_brightfield_mode() || (self.style & CLANRING_OBSERVER) || self.deadflag || self.health <= 0)
	{
		ffa_join_brightfield_clear();
		return;
	}
	if (time >= self.ffa_join_brightfield_until)
	{
		ffa_join_brightfield_clear();
		return;
	}

	self.effects = self.effects | EF_BRIGHTFIELD;
};

float () ffa_item_alpha_mode =
{
	if (cvar("teamplay") > 0)
		return FALSE;

	if (clanring_playmode & CLANRING_HH_MODE)
		return TRUE;

	if (!(clanring_playmode & CLANRING_NORMAL_MODE))
		return FALSE;
	if (clanring_playmode & (CLANRING_MATCH_MODE
	                       | CLANRING_PRACTICE_MODE
	                       | CLANRING_CAPTURE_THE_FLAG
	                       | CLANRING_WIPEOUT_MODE
	                       | CLANRING_DMM4_MODE
	                       | CLANRING_AIRSHOT_MODE
	                       | CLANRING_CA_MODE
	                       | CLANRING_RA_MODE))
		return FALSE;
	return TRUE;
};

float () ffa_item_alpha_value =
{
	local float alpha;

	alpha = cvar("cr_ffa_item_alpha");
	if (alpha <= 0)
		return 1;
	if (alpha >= 1)
		return 1;
	if (alpha < 0.1)
		return 0.1;
	return alpha;
};

float () ffa_item_alpha_enabled =
{
	local float alpha;

	if (!ffa_item_alpha_mode())
		return FALSE;
	alpha = cvar("cr_ffa_item_alpha");
	return ((alpha > 0) && (alpha < 1));
};

float () ffa_item_alpha_time =
{
	local float t;

	t = cvar("cr_ffa_item_alpha_time");
	if (t < 0)
		return 0;
	return t;
};

float (entity item) ffa_item_alpha_applies =
{
	if ((item.classname == "weapon_supershotgun")
	 || (item.classname == "weapon_nailgun")
	 || (item.classname == "weapon_supernailgun")
	 || (item.classname == "weapon_grenadelauncher")
	 || (item.classname == "weapon_rocketlauncher")
	 || (item.classname == "weapon_lightning"))
		return TRUE;

	if ((item.classname == "item_armor1")
	 || (item.classname == "item_armor2")
	 || (item.classname == "item_armorInv"))
		return TRUE;

	if ((item.classname == "item_health")
	 || (item.classname == "item_health_vial"))
		return TRUE;

	if ((item.classname == "item_shells")
	 || (item.classname == "item_spikes")
	 || (item.classname == "item_rockets")
	 || (item.classname == "item_cells"))
		return TRUE;

	if ((item.classname == "item_artifact_super_damage")
	 || (item.classname == "item_artifact_invulnerability")
	 || (item.classname == "item_artifact_invisibility")
	 || (item.classname == "item_artifact_envirosuit"))
		return TRUE;

	return FALSE;
};

float (entity item) ffa_item_alpha =
{
	if ((item.classname == "item_artifact_super_damage") && g1v1_in_effect && g1v1_quad_ghosted)
	{
		if (ffa_item_alpha_enabled())
			return 1;
		return 0.5;
	}
	return 1;
};

void (entity item) ffa_item_update_alpha =
{
	item.alpha = ffa_item_alpha(item);

	if (item.classname != "item_artifact_super_damage")
		return;

	if (g1v1_in_effect && g1v1_quad_ghosted && ffa_item_alpha_enabled())
	{
		item.effects = item.effects | EF_FULLBRIGHT;
		item.colormod = '7 0.5 0.5';
	}
	else
	{
		item.effects = item.effects - (item.effects & EF_FULLBRIGHT);
		item.colormod = '0 0 0';
	}
};

void () ffa_item_spawn_respawn_ghost;
void () ffa_item_remove_respawn_ghost;

void (entity item) ffa_item_clear_respawn_ghost =
{
	if (item.ffa_item_ghost_ent == world)
		return;
	if (!wasfreed(item.ffa_item_ghost_ent))
		remove(item.ffa_item_ghost_ent);
	item.ffa_item_ghost_ent = world;
};

entity (entity item, float expire_time) ffa_item_spawn_ghost_clone =
{
	local entity ghost;

	if (item.mdl == "")
		return world;
	if (expire_time <= time)
		return world;

	ghost = spawn();
	ghost.classname = "item_ffa_ghost";
	ghost.owner = item;
	ghost.solid = SOLID_NOT;
	ghost.movetype = MOVETYPE_NONE;
	ghost.angles = item.angles;
	ghost.frame = item.frame;
	ghost.skin = item.skin;
	ghost.effects = item.effects;
	ghost.colormod = item.colormod;
	setmodel(ghost, item.mdl);
	setorigin(ghost, item.origin);
	ghost.alpha = ffa_item_alpha_value();
	ghost.think = ffa_item_remove_respawn_ghost;
	ghost.nextthink = expire_time;

	item.ffa_item_ghost_ent = ghost;
	return ghost;
};

void () ffa_item_remove_respawn_ghost =
{
	local entity item;

	item = self.owner;
	if ((item != world) && !wasfreed(item) && (item.ffa_item_ghost_ent == self))
		item.ffa_item_ghost_ent = world;

	remove(self);
};

void () ffa_item_spawn_respawn_ghost =
{
	local entity item;

	item = self.owner;
	if ((item == world) || wasfreed(item))
	{
		remove(self);
		return;
	}

	if (item.ffa_item_ghost_ent == self)
		item.ffa_item_ghost_ent = world;

	if (!ffa_item_alpha_enabled() || !ffa_item_alpha_applies(item) || item.nextthink <= time)
	{
		remove(self);
		return;
	}

	if (item.model != string_null)
	{
		remove(self);
		return;
	}

	ffa_item_spawn_ghost_clone(item, item.nextthink);
	remove(self);
};

void (entity item, float ghost_start_time) ffa_item_schedule_ghost_timer =
{
	local entity timer;

	ffa_item_clear_respawn_ghost(item);

	timer = spawn();
	timer.classname = "item_ffa_ghost_timer";
	timer.owner = item;
	timer.solid = SOLID_NOT;
	timer.movetype = MOVETYPE_NONE;
	timer.model = string_null;
	timer.think = ffa_item_spawn_respawn_ghost;
	timer.nextthink = ghost_start_time;
	item.ffa_item_ghost_ent = timer;
};

void (entity item) ffa_item_hide_or_ghost =
{
	local float ghost_time;
	local float respawn_time;

	item.solid = SOLID_NOT;
	ffa_item_clear_respawn_ghost(item);

	if (item.classname == "item_artifact_super_damage")
	{
		item.effects = item.effects - (item.effects & EF_FULLBRIGHT);
		item.colormod = '0 0 0';
	}

	if (ffa_item_alpha_enabled() && ffa_item_alpha_applies(item) && item.nextthink > time)
	{
		ghost_time = ffa_item_alpha_time();
		respawn_time = item.nextthink;

		if ((ghost_time <= 0) || (respawn_time <= time + ghost_time))
		{
			item.model = string_null;
			item.alpha = 1;
			ffa_item_spawn_ghost_clone(item, respawn_time);
			return;
		}

		item.model = string_null;
		item.alpha = 1;
		ffa_item_schedule_ghost_timer(item, respawn_time - ghost_time);
		return;
	}

	item.model = string_null;
	item.alpha = 1;
};

float () items_are_ready =
{
	if (ffa_start_lock_active())
	{
		return FALSE;
	}
	if ((clanring_playmode & CLANRING_MATCH_MODE) && !(clanring_state & CLANRING_MATCH_STARTED))
		return FALSE;
	if ((mode_is_arena()) && ((boss == world) || ((boss != world) && (boss.timetofight == FALSE))))
		return FALSE;
	return TRUE;
};

float () match_in_progress =
{
	if ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
		return TRUE;
	else if ((mode_is_arena()) && (boss.state != CA_MATCH_WAITING))
		return TRUE;
	return FALSE;
};

float () prematch_rules =
{
    // Only honor the global match timer countdown in non-arena modes
    if (!mode_is_arena() && (clanring_state & CLANRING_TIMER_STARTED) && !(clanring_state & CLANRING_MATCH_STARTED))
		return TRUE;
    if (mode_is_arena() && (boss.state == CA_MATCH_ROUNDSTART) && (boss.round == 1) && (!ra_initial_rules_shown))
		return TRUE;
	return FALSE;
}

//
// Get match seconds remaining with fallback logic for robustness
//
float () crx_get_match_secs_remaining =
{
    local float secs;

    secs = -1;

    if ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
    {
        // Primary: use clanring_match_timer which is maintained by match_timer_think2
        // lip = minutes remaining, count = seconds remaining (0-59)
        if (clanring_match_timer != world && clanring_match_timer.lip >= 0)
        {
            secs = (clanring_match_timer.lip * 60) + clanring_match_timer.count;
        }

        // Fallback for arena modes: use boss countdown
        if (secs < 0 && boss != world && boss.lip >= 0)
            secs = (boss.lip * 60) + boss.count;
    }

    if (secs < 0) return -1;
    return secs;
};

//
// Format time duration for display (e.g., "1:23:45" or "0:05:32")
//
string(float seconds) utils_format_time =
{
    local float hours, minutes, secs;
    local string result;
    
    if (seconds < 0)
        seconds = 0;
    
    secs = floor(seconds);
    minutes = floor(secs / 60);
    hours = floor(minutes / 60);
    secs = secs - (minutes * 60);
    minutes = minutes - (hours * 60);
    
    if (hours > 0)
    {
        if (minutes < 10 && secs < 10)
            result = sprintf("%g:0%g:0%g", hours, minutes, secs);
        else if (minutes < 10)
            result = sprintf("%g:0%g:%g", hours, minutes, secs);
        else if (secs < 10)
            result = sprintf("%g:%g:0%g", hours, minutes, secs);
        else
            result = sprintf("%g:%g:%g", hours, minutes, secs);
    }
    else
    {
        if (minutes < 10 && secs < 10)
            result = sprintf("0%g:0%g", minutes, secs);
        else if (secs < 10)
            result = sprintf("%g:0%g", minutes, secs);
        else
            result = sprintf("%g:%g", minutes, secs);
    }
    
    return result;
}

//
// Strip newline character from end of string
//
string(string s) utils_strip_newline =
{
    local float L = strlen(s);
    if (L > 0 && substring(s, L - 1, 1) == "\n")
        return substring(s, 0, L - 1);
    return s;
}

// Content-based string equality (case-sensitive).
// Use !strcasecmp(a,b) if you prefer case-insensitive and your compiler supports it.
float(string a, string b) utils_str_eq =
{
    return !strcmp(a, b);
};

// Publish the observer mode ("*observer" and legacy "observer") and target.
void(entity player, string mode, string observing) utils_set_observer_infokeys =
{
    forceinfokey(player, "*observer", mode);
    forceinfokey(player, "observer", mode);
    forceinfokey(player, "observing", observing);
};

//
// Get persistent server time that continues across map changes
//
// Persistent server time system (similar to hunk storage)
float() utils_server_time =
{
    return server_persistent_time + time - last_time_update;
}

void() utils_update_server_time =
{
    server_persistent_time = utils_server_time();
    last_time_update = time;
}

// Remove older duplicates in-place (keep the most recent instance for each name).
void() utils_dedupe_disconnect_log =
{
    local float i, j, k;
    for (i = 0; i < disconnect_log_count; i = i + 1)
    {
        for (j = i + 1; j < disconnect_log_count; )
        {
            if (disconnect_log[j].player_name != "" &&
                utils_str_eq(disconnect_log[j].player_name, disconnect_log[i].player_name))
            {
                // Drop entry j (older duplicate) and free its zoned string
                if (disconnect_log[j].player_name != "")
                    strunzone(disconnect_log[j].player_name);
                for (k = j; k < disconnect_log_count - 1; k = k + 1)
                {
                    disconnect_log[k].player_name     = disconnect_log[k + 1].player_name;
                    disconnect_log[k].disconnect_time = disconnect_log[k + 1].disconnect_time;
                }
                disconnect_log_count = disconnect_log_count - 1;
                // don't increment j; we just shifted a new thing into j
            }
            else
            {
                j = j + 1;
            }
        }
    }
};

//
// Display the list of recently disconnected players
//
void() utils_show_last_disconnects =
{
    local float i;
    local string time_str;
    local float time_since;
    local float name_len, time_len;
    local float name_padding, p;
    local float NAME_COL;
    
    sprint(self, "\n");
    sprint(self, "Name                    Time\n");
    sprint(self, "----                    ----\n\n");
    
    if (disconnect_log_count == 0)
    {
        sprint(self, "No entries found.\n");
        return;
    }
    
    for (i = 0; i < disconnect_log_count && i < MAX_CLIENT_DISCONNECT_LOG; i++)
    {
        if (disconnect_log[i].player_name != "" && disconnect_log[i].disconnect_time > 0)
        {
            time_since = utils_server_time() - disconnect_log[i].disconnect_time;
            if (time_since < 0)
                time_since = 0;  // Clamp negative times
            time_str = utils_format_time(time_since);
            
            // Right-justify time at consistent column position
            name_len = strlen(disconnect_log[i].player_name);
            time_len = strlen(time_str);
            
            // Calculate total padding needed to right-justify time at position 28
            NAME_COL = 28;
            name_padding = NAME_COL - name_len - time_len;
            
            if (name_padding < 2)  // Minimum 2 spaces between name and time
                name_padding = 2;
            
            sprint(self, disconnect_log[i].player_name);
            
            // Add padding to right-justify the time
            for (p = 0; p < name_padding; p++)
                sprint(self, " ");
                
            sprint(self, time_str);
            sprint(self, "\n");
        }
    }
}

//
// Save disconnect log to file
//
void() utils_save_disconnect_log =
{
    local float i;
    local filestream f;
    
    f = fopen("disconnect_log.txt", FILE_WRITE);
    if (f < 0)
    {
        dprint("WARNING: Could not write to disconnect_log.txt\n");
        return;
    }
    
    // Update persistent time before saving
    utils_update_server_time();
    
    // Write the count and persistent time (only the total, not last_time_update)
    fputs(f, ftos(disconnect_log_count));
    fputs(f, "\n");
    fputs(f, ftos(server_persistent_time));
    fputs(f, "\n");
    
    // Write each entry
    for (i = 0; i < disconnect_log_count && i < MAX_CLIENT_DISCONNECT_LOG; i++)
    {
        if (disconnect_log[i].player_name != "" && disconnect_log[i].disconnect_time > 0)
        {
            fputs(f, disconnect_log[i].player_name);
            fputs(f, "\n");
            fputs(f, ftos(disconnect_log[i].disconnect_time));
            fputs(f, "\n");
        }
    }
    
    fclose(f);
}

//
// Log a player disconnect for the 'last' command (de-duped, MRU-at-0).
//
void(string player_name, float disconnect_time) utils_log_disconnect =
{
    local float i;

    // 1) If name already exists, move it to front and update time (no new alloc).
    for (i = 0; i < disconnect_log_count; i = i + 1)
    {
        if (disconnect_log[i].player_name != "" &&
            utils_str_eq(disconnect_log[i].player_name, player_name))
        {
            local string keep_name = disconnect_log[i].player_name; // already strzone'd
            local float  keep_time = disconnect_time;               // override with latest

            // Shift [i-1..0] down by one
            for ( ; i > 0; i = i - 1)
            {
                disconnect_log[i].player_name     = disconnect_log[i - 1].player_name;
                disconnect_log[i].disconnect_time = disconnect_log[i - 1].disconnect_time;
            }
            // Place updated record at 0
            disconnect_log[0].player_name     = keep_name;
            disconnect_log[0].disconnect_time = keep_time;

            utils_save_disconnect_log();
            return;
        }
    }

    // 2) Not found: insert a new record at the front.
    if (disconnect_log_count == MAX_CLIENT_DISCONNECT_LOG)
    {
        // Evict last; free its zoned string to avoid leaks.
        if (disconnect_log[disconnect_log_count - 1].player_name != "")
            strunzone(disconnect_log[disconnect_log_count - 1].player_name);
    }
    else
    {
        disconnect_log_count = disconnect_log_count + 1;
    }

    // Make room at [0] by shifting down
    for (i = disconnect_log_count - 1; i > 0; i = i - 1)
    {
        disconnect_log[i].player_name     = disconnect_log[i - 1].player_name;
        disconnect_log[i].disconnect_time = disconnect_log[i - 1].disconnect_time;
    }

    // Insert new at front (take a fresh zoned copy)
    disconnect_log[0].player_name     = strzone(player_name);
    disconnect_log[0].disconnect_time = disconnect_time;

    utils_save_disconnect_log();
}

//
// Load disconnect log from file
//
void() utils_load_disconnect_log =
{
    local float i;
    local filestream f;
    local string line;
    local float count;
    
    f = fopen("disconnect_log.txt", FILE_READ);
    if (f < 0)
    {
        // File doesn't exist yet, start with empty log and fresh time
        disconnect_log_count = 0;
        server_persistent_time = 0;
        last_time_update = time;
        return;
    }
    
    // Read the count
    line = fgets(f);
    if (line == "")
    {
        fclose(f);
        disconnect_log_count = 0;
        server_persistent_time = 0;
        last_time_update = time;
        return;
    }
    
    count = stof(line);
    if (count > MAX_CLIENT_DISCONNECT_LOG)
        count = MAX_CLIENT_DISCONNECT_LOG;
    
    // Read the persistent time total
    line = fgets(f);
    if (line == "")
    {
        fclose(f);
        disconnect_log_count = 0;
        server_persistent_time = 0;
        last_time_update = time;
        return;
    }
    server_persistent_time = stof(line);
    
    // Read each entry
    disconnect_log_count = 0;
    for (i = 0; i < count; i++)
    {
        // Read player name
        line = fgets(f);
        if (line == "")
            break;
            
        disconnect_log[i].player_name = strzone(utils_strip_newline(line));
        
        // Read disconnect time
        line = fgets(f);
        if (line == "")
            break;
            
        disconnect_log[i].disconnect_time = stof(line);
        disconnect_log_count = disconnect_log_count + 1;
    }
    
    fclose(f);
    
    // Critical: anchor delta to this map's clock
    last_time_update = time;

    // Clean any legacy duplicates loaded from disk
    utils_dedupe_disconnect_log();
}

// ------------------------------------------------------------
// Discord webhook helper
// ------------------------------------------------------------

string json_escape(string s);                 // from json.qc
float (entity p) Q1_PER_Calc_Eff;            // PER helper
float(entity p) PER_HasNontrivialActivity;   // from stats.qc
float(entity p) stats_has_nontrivial_activity; // from stats.qc

// Private, non-serverinfo storage for webhook URL configured via clanring.cfg
string clanring_captimesdiscordurl;
string clanring_statsdiscordurl;

// Google Sheets integration for captime records
string clanring_googlesheetsurl;      // Google Apps Script web app URL
string clanring_googlesheetsapikey;   // API key for authentication
float  clanring_googlesheets_valid;   // TRUE if last validation succeeded
float webhook_seq;
strbuf webhook_stats_buf;
float webhook_stats_len;
float webhook_stats_max;

// -----------------------------
// Zoned string helpers
// -----------------------------
string(string a, string b) zcat =
{
    local string t;
    t = strcat(a, b);       // tempstring
    if (a) strunzone(a);    // free previous zone if any
    return strzone(t);      // return new zoned string
};

// Buffer-based builder for large webhook stats messages (avoids tempstring overflow)
void(float maxlen) webhook_stats_buf_begin =
{
    if (webhook_stats_buf) buf_del(webhook_stats_buf);
    webhook_stats_buf = buf_create();
    webhook_stats_len = 0;
    webhook_stats_max = maxlen;
};

void(string seg) webhook_stats_buf_append =
{
    local string s;
    local float rem;

    s = seg ? seg : "";
    if (webhook_stats_max <= 0) return;
    if (webhook_stats_len >= webhook_stats_max) return;

    rem = webhook_stats_max - webhook_stats_len;
    if (rem <= 0) return;
    if (strlen(s) > rem) s = substring(s, 0, rem);

    bufstr_add(webhook_stats_buf, s, 0);
    webhook_stats_len = webhook_stats_len + strlen(s);
};

void() webhook_stats_buf_end =
    {
    if (webhook_stats_buf) buf_del(webhook_stats_buf);
    webhook_stats_buf = 0;
    webhook_stats_len = 0;
    webhook_stats_max = 0;
};

// JSON-escape into a *zoned* string (uses strreplace for efficiency)
string(string s) json_escape_zoned_simple =
{
    local string out;
    if (!s) return strzone("");
    
    // Use strreplace for efficiency - only 4 operations instead of N iterations
    // Order matters: escape backslashes FIRST to avoid double-escaping
    out = strreplace("\\", "\\\\", s);
    out = strreplace("\"", "\\\"", out);
    out = strreplace("\n", "\\n", out);
    out = strreplace("\t", "\\t", out);
    
    return strzone(out);
};

// Build {"content":"..."} as a *zoned* JSON payload
string(string body) Webhook_MakeContentPayloadZ =
{
    local string out, esc;
    out = strzone("{\"content\":\"");
    esc = json_escape_zoned_simple(body);  // returns zoned
    out = zcat(out, esc);
    strunzone(esc);
    out = zcat(out, "\"}");
    return out; // zoned
};


// ------------------------------------------------------------
// Quake -> Discord sanitizer (preserve whitespace/padding)
// ------------------------------------------------------------
// - Fold 128..255 to 0..127 (avoid introducing C0 controls)
// - Map common QC control glyphs to ASCII/UTF-8 equivalents
// - Drop remaining C0 controls except TAB(9) and LF(10)
// - Do NOT trim/collapse spaces
string(string s) utils_dequake_for_discord =
{
    local float i, j;
    local string middle_dot;
    local string square;
    local string play_arrow;
    if (!s) return "";
    middle_dot = "\xC2\xB7";
    square = "\xE2\x96\xA0";
    play_arrow = "\xE2\x96\xB6";

    // A) 128..255 -> 0..127 (red -> white).
    // Preserve the control-range glyphs we explicitly decode below so
    // colored digits/brackets/arrows survive dequakeing; other low controls
    // still degrade to '.' unless we decode them explicitly below.
    for (i = 128; i <= 255; i = i + 1)
    {
        j = i - 128; // 0..127
        if (j < 32)
        {
            if (j == 1 || j == 5 || j == 11 || j == 12 || j == 13 || j == 14 || j == 15 || (j >= 16 && j <= 31))
                s = strreplace(sprintf("%c", i), sprintf("%c", j), s);
            else
            s = strreplace(sprintf("%c", i), ".", s);
        }
        else
            s = strreplace(sprintf("%c", i), sprintf("%c", j), s);
    }

    // B) Control glyphs ? readable
    s = strreplace(sprintf("%c", 1 ), ".", s);
    s = strreplace(sprintf("%c", 5 ), middle_dot, s);
    s = strreplace(sprintf("%c", 11), square, s);
    s = strreplace(sprintf("%c", 13), play_arrow, s);
    s = strreplace(sprintf("%c", 14), middle_dot, s);
    s = strreplace(sprintf("%c", 15), middle_dot, s);
    s = strreplace(sprintf("%c", 28), middle_dot, s);
    s = strreplace(sprintf("%c", 16), "[", s);
    s = strreplace(sprintf("%c", 17), "]", s);

    // 18..27 -> '0'..'9'
    for (i = 0; i <= 9; i = i + 1)
        s = strreplace(sprintf("%c", 18 + i), sprintf("%c", 48 + i), s);

    // arrows-ish
    s = strreplace(sprintf("%c", 29), "<", s);
    s = strreplace(sprintf("%c", 30), "-", s);
    s = strreplace(sprintf("%c", 31), ">", s);

    // form feed -> space
    s = strreplace(sprintf("%c", 12), " ", s);

    // C) Drop remaining C0 except TAB/LF
    for (i = 0; i < 32; i = i + 1)
        if (i != 9 && i != 10)
            s = strreplace(sprintf("%c", i), "", s);

    return s;
};

// Sanitize user-provided webhook URL text
string(string in) Webhook_SanitizeURL =
{
    local string s, ch;
    if (!in) return "";
    s = in;

    // Trim L/R whitespace
    while (strlen(s) > 0) { ch = substring(s, 0, 1); if (!(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")) break; s = substring(s, 1, strlen(s) - 1); }
    while (strlen(s) > 0) { ch = substring(s, strlen(s) - 1, 1); if (!(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")) break; s = substring(s, 0, strlen(s) - 1); }

    // Strip UTF-8 BOM, ZW*
    if (strlen(s) >= 3 && substring(s, 0, 3) == "\xEF\xBB\xBF") s = substring(s, 3, strlen(s) - 3);
    s = strreplace("\xE2\x80\x8B", "", s); // ZWSP
    s = strreplace("\xE2\x80\x8C", "", s); // ZWNJ
    s = strreplace("\xE2\x80\x8D", "", s); // ZWJ
    s = strreplace("\xE2\x80\x8E", "", s); // LRM
    s = strreplace("\xE2\x80\x8F", "", s); // RLM
    s = strreplace("\xC2\xA0", " ", s);    // NBSP -> space

    // Strip leading '@'
    while (strlen(s) > 0 && substring(s, 0, 1) == "@") s = substring(s, 1, strlen(s) - 1);

    // Strip <...>, '...', "..."
    while (strlen(s) >= 2)
    {
        if ( (substring(s, 0, 1) == "<"  && substring(s, strlen(s) - 1, 1) == ">") ||
             (substring(s, 0, 1) == "\"" && substring(s, strlen(s) - 1, 1) == "\"") ||
             (substring(s, 0, 1) == "'"  && substring(s, strlen(s) - 1, 1) == "'") )
            s = substring(s, 1, strlen(s) - 2);
        else break;
    }

    // Drop trailing punctuation
    while (strlen(s) > 0)
    {
        ch = substring(s, strlen(s) - 1, 1);
        if (!(ch == "," || ch == "." || ch == ";" || ch == ")")) break;
        s = substring(s, 0, strlen(s) - 1);
    }

    // Final re-trim
    while (strlen(s) > 0) { ch = substring(s, 0, 1); if (!(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")) break; s = substring(s, 1, strlen(s) - 1); }
    while (strlen(s) > 0) { ch = substring(s, strlen(s) - 1, 1); if (!(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")) break; s = substring(s, 0, strlen(s) - 1); }
    return s;
};

// Parse a list of webhook URLs (comma/semicolon/newline separated), sanitize,
// dedupe, and return up to 3 URLs in order.
void(entity ev, string raw) Webhook_SetEventURLsMax3 =
{
    local string s, part, u1, u2, u3;
    local float pos, n, nl, done;

    u1 = "";
    u2 = "";
    u3 = "";

    s = raw ? raw : "";
    s = strreplace("\r\n", "\n", s);
    s = strreplace("\r", "\n", s);
    s = strreplace(";", "\n", s);
    s = strreplace(",", "\n", s);

    pos = 0;
    n = strlen(s);
    done = 0;

    while (!done && pos <= n)
    {
        nl = strstrofs(s, "\n", pos);
        if (nl < 0)
        {
            part = substring(s, pos, n - pos);
            done = 1;
        }
        else
        {
            part = substring(s, pos, nl - pos);
            pos = nl + 1;
        }

        part = Webhook_SanitizeURL(part);
        if (part == "") continue;

        if (u1 == "")
        {
            u1 = part;
            continue;
        }
        if (part == u1) continue;

        if (u2 == "")
        {
            u2 = part;
            continue;
        }
        if (part == u2) continue;

        if (u3 == "")
        {
            u3 = part;
            break; // hard cap: 3
        }
    }

    if (ev.hook_url) strunzone(ev.hook_url);
    if (ev.hook_url2) strunzone(ev.hook_url2);
    if (ev.hook_url3) strunzone(ev.hook_url3);
    ev.hook_url = strzone(u1);
    ev.hook_url2 = strzone(u2);
    ev.hook_url3 = strzone(u3);
};

// Keep content within Discord's limit (budgeted lower for code blocks)
string(string s) Webhook_TruncateForDiscord =
{
    local float max, n, keep;
    local string suffix;

    max = 1900;            // headroom for JSON + headers
    n   = strlen(s);
    if (n <= max) return s;

    suffix = " ... (truncated)";
    keep   = max - strlen(suffix);
    if (keep < 0) keep = 0;
    return strcat(substring(s, 0, keep), suffix);
};

// ------------------------------------------------------------
// PREP functions
// ------------------------------------------------------------
void(entity ev) webhook_captime_info =
{
    local string urls, content;

    content = utils_dequake_for_discord(ev.message);

    urls = clanring_captimesdiscordurl;
    if (urls == "") urls = cvar_string("webhook_url");
    Webhook_SetEventURLsMax3(ev, urls);
    if (ev.hook_url == "") return;

    if (strstrofs(content, "```", 0) < 0) content = strcat("```text\n", content, "```");
    content = Webhook_TruncateForDiscord(content);

    if (ev.hook_payload) strunzone(ev.hook_payload);
    ev.hook_payload = Webhook_MakeContentPayloadZ(content);
};

// Forward declaration (defined later in sender pipeline section)
void() webhook_do_post;

// Prep function for stats continuation parts (ev.message is the @file payload)
void(entity ev) webhook_stats_continuation_info =
{
    local string urls, content;

    content = ev.message;  // "@discord/stats_N.json", zoned by webhook_stats_send

    urls = clanring_statsdiscordurl;
    if (urls == "") urls = cvar_string("webhook_stats_url");
    Webhook_SetEventURLsMax3(ev, urls);
    if (ev.hook_url == "") return;

    if (ev.hook_payload) strunzone(ev.hook_payload);
    ev.hook_payload = strzone(content);
};

// ------------------------------------------------------------
// Discord stats: ANSI-colored tables
// ------------------------------------------------------------
// Tables go in ```ansi code blocks. Discord desktop/web render the colors;
// mobile shows the same text without them. Color has one meaning per kind:
// gold = best in column, red = worst (bad stats), gray = zero / N/A, and
// player names take their team color.
#define WST_MAXROWS 16
#define WST_MAXCOLS 10

#define WST_INT  0
#define WST_PCT  1   // value < 0 shows N/A
#define WST_DEC1 2
#define WST_SECS 3
#define WST_MMSS 4
#define WST_TEAM 5   // row's team name (value unused)
#define WST_BIG  6   // thousands separator

#define WST_NONE  0
#define WST_MAX   1  // highest value in gold
#define WST_MIN   2  // lowest value in gold
#define WST_WORST 3  // highest value in red

#define WST_GOLD "[1;33m"
#define WST_RED  "[1;31m"
#define WST_GRAY "[30m"

// Discord allows 2000 characters per message; strlen counts bytes, which is
// never less than characters, so this leaves room for a reopened fence.
#define WST_MSG_LIMIT 1900

entity wst_row[WST_MAXROWS];
float  wst_frags[WST_MAXROWS];
float  wst_obs[WST_MAXROWS];
float  wst_show[WST_MAXROWS];
float  wst_nrows;
float  wst_namew;
float  wst_val[160];            // WST_MAXROWS * WST_MAXCOLS
string wst_head[WST_MAXCOLS];
float  wst_w[WST_MAXCOLS];
float  wst_kind[WST_MAXCOLS];
float  wst_rule[WST_MAXCOLS];
float  wst_tgt[WST_MAXCOLS];
float  wst_has[WST_MAXCOLS];
float  wst_ncols;
string wst_esc;                 // zoned ESC character
string wst_awards;              // zoned awards line
float  wst_nawards;
float  wst_part;
float  wst_delay;

string(string code, string s) wst_paint =
{
    if (!wst_esc) wst_esc = strzone(chr2str(27));
    if (code == "") return s;
    return strcat(wst_esc, code, s, wst_esc, "[0m");
};

// ANSI color for a team color number (strings_get_teamname order)
string(float h) wst_team_ansi =
{
    if (h == 4) return "[31m";                          // red
    if (h == 13) return "[34m";                         // blue
    if (h == 2 || h == 11) return "[36m";               // light blue, aqua
    if (h == 3 || h == 5) return "[32m";                // green, olive
    if (h == 1 || h == 6 || h == 12) return "[33m";     // brown, gold, yellow
    if (h == 7 || h == 8 || h == 9) return "[35m";      // flesh, lavender, purple
    return "[37m";
};

string(entity p) wst_name_code =
{
    if (!teamplay || p.next_team == world) return "";
    return wst_team_ansi(p.next_team.height);
};

// Colored circle emoji for a team color number
string(float h) wst_team_dot =
{
    if (h == 4) return "\xF0\x9F\x94\xB4";
    if (h == 13 || h == 2 || h == 11) return "\xF0\x9F\x94\xB5";
    if (h == 3 || h == 5) return "\xF0\x9F\x9F\xA2";
    if (h == 6 || h == 12) return "\xF0\x9F\x9F\xA1";
    if (h == 1) return "\xF0\x9F\x9F\xA4";
    if (h == 7 || h == 8 || h == 9) return "\xF0\x9F\x9F\xA3";
    return "\xE2\x9A\xAA";
};

// Escape Discord markdown in text shown outside code blocks
string(string s) wst_md =
{
    s = strreplace("\\", "\\\\", s);
    s = strreplace("*", "\\*", s);
    s = strreplace("_", "\\_", s);
    s = strreplace("~", "\\~", s);
    s = strreplace("`", "\\`", s);
    s = strreplace("|", "\\|", s);
    return s;
};

// 10359 -> "10,359"
string(float n) wst_thou =
{
    local float a, b;
    n = floor(n);
    if (n < 1000) return ftos(n);
    a = floor(n / 1000);
    b = n - a * 1000;
    if (b < 10) return strcat(ftos(a), ",00", ftos(b));
    if (b < 100) return strcat(ftos(a), ",0", ftos(b));
    return strcat(ftos(a), ",", ftos(b));
};

string(float kind, float v, entity r) wst_fmt =
{
    local float m, s;
    if (kind == WST_TEAM)
        return (r.next_team != world) ? utils_rstrip(strings_get_teamname3(r.next_team.height)) : "";
    if (kind == WST_PCT)  return (v < 0) ? "N/A" : strcat(ftos(v), "%");
    if (kind == WST_BIG)  return wst_thou(v);
    if (kind == WST_DEC1) return sprintf("%.1f", v);
    if (kind == WST_SECS) return strcat(ftos(v), "s");
    if (kind == WST_MMSS)
    {
        m = floor(v / 60);
        s = floor(v - m * 60);
        return strcat(ftos(m), (s < 10) ? ":0" : ":", ftos(s));
    }
    return ftos(v);
};

float(entity t) wst_team_rank =
{
    local float r;
    local entity pt;
    if (!teamplay || t == world) return 99;
    r = 0;
    pt = clanring_sentinel.next_team;
    while (pt)
    {
        if (pt != t && (pt.frags > t.frags || (pt.frags == t.frags && pt.height < t.height)))
            r = r + 1;
        pt = pt.next_team;
    }
    return r;
};

// Collect every player who may appear in any table, ordered winning team
// first, then by frags. Per-table eligibility is checked with wst_elig.
void(float is_arena, float participant_cutoff) wst_collect =
{
    local entity p, te;
    local float obs, n, i, j, best, key, bkey, tf, to;

    wst_nrows = 0;
    wst_namew = 4;
    p = find(world, classname, "player");
    while (p && wst_nrows < WST_MAXROWS)
    {
        obs = ((clanring_playmode & CLANRING_MATCH_MODE) &&
               (p.style & CLANRING_OBSERVER) &&
               p.join_time > 0 &&
               p.join_time >= participant_cutoff &&
               stats_has_nontrivial_activity(p));
        if ((is_arena && p.next_team != world) || !(p.style & CLANRING_OBSERVER) || obs)
        {
            n = wst_nrows;
            wst_row[n] = p;
            wst_obs[n] = obs;
            wst_frags[n] = p.frags;
            if (obs && p.frags <= -90)
                wst_frags[n] = p.true_kills - p.mangle_z;
            wst_namew = max(wst_namew, strlen(utils_dequake_for_discord(p.netname)));
            wst_nrows = n + 1;
        }
        p = find(p, classname, "player");
    }
    wst_namew = bound(4, wst_namew, 15);

    // selection sort: team rank ascending, frags descending
    for (i = 0; i < wst_nrows; i++)
    {
        best = i;
        bkey = wst_team_rank(wst_row[i].next_team) * 1000000 - wst_frags[i];
        for (j = i + 1; j < wst_nrows; j++)
        {
            key = wst_team_rank(wst_row[j].next_team) * 1000000 - wst_frags[j];
            if (key < bkey) { best = j; bkey = key; }
        }
        if (best != i)
        {
            te = wst_row[i]; wst_row[i] = wst_row[best]; wst_row[best] = te;
            tf = wst_frags[i]; wst_frags[i] = wst_frags[best]; wst_frags[best] = tf;
            to = wst_obs[i]; wst_obs[i] = wst_obs[best]; wst_obs[best] = to;
        }
    }
};

#define WST_E_SCORE 0   // scoreboard
#define WST_E_MAIN  1   // efficiency, kills, headhunters
#define WST_E_ITEMS 2   // quad, bad stats, items
#define WST_E_CTF   3
#define WST_E_QPER  4

float(float r, float which, float is_arena) wst_elig =
{
    local entity p;
    local float obs, playing;
    p = wst_row[r];
    obs = wst_obs[r];
    playing = (!(p.style & CLANRING_OBSERVER) || obs);
    if (which == WST_E_SCORE) return playing;
    if (which == WST_E_MAIN) return is_arena ? (p.next_team != world) : playing;
    if (which == WST_E_ITEMS)
        return playing && !((clanring_playmode & CLANRING_MATCH_MODE) && p.next_team == world && !obs);
    if (which == WST_E_CTF) return ((!(p.style & CLANRING_OBSERVER) && p.next_team != world) || obs);
    if (which == WST_E_QPER) return playing && p.join_time > 0;
    return FALSE;
};

void() wst_reset =
{
    local float i;
    wst_ncols = 0;
    for (i = 0; i < WST_MAXROWS; i++)
        wst_show[i] = FALSE;
};

void(string head, float w, float kind, float rule) wst_col =
{
    wst_head[wst_ncols] = head;
    wst_w[wst_ncols] = w;
    wst_kind[wst_ncols] = kind;
    wst_rule[wst_ncols] = rule;
    wst_ncols = wst_ncols + 1;
};

void(float r, float c, float v) wst_set =
{
    wst_val[r * WST_MAXCOLS + c] = v;
};

// Pick the highlighted value per column. Nothing is highlighted when fewer
// than two rows show, when the best is zero (gold/red rules), or when more
// than two players share it.
void() wst_pick_targets =
{
    local float c, r, v, best, found, hits, shown;

    shown = 0;
    for (r = 0; r < wst_nrows; r++)
        if (wst_show[r]) shown = shown + 1;

    for (c = 0; c < wst_ncols; c++)
    {
        wst_has[c] = FALSE;
        if (shown < 2 || wst_rule[c] == WST_NONE || wst_kind[c] == WST_TEAM)
            continue;

        found = FALSE;
        best = 0;
        for (r = 0; r < wst_nrows; r++)
        {
            if (!wst_show[r]) continue;
            v = wst_val[r * WST_MAXCOLS + c];
            if (wst_kind[c] == WST_PCT && v < 0) continue;
            if (!found || (wst_rule[c] == WST_MIN ? (v < best) : (v > best)))
            {
                best = v;
                found = TRUE;
            }
        }
        if (!found) continue;
        if (wst_rule[c] != WST_MIN && best <= 0) continue;

        hits = 0;
        for (r = 0; r < wst_nrows; r++)
            if (wst_show[r] && wst_val[r * WST_MAXCOLS + c] == best)
                hits = hits + 1;
        if (hits > 2) continue;

        wst_tgt[c] = best;
        wst_has[c] = TRUE;
    }
};

// Append one titled table to the stats buffer
void(string title) wst_emit =
{
    local float r, c, v, shown;
    local string line, cell, code, nm;

    shown = 0;
    for (r = 0; r < wst_nrows; r++)
        if (wst_show[r]) shown = shown + 1;
    if (!shown) return;

    wst_pick_targets();

    webhook_stats_buf_append(strcat("\n**", title, "**\n"));
    webhook_stats_buf_append("```ansi\n");

    line = strzone(strpad(wst_namew, ""));
    for (c = 0; c < wst_ncols; c++)
    {
        if (wst_kind[c] == WST_TEAM)
            line = zcat(line, strcat(" ", strpad(wst_w[c], wst_head[c])));
        else
            line = zcat(line, strcat(" ", strpad(-wst_w[c], wst_head[c])));
    }
    webhook_stats_buf_append(strcat(line, "\n"));
    strunzone(line);

    for (r = 0; r < wst_nrows; r++)
    {
        if (!wst_show[r]) continue;

        // dequake first: it burns through many tempstrings
        nm = strzone(utils_dequake_for_discord(wst_row[r].netname));
        line = strzone(wst_paint(wst_name_code(wst_row[r]), strpad(wst_namew, nm)));
        strunzone(nm);

        for (c = 0; c < wst_ncols; c++)
        {
            v = wst_val[r * WST_MAXCOLS + c];
            if (wst_kind[c] == WST_TEAM)
                cell = strpad(wst_w[c], wst_fmt(WST_TEAM, 0, wst_row[r]));
            else
                cell = strpad(-wst_w[c], wst_fmt(wst_kind[c], v, wst_row[r]));

            code = "";
            if (wst_has[c] && v == wst_tgt[c])
                code = (wst_rule[c] == WST_WORST) ? WST_RED : WST_GOLD;
            else if (wst_kind[c] != WST_TEAM && (v == 0 || (wst_kind[c] == WST_PCT && v < 0)))
                code = WST_GRAY;

            line = zcat(line, strcat(" ", wst_paint(code, cell)));
        }
        webhook_stats_buf_append(strcat(line, "\n"));
        strunzone(line);
    }
    webhook_stats_buf_append("```\n");
};

// Award from column 0 of wst_val (rows with wst_show set, value > 0).
// Ties of up to two players are listed; larger ties are skipped.
void(string label, float kind) wst_award =
{
    local float r, v, best, hits;
    local string who, nm;

    best = 0;
    for (r = 0; r < wst_nrows; r++)
    {
        if (!wst_show[r]) continue;
        v = wst_val[r * WST_MAXCOLS];
        if (v > best) best = v;
    }
    if (best <= 0) return;

    hits = 0;
    for (r = 0; r < wst_nrows; r++)
        if (wst_show[r] && wst_val[r * WST_MAXCOLS] == best)
            hits = hits + 1;
    if (hits > 2) return;

    who = strzone("");
    for (r = 0; r < wst_nrows; r++)
    {
        if (!(wst_show[r] && wst_val[r * WST_MAXCOLS] == best)) continue;
        nm = strzone(wst_md(utils_dequake_for_discord(wst_row[r].netname)));
        if (who == "")
            who = zcat(who, nm);
        else
            who = zcat(who, strcat(", ", nm));
        strunzone(nm);
    }

    if (wst_nawards > 0)
        wst_awards = zcat(wst_awards, " \xC2\xB7 ");
    wst_awards = zcat(wst_awards, strcat(label, " **", who, " ", wst_fmt(kind, best, world), "**"));
    strunzone(who);
    wst_nawards = wst_nawards + 1;
};

// ------------------------------------------------------------
// Discord stats: sending
// ------------------------------------------------------------
// Each message is written to data/discord/stats_N.json and posted with
// uri_post's "@file" body, so a message is not limited by the engine's
// 1024-byte tempstrings and can use Discord's full message length.

string(string s) wst_json_esc =
{
    if (!wst_esc) wst_esc = strzone(chr2str(27));
    s = strreplace("\\", "\\\\", s);
    s = strreplace("\"", "\\\"", s);
    s = strreplace("\r", "", s);
    s = strreplace("\n", "\\n", s);
    s = strreplace("\t", "    ", s);
    s = strreplace(wst_esc, "\\u001b", s);
    return s;
};

float(string seg) wst_is_section =
{
    if (substring(seg, 0, 3) == "\n**") return TRUE;
    if (substring(seg, 0, 3) == "## ") return TRUE;
    return (substring(seg, 0, 2) == "**");
};

void(entity ev, float a, float b, float reopen, float closefence) wst_write_part =
{
    local string path, payload;
    local float f, j;
    local entity cont;

    wst_part = wst_part + 1;
    path = strzone(sprintf("discord/stats_%g.json", wst_part));
    f = fopen(path, FILE_WRITE);
    if (f < 0)
    {
        dprint("webhook: cannot write ", path, "\n");
        strunzone(path);
        return;
    }
    fputs(f, "{\"allowed_mentions\":{\"parse\":[]},\"content\":\"");
    if (reopen) fputs(f, "```ansi\\n");
    for (j = a; j < b; j++)
        fputs(f, wst_json_esc(bufstr_get(webhook_stats_buf, j)));
    if (closefence) fputs(f, "```");
    fputs(f, "\"}");
    fclose(f);

    // fopen wrote <gamedir>/data/<path>; uri_post's "@" lookup tries that.
    payload = strzone(strcat("@", path));
    strunzone(path);

    if (wst_part == 1)
    {
        if (ev.hook_payload) strunzone(ev.hook_payload);
        ev.hook_payload = payload;
    }
    else
    {
        cont = spawn();
        cont.classname = "webhook_event";
        cont.message = payload;
        cont.webhook_prepfn = webhook_stats_continuation_info;
        cont.nextthink = time + wst_delay;
        cont.think = webhook_do_post;
        wst_delay = wst_delay + 0.5;
    }
};

// Group buffered segments into messages, breaking between sections and only
// splitting a section (closing and reopening its code block) if it can't fit.
void(entity ev) webhook_stats_send =
{
    local float n, i, j, len, seclen, start, incode, reopen;
    local string seg;

    wst_part = 0;
    wst_delay = 0.5;
    n = buf_getsize(webhook_stats_buf);
    start = 0;
    len = 0;
    incode = FALSE;
    reopen = FALSE;

    for (i = 0; i < n; i++)
    {
        seg = bufstr_get(webhook_stats_buf, i);
        if (wst_is_section(seg))
        {
            seclen = 0;
            for (j = i; j < n; j++)
            {
                if (j > i && wst_is_section(bufstr_get(webhook_stats_buf, j))) break;
                seclen = seclen + strlen(bufstr_get(webhook_stats_buf, j));
            }
            if (len > 0 && len + seclen > WST_MSG_LIMIT)
            {
                wst_write_part(ev, start, i, reopen, FALSE);
                start = i;
                len = 0;
                reopen = FALSE;
            }
            seg = bufstr_get(webhook_stats_buf, i);
        }
        else if (len > 0 && seg != "```\n" && len + strlen(seg) + 4 > WST_MSG_LIMIT)
        {
            wst_write_part(ev, start, i, reopen, incode);
            start = i;
            reopen = incode;
            len = incode ? 8 : 0;
            seg = bufstr_get(webhook_stats_buf, i);
        }
        len = len + strlen(seg);
        if (seg == "```ansi\n") incode = TRUE;
        else if (seg == "```\n") incode = FALSE;
    }
    if (start < n)
        wst_write_part(ev, start, n, reopen, FALSE);
};

// Build and send the Discord "stats" message
void(entity ev) webhook_stats_info =
{
    local string urls;
    local entity p;
    local float is_arena, r, v, k, m;
    local float eligible_players, total_frags, hh_has_activity, obs;
    local float participant_cutoff;
    local float kfrac, ktot;
    local float b1, b2, b3, b4, b5;
    local entity e1, e2, e3, e4, e5;
    local string nm, s;

    is_arena = mode_is_arena();
    v = clanring_timelimit;
    if (v <= 0) v = cvar("timelimit");
    if (v <= 0) v = 20;
    participant_cutoff = clanring_sentinel.matchTime;
    if (participant_cutoff <= 0) participant_cutoff = time;
    participant_cutoff = participant_cutoff - (v * 60 + 180);

    // Skip Discord stats if there are fewer than two eligible players,
    // or if every player has 0 frags (idle/afk game).
    wst_collect(is_arena, participant_cutoff);
    eligible_players = 0;
    total_frags = 0;
    hh_has_activity = 0;
    for (r = 0; r < wst_nrows; r++)
    {
        p = wst_row[r];
        obs = wst_obs[r];
        if ((is_arena && p.next_team != world) ||
            (!is_arena && (!(p.style & CLANRING_OBSERVER) || obs)))
        {
            eligible_players = eligible_players + 1;
            total_frags = total_frags + wst_frags[r];
            if ((clanring_playmode & CLANRING_HH_MODE) && stats_has_nontrivial_activity(p))
                hh_has_activity = TRUE;
        }
    }
    if (eligible_players < 2)
        return;
    if ((total_frags <= 0) && !hh_has_activity)
        return;

    // Resolve + sanitize URL
    urls = clanring_statsdiscordurl;
    if (urls == "") urls = cvar_string("webhook_stats_url");
    Webhook_SetEventURLsMax3(ev, urls);
    if (ev.hook_url == "") return;

    webhook_stats_buf_begin(16000);

    // QPER ranking (top 5), used for the MVP line and the QPER table
    b1 = b2 = b3 = b4 = b5 = -9999;
    e1 = e2 = e3 = e4 = e5 = world;
    if (!is_arena)
    {
        for (r = 0; r < wst_nrows; r++)
        {
            if (!wst_elig(r, WST_E_QPER, is_arena)) continue;
            p = wst_row[r];
            v = qper_rating(p);
            if (v > b1) { b5=b4; e5=e4; b4=b3; e4=e3; b3=b2; e3=e2; b2=b1; e2=e1; b1=v; e1=p; }
            else if (v > b2) { b5=b4; e5=e4; b4=b3; e4=e3; b3=b2; e3=e2; b2=v; e2=p; }
            else if (v > b3) { b5=b4; e5=e4; b4=b3; e4=e3; b3=v; e3=p; }
            else if (v > b4) { b5=b4; e5=e4; b4=v; e4=p; }
            else if (v > b5) { b5=v; e5=p; }
        }
    }

    // -------------------------
    // Headline: score, details, MVP, awards
    // -------------------------
    {
        local entity pteam, best_team, t1, t2;
        local float best_score, num_teams, i;
        local string hdr_time, time_str, map_z, line;
        local float hourpos;

        num_teams = 0;
        if (teamplay)
        {
            pteam = clanring_sentinel.next_team;
            while (pteam) { num_teams = num_teams + 1; pteam = pteam.next_team; }
        }

        line = strzone("## ");
        if (num_teams >= 2)
        {
            // teams in descending score order (.cnt as printed flag)
            t1 = t2 = world;
            for (i = 0; i < num_teams; i = i + 1)
            {
                best_team = world;
                best_score = -999999;
                pteam = clanring_sentinel.next_team;
                while (pteam)
                {
                    if ((pteam.cnt == 0) && (pteam.frags > best_score))
                    {
                        best_score = pteam.frags;
                        best_team = pteam;
                    }
                    pteam = pteam.next_team;
                }
                if (best_team == world) break;
                best_team.cnt = 1;
                if (i == 0) t1 = best_team;
                if (i == 1) t2 = best_team;

                if (best_team.netname != "")
                    nm = strzone(wst_md(utils_dequake_for_discord(best_team.netname)));
                else
                    nm = strzone(utils_rstrip(strings_get_teamname2(best_team.height)));

                if (num_teams == 2 && i == 1)
                    line = zcat(line, strcat(" \xE2\x80\x93 ", ftos(best_team.frags), " ", nm, " ", wst_team_dot(best_team.height)));
                else if (num_teams == 2)
                    line = zcat(line, strcat(wst_team_dot(best_team.height), " ", nm, " ", ftos(best_team.frags)));
                else
                {
                    if (i > 0) line = zcat(line, " \xC2\xB7 ");
                    line = zcat(line, strcat(wst_team_dot(best_team.height), " ", nm, " ", ftos(best_team.frags)));
                }
                strunzone(nm);
            }
            pteam = clanring_sentinel.next_team;
            while (pteam) { pteam.cnt = 0; pteam = pteam.next_team; }
        }
        else
        {
            // no teams: top fragger (rows are sorted by frags)
            for (r = 0; r < wst_nrows; r++)
                if (wst_elig(r, WST_E_SCORE, is_arena)) break;
            if (r < wst_nrows)
            {
                nm = strzone(wst_md(utils_dequake_for_discord(wst_row[r].netname)));
                line = zcat(line, strcat("\xF0\x9F\x8F\x86 ", nm, " wins \xC2\xB7 ", ftos(wst_frags[r]), " frags"));
                strunzone(nm);
            }
            else
                line = zcat(line, "Match Statistics");
        }
        webhook_stats_buf_append(strcat(line, "\n"));
        strunzone(line);

        // Details line (Discord subtext)
        {
            local float tl, reg_tl, ot_len, ot_n, current_period_tl, completed_mins, total_tl;
            local float remaining_secs, elapsed_mins, is_match_mode;
            local string ot_suffix, modes;

            is_match_mode = (clanring_playmode & CLANRING_MATCH_MODE);
            tl = clanring_timelimit;
            if (tl <= 0) tl = cvar("timelimit");
            if (tl <= 0) tl = 20;

            // When the match has entered OT, clanring_timelimit holds the OT
            // length, so regulation comes from clanring_match_initial_timelimit.
            ot_n = clanring_overtime_count;
            if (ot_n < 0) ot_n = 0;
            reg_tl = clanring_match_initial_timelimit;
            if (reg_tl <= 0) reg_tl = tl;
            ot_len = (ot_n > 0) ? tl : 0;
            current_period_tl = (ot_n > 0) ? ot_len : reg_tl;
            completed_mins = (ot_n > 0) ? (reg_tl + (ot_n - 1) * ot_len) : 0;
            total_tl = reg_tl + ot_n * ot_len;

            ot_suffix = "";
            if (ot_n == 1) ot_suffix = " (1 OT)";
            else if (ot_n > 1) ot_suffix = sprintf(" (%g OT)", ot_n);

            if (is_match_mode && clanring_match_timer != world && current_period_tl > 0)
            {
                remaining_secs = (clanring_match_timer.lip * 60) + clanring_match_timer.count;
                if (remaining_secs < 0) remaining_secs = 0;
                elapsed_mins = completed_mins + floor((current_period_tl * 60 - remaining_secs) / 60);
                if (elapsed_mins < 1) elapsed_mins = 1;
                if (remaining_secs > 0 && remaining_secs < 60) elapsed_mins = total_tl;
                if (remaining_secs >= 60 && elapsed_mins < total_tl)
                    time_str = sprintf("%g of %g min%s", elapsed_mins, total_tl, ot_suffix);
                else
                    time_str = sprintf("%g min%s", total_tl, ot_suffix);
            }
            else if (!is_match_mode)
            {
                elapsed_mins = floor(time / 60);
                if (elapsed_mins < 1) elapsed_mins = 1;
                time_str = sprintf("%g min", elapsed_mins);
            }
            else
                time_str = sprintf("%g min%s", total_tl, ot_suffix);
            time_str = strzone(time_str);

            if      (clanring_playmode & CLANRING_RA_MODE)          modes = "Rocket Arena";
            else if (clanring_playmode & CLANRING_CA_MODE)          modes = "Clan Arena";
            else if (clanring_playmode & CLANRING_WIPEOUT_MODE)     modes = "Wipeout";
            else if (clanring_playmode & CLANRING_DMM4_MODE)        modes = "DMM4";
            else if (clanring_playmode & CLANRING_AIRSHOT_MODE)     modes = "Airshot";
            else if (clanring_playmode & CLANRING_HH_MODE)          modes = "Headhunters";
            else if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
            {
                if      (clanring_playmode & CLANRING_MATCH_MODE)    modes = "CTF Match";
                else if (clanring_playmode & CLANRING_PRACTICE_MODE) modes = "CTF Practice";
                else                                                 modes = "CTF Normal";
            }
            else
            {
                if      (clanring_playmode & CLANRING_MATCH_MODE)    modes = "DM Match";
                else if (clanring_playmode & CLANRING_PRACTICE_MODE) modes = "DM Practice";
                else                                                 modes = "DM FFA";
            }

            hdr_time = utils_dequake_for_discord(strftime(TRUE, "%m-%d-%Y %I:%M %p"));
            if (substring(hdr_time, 0, 1) == "0")
                hdr_time = substring(hdr_time, 1, strlen(hdr_time) - 1);
            hourpos = strstrofs(hdr_time, " ", 0);
            if (hourpos >= 0 && substring(hdr_time, hourpos + 1, 1) == "0")
                hdr_time = strcat(substring(hdr_time, 0, hourpos + 1), substring(hdr_time, hourpos + 2, strlen(hdr_time) - (hourpos + 2)));
            hdr_time = strzone(hdr_time);

            map_z = strzone(wst_md(utils_dequake_for_discord(clanring_current_mapname())));
            line = strzone(strcat("-# ", map_z, " \xC2\xB7 ", time_str));
            if (clanring_maxsize > 0)
                line = zcat(line, sprintf(" %gv%g", clanring_maxsize, clanring_maxsize));
            line = zcat(line, strcat(" \xC2\xB7 ", modes, " \xC2\xB7 "));
            s = strzone(wst_md(utils_dequake_for_discord(infokey(world, "hostname"))));
            line = zcat(line, strcat(s, " \xC2\xB7 ", hdr_time, "\n"));
            webhook_stats_buf_append(line);
            strunzone(s);
            strunzone(line);
            strunzone(map_z);
            strunzone(hdr_time);
            strunzone(time_str);
        }

        // MVP line
        if (e1 != world)
        {
            nm = strzone(wst_md(utils_dequake_for_discord(e1.netname)));
            line = strzone(strcat("\xE2\xAD\x90 MVP **", nm, "** \xC2\xB7 ", sprintf("%.1f", b1), " QPER"));
            line = zcat(line, strcat(" \xC2\xB7 ", ftos(e1.true_kills), "/", ftos(e1.mangle_z), " K/D"));
            line = zcat(line, strcat(" \xC2\xB7 ", wst_thou(e1.dmg_given), " dmg"));
            if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && e1.fcaptures > 0)
                line = zcat(line, strcat(" \xC2\xB7 ", ftos(e1.fcaptures), (e1.fcaptures == 1) ? " cap" : " caps"));
            webhook_stats_buf_append(strcat(line, "\n"));
            strunzone(line);
            strunzone(nm);
        }

        // Awards (each reads column 0 of wst_val)
        if (wst_awards) strunzone(wst_awards);
        wst_awards = strzone("");
        wst_nawards = 0;

        wst_reset();
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_MAIN, is_arena);
            wst_set(r, 0, (p.dest1_z >= 50) ? floor(100 * p.dest2_z / p.dest1_z) : 0);
        }
        wst_award("\xF0\x9F\x8E\xAF Best LG", WST_PCT);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_set(r, 0, (p.dest_x >= 10) ? floor(100 * p.dest_y / p.dest_x) : 0);
        }
        wst_award("\xF0\x9F\x9A\x80 Best RL", WST_PCT);
        for (r = 0; r < wst_nrows; r++)
            wst_set(r, 0, wst_row[r].dmg_given);
        wst_award("\xF0\x9F\x92\xA5 Top dmg", WST_BIG);

        if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        {
            for (r = 0; r < wst_nrows; r++)
            {
                wst_show[r] = wst_elig(r, WST_E_CTF, is_arena);
                wst_set(r, 0, wst_row[r].fcaptures);
            }
            wst_award("\xF0\x9F\x9A\xA9 Most caps", WST_INT);
            for (r = 0; r < wst_nrows; r++)
                wst_set(r, 0, wst_row[r].freturns);
            wst_award("\xF0\x9F\x9B\xA1\xEF\xB8\x8F Most returns", WST_INT);
            for (r = 0; r < wst_nrows; r++)
                wst_set(r, 0, floor(wst_row[r].fcarries_time));
            wst_award("\xE2\x8F\xB1\xEF\xB8\x8F Longest hold", WST_MMSS);
        }

        if (!is_arena)
        {
            for (r = 0; r < wst_nrows; r++)
            {
                wst_show[r] = wst_elig(r, WST_E_ITEMS, is_arena);
                wst_set(r, 0, wst_row[r].clanring_qdkill_x);
            }
            wst_award("\xE2\x9A\xA1 Most quad kills", WST_INT);
            for (r = 0; r < wst_nrows; r++)
            {
                p = wst_row[r];
                kfrac = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y + p.clanring_badstats_y + p.clanring_badstats_z;
                wst_set(r, 0, (kfrac > 0) ? floor(100 * p.clanring_badstats_y / kfrac) : 0);
            }
            wst_award("\xF0\x9F\x98\xAC Most self dmg", WST_PCT);
        }

        if (wst_nawards > 0)
            webhook_stats_buf_append(strcat(wst_awards, "\n"));
    }

    // New CTF record note
    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_new_record_player != ""))
    {
        nm = strzone(wst_md(utils_dequake_for_discord(clanring_new_record_player)));
        webhook_stats_buf_append(strcat("\xF0\x9F\x8F\x81 **", nm, "** set a new match capture record!\n"));
        strunzone(nm);
    }

    // ---- Scoreboard ----
    wst_reset();
    if (teamplay) wst_col("team", 8, WST_TEAM, WST_NONE);
    wst_col("frags", 5, WST_INT, WST_MAX);
    wst_col("ping", 4, WST_INT, WST_NONE);
    for (r = 0; r < wst_nrows; r++)
    {
        wst_show[r] = wst_elig(r, WST_E_SCORE, is_arena);
        k = 0;
        if (teamplay) { wst_set(r, k, 0); k = k + 1; }
        wst_set(r, k, wst_frags[r]);
        wst_set(r, k + 1, floor(wst_row[r].ping_time + 0.5));
    }
    wst_emit("Scoreboard");

    // ---- Efficiency ----
    wst_reset();
    wst_col("kill", 4, WST_PCT, WST_MAX);
    wst_col("weap", 4, WST_PCT, WST_MAX);
    wst_col("bul", 4, WST_PCT, WST_MAX);
    wst_col("nls", 4, WST_PCT, WST_MAX);
    wst_col("rox", 4, WST_PCT, WST_MAX);
    wst_col("lg", 4, WST_PCT, WST_MAX);
    wst_col("fpm", 4, WST_DEC1, WST_MAX);
    for (r = 0; r < wst_nrows; r++)
    {
        p = wst_row[r];
        wst_show[r] = wst_elig(r, WST_E_MAIN, is_arena);

        kfrac = p.true_kills;
        ktot  = kfrac + p.mangle_z;
        wst_set(r, 0, (ktot > 0) ? floor(100 * kfrac / ktot) : -1);
        ktot  = p.dest1_x + p.dest1_y + p.dest1_z + p.dest_x;
        kfrac = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y;
        wst_set(r, 1, (ktot > 0) ? floor(100 * kfrac / ktot) : -1);
        wst_set(r, 2, (p.dest1_x > 0) ? floor(100 * p.dest2_x / p.dest1_x) : -1);
        wst_set(r, 3, (p.dest1_y > 0) ? floor(100 * p.dest2_y / p.dest1_y) : -1);
        wst_set(r, 4, (p.dest_x > 0) ? floor(100 * p.dest_y / p.dest_x) : -1);
        wst_set(r, 5, (p.dest1_z > 0) ? floor(100 * p.dest2_z / p.dest1_z) : -1);

        v = 0;
        if (p.join_time > 0)
        {
            m = clanring_sentinel.matchTime;
            if (m <= 0) m = time;
            m = m - p.join_time;
            if (m > 0) v = p.true_kills * 60 / m;
        }
        wst_set(r, 6, floor(v * 10 + 0.5) / 10);
    }
    wst_emit("Efficiency");

    // ---- Kills and damage ----
    wst_reset();
    wst_col("K", 3, WST_INT, WST_MAX);
    wst_col("D", 3, WST_INT, WST_MIN);
    if (stats_weapon_carrier_kills_enabled())
    {
        wst_col("RLk", 3, WST_INT, WST_MAX);
        wst_col("LGk", 3, WST_INT, WST_MAX);
    }
    wst_col("dmg", 6, WST_INT, WST_MAX);
    wst_col("taken", 6, WST_INT, WST_MIN);
    wst_col("ewep", 5, WST_INT, WST_MAX);
    for (r = 0; r < wst_nrows; r++)
    {
        p = wst_row[r];
        wst_show[r] = wst_elig(r, WST_E_MAIN, is_arena);
        wst_set(r, 0, p.true_kills);
        wst_set(r, 1, p.mangle_z);
        k = 2;
        if (stats_weapon_carrier_kills_enabled())
        {
            wst_set(r, 2, p.stats_rl_carrier_kills);
            wst_set(r, 3, p.stats_lg_carrier_kills);
            k = 4;
        }
        wst_set(r, k, p.dmg_given);
        wst_set(r, k + 1, p.dmg_taken);
        wst_set(r, k + 2, p.ewep);
    }
    wst_emit("Kills and damage");
    if (stats_weapon_carrier_kills_enabled())
        webhook_stats_buf_append("-# RLk/LGk: enemies killed while carrying RL/LG\n");

    // ---- Headhunters ----
    if (clanring_playmode & CLANRING_HH_MODE)
    {
        wst_reset();
        wst_col("pick", 4, WST_INT, WST_MAX);
        wst_col("rec", 3, WST_INT, WST_MAX);
        wst_col("scr", 3, WST_INT, WST_MAX);
        wst_col("val", 4, WST_INT, WST_MAX);
        wst_col("peak", 4, WST_INT, WST_MAX);
        wst_col("drop", 4, WST_INT, WST_WORST);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_MAIN, is_arena);
            wst_set(r, 0, p.hh_stats_heads_picked);
            wst_set(r, 1, p.hh_stats_heads_reclaimed);
            wst_set(r, 2, p.hh_stats_heads_scored);
            wst_set(r, 3, p.hh_stats_score_value);
            wst_set(r, 4, p.hh_stats_peak_value);
            wst_set(r, 5, p.hh_stats_heads_dropped);
        }
        wst_emit("Headhunters");

        wst_reset();
        wst_col("hunt", 4, WST_INT, WST_MAX);
        wst_col("bite", 4, WST_INT, WST_MAX);
        wst_col("kil", 3, WST_INT, WST_MAX);
        wst_col("time", 5, WST_MMSS, WST_MAX);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_MAIN, is_arena);
            v = p.hh_stats_haunt_time;
            if (p.hh_stats_haunt_start > 0)
                v = v + max(0, time - p.hh_stats_haunt_start);
            wst_set(r, 0, p.hh_stats_haunts_started);
            wst_set(r, 1, p.hh_stats_haunt_bites);
            wst_set(r, 2, p.hh_stats_haunt_kills);
            wst_set(r, 3, floor(v));
        }
        wst_emit("Haunts");
    }

    if (!is_arena)
    {
        // ---- Quad (only players who took one) ----
        wst_reset();
        wst_col("quads", 5, WST_INT, WST_MAX);
        wst_col("time", 5, WST_SECS, WST_MAX);
        wst_col("eff", 4, WST_PCT, WST_MAX);
        wst_col("opp", 3, WST_INT, WST_MAX);
        wst_col("self", 4, WST_INT, WST_WORST);
        wst_col("tm", 3, WST_INT, WST_WORST);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = FALSE;
            if (p.clanring_qdwep_z > 0)
                wst_show[r] = wst_elig(r, WST_E_ITEMS, is_arena);
            wst_set(r, 0, p.clanring_qdwep_z);
            wst_set(r, 1, floor(p.totalquad + 0.5));
            wst_set(r, 2, (p.clanring_qdwep_y > 0) ? floor(100 * p.clanring_qdwep_x / p.clanring_qdwep_y) : -1);
            wst_set(r, 3, p.clanring_qdkill_x);
            wst_set(r, 4, p.clanring_qdkill_z);
            wst_set(r, 5, p.clanring_qdkill_y);
        }
        wst_emit("Quad");

        // ---- Bad stats ----
        wst_reset();
        wst_col("paks", 4, WST_INT, WST_WORST);
        wst_col("self", 4, WST_PCT, WST_WORST);
        wst_col("team", 4, WST_PCT, WST_WORST);
        wst_col("bore", 4, WST_INT, WST_WORST);
        wst_col("lava", 4, WST_INT, WST_WORST);
        wst_col("axe", 3, WST_INT, WST_WORST);
        wst_col("fall", 4, WST_INT, WST_WORST);
        if (stats_badstats_has_walkover_categories())
        {
            wst_col("spawn", 5, WST_INT, WST_NONE);
            wst_col("tele", 4, WST_INT, WST_NONE);
        }
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_ITEMS, is_arena);
            ktot = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y + p.clanring_badstats_y + p.clanring_badstats_z;
            wst_set(r, 0, p.clanring_badstats_x);
            wst_set(r, 1, (ktot > 0) ? floor(100 * p.clanring_badstats_y / ktot) : 0);
            wst_set(r, 2, (ktot > 0) ? floor(100 * p.clanring_badstats_z / ktot) : 0);
            wst_set(r, 3, p.clanring_badstats_bores);
            wst_set(r, 4, p.clanring_badstats2_x);
            wst_set(r, 5, p.clanring_badstats2_y);
            wst_set(r, 6, p.clanring_badstats2_z);
            wst_set(r, 7, p.clanring_badstats_spawnwalk);
            wst_set(r, 8, p.clanring_badstats_telewalk);
        }
        wst_emit("Bad stats");

        // ---- Items ----
        wst_reset();
        wst_col("Q", 3, WST_INT, WST_MAX);
        wst_col("RA", 3, WST_INT, WST_MAX);
        wst_col("YA", 3, WST_INT, WST_MAX);
        wst_col("MG", 3, WST_INT, WST_MAX);
        wst_col("RL", 3, WST_INT, WST_MAX);
        wst_col("LG", 3, WST_INT, WST_MAX);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_ITEMS, is_arena);
            wst_set(r, 0, p.clanring_qdwep_z);
            wst_set(r, 1, p.stats_item_redarmor);
            wst_set(r, 2, p.stats_item_yellowarmor);
            wst_set(r, 3, p.stats_item_mega);
            wst_set(r, 4, p.stats_item_rl);
            wst_set(r, 5, p.stats_item_lg);
        }
        wst_emit("Items");

        // ---- QPER (top 5) + reasons for #1 ----
        if (e1 != world)
        {
            webhook_stats_buf_append("\n**QPER (top 5)**\n");
            webhook_stats_buf_append("```ansi\n");
            for (k = 1; k <= 5; k++)
            {
                if (k == 1) { p = e1; v = b1; }
                else if (k == 2) { p = e2; v = b2; }
                else if (k == 3) { p = e3; v = b3; }
                else if (k == 4) { p = e4; v = b4; }
                else { p = e5; v = b5; }
                if (p == world) break;

                nm = strzone(utils_dequake_for_discord(p.netname));
                s = strzone(wst_paint(wst_name_code(p), strpad(wst_namew, nm)));
                webhook_stats_buf_append(strcat(ftos(k), ") ", s, " ",
                                         wst_paint((k == 1) ? WST_GOLD : "", sprintf("%5.1f", v)), "\n"));
                strunzone(s);
                strunzone(nm);
            }

            qper_find_top_terms(e1);
            if (qper_top_id1 >= 0)
            {
                nm = strzone(utils_dequake_for_discord(e1.netname));
                webhook_stats_buf_append(strcat("\nwhy ", nm, " led:\n"));
                strunzone(nm);
                webhook_stats_buf_append(sprintf("  %s %s\n", utils_dequake_for_discord(qper_term_label(e1, qper_top_id1)),
                                                 wst_paint(WST_GOLD, sprintf("+%.1f", qper_top_v1))));
                if (qper_top_id2 >= 0)
                    webhook_stats_buf_append(sprintf("  %s %s\n", utils_dequake_for_discord(qper_term_label(e1, qper_top_id2)),
                                                     wst_paint(WST_GOLD, sprintf("+%.1f", qper_top_v2))));
                if (qper_top_id3 >= 0)
                    webhook_stats_buf_append(sprintf("  %s %s\n", utils_dequake_for_discord(qper_term_label(e1, qper_top_id3)),
                                                     wst_paint(WST_GOLD, sprintf("+%.1f", qper_top_v3))));
            }
            webhook_stats_buf_append("```\n");
        }
    }

    // ---- CTF ----
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        wst_reset();
        wst_col("cap", 3, WST_INT, WST_MAX);
        wst_col("rtn", 3, WST_INT, WST_MAX);
        wst_col("def", 3, WST_INT, WST_MAX);
        wst_col("cdef", 4, WST_INT, WST_MAX);
        wst_col("cfrg", 4, WST_INT, WST_MAX);
        wst_col("hold", 5, WST_MMSS, WST_MAX);
        for (r = 0; r < wst_nrows; r++)
        {
            p = wst_row[r];
            wst_show[r] = wst_elig(r, WST_E_CTF, is_arena);
            wst_set(r, 0, p.fcaptures);
            wst_set(r, 1, p.freturns);
            wst_set(r, 2, p.fdefenses);
            wst_set(r, 3, p.fcdefenses);
            wst_set(r, 4, p.fcfrags);
            wst_set(r, 5, floor(p.fcarries_time));
        }
        wst_emit("CTF");
    }

    webhook_stats_send(ev);
    webhook_stats_buf_end();
};


// ------------------------------------------------------------
// Sender pipeline (deferred + dedupe)
// ------------------------------------------------------------
#define WEBHOOK_DEBUG   0
#define WEBHOOK_DEDUPE  1

#define WEBHOOK_DEDUPE_SLOTS 16
string webhook_recent_fingerprint[WEBHOOK_DEDUPE_SLOTS];
float  webhook_recent_until[WEBHOOK_DEDUPE_SLOTS];
float  webhook_recent_rr;

float(string url, string payload) Webhook_AllowSend =
{
    local float n1, n2, i, slot;
    local string url_head, payload_head, fp;

    n1 = strlen(url);     if (n1 > 64)  n1 = 64;
    n2 = strlen(payload); if (n2 > 256) n2 = 256;

    url_head     = substring(url, 0, n1);
    payload_head = substring(payload, 0, n2);
    fp = strcat(url_head, "\n", payload_head);

    // Reject if we've seen this exact url+payload fingerprint recently.
    for (i = 0; i < WEBHOOK_DEDUPE_SLOTS; i = i + 1)
    {
        if (webhook_recent_fingerprint[i] != "" &&
            fp == webhook_recent_fingerprint[i] &&
            time < webhook_recent_until[i])
            return FALSE;
    }

    // Pick first free/expired slot, otherwise round-robin overwrite.
    slot = -1;
    for (i = 0; i < WEBHOOK_DEDUPE_SLOTS; i = i + 1)
    {
        if (webhook_recent_fingerprint[i] == "" || time >= webhook_recent_until[i])
        {
            slot = i;
            break;
        }
    }
    if (slot < 0)
    {
        slot = floor(webhook_recent_rr);
        webhook_recent_rr = webhook_recent_rr + 1;
        if (webhook_recent_rr >= WEBHOOK_DEDUPE_SLOTS) webhook_recent_rr = 0;
    }

    if (webhook_recent_fingerprint[slot]) strunzone(webhook_recent_fingerprint[slot]);
    webhook_recent_fingerprint[slot] = strzone(fp);
    webhook_recent_until[slot] = time + 2.0;
    return TRUE;
};

void(string url, string payload) webhook_post =
{
    local float ok, id;

    if (url == "") return;
    if (!(substring(url, 0, 8) == "https://" || substring(url, 0, 7) == "http://")) return;
    if (payload == "") return;

    webhook_seq = webhook_seq + 1;
    id = 9100 + webhook_seq;

    ok = uri_post(url, id, "application/json", payload);

#if WEBHOOK_DEBUG
    if (!ok) bprint("webhook: uri_post returned 0 (submit failed to queue)\n");
#endif
};

void() webhook_cleanup =
{
    local entity ev = self;
    if (ev.hook_payload) strunzone(ev.hook_payload);
    if (ev.hook_url)     strunzone(ev.hook_url);
    if (ev.hook_url2)    strunzone(ev.hook_url2);
    if (ev.hook_url3)    strunzone(ev.hook_url3);
    if (ev.message)      strunzone(ev.message);
    remove(ev);
};

void() webhook_do_post =
{
    local entity ev = self;
    local float posted; posted = FALSE;

    if (ev.webhook_prepfn)
    {
        // 1) PREP fills ev.hook_url + ev.hook_payload (both zoned)
        ev.webhook_prepfn(ev);

        // 2) POST to configured URLs (stats supports up to 3)
        if (ev.hook_payload != "" && (ev.hook_url != "" || ev.hook_url2 != "" || ev.hook_url3 != ""))
        {
#if WEBHOOK_DEDUPE
            if (ev.hook_url != "" && Webhook_AllowSend(ev.hook_url, ev.hook_payload)) {
                webhook_post(ev.hook_url, ev.hook_payload);
                posted = TRUE;
            }
            if (ev.hook_url2 != "" && Webhook_AllowSend(ev.hook_url2, ev.hook_payload)) {
                webhook_post(ev.hook_url2, ev.hook_payload);
                posted = TRUE;
            }
            if (ev.hook_url3 != "" && Webhook_AllowSend(ev.hook_url3, ev.hook_payload)) {
                webhook_post(ev.hook_url3, ev.hook_payload);
                posted = TRUE;
            }
#else
            if (ev.hook_url != "")  { webhook_post(ev.hook_url,  ev.hook_payload); posted = TRUE; }
            if (ev.hook_url2 != "") { webhook_post(ev.hook_url2, ev.hook_payload); posted = TRUE; }
            if (ev.hook_url3 != "") { webhook_post(ev.hook_url3, ev.hook_payload); posted = TRUE; }
#endif
        }
    }

    // Delay cleanup slightly if posted (allow asyncs to read strings)
    ev.think     = webhook_cleanup;
    ev.nextthink = time + (posted ? 3.0 : 0.1);
};

// Schedule the deferred POST with a swappable PREP (entity-only)
void(void(entity) prepfn, string content) webhook_post_deferred =
{
    local entity ev = spawn();

    ev.classname      = "webhook_event";
    ev.message        = strzone(content);
    ev.webhook_prepfn = prepfn;
    ev.nextthink      = time + 0.5;
    ev.think          = webhook_do_post;
};


































// ===========================
// Match POST (JSON) single knob
// ===========================

// Empty => OFF. Non-empty => ON.
string clanring_matchpost_url;

// sensible defaults when ON
const float MATCHPOST_DEFAULT_PRETTY   = 0; // compact JSON by default (avoid 1KB QC string cap)
const float MATCHPOST_DEFAULT_DEFERRED = 1; // send via tiny deferred event

float  matchpost_seq;
float  matchpost_debug = 1; // turn on previews while fixing

// ---- diagnostics helpers (no cvars) ----
string(string s, float maxlen) mp_trunc =
{
    if (!s) return "";
    if (strlen(s) <= maxlen) return s;
    return strcat(substring(s, 0, maxlen), "...");
};

// Read the first N bytes of a file safely (for previews only)
string(string p, float cap) mp_readfile_head =
{
    local float f = fopen(p, FILE_READ);
    if (f < 0) return "";
    local string s = "", line;
    while (strlen(s) < cap) { line = fgets(f); if (line == "") break; s = strcat(s, line); }
    fclose(f);
    if (strlen(s) > cap) s = substring(s, 0, cap);
    return s;
};

// Compact preview helper for payload/response
void(string label, string s, float maxshow) mp_preview =
{
    bprint(sprintf("[matchpost] %s bytes=%g\n", label, s ? strlen(s) : 0));
    if (s && strlen(s) > 0)
        bprint(sprintf("[matchpost] %s preview: %s\n", label, mp_trunc(s, maxshow)));
};

/* (removed) We no longer read the pretty file for POSTs; we send compact builder output. */

// Keep only the JSON portion (from first '{' or '[' to the last '}' or ']')
string(string s) mp_json_only =
{
    if (!s) return "";
    local float n = strlen(s), i = 0, j = n - 1;
    local string ch;
    // find first '{' or '['
    while (i < n)
    {
        ch = substring(s, i, 1);
        if (ch == "{" || ch == "[") break;
        i = i + 1;
    }
    if (i >= n) return s; // nothing found; let server complain
    // find last '}' or ']'
    while (j >= i)
    {
        ch = substring(s, j, 1);
        if (ch == "}" || ch == "]") break;
        j = j - 1;
    }
    if (j < i) return s; // malformed; let server complain
    return substring(s, i, (j - i + 1));
};

// Write helper (must be before mp_save_payload_for_debug for some QC compilers)
void(string path, string data) mp_writefile =
{
    local filestream fh = fopen(path, FILE_WRITE);
    if (!fh) { bprint(sprintf("[matchpost] fopen failed: '%s'\n", path)); return; }
    fputs(fh, data ? data : "");
    fclose(fh);
    bprint(sprintf("[matchpost] wrote '%s'\n", path));
};

// For quick diffs: persist what we actually send
void(string data) mp_save_payload_for_debug =
{
    mp_writefile("json/matchpost_payload.txt", data ? data : "");
};

// super-light "OK" sniff (works even when status==0)
float(string body) mp_body_looks_ok =
{
    if (!body) return 0;
    if (strstrofs(body, "\"ok\":true", 0) >= 0) return 1;
    if (strstrofs(body, "\"status\":\"ok\"", 0) >= 0) return 1;
    return 0;
};


// super-light Discord "OK" sniff (works even when status==0)
float(string body) webhook_body_looks_ok =
{
    if (!body) return 0;
    if (strstrofs(body, "id", 0) >= 0 && strstrofs(body, "content", 0) >= 0) return 1;
    return 0;
};

// Discord error JSON usually contains "message" and "code"
float(string body) webhook_body_looks_error =
{
    if (!body) return 0;
    if (strstrofs(body, "message", 0) >= 0 && strstrofs(body, "code", 0) >= 0) return 1;
    return 0;
};

// DP-style 3-arg callback. Normalize+forward into the canonical handler only.
void(float id, float status, string data) uri_get_callback =
{
    // Forward into the 4-arg canonical handler for unified logic.
    URI_Get_Callback(id, status, data ? data : "", data ? strlen(data) : 0);
}

// --- keep the callback from ever being stripped by aggressive QC optimizers ---
void() _mp_bind_callback_ref =
{
    // never runs; forces a reference to the symbol so the engine can find it by name
    if (time < -999999)
    {
        uri_get_callback(0, 0, "");
        URI_Get_Callback(0, 0, "", 0); // match fteextensions signature (last arg is __int)
    }
};

// fteextensions.qc callback signature:
//   void(float reqid, float responsecode, string resourcebody, __int resourcebytes)
void(float reqid, float responsecode, string resourcebody, __int resourcebytes) URI_Get_Callback =
{
    local float L, bytes;
    // Prefer engine-provided byte count; else strlen()
    if (resourcebytes > 0) bytes = resourcebytes; else bytes = resourcebody ? strlen(resourcebody) : 0;

    // --- Test GET (9001) ----------------------------------------------------
    if (reqid == 9001)
    {
        bprint(sprintf("GET %f status=%g bytes=%g\n", reqid, responsecode, bytes));
        L = bytes; if (L > 200) L = 200;
        if (L > 0) { bprint(substring(resourcebody, 0, L)); bprint("\n"); }
        return;
    }

    // --- Test POST (9002) ---------------------------------------------------
    if (reqid == 9002)
    {
        bprint(sprintf("POST %f status=%g bytes=%g\n", reqid, responsecode, bytes));
        L = bytes; if (L > 200) L = 200;
        if (L > 0) { bprint(substring(resourcebody, 0, L)); bprint("\n"); }
        return;
    }

    // --- Webhook posts (9100-9199) -----------------------------------------
    if (reqid >= 9100 && reqid < 9200)
    {
        if (responsecode >= 200 && responsecode < 300) {
            dprint(sprintf("WEBHOOK %f OK (%g)\n", reqid, responsecode));
        } else if (responsecode == 429) {
            bprint(sprintf("WEBHOOK %f rate-limited (429). Consider slowing or batching.\n", reqid));
        } else if (responsecode == 0) {
            // Some engines report status=0 even on success. If body looks like a Discord message JSON, treat as OK.
            if (bytes <= 0 || webhook_body_looks_ok(resourcebody)) {
                dprint(sprintf("WEBHOOK %f OK (status=0)\n", reqid));
            } else if (webhook_body_looks_error(resourcebody)) {
                dprint(sprintf("WEBHOOK %f ERROR (status=0 bytes=%g)\n", reqid, bytes));
                L = bytes; if (L > 200) L = 200;
                if (L > 0) { dprint(substring(resourcebody, 0, L)); dprint("\n"); }
            } else {
                dprint(sprintf("WEBHOOK %f HTTP %g (bytes=%g)\n", reqid, responsecode, bytes));
                L = bytes; if (L > 200) L = 200;
                if (L > 0) { dprint(substring(resourcebody, 0, L)); dprint("\n"); }
            }
        } else {
            dprint(sprintf("WEBHOOK %f HTTP %g (bytes=%g)\n", reqid, responsecode, bytes));
            L = bytes; if (L > 200) L = 200;
            if (L > 0) { dprint(substring(resourcebody, 0, L)); dprint("\n"); }
        }
        return;
    }

    // --- MATCH posts (9300-9399) ------------------------------------------
    if (reqid >= 9300 && reqid < 9400) {
        bprint(sprintf("MATCHPOST %f status=%g bytes=%g\n", reqid, responsecode, bytes));
        L = bytes; if (L > 200) L = 200;
        if (L > 0) bprint(sprintf("MATCHPOST %f preview: %s\n", reqid, substring(resourcebody, 0, L)));
        mp_writefile("json/matchpost_last.txt", resourcebody ? resourcebody : "");

        // Decide OK/FAIL (fallback sniff when status==0)
        if (responsecode >= 200 && responsecode < 300)
            bprint("MATCHPOST RESULT: OK (HTTP 2xx)\n");
        else if (responsecode == 0 && mp_body_looks_ok(resourcebody))
            bprint("MATCHPOST RESULT: OK (status=0 but body looks OK)\n");
        else if (responsecode == 0)
            bprint("MATCHPOST RESULT: UNKNOWN/FAIL (status=0)\n");
        else
            bprint(sprintf("MATCHPOST RESULT: FAIL (HTTP %g)\n", responsecode));
        return;
    }

    // --- Google Sheets requests (200-206) -----------------------------------
    if (reqid >= 200 && reqid <= 206)
    {
        gsheets_callback(reqid, responsecode, resourcebody);
        return;
    }

    // --- Default path -------------------------------------------------------
    if (matchpost_debug)
    {
        dprint(sprintf("URI %f status=%g bytes=%g\n", reqid, responsecode, bytes));
        L = bytes; if (L > 200) L = 200;
        if (L > 0) { dprint(substring(resourcebody, 0, L)); dprint("\n"); }
    }
};

string(string url) mp_sanitize_url =
{
    if (!url) return "";
    if (substring(url, 0, 1) == "@")
        url = substring(url, 1, strlen(url) - 1);
    while (strlen(url) > 0 && substring(url, 0, 1) == " ")
        url = substring(url, 1, strlen(url) - 1);
    while (strlen(url) > 0 && substring(url, strlen(url)-1, 1) == " ")
        url = substring(url, 0, strlen(url) - 1);
    return url;
};

// ---------- core send (immediate) ----------
void(string payload) match_post_json =
{
    local string url = mp_sanitize_url(clanring_matchpost_url);
    if (url == "") { bprint("[matchpost] OFF (empty URL)\n"); return; }
    if (!(substring(url,0,8)=="https://" || substring(url,0,7)=="http://"))
    { bprint("[matchpost] invalid URL scheme; use http:// or https://\n"); return; }

    // Ensure ?wait=true for easier debugging.
    if (strstrofs(url,"?",0) < 0)            url = strcat(url,"?wait=true");
    else if (strstrofs(url,"wait=",0) < 0)   url = strcat(url,"&wait=true");

    matchpost_seq = matchpost_seq + 1;
    local float id = 9300 + matchpost_seq;

    // ============== FILE MODE ==============
    if (payload && substring(payload,0,1) == "@")
    {
        local string rel = substring(payload,1,strlen(payload)-1);

        // Gather cvars
        local string gdir = cvar_string("fs_gamedir");
        local string bdir = cvar_string("fs_basedir");
        local string mod  = cvar_string("game");

        bprint(sprintf("[matchpost] post-file rel='%s'\n", rel));
        bprint(sprintf("[matchpost]   fs_gamedir='%s'\n", gdir ? gdir : ""));
        bprint(sprintf("[matchpost]   fs_basedir='%s'\n", bdir ? bdir : ""));
        bprint(sprintf("[matchpost]   game='%s'\n",      mod  ? mod  : ""));

        // Build candidate list (as PF_uri_get does raw fopen, we must hand real paths).
        local string cand[10]; local float n = 0;
        // Try as-is first (works if server CWD == game root or rel is absolute)
        cand[n++] = rel;
        // gdir + rel
        if (gdir && gdir!="") { cand[n++] = strcat(gdir, "/", rel); }
        // bdir/game + rel
        if (bdir && bdir!="" && mod && mod!="") { cand[n++] = strcat(bdir, "/", mod, "/", rel); }
        // If rel lacks "data/", try adding it
        if (!(strlen(rel) >= 5 && substring(rel,0,5)=="data/"))
        {
            if (gdir && gdir!="") cand[n++] = strcat(gdir, "/data/", rel);
            if (bdir && bdir!="" && mod && mod!="") cand[n++] = strcat(bdir, "/", mod, "/data/", rel);
            if (mod && mod!="") cand[n++] = strcat(mod, "/data/", rel);
            cand[n++] = strcat("data/", rel);
        }
        // If rel has "data/", try the sibling without it
        if (strlen(rel) >= 5 && substring(rel,0,5)=="data/")
        {
            local string nodata = substring(rel,5,strlen(rel)-5);
            if (gdir && gdir!="") cand[n++] = strcat(gdir, "/", nodata);
            if (bdir && bdir!="" && mod && mod!="") cand[n++] = strcat(bdir, "/", mod, "/", nodata);
            if (mod && mod!="") cand[n++] = strcat(mod, "/", nodata);
            cand[n++] = nodata;
        }

        // Try each candidate. The first one the engine accepts wins.
        local float i, ok = 0;
        for (i = 0; i < n; i = i + 1)
        {
            local string p = cand[i];
            if (!p || p == "") continue;

            // Optional: QC-side fopen check (helps spot typos early)
            local float chk = fopen(p, FILE_READ);
            if (chk < 0) { dprint(sprintf("[matchpost] QC fopen failed: '%s'\n", p)); }
            else
            {
                // Show a tiny head so we know we're pointing at the JSON file we just wrote
                local string head = mp_readfile_head(p, 160);
                if (strlen(head) > 0)
                {
                    bprint(sprintf("[matchpost] file head bytes=%g\n", strlen(head)));
                    bprint(sprintf("[matchpost] file head preview: %s\n", head));
                }
                fclose(chk);
            }

            bprint(sprintf("[matchpost] dispatch id=%g (file try %g): @%s\n", id, i, p));
            ok = uri_get(url, id, "application/json", strcat("@", p));
            if (ok) { bprint(sprintf("[matchpost] engine accepted transfer id=%g\n", id)); break; }
        }

        if (!ok) bprint("[matchpost] engine rejected transfer (transport not accepted)\n");
        return;
    }

    // ============== STRING MODE (fallback) ==============
    {
        local string body = mp_json_only(payload);
        mp_preview("payload (json-only)", body, 160);

        // For big bodies, write to a temp file and recurse into file mode.
        if (strlen(body) > 900)
        {
            local string tmp = "json/matchpost_send.json";
            mp_writefile(tmp, body);
            // Re-enter file mode using the same resolver path.
            match_post_json(strcat("@", tmp));
            return;
        }

        bprint(sprintf("[matchpost] dispatch id=%g bytes=%g (inline)\n", id, strlen(body)));
        ok = uri_get(url, id, "application/json", body);
        if (!ok) bprint("[matchpost] engine rejected transfer (inline)\n");
        else     bprint(sprintf("[matchpost] engine accepted transfer id=%g\n", id));
        if (matchpost_debug) mp_save_payload_for_debug(strlen(body) > 512 ? substring(body,0,512) : body);
    }
};

// ---------- deferred send ----------
void() match_post_do_send =
{
    if (self.message != "")
    {
        bprint(sprintf("[matchpost] deferred send bytes=%g\n", strlen(self.message)));
        // Show a short preview of what we're about to POST (debug only)
        if (matchpost_debug) mp_preview("deferred payload", self.message, 160);
        match_post_json(self.message);
        strunzone(self.message);
    }
    remove(self);
};
void(string payload) match_post_json_deferred =
{
    local entity ev = spawn();
    ev.classname = "matchpost_event";
    ev.message   = strzone(payload);
    ev.nextthink = time + 0.5;
    ev.think     = match_post_do_send;
    bprint(sprintf("[matchpost] queued deferred payload bytes=%g\n", strlen(payload)));
    // Preview what we just queued (debug only)
    if (matchpost_debug) mp_preview("queued payload", payload, 160);
};

// Trim trailing spaces/tabs from a string (ASCII-safe)
string(string s) utils_rstrip =
{
    if (!s) return "";
    float n = strlen(s);
    if (n <= 0) return s;
    float i = n - 1;
    while (i >= 0)
    {
        string ch = substring(s, i, 1);
        if (!(ch == " " || ch == "\t"))
            break;
        i = i - 1;
    }
    return substring(s, 0, i + 1);
};

// --- Mode normalization ------------------------------------------------
string(string mode) normalize_mode =
{
    if (!mode)                         return "DM";
    if (mode == "dm")                  return "DM";
    if (mode == "ctf")                 return "CTF";
    if (mode == "rocketarena" || mode == "rocket_arena" || mode == "ra")
        return "RA";
    if (mode == "clanarena" || mode == "clan_arena" || mode == "ca")
        return "CA";
    if (mode == "wipeout" || mode == "wipe")
        return "WIPEOUT";
    if (mode == "dmm4")                return "DMM4";
    if (mode == "airshot")             return "AIRSHOT";
    return mode; // Unknown: return as-is
};

float() utils_ui_supported_now
{
    if (self.has_userinfo) return 1;
    if (infokey(self, "name") != "") 
    {
        self.has_userinfo = 1;
        return 1;
    }
    return 0;
};

// Return a single Quake font glyph by numeric code (0..255).
string(float code) utils_qf_chr =
{
    return sprintf("%c", code);
};

// Quake "dot" separator (0x9C = 156). Safer than relying on "\x9C".
string() utils_qf_dot =
{
    return utils_qf_chr(156); // \xB7
};

// Quake-font brackets (code 16 = left, 17 = right)
string() utils_qf_lbrack =
{
    return utils_qf_chr(16);
};
string() utils_qf_rbrack =
{
    return utils_qf_chr(17);
};

// Result (no spaces touching brackets): [when_ago \xB7 MODE \xB7 map_name]
string(string when_ago, string map_name, string raw_mode) format_match_header =
{
    string sep = strcat(" ", utils_qf_dot(), " "); // " \xB7 "
    string mid = strcat(when_ago, sep, normalize_mode(raw_mode), sep, map_name);
    return strcat(utils_qf_lbrack(), mid, utils_qf_rbrack());
};

// https://quakewiki.org/wiki/Quake_font hex codes cheatsheet to print unicode characters

//   0=0x00    1=0x01    2=0x02    3=0x03    4=0x04    5=0x05    6=0x06    7=0x07
//   8=0x08    9=0x09   10=0x0A   11=0x0B   12=0x0C   13=0x0D   14=0x0E   15=0x0F
//  16=0x10   17=0x11   18=0x12   19=0x13   20=0x14   21=0x15   22=0x16   23=0x17
//  24=0x18   25=0x19   26=0x1A   27=0x1B   28=0x1C   29=0x1D   30=0x1E   31=0x1F
//  32=0x20   33=0x21   34=0x22   35=0x23   36=0x24   37=0x25   38=0x26   39=0x27
//  40=0x28   41=0x29   42=0x2A   43=0x2B   44=0x2C   45=0x2D   46=0x2E   47=0x2F
//  48=0x30   49=0x31   50=0x32   51=0x33   52=0x34   53=0x35   54=0x36   55=0x37
//  56=0x38   57=0x39   58=0x3A   59=0x3B   60=0x3C   61=0x3D   62=0x3E   63=0x3F
//  64=0x40   65=0x41   66=0x42   67=0x43   68=0x44   69=0x45   70=0x46   71=0x47
//  72=0x48   73=0x49   74=0x4A   75=0x4B   76=0x4C   77=0x4D   78=0x4E   79=0x4F
//  80=0x50   81=0x51   82=0x52   83=0x53   84=0x54   85=0x55   86=0x56   87=0x57
//  88=0x58   89=0x59   90=0x5A   91=0x5B   92=0x5C   93=0x5D   94=0x5E   95=0x5F
//  96=0x60   97=0x61   98=0x62   99=0x63  100=0x64  101=0x65  102=0x66  103=0x67
// 104=0x68  105=0x69  106=0x6A  107=0x6B  108=0x6C  109=0x6D  110=0x6E  111=0x6F
// 112=0x70  113=0x71  114=0x72  115=0x73  116=0x74  117=0x75  118=0x76  119=0x77
// 120=0x78  121=0x79  122=0x7A  123=0x7B  124=0x7C  125=0x7D  126=0x7E  127=0x7F
// 128=0x80  129=0x81  130=0x82  131=0x83  132=0x84  133=0x85  134=0x86  135=0x87
// 136=0x88  137=0x89  138=0x8A  139=0x8B  140=0x8C  141=0x8D  142=0x8E  143=0x8F
// 144=0x90  145=0x91  146=0x92  147=0x93  148=0x94  149=0x95  150=0x96  151=0x97
// 152=0x98  153=0x99  154=0x9A  155=0x9B  156=0x9C  157=0x9D  158=0x9E  159=0x9F
// 160=0xA0  161=0xA1  162=0xA2  163=0xA3  164=0xA4  165=0xA5  166=0xA6  167=0xA7
// 168=0xA8  169=0xA9  170=0xAA  171=0xAB  172=0xAC  173=0xAD  174=0xAE  175=0xAF
// 176=0xB0  177=0xB1  178=0xB2  179=0xB3  180=0xB4  181=0xB5  182=0xB6  183=0xB7
// 184=0xB8  185=0xB9  186=0xBA  187=0xBB  188=0xBC  189=0xBD  190=0xBE  191=0xBF
// 192=0xC0  193=0xC1  194=0xC2  195=0xC3  196=0xC4  197=0xC5  198=0xC6  199=0xC7
// 200=0xC8  201=0xC9  202=0xCA  203=0xCB  204=0xCC  205=0xCD  206=0xCE  207=0xCF
// 208=0xD0  209=0xD1  210=0xD2  211=0xD3  212=0xD4  213=0xD5  214=0xD6  215=0xD7
// 216=0xD8  217=0xD9  218=0xDA  219=0xDB  220=0xDC  221=0xDD  222=0xDE  223=0xDF
// 224=0xE0  225=0xE1  226=0xE2  227=0xE3  228=0xE4  229=0xE5  230=0xE6  231=0xE7
// 232=0xE8  233=0xE9  234=0xEA  235=0xEB  236=0xEC  237=0xED  238=0xEE  239=0xEF
// 240=0xF0  241=0xF1  242=0xF2  243=0xF3  244=0xF4  245=0xF5  246=0xF6  247=0xF7
// 248=0xF8  249=0xF9  250=0xFA  251=0xFB  252=0xFC  253=0xFD  254=0xFE  255=0xFF
