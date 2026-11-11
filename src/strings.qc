//
// Strings.qc
//
// A bunch of routines for returning various strings.
// Several routines were inspired by the clanring server mod.
//
// All code by J.P. Grossman unless otherwise commented.
//

//
//  F T O S
//
//  Some numbers have been hard-coded to avoid the problems associated with
//  a single ftosbuffer.
//
string (float n) strings_ftos=
{
	return (ftos(n));
};

//
//  F T O S  G O L D
//
//  Return some gold number strings.
//
string (float n) strings_ftos_gold =
{
	local float d1, d2, d3, t1;
	if (n > 999)
	{
		return ftos(n); //sol for now
	}
	else if (n > 99)
	{
		d1 = n % 10;
		t1 = (n - d1) / 10;
		d2 = t1 % 10;
		d3 = (t1 - d2) / 10;
		return sprintf("%s%s%s", chr2str(18+d3), chr2str(18+d2), chr2str(18+d1));
	}
	else if (n > 9)
	{
		d1 = n % 10;
		d2 = (n - d1) / 10;
		return sprintf("%s%s", chr2str(18+d2), chr2str(18+d1));
	}
	return chr2str(18+n);
};

string (float n) strings_ftos_bronze =
{
	local string temp;
	temp = sprintf("%-2g", floor(n));
	return temp;
};

//
//  G E T  A R M O U R  V A L
//
//  Returns a string containing the amount of armour the player has.
//  Used for observer mode heads-up display.
//
string (entity e) strings_get_armour_val =
{
	local string temp = "";

    if (e.items & IT_INVULNERABILITY)
        return "\<\6\6\6\>";
	temp = sprintf("%03g", e.armorvalue);
	return temp;
};

//
//  G E T  A R M O U R  T Y P E
//
//  Returns one of
//
//     "Armour: R "
//     "Armour: Y "
//     "Armour: G "
//     "Armour: "
//
//  Used for observer mode heads-up display.
//
string (entity e) strings_get_armour_type =
{

    ///if (e.items & IT_INVULNERABILITY) return "\xC1\xF2\xED\xEF\xF2\xBA ";
    if (e.armortype == 0.8) return "\xC1\xF2\xED\xEF\xF2\xBA R ";
    if (e.armortype == 0.6) return "\xC1\xF2\xED\xEF\xF2\xBA Y ";
    if (e.armortype == 0.3) return "\xC1\xF2\xED\xEF\xF2\xBA G ";
    return "\xC1\xF2\xED\xEF\xF2\xBA ";
};

