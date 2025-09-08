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

// Private, non-serverinfo storage for webhook URL configured via clanring.cfg
string clanring_captimesdiscordurl;
float webhook_seq;

string(string s) discord_escape =
{
    // Discord/JSON-safe escaping for content strings

    // 1) Strip control bytes that can break JSON/UTF-8 or cause weirdness
    //    - ESC (0x1B), DEL (0x7F), and C1 controls (0x80–0x9F)
    s = strreplace("\x1B", "", s); // ESC
    s = strreplace("\x7F", "", s); // DEL
    s = strreplace("\x80", "", s);
    s = strreplace("\x81", "", s);
    s = strreplace("\x82", "", s);
    s = strreplace("\x83", "", s);
    s = strreplace("\x84", "", s);
    s = strreplace("\x85", "", s);
    s = strreplace("\x86", "", s);
    s = strreplace("\x87", "", s);
    s = strreplace("\x88", "", s);
    s = strreplace("\x89", "", s);
    s = strreplace("\x8A", "", s);
    s = strreplace("\x8B", "", s);
    s = strreplace("\x8C", "", s);
    s = strreplace("\x8D", "", s);
    s = strreplace("\x8E", "", s);
    s = strreplace("\x8F", "", s);
    s = strreplace("\x90", "", s);
    s = strreplace("\x91", "", s);
    s = strreplace("\x92", "", s);
    s = strreplace("\x93", "", s);
    s = strreplace("\x94", "", s);
    s = strreplace("\x95", "", s);
    s = strreplace("\x96", "", s);
    s = strreplace("\x97", "", s);
    s = strreplace("\x98", "", s);
    s = strreplace("\x99", "", s);
    s = strreplace("\x9A", "", s);
    s = strreplace("\x9B", "", s);
    s = strreplace("\x9C", "", s);
    s = strreplace("\x9D", "", s);
    s = strreplace("\x9E", "", s);
    s = strreplace("\x9F", "", s);

    // 2) Normalize newlines
    s = strreplace("\r", "\n", s);

    // 3) JSON-escape special characters
    s = strreplace("\\", "\\\\", s);
    s = strreplace("\"", "\\\"", s);
    s = strreplace("\n", "\\n", s);
    s = strreplace("\t", "\\t", s);

    return s;
};

void(string content) webhook_post =
{
    local string url, body, payload;
    local float ok, id;

    // Prefer private configured value from clanring.cfg; fallback to legacy cvar
    url = clanring_captimesdiscordurl;
    if (url == "")
        url = cvar_string("webhook_url");

    // Sanitize accidental leading '@' and trim simple whitespace
    if (substring(url, 0, 1) == "@")
        url = substring(url, 1, strlen(url) - 1);
    while (strlen(url) > 0 && substring(url, 0, 1) == " ")
        url = substring(url, 1, strlen(url) - 1);
    while (strlen(url) > 0 && substring(url, strlen(url) - 1, 1) == " ")
        url = substring(url, 0, strlen(url) - 1);

    // Abort cleanly if no URL configured
    if (url == "")
    {
        if (cvar("webhook_debug") > 0)
            dprint("webhook: no URL set (set 'captimesdiscordurl' in configs/clanring.cfg or cvar \"webhook_url\"). Skipping send.\n");
        return;
    }

    // Basic schema sanity check
    if (!(substring(url, 0, 8) == "https://" || substring(url, 0, 7) == "http://"))
    {
        dprint("webhook: invalid URL scheme; must start with http:// or https://\n");
        return;
    }

    // Ensure wait=true for Discord to return a payload reliably
    if (strstrofs(url, "?", 0) < 0)
        url = strcat(url, "?wait=true");
    else if (strstrofs(url, "wait=", 0) < 0)
        url = strcat(url, "&wait=true");

    // Build minimal payload first; some Discord setups reject extra fields
    body = discord_escape(content);
    payload = sprintf("{\"content\":\"%s\"}", body);

    webhook_seq = webhook_seq + 1;
    id = 9100 + webhook_seq;

    if (cvar("webhook_debug") > 0)
    {
        dprint(sprintf("Discord webhook POST id=%g, len=%g\n", id, strlen(payload)));
        if (cvar("webhook_debug") > 1)
        {
            // Do not print full URL to keep webhook private
            dprint("URL: [hidden]\n");
            dprint(sprintf("Payload: %s\n", substring(payload, 0, min(strlen(payload), 200))));
        }
    }

    ok = uri_get(url, id, "application/json", payload);
    if (!ok)
        dprint("webhook POST not accepted\n");
};

