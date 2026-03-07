
string (entity e) ident_get_weapon_in_hand =
{
	if (e.weapon == IT_ROCKET_LAUNCHER) 	return "rl";
	if (e.weapon == IT_LIGHTNING) 			return "lg";
	if (e.weapon == IT_GRENADE_LAUNCHER) 	return "gl";
	if (e.weapon == IT_SUPER_NAILGUN) 		return "sng";
	if (e.weapon == IT_SUPER_SHOTGUN) 		return "ssg";
	if (e.weapon == IT_NAILGUN) 			return "ng";
	if (e.weapon == IT_SHOTGUN) 			return "sg";
	if (e.weapon == IT_AXE) 				return "axe";
//	if (e.weapon == IT_HOOK)				return "hook";
//											return "fist";
	return "";
}

string (entity e) ident_get_other_weapons =
{
	local string t = "";

	if ((e.items & IT_ROCKET_LAUNCHER) 	&& (e.weapon != IT_ROCKET_LAUNCHER))	t = sprintf("%s%s", t, "\.rl");
	if ((e.items & IT_LIGHTNING) 		&& (e.weapon != IT_LIGHTNING))			t = sprintf("%s%s", t, "\.lg");
	else
	if ((e.items & IT_GRENADE_LAUNCHER) && (e.weapon != IT_GRENADE_LAUNCHER))	t = sprintf("%s%s", t, "\.gl");
	else
	if ((e.items & IT_SUPER_NAILGUN) 	&& (e.weapon != IT_SUPER_NAILGUN))		t = sprintf("%s%s", t, "\.sng");
	else
	if ((e.items & IT_SUPER_SHOTGUN)	&& (e.weapon != IT_SUPER_SHOTGUN))		t = sprintf("%s%s", t, "\.ssg");
	else
	if ((e.items & IT_NAILGUN)			&& (e.weapon != IT_NAILGUN))			t = sprintf("%s%s", t, "\.ng");

	return t;
}

string (entity e) ident_get_rune_type =
{
	if (e.player_flag & ITEM_RUNE1_FLAG)//Rune 1 - Earth Magic(resistance)
	   return "\.resistance";	
	if (e.player_flag & ITEM_RUNE2_FLAG)//Rune 2 - Black Magic(strength)
	   return "\.strength";
	if (e.player_flag & ITEM_RUNE3_FLAG)//Rune 3 - Hell Magic(haste)
	   return "\.haste";
	if (e.player_flag & ITEM_RUNE4_FLAG)//Rune 4 - Elder Magic(regeneration)
	   return "\.regeneration";
	   
	return "";
};

string (entity e) ident_get_armor_type =
{	
   	if (e.items & IT_ARMOR3)	return "r";    	
   	if (e.items & IT_ARMOR2)	return "y";   	
   	if (e.items & IT_ARMOR1) 	return "g";
   	  
	return "";
};

void(entity who, float b) ident_update_display =
{	
	string rname = who.netname, res;
	
	if (prematch_rules())//avoid centerprint war
		return;

	res	= TeamSetStatRes2(self);//r00K: Position the idenifier based on the player's .statstate setting (impulse 71 - 81)

/*
	woods in prewar it should identify everyone with only name
*/
	if (clanring_playmode & CLANRING_MATCH_MODE && (!(clanring_state & CLANRING_MATCH_STARTED)))
	{
		if (b)
		{
			rname = redify(who.netname);	//R00k: display teammates out of pov in red.
			centerprint(self, res, rname);
		}
		else
			centerprint(self, res, who.netname);	//otherwise white for in pov.
		return;
	}
//FIXME: strzone these???
	local string armour;
	local string aval, hval, rtype, weap, ammo, it;
	local string line1 = "", line2 = "";	
	
	armour	= ident_get_armor_type(who);
	aval 	= strings_ftos_gold(who.armorvalue);
	hval	= ftos(who.health);                  
	rtype	= ident_get_rune_type(who);
	weap 	= ident_get_weapon_in_hand(who);
	ammo 	= ftos(who.currentammo);
	it		= ident_get_other_weapons(who);
	
	line1 	= sprintf("\b[\b%s%s\.%s%s\b]", armour, aval, hval, rtype);

	if (who.currentammo)
		line2 = sprintf("\[%s\.%s\]%s", weap, ammo, it);
	else
	{
		if (weap && it)//don't show empty brackets.
			line2 = sprintf("\[%s\]%s", weap, it);
	}
 
	if (b)
	{
		rname = redify(who.netname);
		centerprint(self, res, rname, line1, line2, "\n\n\n\n\n");
	}
	else
		centerprint(self, res, who.netname, line1, line2, "\n\n\n\n\n");
};
/*
=============
infront

returns 1 if the entity is in front (in sight) of self
=============
from ai.qc
*/
float(entity targ) infront =
{
	local vector	vec;
	local float		dot;
	
	makevectors (self.angles);
	vec = normalize (targ.origin - self.origin);
	dot = vec * v_forward;
	
	if (dot > 0.33)
	{
		return TRUE;
	}
	return FALSE;
};

void() ident_get_target =
{
	local entity tm = world;
	if (prematch_rules())
		return;

	if (self.style & CLANRING_MOTD)
		return;
	tm = findradius(self.origin, 2048);	//R00k: find nearby teammates, same distance as a shotgun blast
	while (tm)
	{
		if ((tm.classname == "player") && (tm.style & CLANRING_CONNECTED) && (tm != self) && ((tm.team == self.team) || (match_prewar())))     //R00k: show all players' identity in prewar.
		{
			if (infront(tm))
			{
				if (utils_visible(self, tm)) //can we actually see them; clips against walls
				{
					ident_update_display(tm, FALSE);
				}
				makevectors (self.v_angle);
				traceline (self.origin, self.origin + v_forward * 2048 + '0 0 32', FALSE, self);

				if (trace_fraction < 1)
				{
					if ((trace_ent.classname == "player") && (trace_ent.style & CLANRING_CONNECTED))
					{
						if ((trace_ent.team == self.team) || (match_prewar()))//R00k: show all players' identity in prewar.
							ident_update_display(trace_ent, FALSE);
						break;//if we are aiming directly at someone, then don't continue to find others.
					}
				}				
			}
/*			else		//Disabling this as it might provide too much info/centerprint war
			{
				if (utils_visible(self, tm)) // visible within radius
				{
					ident_update_display(tm, TRUE);
				}
			}*/
		}
		tm = tm.chain;
	}
};
