//
// Utils.qc
//
// This file contains a bunch of useful definitions and utilities.
//
// All code by J.P. Grossman unless otherwise commented.
//
float () match_prewar;
float () mode_is_arena;
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
	self.name_ready = strpad(16, substring(self.netname, 0, 15));
	self.name_ready = strcat(self.name_ready, status);	

}

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
	if (self.style & CLANRING_CONNECTED)
		updatename(self,self.netname);		
};

void (entity who) wait_name =
{
	local string text;

	text = " \bwaiting\b";
	who.name_ready = strpad(16, who.netname);
	who.name_ready = strcat (who.name_ready, text);
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
		localcmd("0");
	s = ftos(n);
	localcmd(s);
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
	localcmd(":");
	//--------------------
	utils_cprint_int2 (seconds);
	//--------------------
	localcmd(":");
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
  	localcmd(s);

//-- f>1000
	d = floor(n / 1000);
   	temp = floor(n / 1000);
   	s = " ";
   	if (d) s = ftos(d);
           else if (f >= 1000) s="0";
     	n = n - (d * 1000);
  	localcmd(s);
  	
//-- f>100
   	d = floor(n / 100);
   	temp = floor(n / 100);
   	s = " ";
   	if (d) s = ftos(d);
           else if (f >= 100)  s="0";
   	n = n - (d * 100);
  	localcmd(s);
  	
//-- f>10
   	d = floor(n / 10);
           s = " ";
   	if (temp || d) s = ftos(d);
   	else if (f >= 10) s="0";
           n = n - (d * 10);     
  	localcmd(s);
   	
// < 10   	
   	s = ftos(d);
  	localcmd(s);
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
            localcmd("-99");
        else if (n > -10)
            localcmd(" ");
    }
    else
    {
        if (n < 100)
            localcmd(" ");
        if (n < 10)
            localcmd(" ");
    }
    s = ftos(n);
    localcmd(s);
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

