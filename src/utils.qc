//
// Utils.qc
//
// This file contains a bunch of useful definitions and utilities.
//
// All code by J.P. Grossman unless otherwise commented.
//
float () match_prewar;
float () mode_is_arena;
void() utils_update_server_time;
void() utils_save_disconnect_log;
// from strings.qc
string(float v) strings_ftos_gold;
// --- prototypes needed by name overlay watcher ---
float (string a, string b) utils_str_eq;
void  (entity ent, string c_name) updatename;
void  (void () dofunc) utils_do_players;
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
    if (self.name_ready) { strunzone(self.name_ready); self.name_ready = string_null; }
    if (self.style & CLANRING_CONNECTED)
        updatename(self,self.netname);		
};

void (entity who) wait_name =
{
	local string text;
	local string temp;

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
	m = (floor( t / 60 ));
	tm = ftos(m);

	if ((self.style & CLANRING_READY) && (!(clanring_state & CLANRING_MATCH_STARTED)) && (!(clanring_state & CLANRING_MATCH_OVER)))
	{
		text = "\bReady AFK\b";
	}
	else
	{
		if (self.health < 1)
			text = "\bdead\b \bAFK\b";		
		else
		{
			if (t < clanring_afk_check)	//If someone manually typed 'afk' then indicate now.
				text = "\bAFK\b brb";
			else
			{
				if (((clanring_afk_timeout/60) - m) < 2)	//Display time as RED if less than two minutes left before being kicked...
					tm = redify(tm);
				text = sprintf("\bAFK\b %sm",tm);
			}
		}
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

void (entity client, float x) utils_sprint_time =
{
	local float  minutes;
	local float  seconds;
	local string temp;

	minutes = floor(x / 60);
	seconds = floor(((x/60) - minutes)*60);
	
	temp = ftos(minutes);
	
	sprint(client, temp);
	sprint(client, ":");
	
	temp = ftos(seconds);
	
	if (seconds < 10)
		sprint(client, "0");
	
	sprint(client, temp);
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

void () utils_dprint_time =
{
	local float t;
	local float hours;
	local float minutes;
	local float seconds;
	local string temp;

	t = 9932;
	hours   = floor(t/3600);
	minutes = floor(((t/3600)-hours)*60);
	seconds = floor(((((t/3600)-hours)*60)-minutes)*60);

	//--------------------
	temp = ftos(hours);
	if ((hours < 10))
	{
		bprint("0");
	}
	bprint(temp);
	//--------------------
	bprint(":");
	//--------------------
	temp = ftos(minutes);
	if ((minutes < 10))
	{
		bprint("0");
	}
	bprint(temp);
	//--------------------
	bprint(":");
	//--------------------
	temp = ftos(seconds);
	if ((seconds < 10))
	{
		bprint("0");
	}
	bprint(temp);
};

void (float t) utils_bprint_time =
{
	local float minutes;
	local float seconds;
	local float csec;
	local string temp;

//	hours   = floor(t/3600);
//	minutes = floor(((t/60)-hours)*60);	
//	seconds = floor(((((t/60)-hours)*60)-minutes)*60));

	minutes = floor((t/60));
	seconds = floor((((t/60)-minutes)*60));
	csec    = floor((((((t/60)-minutes)*60)-seconds)*100));
	
	//--------------------
	temp = ftos(minutes);
	if ((minutes < 10))
	   {
	      bprint("0");
	   }
	bprint(temp);
	//--------------------
	bprint(":");
	//--------------------
	temp = ftos(seconds);
	if ((seconds < 10))
	   {
	      bprint("0");
	   }
	bprint(temp);
	//--------------------
	bprint(".");
	//--------------------
	temp = ftos(csec);
	if ((csec < 10))
	   {
	      bprint("0");
	   }	
	bprint(temp);	
	//--------------------
};

//
// G E T   T I M E   M I N U T E S   A N D   S E C O N D S
//
// Returns a string of t in mm:ss format, t is seconds
//
string (float t) utils_get_time_m_s =
{
	float minutes, seconds = 0;
	string tmin="",tsec="";

	minutes = floor((t/60));
	seconds = floor((((t/60)-minutes)*60));

	if ((minutes < 10))
		tmin = sprintf("0%g", minutes);
	else
		tmin = sprintf("%g", minutes);

	if ((seconds < 10))
		tsec = sprintf("0%g", seconds);
	else
		tsec = sprintf("%g", seconds);

	return sprintf("%s:%s", tmin, tsec);
};

//	
// G E T   T I M E   w it h   M I L L I S E C O N D S
//
// Returns a string of t in mm:ss.ms format, t is seconds
//
string (float t) utils_get_time =
{
	local float minutes;
	local float seconds;
	local float csec;
	local string temp;
	local string tmin="",tsec="",tcsec="";

	minutes = floor((t/60));
	seconds = floor((((t/60)-minutes)*60));
	csec    = floor((((((t/60)-minutes)*60)-seconds)*100));

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

	temp = ftos(csec);
	if ((csec < 10))
		tcsec = sprintf("0%s", temp);
	else
		tcsec = temp;

		return sprintf("%s:%s.%s",tmin,tsec,tcsec);
};

// Print time with minimal leading zeros for diffs (e.g., "2.50" or "1:23.45")
// Uses strings_ftos_gold() for consistent gold coloring.
void(float t) utils_bprint_time_splitcolor =
{
    local float total, mins, secs, cs;
    local float tens, ones;

    if (t < 0) t = 0;

    // round to centiseconds
    total = floor(t * 100 + 0.5);
    mins  = floor(total / 6000);
    secs  = floor((total - mins * 6000) / 100);
    cs    = total - mins * 6000 - secs * 100;

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

    // centiseconds (no leading zero) - all gold
    tens = floor(cs / 10);
    ones = cs - tens * 10;

    if (tens > 0)
    {
        bprint(strings_ftos_gold(tens));
    }
    bprint(strings_ftos_gold(ones));
};

// Print MM:SS.CS with all digits in white (for capture times and records).
// No color codes, plain white text.
void(float t) utils_bprint_time_plain =
{
    local float total, mins, secs, cs;
    local float tens, ones;

    if (t < 0) t = 0;

    // round to centiseconds
    total = floor(t * 100 + 0.5);
    mins  = floor(total / 6000);
    secs  = floor((total - mins * 6000) / 100);
    cs    = total - mins * 6000 - secs * 100;

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

    // centiseconds (two digits) - all white
    tens = floor(cs / 10);
    ones = cs - tens * 10;
    bprint(ftos(tens));
    bprint(ftos(ones));
};

// Prints a signed delta with red sign and gold numbers (e.g., " +00:02.11" or " -00:00.45")
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
        else if (f >= 10000)  s="’";
	n = n - (d * 10000);
  	sprint(self, s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 1000) s="’";
     	n = n - (d * 1000);
  	sprint(self, s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 100)  s="’";
   	n = n - (d * 100);
  	sprint(self, s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) 	s = strings_ftos_gold(d);
   	else if (f >= 10) s="’";
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
        else if (f >= 10000)  s="’";
	n = n - (d * 10000);
  	bprint(s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 1000) s="’";
     	n = n - (d * 1000);
  	bprint(s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d)  s = strings_ftos_gold(d);
           else if (f >= 100)  s="’";
   	n = n - (d * 100);
  	bprint(s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) 	s = strings_ftos_gold(d);
   	else if (f >= 10) s="’";
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
//  P R I N T  V E C
//
//  Prints a vector followed by CR to 'self'.
//  Used for debugging.
//
void (vector v) utils_print_vec =
{
    local string s;

    s = vtos(v);
    sprint2(self, s, "\n");
};

//
//  P R I N T  B I T
//
//  Prints a single bit to 'self'.
//  Used for debugging.
//
void (float b) utils_print_bit =
{
    if (b)
        sprint(self, "1");
    else
        sprint(self, "0");
};

//
//  P R I N T  B I N
//
//  Prints a binary number followed by CR to 'self'.
//  Used for debugging.
//
void (float n) utils_print_bin =
{
    local float bit;

    if (!n)
    {
        sprint(self, "0\n");
        return;
    }

    bit = 32768 * 32768 * 2;
    while (bit > 0.5)
    {
        if (n & bit)
        {
            while (bit > 0.5)
            {
                utils_print_bit(n & bit);
                bit = bit / 2;
            }
        }
        bit = bit / 2;
    }
    sprint(self, "\n");
};


//
//  D U M P  P O S I T I O N
//
//  Dumps all 3d position information for an entity to 'self'.
//  Used for debugging.
//
void (entity e) utils_dump_position =
{
    sprint(self, "origin = ");
    utils_print_vec(e.origin);
    sprint(self, "mins = ");
    utils_print_vec(e.mins);
    sprint(self, "maxs = ");
    utils_print_vec(e.maxs);
    sprint(self, "size = ");
    utils_print_vec(e.size);
    sprint(self, "absmin = ");
    utils_print_vec(e.absmin);
    sprint(self, "absmax = ");
    utils_print_vec(e.absmax);
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
//  M A X 3
//
float (float a, float b, float c) utils_max3 =
{
    local float d;
    if (a > b)
        d = a;
    else
        d = b;
    if (d > c)
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

// CRMOD
// S T U F F  T O  P L A Y E R
//      by Paul Baker
//
//   stuffcmd's a message to the player by their entity number (status number).
//   this is used primarily to tell a person they've been kicked.
//

void (float i, string txt) utils_stuff_to_player =
{
	local entity e;

	e = find(world, classname, "player");
	while (e != world)
	{
		if (e.colormap == i)
		{
			stuffcmd(e, txt);
			return;
		}
		e = find(e, classname, "player");
	}
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

//Returns a random vector bewteen m1 and m2

vector (vector m1, vector m2) Rvec =
{
	local vector v;
	
	m2 = m2 - m1;
	
	v_x = m2_x * random() + m1_x;
	v_y = m2_y * random() + m1_y;
	v_z = m2_z * random() + m1_z;
	
	return  v;
};

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

float () items_are_ready =
{
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
    local float tl;

    secs = -1;

    if ((clanring_playmode & CLANRING_MATCH_MODE) && (clanring_state & CLANRING_MATCH_STARTED))
    {
        // 1) Primary: use clanring_sentinel.matchTime (authoritative match time tracker)
        tl = cvar("timelimit"); // minutes
        if (tl > 0 && clanring_sentinel.matchTime > 0)
        {
            // matchTime tracks current time during match
            // Calculate remaining from timelimit
            local float total_secs = tl * 60;
            local float elapsed = clanring_sentinel.matchTime;
            secs = total_secs - elapsed;
            if (secs < 0) secs = 0; // clamp to zero
        }
        
        // 2) Fallback: use boss countdown if matchTime is not available
        if (secs <= 0 && boss != world && boss.lip >= 0)
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

// Return TRUE if 'player_name' contains "player" anywhere (case-insensitive-ish).
// Note: If your QC supports strtolower(), replace the three checks with:
//   if (strstrofs(strtolower(player_name), "player", 0) >= 0) return TRUE;
float(string player_name) utils_name_has_player =
{
    if (player_name == "")
        return FALSE;

    // Best-effort case-insensitive substring checks for common casings
    if (strstrofs(player_name, "player", 0) >= 0) return TRUE;
    if (strstrofs(player_name, "Player", 0) >= 0) return TRUE;
    if (strstrofs(player_name, "PLAYER", 0) >= 0) return TRUE;
    return FALSE;
};

// Returns TRUE if 'player_name' matches any entry in the recent disconnect log
float(string player_name) utils_is_in_last_disconnects =
{
    local float i;
    if (player_name == "")
        return FALSE;

    for (i = 0; i < disconnect_log_count && i < MAX_CLIENT_DISCONNECT_LOG; i = i + 1)
    {
        if (disconnect_log[i].player_name != "" && utils_str_eq(disconnect_log[i].player_name, player_name))
            return TRUE;
    }
    return FALSE;
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

// Private, non-serverinfo storage for webhook URL configured via clanring.cfg
string clanring_captimesdiscordurl;
string clanring_statsdiscordurl;
float webhook_seq;

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

// Append segment with a hard cap, return new *zoned* msg (free old via zcat)
string(string msg, string seg, float maxlen) append_capped_z =
{
    local float rem;
    local string s, z;

    if (!msg) msg = strzone("");

    rem = maxlen - strlen(msg);
    if (rem <= 0) return msg;

    s = seg ? seg : "";
    if (strlen(s) > rem) s = substring(s, 0, rem);

    z = strzone(s);
    msg = zcat(msg, z);
    strunzone(z);
    return msg;
};

// JSON-escape into a *zoned* string (safe vs tempstring churn)
string(string s) json_escape_zoned_simple =
{
    local float i, n;
    local string out, ch, src;

    src = strzone(s);                // protect source
    out = strzone("");
    n   = strlen(src);

    for (i = 0; i < n; i = i + 1)
    {
        ch = substring(src, i, 1);  // tempstring ok; src is zoned
        if (ch == "\\")      out = zcat(out, "\\\\");
        else if (ch == "\"") out = zcat(out, "\\\"");
        else if (ch == "\n") out = zcat(out, "\\n");
        else if (ch == "\t") out = zcat(out, "\\t");
        else                 out = zcat(out, ch);
    }

    strunzone(src);
    return out; // zoned
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

// For legacy callers that want a tempstring payload (kept for compatibility)
string(string raw) Webhook_MakeContentPayload =
{
    local string s;
    s = raw ? raw : "";
    return sprintf("{\"content\":\"%s\"}", json_escape(s));
};

// Macro for capped appends
#define APPEND_SAFE(_segexpr) ( msg = append_capped_z(msg, (_segexpr), maxlen) )

// ------------------------------------------------------------
// Quake -> Discord sanitizer (preserve whitespace/padding)
// ------------------------------------------------------------
// - Fold 128..255 to 0..127 (avoid introducing C0 controls)
// - Map common QC control glyphs to ASCII
// - Drop remaining C0 controls except TAB(9) and LF(10)
// - Do NOT trim/collapse spaces
string(string s) utils_dequake_for_discord =
{
    local float i, j;
    if (!s) return "";

    // A) 128..255 -> 0..127 (red -> white). If target < 32, make '.'.
    for (i = 128; i <= 255; i = i + 1)
    {
        j = i - 128; // 0..127
        if (j < 32)
            s = strreplace(sprintf("%c", i), ".", s);
        else
            s = strreplace(sprintf("%c", i), sprintf("%c", j), s);
    }

    // B) Control glyphs ? readable
    s = strreplace(sprintf("%c", 1 ), ".", s);
    s = strreplace(sprintf("%c", 5 ), ".", s);
    s = strreplace(sprintf("%c", 14), ".", s);
    s = strreplace(sprintf("%c", 15), ".", s);
    s = strreplace(sprintf("%c", 28), ".", s);
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

// Compact helper: dequake -> json_escape
string(string s) discord_escape =
{
    if (!s) return "";
    return json_escape(utils_dequake_for_discord(s));
};

// Mask a secret URL for logs: keep head and tail only
string(string s) webhook_mask =
{
    local float n;
    if (!s) return "";
    n = strlen(s);
    if (n <= 20) return s;
    return strcat(substring(s, 0, 12), "...", substring(s, n - 4, 4));
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

// Keep content within Discord’s limit (budgeted lower for code blocks)
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

// Count ``` fences in a string
float(string s) Webhook_CountFences =
{
    local float count, pos;

    count = 0;
    pos = 0;
    while (TRUE)
    {
        pos = strstrofs(s, "```", pos);
        if (pos < 0) break;
        count = count + 1;
        pos = pos + 3;
    }

    return count;
};

// Split helper: prefer section boundaries and avoid cutting ``` fences
float(string s, float limit) Webhook_FindSplitPos =
{
    local float split_pos, search_start;
    local float n;

    n = strlen(s);
    if (limit < 1) limit = 1;
    if (n <= limit) return n;

    split_pos = -1;
    search_start = limit - 200;
    if (search_start < 100) search_start = 100;

    {
        local float i;
        for (i = limit - 1; i > search_start; i = i - 1)
        {
            if (substring(s, i, 1) == "\n")
            {
                local string nextch;
                nextch = substring(s, i + 1, 1);
                if (nextch == "*" || nextch == "`")
                {
                    split_pos = i + 1;
                    break;
                }
            }
        }
    }

    if (split_pos < 0)
    {
        local float j;
        for (j = limit - 1; j > 0; j = j - 1)
        {
            if (substring(s, j, 1) == "\n")
            {
                split_pos = j + 1;
                break;
            }
        }
    }

    if (split_pos < 0) split_pos = limit;

    while (split_pos > 0)
    {
        if (split_pos >= 2 && substring(s, split_pos - 2, 3) == "```") { split_pos = split_pos - 2; continue; }
        if (split_pos >= 1 && substring(s, split_pos - 1, 3) == "```") { split_pos = split_pos - 1; continue; }
        break;
    }

    if (split_pos < 1) split_pos = min(limit, n);
    return split_pos;
};

// ------------------------------------------------------------
// PREP functions
// ------------------------------------------------------------
void(entity ev) webhook_captime_info =
{
    local string url, content;

    content = utils_dequake_for_discord(ev.message);

    url = clanring_captimesdiscordurl;
    if (url == "") url = cvar_string("webhook_url");
    url = Webhook_SanitizeURL(url);
    if (url == "") return;

    if (strstrofs(url, "?", 0) < 0)           url = strcat(url, "?wait=true");
    else if (strstrofs(url, "wait=", 0) < 0)  url = strcat(url, "&wait=true");

    if (ev.hook_url) strunzone(ev.hook_url);
    ev.hook_url = strzone(url);

    if (strstrofs(content, "```", 0) < 0) content = strcat("```text\n", content, "```");
    content = Webhook_TruncateForDiscord(content);

    if (ev.hook_payload) strunzone(ev.hook_payload);
    ev.hook_payload = Webhook_MakeContentPayloadZ(content);
};

// Forward declaration (defined later in sender pipeline section)
void() webhook_do_post;

// Prep function for stats continuation parts (ev.message already contains the chunk)
void(entity ev) webhook_stats_continuation_info =
{
    local string url, content;

    content = ev.message;  // already zoned by caller

    url = clanring_statsdiscordurl;
    if (url == "") url = cvar_string("webhook_stats_url");
    url = Webhook_SanitizeURL(url);
    if (url == "") return;

    if (strstrofs(url, "?", 0) < 0)           url = strcat(url, "?wait=true");
    else if (strstrofs(url, "wait=", 0) < 0)  url = strcat(url, "&wait=true");

    if (ev.hook_url) strunzone(ev.hook_url);
    ev.hook_url = strzone(url);

    if (ev.hook_payload) strunzone(ev.hook_payload);
    ev.hook_payload = Webhook_MakeContentPayloadZ(content);
};

// Build and store a Discord "stats" message (safe against tempstring aliasing)
void(entity ev) webhook_stats_info =
{
    local string url, msg;
    local entity p;
    local float lines, maxlines;
    local float use_find; // choose player iteration strategy (arena uses find())
    local float is_arena;

    // efficiency helpers
    local float kfrac, ktot, wfrac, wtot;
    local string killpct, weappct;

    // shared scratch
    local string nm;
    local string hdr_time;
    local float m, s;
    local float hourpos;
    local float mins_norm, per_min, v;
    local float b1, b2, b3, b4, b5;

    // shared tempstring-safe buffers
    local string line;          // reusable line buffer
    local string zname;         // zoned name buffer
    local string z_mmss;        // zoned "mm:ss"
    local string mmss_tmp;      // temp "mm:ss" pre-zone
    local string ss_str;        // seconds (zero-padded)

    float maxlen; maxlen = 8000;  // build full message, then split later
    is_arena = mode_is_arena();
    use_find = is_arena || !(clanring_playmode & CLANRING_MATCH_MODE);

    // Resolve + sanitize URL
    url = clanring_statsdiscordurl;
    if (url == "") url = cvar_string("webhook_stats_url");
    url = Webhook_SanitizeURL(url);
    if (url == "") return;

    if (strstrofs(url, "?", 0) < 0)           url = strcat(url, "?wait=true");
    else if (strstrofs(url, "wait=", 0) < 0)  url = strcat(url, "&wait=true");

    if (ev.hook_url) strunzone(ev.hook_url);
    ev.hook_url = strzone(url);

    // -------------------------
    // Header (piecewise)
    // -------------------------
    msg = strzone("\n**Match Statistics**\n");
    hdr_time = utils_dequake_for_discord(strftime(TRUE, "%m-%d-%Y %I:%M %p"));
    if (substring(hdr_time, 0, 1) == "0")
        hdr_time = substring(hdr_time, 1, strlen(hdr_time) - 1);
    hourpos = strstrofs(hdr_time, " ", 0);
    if (hourpos >= 0 && substring(hdr_time, hourpos + 1, 1) == "0")
        hdr_time = strcat(substring(hdr_time, 0, hourpos + 1), substring(hdr_time, hourpos + 2, strlen(hdr_time) - (hourpos + 2)));
    APPEND_SAFE(hdr_time);
    APPEND_SAFE("\n");
    APPEND_SAFE(utils_dequake_for_discord(infokey(world, "hostname")));
    APPEND_SAFE("\n");
    APPEND_SAFE(utils_dequake_for_discord(mapname));  // just the map name
    APPEND_SAFE("\n");

    // Modes (no label/brackets)
    {
        local string modes;

        // Arena family first
        if      (clanring_playmode & CLANRING_RA_MODE)          modes = "Rocket Arena";
        else if (clanring_playmode & CLANRING_CA_MODE)          modes = "Clan Arena";
        else if (clanring_playmode & CLANRING_WIPEOUT_MODE)     modes = "Wipeout";
        else if (clanring_playmode & CLANRING_DMM4_MODE)        modes = "DMM4";
        else if (clanring_playmode & CLANRING_AIRSHOT_MODE)     modes = "Airshot";
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

        APPEND_SAFE(modes);
        APPEND_SAFE("\n\n");
    }

    // New CTF record note
    if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && (clanring_new_record_player != ""))
    {
        APPEND_SAFE(utils_dequake_for_discord(clanring_new_record_player));
        APPEND_SAFE(" set a new match capture record!\n\n");
    }

    #define PCT_STR(_frac,_tot) ( (_tot) > 0 ? sprintf("%g%%", floor(100 * (_frac) / (_tot))) : "N/A" )

    // ---- Efficiency (kill% / weap% | bul nls rox lg | fpm) ----
    APPEND_SAFE("**Efficiency (kill% / weap% | bul nls rox lg | fpm)**\n");
    APPEND_SAFE("```\n");
    {
        lines = 0; maxlines = 16;
        if (use_find) p = find(world, classname, "player");
        else p = clanring_sentinel.next_player;
        while (p && lines < maxlines)
        {
            if ((is_arena && p.next_team != world) ||
                (!is_arena && !(p.style & CLANRING_OBSERVER)))
            {
                // kill + weapon accuracy
                kfrac = p.true_kills;
                ktot  = kfrac + p.mangle_z;

                wtot  = p.dest1_x + p.dest1_y + p.dest1_z + p.dest_x;
                wfrac = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y;

                // per-weapon detail + frags per minute
                local float fpm_val;
                local string pct_bul, pct_nail, pct_rox, pct_lg, fpm_str;

                fpm_val = 0;
                if (p.join_time > 0)
                {
                    v = clanring_sentinel.matchTime;
                    if (v <= 0) v = time;
                    v = v - p.join_time;
                    if (v > 0) fpm_val = p.true_kills * 60 / v;
                }

                // ZONE tempstrings so later tempstrings (like names) don't alias them
                killpct = strzone(sprintf("%4s", PCT_STR(kfrac, ktot)));
                weappct = strzone(sprintf("%4s", PCT_STR(wfrac, wtot)));

                pct_bul  = strzone(sprintf("%4s", PCT_STR(p.dest2_x, p.dest1_x)));
                pct_nail = strzone(sprintf("%4s", PCT_STR(p.dest2_y, p.dest1_y)));
                pct_rox  = strzone(sprintf("%4s", PCT_STR(p.dest_y,  p.dest_x)));
                pct_lg   = strzone(sprintf("%4s", PCT_STR(p.dest2_z, p.dest1_z)));
                fpm_str  = strzone(sprintf("%4.1f", fpm_val));

                zname = strzone(utils_dequake_for_discord(p.netname));
                line = sprintf("%s / %s | %s %s %s %s | %s    ",
                               killpct, weappct,
                               pct_bul, pct_nail, pct_rox, pct_lg,
                               fpm_str);
                APPEND_SAFE(line);
                APPEND_SAFE(zname);
                APPEND_SAFE("\n");
                strunzone(killpct);
                strunzone(weappct);
                strunzone(pct_bul);
                strunzone(pct_nail);
                strunzone(pct_rox);
                strunzone(pct_lg);
                strunzone(fpm_str);
                strunzone(zname);
                lines = lines + 1;
                if (strlen(msg) > (maxlen - 120)) break;
            }
            if (use_find) p = find(p, classname, "player"); else p = p.next_player;
        }
    }
    APPEND_SAFE("```\n");

    // ---- K/D, damage, ewep ----
    APPEND_SAFE("\n**K/D | dmg given, dmg taken | ewep**\n");
    APPEND_SAFE("```\n");
    {
        local float k_seen, k_inc, k_obs, k_limit;
        k_seen = k_inc = k_obs = k_limit = 0;

        lines = 0; maxlines = 16;
        if (use_find) p = find(world, classname, "player");
        else p = clanring_sentinel.next_player;
        while (p && lines < maxlines)
        {
            k_seen += 1;

            if ((is_arena && p.next_team != world) ||
                (!is_arena && !(p.style & CLANRING_OBSERVER)))
            {
                nm = utils_dequake_for_discord(p.netname);
                APPEND_SAFE(sprintf("%g/%g | %g %g | %g    %s\n",
                                    p.true_kills, p.mangle_z,
                                    p.dmg_given,  p.dmg_taken,
                                    p.ewep,
                                    nm));
                k_inc += 1; lines += 1;
                if (strlen(msg) > (maxlen - 120)) { k_limit += 1; break; }
            }
            else if (p.style & CLANRING_OBSERVER) { k_obs += 1; }
            if (use_find) p = find(p, classname, "player"); else p = p.next_player;
        }
    }
    APPEND_SAFE("```\n");

    if (!mode_is_arena())
    {
        // ---- Bad stats (paks self% team% lava axe fall) ----
        {
            local float opened; opened = 0;
            local float b_seen, b_inc, b_obs, b_noteam, b_limit;
            b_seen = b_inc = b_obs = b_noteam = b_limit = 0;

            lines = 0; maxlines = 16;
            if (use_find) p = find(world, classname, "player");
            else p = clanring_sentinel.next_player;

            while (p && lines < maxlines)
            {
                b_seen += 1;

                if (p.style & CLANRING_OBSERVER) { b_obs += 1; }
                else if (p.next_team == world)   { b_noteam += 1; }
                else
                {
                    if (!opened) {
                        APPEND_SAFE("\n**Bad stats (paks self% team% lava axe fall)**\n\n");
                        APPEND_SAFE("```\n");
                        opened = 1;
                    }
                    // totals
                    local float tot_enemy = p.dest2_x + p.dest2_y + p.dest2_z + p.dest_y;
                    local float tot_done  = tot_enemy + p.clanring_badstats_y + p.clanring_badstats_z;

                    // percentages
                    local float self_pct = 0, team_pct = 0;
                    if (tot_done > 0)
                    {
                        self_pct = floor(100 * p.clanring_badstats_y / tot_done);
                        team_pct = floor(100 * p.clanring_badstats_z / tot_done);
                    }

                    // zone name to avoid tempstring aliasing
                    nm    = utils_dequake_for_discord(p.netname);
                    zname = strzone(nm);

                    // one-shot formatted line; name only at the end
                    line = sprintf(
                        "%g %g%% %g%% %g %g %g    %s\n",
                        p.clanring_badstats_x,       // paks
                        self_pct,                    // self %
                        team_pct,                    // team %
                        p.clanring_badstats2_x,      // lava
                        p.clanring_badstats2_y,      // axe
                        p.clanring_badstats2_z,      // fall
                        zname
                    );

                    APPEND_SAFE(line);
                    strunzone(zname);

                    b_inc += 1; lines += 1;
                    if (strlen(msg) > (maxlen - 120)) { b_limit += 1; break; }
                }

                if (use_find) p = find(p, classname, "player"); else p = p.next_player;
            }
        }
        // close if opened
        if (opened) APPEND_SAFE("```\n");

        // ---- Items (Q RA YA MG RL LG) ----
        {
            local float opened2; opened2 = 0;
            local float it_seen, it_inc, it_obs, it_noteam, it_limit;
            it_seen = it_inc = it_obs = it_noteam = it_limit = 0;

            lines = 0; maxlines = 16;
            if (use_find) p = find(world, classname, "player");
            else p = clanring_sentinel.next_player;

            while (p && lines < maxlines)
            {
                it_seen += 1;

                if (p.style & CLANRING_OBSERVER) { it_obs += 1; }
                else if (p.next_team == world)   { it_noteam += 1; }
                else
                {
                    if (!opened2) {
                        APPEND_SAFE("\n**Items (Q RA YA MG RL LG)**\n\n");
                        APPEND_SAFE("```\n");
                        opened2 = 1;
                    }
                    nm = utils_dequake_for_discord(p.netname);

                    // Q = number of Quads taken (clanring_qdwep_z)
                    APPEND_SAFE(sprintf("%g %g %g %g %g %g    %s\n",
                                        p.clanring_qdwep_z,          // Q
                                        p.stats_item_redarmor,       // RA
                                        p.stats_item_yellowarmor,    // YA
                                        p.stats_item_mega,           // MG
                                        p.stats_item_rl,             // RL
                                        p.stats_item_lg,             // LG
                                        nm));                        // name

                    it_inc += 1; lines += 1;
                    if (strlen(msg) > (maxlen - 120)) { it_limit += 1; break; }
                }

                if (clanring_playmode & CLANRING_MATCH_MODE) p = p.next_player;
                else p = find(p, classname, "player");
            }
        }
        if (opened2) APPEND_SAFE("```\n");

        // ---- PER (top-5, per-min) + inline reasons for #1 ----
        {
            local entity e1, e2, e3, e4, e5;
            local float opened3; opened3 = 0;
            b1 = b2 = b3 = b4 = b5 = -9999;
            e1 = e2 = e3 = e4 = e5 = world;

            if (use_find) p = find(world, classname, "player");
            else p = clanring_sentinel.next_player;
            while (p)
            {
                if (!(p.style & CLANRING_OBSERVER) && p.next_team != world && p.join_time > 0)
                {
                    mins_norm = max(1, (time - p.join_time) / 60);
                    per_min   = Q1_PER_Calc_Eff(p) / mins_norm;
                    v = per_min;

                    if (v > b1) { b5=b4; e5=e4; b4=b3; e4=e3; b3=b2; e3=e2; b2=b1; e2=e1; b1=v; e1=p; }
                    else if (v > b2) { b5=b4; e5=e4; b4=b3; e4=e3; b3=b2; e3=e2; b2=v; e2=p; }
                    else if (v > b3) { b5=b4; e5=e4; b4=b3; e4=e3; b3=v; e3=p; }
                    else if (v > b4) { b5=b4; e5=e4; b4=v; e4=p; }
                    else if (v > b5) { b5=v; e5=p; }
                }
                if (use_find) p = find(p, classname, "player"); else p = p.next_player;
            }

            if (e1 && e1 != world) { if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; } APPEND_SAFE(sprintf("1) %5.1f    %s\n", b1, utils_dequake_for_discord(e1.netname))); }
            if (e2 && e2 != world) { if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; } APPEND_SAFE(sprintf("2) %5.1f    %s\n", b2, utils_dequake_for_discord(e2.netname))); }
            if (e3 && e3 != world) { if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; } APPEND_SAFE(sprintf("3) %5.1f    %s\n", b3, utils_dequake_for_discord(e3.netname))); }
            if (e4 && e4 != world) { if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; } APPEND_SAFE(sprintf("4) %5.1f    %s\n", b4, utils_dequake_for_discord(e4.netname))); }
            if (e5 && e5 != world) { if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; } APPEND_SAFE(sprintf("5) %5.1f    %s\n", b5, utils_dequake_for_discord(e5.netname))); }

            // Inline reasons for #1 (same code fence)
            if (e1 && e1 != world)
            {
                if (!opened3) { APPEND_SAFE("\n**PER (top-5, per-min)**\n\n"); APPEND_SAFE("```\n"); opened3 = 1; }
                local entity ep; ep = e1;

                // per-minute normalizer
                local float per_mins = max(1, (time - ep.join_time) / 60);

                // recompute atomic terms (mirror of PER_PrintTop3Reasons), per-minute
                local float dmg_min   = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 142 : 100;
                local float res_coeff = (clanring_playmode & CLANRING_CAPTURE_THE_FLAG) ? 10  : 13;

                local float kd_spread  = ep.true_kills - ep.mangle_z;
                local float dmg_spread = ep.dmg_given - ep.dmg_taken;
                local float dmg_tokill = (ep.mangle_z > 0) ? (ep.dmg_taken / ep.mangle_z) : ep.dmg_taken;
                local float resilience = dmg_tokill / dmg_min;
                local float res_term   = res_coeff * max(0, pow(resilience, 1.2) - 1);

                local float T[20]; local float base, vv;
                T[0]  = (0.9 * kd_spread * pow(fabs(kd_spread), 0.1125)) / per_mins;         // big KD spread
                T[1]  = (0.6 * (dmg_spread / dmg_min)) / per_mins;                           // damage advantage
                T[2]  = res_term / per_mins;                                                 // hard-to-kill bonus
                T[3]  = (2.5 * ep.stats_powerup_denial_quad) / per_mins;                     // enemy Quad kills

                T[4]  = (2.0 * ep.totalquad) / per_mins;                                     // Quad control time
                T[5]  = (5.0 * ep.clanring_ptwep_z) / per_mins;                              // Pents taken
                T[6]  = (1.0 * ep.stats_item_ring) / per_mins;                               // Rings
                T[7]  = (0.30 * ep.stats_item_redarmor) / per_mins;                          // RA
                T[8]  = (0.10 * ep.stats_item_yellowarmor) / per_mins;                       // YA
                T[9]  = (0.15 * ep.stats_item_mega) / per_mins;                              // Megas
                T[10] = (0.20 * ep.stats_item_rl) / per_mins;                                // RL
                T[11] = (0.20 * ep.stats_item_lg) / per_mins;                                // LG
                base = 12;

                if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
                {
                    T[12] = (2.5 * ep.fcaptures + 0.55 * pow(ep.fcaptures, 1.125)) / per_mins; // captures
                    T[13] = (5.0 * pow(ep.fcarries_time / 60, 0.9)) / per_mins;                // long holds
                    T[14] = (1.5 * ep.fcfrags) / per_mins;                                     // carrier kills
                    T[15] = (0.25 * ep.freturns) / per_mins;                                   // returns
                    T[16] = (2.25 * ep.strategic_returns) / per_mins;                          // strategic returns
                    T[17] = (1.0 * ep.fdefenses + 0.23 * pow(ep.fdefenses, 1.10)) / per_mins;  // base defenses
                    T[18] = (1.0 * ep.fcdefenses) / per_mins;                                  // carrier defenses
                    base = 19;
                }

                // pick top-3 above a small threshold to avoid noise
                local float min_show = 0.25;
                local float r1v=-9999, r2v=-9999, r3v=-9999;
                local float i1=-1, i2=-1, i3=-1;
                {
                    local float ii;
                    for (ii = 0; ii < base; ii = ii + 1)
                    {
                        vv = T[ii];
                        if (vv <= min_show) continue;
                        if (vv > r1v) { r3v=r2v; i3=i2; r2v=r1v; i2=i1; r1v=vv; i1=ii; }
                        else if (vv > r2v) { r3v=r2v; i3=i2; r2v=vv; i2=ii; }
                        else if (vv > r3v) { r3v=vv; i3=ii; }
                    }
                }

                // quad control helper: show seconds held + pickup count
                local float quad_secs = floor(ep.totalquad + 0.5);
                local float quad_takes = ep.clanring_qdwep_z;
                local string quad_pickup_word; quad_pickup_word = "quad pickups";
                if (quad_takes == 1) quad_pickup_word = "quad pickup";

                // heading: keep within same fence
                APPEND_SAFE(sprintf("\nwhy %s led PER:\n", utils_dequake_for_discord(ep.netname)));

                // emit a line for each reason index
                if (i1 >= 0)
                {
                    if      (i1 == 0)  APPEND_SAFE(sprintf("  1) big KD spread (%g-%g) (+%3.1f/min)\n", ep.true_kills, ep.mangle_z, r1v));
                    else if (i1 == 1)  APPEND_SAFE(sprintf("  1) damage advantage (+%g) (+%3.1f/min)\n", dmg_spread, r1v));
                    else if (i1 == 2)  APPEND_SAFE(sprintf("  1) hard-to-kill bonus (~%3.1f dmg/life) (+%3.1f/min)\n", floor(dmg_tokill*10+0.5)/10, r1v));
                    else if (i1 == 3)  APPEND_SAFE(sprintf("  1) enemy Quad kills (%g) (+%3.1f/min)\n", ep.stats_powerup_denial_quad, r1v));
                    else if (i1 == 4)  APPEND_SAFE(sprintf("  1) Quad control time (%gs total; %g %s) (+%3.1f/min)\n", quad_secs, quad_takes, quad_pickup_word, r1v));
                    else if (i1 == 5)  APPEND_SAFE(sprintf("  1) Pents taken (%g) (+%3.1f/min)\n", ep.clanring_ptwep_z, r1v));
                    else if (i1 == 6)  APPEND_SAFE(sprintf("  1) Rings taken (%g) (+%3.1f/min)\n", ep.stats_item_ring, r1v));
                    else if (i1 == 7)  APPEND_SAFE(sprintf("  1) RA control (%g) (+%3.1f/min)\n", ep.stats_item_redarmor, r1v));
                    else if (i1 == 8)  APPEND_SAFE(sprintf("  1) YA pickups (%g) (+%3.1f/min)\n", ep.stats_item_yellowarmor, r1v));
                    else if (i1 == 9)  APPEND_SAFE(sprintf("  1) Megas taken (%g) (+%3.1f/min)\n", ep.stats_item_mega, r1v));
                    else if (i1 == 10) APPEND_SAFE(sprintf("  1) RL pickups (%g) (+%3.1f/min)\n", ep.stats_item_rl, r1v));
                    else if (i1 == 11) APPEND_SAFE(sprintf("  1) LG pickups (%g) (+%3.1f/min)\n", ep.stats_item_lg, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 12) APPEND_SAFE(sprintf("  1) flag captures (%g) (+%3.1f/min)\n", ep.fcaptures, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 13) { local float cm=floor(ep.fcarries_time/60); local float cs=ep.fcarries_time-cm*60; APPEND_SAFE(sprintf("  1) long flag holds (%g:%02g) (+%3.1f/min)\n", cm, cs, r1v)); }
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 14) APPEND_SAFE(sprintf("  1) carrier kills (%g) (+%3.1f/min)\n", ep.fcfrags, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 15) APPEND_SAFE(sprintf("  1) returns (%g) (+%3.1f/min)\n", ep.freturns, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 16) APPEND_SAFE(sprintf("  1) strategic returns (%g) (+%3.1f/min)\n", ep.strategic_returns, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 17) APPEND_SAFE(sprintf("  1) base defenses (%g) (+%3.1f/min)\n", ep.fdefenses, r1v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i1 == 18) APPEND_SAFE(sprintf("  1) carrier defenses (%g) (+%3.1f/min)\n", ep.fcdefenses, r1v));
                }
                if (i2 >= 0)
                {
                    if      (i2 == 0)  APPEND_SAFE(sprintf("  2) big KD spread (%g-%g) (+%3.1f/min)\n", ep.true_kills, ep.mangle_z, r2v));
                    else if (i2 == 1)  APPEND_SAFE(sprintf("  2) damage advantage (+%g) (+%3.1f/min)\n", dmg_spread, r2v));
                    else if (i2 == 2)  APPEND_SAFE(sprintf("  2) hard-to-kill bonus (~%3.1f dmg/life) (+%3.1f/min)\n", floor(dmg_tokill*10+0.5)/10, r2v));
                    else if (i2 == 3)  APPEND_SAFE(sprintf("  2) enemy Quad kills (%g) (+%3.1f/min)\n", ep.stats_powerup_denial_quad, r2v));
                    else if (i2 == 4)  APPEND_SAFE(sprintf("  2) Quad control time (%gs total; %g %s) (+%3.1f/min)\n", quad_secs, quad_takes, quad_pickup_word, r2v));
                    else if (i2 == 5)  APPEND_SAFE(sprintf("  2) Pents taken (%g) (+%3.1f/min)\n", ep.clanring_ptwep_z, r2v));
                    else if (i2 == 6)  APPEND_SAFE(sprintf("  2) Rings taken (%g) (+%3.1f/min)\n", ep.stats_item_ring, r2v));
                    else if (i2 == 7)  APPEND_SAFE(sprintf("  2) RA control (%g) (+%3.1f/min)\n", ep.stats_item_redarmor, r2v));
                    else if (i2 == 8)  APPEND_SAFE(sprintf("  2) YA pickups (%g) (+%3.1f/min)\n", ep.stats_item_yellowarmor, r2v));
                    else if (i2 == 9)  APPEND_SAFE(sprintf("  2) Megas taken (%g) (+%3.1f/min)\n", ep.stats_item_mega, r2v));
                    else if (i2 == 10) APPEND_SAFE(sprintf("  2) RL pickups (%g) (+%3.1f/min)\n", ep.stats_item_rl, r2v));
                    else if (i2 == 11) APPEND_SAFE(sprintf("  2) LG pickups (%g) (+%3.1f/min)\n", ep.stats_item_lg, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 12) APPEND_SAFE(sprintf("  2) flag captures (%g) (+%3.1f/min)\n", ep.fcaptures, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 13) { local float cm2=floor(ep.fcarries_time/60); local float cs2=ep.fcarries_time-cm2*60; APPEND_SAFE(sprintf("  2) long flag holds (%g:%02g) (+%3.1f/min)\n", cm2, cs2, r2v)); }
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 14) APPEND_SAFE(sprintf("  2) carrier kills (%g) (+%3.1f/min)\n", ep.fcfrags, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 15) APPEND_SAFE(sprintf("  2) returns (%g) (+%3.1f/min)\n", ep.freturns, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 16) APPEND_SAFE(sprintf("  2) strategic returns (%g) (+%3.1f/min)\n", ep.strategic_returns, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 17) APPEND_SAFE(sprintf("  2) base defenses (%g) (+%3.1f/min)\n", ep.fdefenses, r2v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i2 == 18) APPEND_SAFE(sprintf("  2) carrier defenses (%g) (+%3.1f/min)\n", ep.fcdefenses, r2v));
                }
                if (i3 >= 0)
                {
                    if      (i3 == 0)  APPEND_SAFE(sprintf("  3) big KD spread (%g-%g) (+%3.1f/min)\n", ep.true_kills, ep.mangle_z, r3v));
                    else if (i3 == 1)  APPEND_SAFE(sprintf("  3) damage advantage (+%g) (+%3.1f/min)\n", dmg_spread, r3v));
                    else if (i3 == 2)  APPEND_SAFE(sprintf("  3) hard-to-kill bonus (~%3.1f dmg/life) (+%3.1f/min)\n", floor(dmg_tokill*10+0.5)/10, r3v));
                    else if (i3 == 3)  APPEND_SAFE(sprintf("  3) enemy Quad kills (%g) (+%3.1f/min)\n", ep.stats_powerup_denial_quad, r3v));
                    else if (i3 == 4)  APPEND_SAFE(sprintf("  3) Quad control time (%gs total; %g %s) (+%3.1f/min)\n", quad_secs, quad_takes, quad_pickup_word, r3v));
                    else if (i3 == 5)  APPEND_SAFE(sprintf("  3) Pents taken (%g) (+%3.1f/min)\n", ep.clanring_ptwep_z, r3v));
                    else if (i3 == 6)  APPEND_SAFE(sprintf("  3) Rings taken (%g) (+%3.1f/min)\n", ep.stats_item_ring, r3v));
                    else if (i3 == 7)  APPEND_SAFE(sprintf("  3) RA control (%g) (+%3.1f/min)\n", ep.stats_item_redarmor, r3v));
                    else if (i3 == 8)  APPEND_SAFE(sprintf("  3) YA pickups (%g) (+%3.1f/min)\n", ep.stats_item_yellowarmor, r3v));
                    else if (i3 == 9)  APPEND_SAFE(sprintf("  3) Megas taken (%g) (+%3.1f/min)\n", ep.stats_item_mega, r3v));
                    else if (i3 == 10) APPEND_SAFE(sprintf("  3) RL pickups (%g) (+%3.1f/min)\n", ep.stats_item_rl, r3v));
                    else if (i3 == 11) APPEND_SAFE(sprintf("  3) LG pickups (%g) (+%3.1f/min)\n", ep.stats_item_lg, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 12) APPEND_SAFE(sprintf("  3) flag captures (%g) (+%3.1f/min)\n", ep.fcaptures, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 13) { local float cm3=floor(ep.fcarries_time/60); local float cs3=ep.fcarries_time-cm3*60; APPEND_SAFE(sprintf("  3) long flag holds (%g:%02g) (+%3.1f/min)\n", cm3, cs3, r3v)); }
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 14) APPEND_SAFE(sprintf("  3) carrier kills (%g) (+%3.1f/min)\n", ep.fcfrags, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 15) APPEND_SAFE(sprintf("  3) returns (%g) (+%3.1f/min)\n", ep.freturns, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 16) APPEND_SAFE(sprintf("  3) strategic returns (%g) (+%3.1f/min)\n", ep.strategic_returns, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 17) APPEND_SAFE(sprintf("  3) base defenses (%g) (+%3.1f/min)\n", ep.fdefenses, r3v));
                    else if ((clanring_playmode & CLANRING_CAPTURE_THE_FLAG) && i3 == 18) APPEND_SAFE(sprintf("  3) carrier defenses (%g) (+%3.1f/min)\n", ep.fcdefenses, r3v));
                }
            }
        }
        if (opened3) APPEND_SAFE("```\n");
    }

    // ---- CTF ----
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
    {
        {
            local float opened4; opened4 = 0;
            lines = 0; maxlines = 16;
            if (use_find) p = find(world, classname, "player");
            else p = clanring_sentinel.next_player;

            while (p && lines < maxlines)
            {
                if (!(p.style & CLANRING_OBSERVER) && p.next_team != world)
                {
                    if (!opened4) {
                        APPEND_SAFE("\n**CTF (cap rtn def cdef cfrg hold)**\n");
                        APPEND_SAFE("```\n");
                        opened4 = 1;
                    }
                    m = floor(p.fcarries_time / 60);
                    s = p.fcarries_time - m * 60;

                    // Build mm:ss and ZONE it (avoid %02g and temp aliasing)
                    ss_str   = ftos(s);
                    if (s < 10) ss_str = strcat("0", ss_str);
                    mmss_tmp = strcat(ftos(m), ":", ss_str);
                    z_mmss   = strzone(mmss_tmp);

                    // Dequake name and ZONE it (avoid aliasing)
                    nm    = utils_dequake_for_discord(p.netname);
                    zname = strzone(nm);

                    // One-shot format using only zoned/safe args
                    line = sprintf(
                        "%g %g %g %g %g %s    %s\n",
                        p.fcaptures, p.freturns, p.fdefenses, p.fcdefenses, p.fcfrags,
                        z_mmss, zname
                    );

                    APPEND_SAFE(line);

                    // cleanup
                    strunzone(z_mmss);
                    strunzone(zname);

                    lines = lines + 1;
                    if (strlen(msg) > (maxlen - 120)) break;
                }
                if (use_find) p = find(p, classname, "player"); else p = p.next_player;
            }
        }
        if (opened4) APPEND_SAFE("```\n");
    }

    // Normalize newlines/tabs, then split into multiple Discord messages if needed
    {
        local string prepared;
        local float discord_limit;
        local float part_num, delay_offset;
        local float carry_code;
        local entity continuation_ev;

        prepared = strreplace("\r\n", "\n", msg);
        prepared = strreplace("\r", "\n", prepared);
        prepared = strreplace("\t", "    ", prepared);

        discord_limit = 1900;  // safe limit under Discord's 2000

        part_num = 1;
        delay_offset = 0;
        carry_code = 0;

        while (strlen(prepared) > 0)
        {
            local string prefix, chunk_body, chunk_send, remainder, suffix;
            local float prefix_len, split_pos, fence_count;
            local float end_in_code, suffix_len;

            if (carry_code) { prefix = "```\n"; prefix_len = 4; }
            else { prefix = ""; prefix_len = 0; }

            split_pos = Webhook_FindSplitPos(prepared, discord_limit - prefix_len);
            chunk_body = substring(prepared, 0, split_pos);

            fence_count = Webhook_CountFences(chunk_body);
            end_in_code = carry_code;
            if (fence_count - floor(fence_count / 2) * 2 == 1)
                end_in_code = carry_code ? 0 : 1;

            suffix = "";
            suffix_len = 0;

            if (end_in_code)
            {
                if (strlen(chunk_body) > 0 && substring(chunk_body, strlen(chunk_body) - 1, 1) == "\n")
                {
                    suffix = "```";
                    suffix_len = 3;
                }
                else
                {
                    suffix = "\n```";
                    suffix_len = 4;
                }

                if (split_pos + prefix_len + suffix_len > discord_limit)
                {
                    split_pos = Webhook_FindSplitPos(prepared, discord_limit - prefix_len - suffix_len);
                    chunk_body = substring(prepared, 0, split_pos);

                    fence_count = Webhook_CountFences(chunk_body);
                    end_in_code = carry_code;
                    if (fence_count - floor(fence_count / 2) * 2 == 1)
                        end_in_code = carry_code ? 0 : 1;

                    if (end_in_code)
                    {
                        if (strlen(chunk_body) > 0 && substring(chunk_body, strlen(chunk_body) - 1, 1) == "\n")
                            suffix = "```";
                        else
                            suffix = "\n```";
                    }
                    else
                    {
                        suffix = "";
                    }
                }
            }

            chunk_send = prefix;
            chunk_send = strcat(chunk_send, chunk_body);
            if (end_in_code) chunk_send = strcat(chunk_send, suffix);

            remainder = substring(prepared, split_pos, strlen(prepared) - split_pos);

            if (end_in_code)
            {
                if (strlen(remainder) >= 3 && substring(remainder, 0, 3) == "```")
                {
                    remainder = substring(remainder, 3, strlen(remainder) - 3);
                    if (strlen(remainder) > 0 && substring(remainder, 0, 1) == "\n")
                        remainder = substring(remainder, 1, strlen(remainder) - 1);
                    end_in_code = 0;
                }
                else if (strlen(remainder) >= 4 && substring(remainder, 0, 4) == "\n```")
                {
                    remainder = substring(remainder, 4, strlen(remainder) - 4);
                    if (strlen(remainder) > 0 && substring(remainder, 0, 1) == "\n")
                        remainder = substring(remainder, 1, strlen(remainder) - 1);
                    end_in_code = 0;
                }
            }

            if (part_num == 1)
            {
                if (ev.hook_payload) strunzone(ev.hook_payload);
                ev.hook_payload = Webhook_MakeContentPayloadZ(chunk_send);
            }
            else
            {
                continuation_ev = spawn();
                continuation_ev.classname = "webhook_event";
                continuation_ev.message = strzone(chunk_send);
                continuation_ev.webhook_prepfn = webhook_stats_continuation_info;
                continuation_ev.nextthink = time + 0.5 + delay_offset;
                continuation_ev.think = webhook_do_post;
                delay_offset = delay_offset + 0.5;
            }

            prepared = remainder;
            part_num = part_num + 1;
            carry_code = end_in_code;
        }
    }
    if (msg) strunzone(msg);
    #undef PCT_STR
};


// ------------------------------------------------------------
// Sender pipeline (deferred + dedupe)
// ------------------------------------------------------------
#define WEBHOOK_DEBUG   0
#define WEBHOOK_DEDUPE  1

float  webhook_dedupe_until;
string webhook_last_fingerprint;

float(string url, string payload) Webhook_AllowSend =
{
    local float n1, n2;
    local string url_head, payload_head, fp;

    n1 = strlen(url);     if (n1 > 64)  n1 = 64;
    n2 = strlen(payload); if (n2 > 256) n2 = 256;

    url_head     = substring(url, 0, n1);
    payload_head = substring(payload, 0, n2);
    fp = strcat(url_head, "\n", payload_head);

    if (webhook_last_fingerprint != "" && fp == webhook_last_fingerprint && time < webhook_dedupe_until)
        return FALSE;

    if (webhook_last_fingerprint) strunzone(webhook_last_fingerprint);
    webhook_last_fingerprint = strzone(fp);
    webhook_dedupe_until = time + 2.0;
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

        // 2) POST once if both fields present
        if (ev.hook_url != "" && ev.hook_payload != "")
        {
#if WEBHOOK_DEDUPE
            if (Webhook_AllowSend(ev.hook_url, ev.hook_payload)) {
                webhook_post(ev.hook_url, ev.hook_payload);
                posted = TRUE;
            }
#else
            webhook_post(ev.hook_url, ev.hook_payload);
            posted = TRUE;
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
// Match POST (JSON) — single knob
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

// Resolve a relative file (like "json/foo.json") to something the engine's fopen() can see.
// Order: fs_gamedir -> (fs_basedir + '/' + game) -> (game + '/') -> "id1/" fallback.
string(string rel) mp_resolve_for_engine =
{
    if (!rel || rel == "") return rel;
    local string gdir = cvar_string("fs_gamedir");
    local string bdir = cvar_string("fs_basedir");
    local string mod  = cvar_string("game");
    // Prefer an absolute fs_gamedir if available
    if (gdir && gdir != "")
        return strcat(gdir, "/", rel);
    // Next: base dir + game
    if (bdir && bdir != "" && mod && mod != "")
        return strcat(bdir, "/", mod, "/", rel);
    // Next: just the game subdir
    if (mod && mod != "")
        return strcat(mod, "/", rel);
    // Fallback: id1
    return strcat("id1/", rel);
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

    // --- Webhook posts (9100–9199) -----------------------------------------
    if (reqid >= 9100 && reqid < 9200)
    {
        if (responsecode >= 200 && responsecode < 300) {
            dprint(sprintf("WEBHOOK %f OK (%g)\n", reqid, responsecode));
        } else if (responsecode == 429) {
            bprint(sprintf("WEBHOOK %f rate-limited (429). Consider slowing or batching.\n", reqid));
        } else {
            dprint(sprintf("WEBHOOK %f HTTP %g (bytes=%g)\n", reqid, responsecode, bytes));
            L = bytes; if (L > 200) L = 200;
            if (L > 0) { dprint(substring(resourcebody, 0, L)); dprint("\n"); }
        }
        return;
    }

    // --- MATCH posts (9300–9399) ------------------------------------------
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
                // Show a tiny head so we know we’re pointing at the JSON file we just wrote
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

// Helpers: format a delta (in seconds) as a friendly "ago" string.
// Examples: "1 Minute Ago", "12 Minutes Ago", "2 Hours Ago", "1 Day Ago"
string(float dt) utils_fmt_ago =
{
    // ----- Smart "Ago" string: clamp tiny deltas to 1 minute -----
    string ago;
    if (dt < 60)
    {
        ago = "1 Minute Ago";
    }
    else if (dt < 3600)
    {
        float mins = floor(dt / 60);
        if (mins < 1) mins = 1;
        ago = (mins == 1) ? "1 Minute Ago" : strcat(ftos(mins), " Minutes Ago");
    }
    else if (dt < 86400)
    {
        float hours = floor(dt / 3600);
        ago = (hours == 1) ? "1 Hour Ago" : strcat(ftos(hours), " Hours Ago");
    }
    else if (dt < 604800)
    {
        float days = floor(dt / 86400);
        ago = (days == 1) ? "1 Day Ago" : strcat(ftos(days), " Days Ago");
    }
    else
    {
        float weeks = floor(dt / 604800);
        ago = (weeks == 1) ? "1 Week Ago" : strcat(ftos(weeks), " Weeks Ago");
    }
    return ago;
};

// Truncate helper for neat headers (UTF-8 naive, fine for ASCII names)
string(string s, float maxlen) utils_trunc =
{
    if (!s) return "";
    if (strlen(s) <= maxlen) return s;
    return sprintf("%s...", substring(s, 0, maxlen - 3));
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
    return utils_qf_chr(156); // ·
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

// Result (no spaces touching brackets): [when_ago · MODE · map_name]
string(string when_ago, string map_name, string raw_mode) format_match_header =
{
    string sep = strcat(" ", utils_qf_dot(), " "); // " · "
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