//
//  G E T  W E A P O N
//
//  Returns "[QOR] <weapon>\n" where [QOR] are the quad, ring and
//  suit flags (either present or absent) and <weapon> is the player's
//  weapon (I'm sure you were having trouble figuring that one out).
//  Used for observer mode heads-up display.
//
string (entity e) strings_get_weapon =
{
    if (e.items & IT_SUIT)
    {
        if (e.items & IT_QUAD)
        {
            if (e.items & IT_INVISIBILITY)
            {
                if (e.weapon == 32) return " \x9DQ\x92\x83\x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9DQ\x92\x83\x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9DQ\x92\x83\x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9DQ\x92\x83\x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9DQ\x92\x83\x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9DQ\x92\x83\x91 Nailgun\n";
                if (e.weapon == 1) return " \x9DQ\x92\x83\x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9DQ\x92\x83\x91 Axe\n";
                return " \x9DQ\x92\x83\x91 No Weapon\n";
            }
            else
            {
                if (e.weapon == 32) return " \x9DQ \x83\x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9DQ \x83\x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9DQ \x83\x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9DQ \x83\x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9DQ \x83\x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9DQ \x83\x91 Nailgun\n";
                if (e.weapon == 1) return " \x9DQ \x83\x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9DQ \x83\x91 Axe\n";
                return " \x9DQ \x83\x91 No Weapon\n";
            }
        }
        else
        {
            if (e.items & IT_INVISIBILITY)
            {
                if (e.weapon == 32) return " \x9D \x92\x83\x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9D \x92\x83\x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9D \x92\x83\x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9D \x92\x83\x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9D \x92\x83\x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9D \x92\x83\x91 Nailgun\n";
                if (e.weapon == 1) return " \x9D \x92\x83\x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9D \x92\x83\x91 Axe\n";
                return "   \x9D \x92\x83\x91 No Weapon\n";
            }
            else
            {
                if (e.weapon == 32) return " \x9D  \x83\x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9D  \x83\x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9D  \x83\x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9D  \x83\x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9D  \x83\x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9D  \x83\x91 Nailgun\n";
                if (e.weapon == 1) return " \x9D  \x83\x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9D  \x83\x91 Axe\n";
                return "   \x9D  \x83\x91 No Weapon\n";
            }
        }
    }
    else
    {
        if (e.items & IT_QUAD)
        {
            if (e.items & IT_INVISIBILITY)
            {
                if (e.weapon == 32) return " \x9DQ\x92 \x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9DQ\x92 \x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9DQ\x92 \x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9DQ\x92 \x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9DQ\x92 \x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9DQ\x92 \x91 Nailgun\n";
                if (e.weapon == 1) return " \x9DQ\x92 \x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9DQ\x92 \x91 Axe\n";
                return " \x9DQ\x92 \x91 No Weapon\n";
            }
            else
            {
                if (e.weapon == 32) return " \x9DQ  \x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9DQ  \x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9DQ  \x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9DQ  \x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9DQ  \x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9DQ  \x91 Nailgun\n";
                if (e.weapon == 1) return " \x9DQ  \x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9DQ  \x91 Axe\n";
                return " \x9DQ  \x91 No Weapon\n";
            }
        }
        else
        {
            if (e.items & IT_INVISIBILITY)
            {
                if (e.weapon == 32) return " \x9D \x92 \x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9D \x92 \x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9D \x92 \x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9D \x92 \x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9D \x92 \x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9D \x92 \x91 Nailgun\n";
                if (e.weapon == 1) return " \x9D \x92 \x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9D \x92 \x91 Axe\n";
                return "   \x9D \x92 \x91 No Weapon\n";
            }
            else
            {
                if (e.weapon == 32) return " \x9D   \x91 Rocket Launcher\n";
                if (e.weapon == 64) return " \x9D   \x91 Lightning Gun\n";
                if (e.weapon == 16) return " \x9D   \x91 Grenade Launcher\n";
                if (e.weapon == 8) return " \x9D   \x91 Super Nailgun\n";
                if (e.weapon == 2) return " \x9D   \x91 Super Shotgun\n";
                if (e.weapon == 4) return " \x9D   \x91 Nailgun\n";
                if (e.weapon == 1) return " \x9D   \x91 Shotgun\n";
                if (e.weapon == 4096) return " \x9D   \x91 Axe\n";
                return "   \x9D   \x91 No Weapon\n";
            }
        }
    }
};


//
//  G E T  H E A L T H  A M M O
//
//  Returns "  Health: <amount>   Ammo: "
//
//  The nested ifs are to speed things up.  Used for observer mode
//  heads-up display.
//
string (entity e) strings_get_health_ammo =
{
	local string temp;
	temp = sprintf("  \xC8\xE5\xE1\xEC\xF4\xE8\xBA %03g  \xC1\xED\xED\xEF\xBA", e.health);
	return temp;

};

//
//  G E T  T E A M N A M E
//
//  Return the colour string corresponding to a given team.
//
string (float num) strings_get_teamname =
{
	const string tab[] = 
	{
		"Brown team",	"Light Blue team",
		"Green team",	"Red team",
		"Olive team",	"Gold team",
		"Flesh team",	"Lavender team",
		"Purple team",	"Beige team",
		"Aqua team",	"Yellow team",
		"Blue team"
	};
	if (num < 1 || num > 13)
		return "Unknown team";
	return tab[num-1];
};

//
//  G E T  T E A M N A M E  B R O N Z E
//
//  Same as above, but in bronze letters - exactly 15 of them
//  My God, I've gone insane.
//
string (float num) strings_get_teamname_bronze =
{
	const string tab[] = 
	{
		"\bBrown team     ",	"\bLight Blue team",
		"\bGreen team     ",	"\bRed team       ",
		"\bOlive team     ",	"\bGold team      ",
		"\bFlesh team     ",	"\bLavender team  ",
		"\bPurple team    ",	"\bBeige team     ",
		"\bAqua team      ",	"\bYellow team    ",
		"\bBlue team      "
	};
	if (num < 1 || num > 13)
		return "\bUnknown team   ";
	return tab[num-1];
};