void() webhook_do_post =
{
	local entity ev;
	local string payload;

	ev = self;
	payload = ev.message;
	if (payload != "")
	{
        // Send and avoid spamming repeated posts if many records happen quickly
        if (cvar("webhook_debug") > 0)
        {
            dprint(sprintf("Deferred Discord webhook len=%g\n", strlen(payload)));
        }
        webhook_post(payload);
		strunzone(ev.message);
	}
	remove(ev);
};

void(string content) webhook_post_deferred =
{
	local entity ev;
	ev = spawn();
    ev.classname = "webhook_event";
	ev.message = strzone(content);
    ev.nextthink = time + 0.5;
    ev.think = webhook_do_post;
};


// Engine callback for all uri_get requests from this VM

void(float reqid, float responsecode, string resourcebody, int resourcebytes) URI_Get_Callback =
{
    local float L, bytes, dp_style;

    // Transport failure (socket, DNS, etc.)
    if (responsecode < 0)
    {
        bprint(sprintf("URI %f transport failure (code=%g)\n", reqid, responsecode));
        return;
    }

    // Detect DP-style callback routed through FTE-style declaration:
    // resourcebytes often 0/garbage and resourcebody contains content-type.
    dp_style = 0;
    if (resourcebytes <= 0 && (resourcebody == "application/json"
                            || resourcebody == "text/plain"
                            || resourcebody == "application/json; charset=UTF-8"))
        dp_style = 1;

    // Compute bytes from what we actually have (safe even if dp_style)
    bytes = strlen(resourcebody);

    // --- Test GET (9001) ----------------------------------------------------
    if (reqid == 9001)
    {
        if (dp_style)
        {
            bprint(sprintf("GET %f OK, type=%s\n", reqid, resourcebody));
        }
        else
        {
            bprint(sprintf("GET %f OK, bytes=%g\n", reqid, bytes));
            L = strlen(resourcebody);
            if (L > 200) L = 200;
            bprint(substring(resourcebody, 0, L));
            bprint("\n");
        }
        return;
    }

    // --- Test POST (9002) ---------------------------------------------------
    if (reqid == 9002)
    {
        if (dp_style)
        {
            bprint(sprintf("POST %f OK, type=%s\n", reqid, resourcebody));
        }
        else
        {
            bprint(sprintf("POST %f OK, bytes=%g\n", reqid, bytes));
            L = strlen(resourcebody);
            if (L > 200) L = 200;
            bprint(substring(resourcebody, 0, L));
            bprint("\n");
        }
        return;
    }

    // --- Webhook posts (9100–9199) -----------------------------------------
    if (reqid >= 9100 && reqid < 9200)
    {
        if (responsecode >= 200 && responsecode < 300)
        {
            dprint(sprintf("WEBHOOK %f OK (%g)\n", reqid, responsecode));
        }
        else if (responsecode == 429)
        {
            bprint(sprintf("WEBHOOK %f rate-limited (429). Consider slowing or batching.\n", reqid));
        }
        else
        {
            dprint(sprintf("WEBHOOK %f HTTP %g (bytes=%g)\n", reqid, responsecode, bytes));
            if (!dp_style)
            {
                L = strlen(resourcebody);
                if (L > 200) L = 200;
                dprint(substring(resourcebody, 0, L));
                dprint("\n");
            }
        }
        return;
    }

    // --- Default path -------------------------------------------------------
    if (dp_style)
    {
        dprint(sprintf("URI %f OK, type=%s, status=%g\n", reqid, resourcebody, responsecode));
    }
    else
    {
        dprint(sprintf("URI %f status=%g, bytes=%g\n", reqid, responsecode, bytes));
        L = strlen(resourcebody);
        if (L > 200) L = 200;
        dprint(substring(resourcebody, 0, L));
        dprint("\n");
    }
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