//
//  G E T  T E A M N A M E 2
//
//  Return the colour string corresponding to a given team.
//  The string contains EXACTLY 10 characters.
//
string (float num) strings_get_teamname2 =
{
	const string tab[] = 
	{
		"Brown     ",	"Light Blue",
		"Green     ",	"Red       ",
		"Olive     ",	"Gold      ",
		"Flesh     ",	"Lavender  ",
		"Purple    ",	"Beige     ",
		"Aqua      ",	"Yellow    ",
		"Blue      "
	};
	if (num < 1 || num > 13)
		return "Unknown   ";
	return tab[num-1];
};
//
//  G E T  T E A M N A M E 3
//
//  For when 10 characters is too many.. I can't believe I'm doing this.
//
string (float num) strings_get_teamname3 =
{
	const string tab[] = 
	{
		"Brown   ",	"Lt. Blue",
		"Green   ",	"Red     ",
		"Olive   ",	"Gold    ",
		"Flesh   ",	"Lavender",
		"Purple  ",	"Beige   ",
		"Aqua    ",	"Yellow  ",
		"Blue    "
	};
	if (num < 1 || num > 13)
		return "Unknown ";
	return tab[num-1];
};
//
//  G E T  T E A M N A M E 4
//
//  For when 3 characters is what we need.. Believe it.
//
string (float num) strings_get_teamname4 =
{
	const string tab[] = 
	{
		"Bro",	"LBl",
		"Grn",	"Red",
		"Olv",	"Gld",
		"Fle",	"Lav",
		"Pur",	"Bei",
		"Aqu",	"Yel",
		"Blu"
	};
	if (num < 1 || num > 13)
		return "???";
	return tab[num-1];
};
string (float num) strings_get_teamname4_red =
{
	const string tab[] = 
	{
		"\bBro\b",	"\bLBl\b",
		"\bGrn\b",	"\bRed\b",
		"\bOlv\b",	"\bGld\b",
		"\bFle\b",	"\bLav\b",
		"\bPur\b",	"\bBei\b",
		"\bAqu\b",	"\bYel\b",
		"\bBlu\b"
	};
	if (num < 1 || num > 13)
		return "\b???\b";
	return tab[num-1];
};
//
//  G E T  C O L O U R
//
//  Return the colour string corresponding to a given team.
//
string (float num) strings_get_colour =
{
	const string tab[] = 
	{
        "white",
		"brown",	
        "light blue",
		"green",	
        "red",
		"olive",	
        "gold",
		"flesh",	
        "lavender",
		"purple",	
        "beige",
		"aqua",		
        "yellow",
		"blue"
	};

	if (num < 0 || num > 13)
		return "unknown";
	return tab[num];
};

//
//  G E T  T E A M N A M E  U P  B Y
//
//  Return the "colour up by " string corresponding to a given team.
//
string (float num) strings_get_teamname_up_by =
{
	return strpad(-20, strcat(strtrim(strings_get_teamname2(num)), " up by "));
};

//
//  G E T  M O D E
//
//  Returns "Normal", "Practice", or "Match".
//
string (float mode) strings_get_mode =
{
	switch(mode)
	{
		case 0:	return "Normal/FFA";
		case 1: return "Practice";
		case 2: return "Match";
		case 3: return "CTF";
		case 4:	return "CA";
		case 5: return "RA";
		case 6: return "Airshot";
		case 7: return "DMM4";
		case 8: return "Wipeout";		
		case 9: return "Head Hunters";
	}
	return "";
};

string (float mode) strings_get_mode_gold =
{
	switch(mode)
	{

		case 0:	return "\bNormal";
		case 1: return "\bPractice";
		case 2: return "\bMatch";
		case 3: return "\bCTF";
		case 4:	return "\bCA";
		case 5: return "\bRA";
		case 6: return "\bAirshot";
		case 7: return "\bDMM4";
		case 8: return "\bWipeout";
		case 9: return "\bHead Hunters";
	}
	return "";
};


//
//  S Z P L U R A L
//
//  Helper string for printing.
//
string (float n) strings_szplural =
{
    if ((n == 1)||(n == -1))
        return "";	
    return "s";
};
