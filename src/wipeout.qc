void() powerup_touch;

float (entity spot) wipeout_get_spawn_radius =
{
	// KTX defaults Wipeout occupancy checks to 84 units and widens a few
	// abusable dm3 spawns. Origin matching mirrors KTX's map-specific table.
	if (mapname != "dm3")
		return 84;

	if (vlen(spot.origin - '-880 -232 -16') < 1)
		return 128;
	if (vlen(spot.origin - '1520 432 -88') < 1)
		return 300;
	if (vlen(spot.origin - '-632 -680 -16') < 1)
		return 128;
	if (vlen(spot.origin - '512 768 216') < 1)
		return 128;

	return 84;
};

// Match current KTX Wipeout pacing: respawn delay scales with team size,
// is capped to a four-life schedule, and a solo player's first return is free.
float (entity player, float offset) wipeout_get_respawn =
{
	local float deaths, multiple, teamsize;

	deaths = player.rounddeaths + offset;
	teamsize = player.next_team.teamtotal;
	if (teamsize < 1)
		teamsize = 1;

	if ((teamsize == 1) && (deaths == 1))
		return 0;
	if (deaths <= 0)
		return 0;

	if (deaths > 4)
		return 999;

	multiple = teamsize + 1;
	if (multiple < 3)
		multiple = 3;
	else if (multiple > 6)
		multiple = 6;

	if (deaths == 1)
		return multiple;

	return (deaths - 1) * (multiple * 2);
};

float (entity team) wipeout_team_has_pending_respawn =
{
	local entity player;

	player = team.chain_gang;
	while (player != world)
	{
		if ((player.style & CLANRING_CONNECTED) && (player.respawntime > 0))
			return TRUE;
		player = player.chain_gang;
	}

	return FALSE;
};

void (entity team) wipeout_update_team_nextspawn =
{
	local entity player;
	local float earliest;

	if (team == world)
		return;

	earliest = 0;
	player = team.chain_gang;
	while (player != world)
	{
		if ((player.style & CLANRING_CONNECTED) && (player.respawntime > time) &&
			((earliest == 0) || (player.respawntime < earliest)))
		{
			earliest = player.respawntime;
		}
		player = player.chain_gang;
	}

	team.nextspawn = earliest;
};

void (entity team, entity respawned) wipeout_mark_team_escape =
{
	local entity player;

	// Only the sole living teammate can have just escaped a wipe.
	if ((team == world) || (team.teamalive != 1))
		return;

	player = team.chain_gang;
	while (player != world)
	{
		if ((player != respawned) && (player.style & CLANRING_CONNECTED) &&
			!(player.style & CLANRING_OBSERVER) && (player.health > 0))
		{
			player.wipeout_escape_time = time;
		}
		player = player.chain_gang;
	}
};

void (entity victim, entity attacker) wipeout_reward_escape =
{
	local entity player;
	local float escaped_by;

	if ((victim == world) || (victim.classname != "player") ||
		(victim.wipeout_escape_time <= 0))
		return;

	escaped_by = time - victim.wipeout_escape_time;
	victim.wipeout_escape_time = 0;
	if ((escaped_by <= 0) || (escaped_by >= 0.3))
		return;

	victim.rounddeaths -= 1;

	player = victim.next_team.chain_gang;
	while (player != world)
	{
		if (player.style & CLANRING_CONNECTED)
			clanring_stuffcmd_compat_play(player, "ca/hero.wav", "misc/medkey.wav");
		player = player.chain_gang;
	}

	if ((attacker != world) && (attacker.next_team != world) &&
		(attacker.next_team != victim.next_team))
	{
		player = attacker.next_team.chain_gang;
		while (player != world)
		{
			if (player.style & CLANRING_CONNECTED)
				clanring_stuffcmd_compat_play(player, "boss2/idle.wav", "misc/medkey.wav");
			player = player.chain_gang;
		}
	}

	bprint4(victim.netname, " survives by ", ftos(floor(escaped_by * 1000)), " milliseconds!\n");
};

void (entity player) wipeout_check_solo_regen =
{
	local float required_time;

	if ((player == world) || IS_CA_OBSERVER(player) ||
		(player.next_team == world) || (player.next_team.teamtotal != 1) ||
		(player.wipeout_regen_time <= 0))
		return;

	required_time = player.wipeout_round_kills * 5;
	if ((time - player.wipeout_regen_time) <= required_time)
		return;

	stuffcmd(player, "play misc/secret.wav\n");
	player.items = player.items - (player.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	player.items = player.items | IT_ARMOR3;
	player.armorvalue = 200;
	player.armortype = 0.8;
	player.health = 100;
	player.ammo_nails = 200;
	player.ammo_shells = 100;
	player.ammo_rockets = 50;
	player.ammo_cells = 150;
	player.wipeout_regen_time = 0;
};

entity (float wnum) check_weapon_spot =
{
	local entity spot = world;
	if (wnum == 13)
	{
		spot = find(spot, classname, "weapon_lightning");
	}
	else if (wnum == 12)
	{
		spot = find(spot, classname, "weapon_supershotgun");
	}
	else if (wnum == 11)
	{
		spot = find(spot, classname, "weapon_nailgun");
	}
	else if (wnum == 10)
	{
		spot = find(spot, classname, "weapon_supernailgun");
	}
	else if (wnum == 9)
	{
		spot = find(spot, classname, "weapon_grenadelauncher");
	}
	else if (wnum == 8)
	{
		spot = find(spot, classname, "weapon_rocketlauncher");
	}
	else
	{
		spot = find(spot, classname, "item_weapon");
	}
	return spot;
};

entity () find_item_spawn_spot =
{
	local entity spot = world;
	local float	pcount;

	pcount = random() * (16 - 0.001);
	pcount = floor(pcount);
	if (pcount > 7)
	{
		spot = check_weapon_spot(pcount);
	}

	if (spot == world)
	{
		pcount = random() * (dm_num_spawns - 0.001);
		pcount = floor(pcount);
		spot = find(world, classname, "info_player_deathmatch");
		while (pcount > 0)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
				pcount = pcount - 1;
		}
		if (spot == world)
			spot = find(spot, classname, "info_player_deathmatch");
	}
	return spot;
};

// void (vector vspot) do_spawn_quad =
// {
// 	local entity item;
// 	item = spawn ();
// 	item.origin = vspot;
// 	item.classname = "item_artifact_super_damage";
// 	item.velocity = '0 0 0';
// 	item.noise = "items/damage.wav";
// 	item.mdl = "progs/quaddama.mdl";
// 	setmodel (item, item.mdl);
// 	item.netname = "Quad Damage";
// 	item.items = IT_QUAD;
// 	setsize (item, '-16 -16 -24', '16 16 32');
// 	item.count = item.cnt = 0;
// 	item.owner = world;
// 	item.height = 0;
// 	item.flags = FL_ITEM;
// 	item.solid = SOLID_TRIGGER;
// 	item.movetype = MOVETYPE_TOSS;
// 	item.touch = powerup_touch;
// 	item.nextthink = time + 30;
// 	item.think = SUB_Remove;
// 	sound (item, CHAN_VOICE, "crx/itembk3.wav", 1, ATTN_NORM);
// };

void() BackpackTouch;
void (vector vspot) do_spawn_pack =
{
	local float rammo = 0;
	local entity item;
	item = spawn();
	item.origin = vspot;
	item.origin_z = item.origin_z - 24;
    item.classname = "item_backpack";
	rammo = (random() * 2) + 1;
	if (rammo == 1)
	{
		item.items = IT_GRENADE_LAUNCHER;
		item.netname = "Grenade Launcher";
	}
	else
	{
		item.items = IT_LIGHTNING;
		item.netname = "Thunderbolt";
	}
	rammo = (random() * 20) + 1;
	item.ammo_shells = floor(rammo);
	rammo = (random() * 25) + 1;
	item.ammo_nails = floor(rammo);
	rammo = (random() * 8) + 1;
	item.ammo_rockets = floor(rammo);
	rammo = (random() * 12) + 1;
	item.ammo_cells = floor(rammo);
	item.velocity = '0 0 0';
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;
	item.nextthink = time + 60;
	item.think = SUB_Remove;
	sound (item, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);
};

//void() health_touch;
void (vector vspot) do_spawn_health =
{
	// local entity item;
	// item = spawn();
	// item.origin = vspot - '0 0 24';
    // item.classname = "item_health";
	// item.velocity = '0 0 0';
	// item.flags = FL_ITEM;
	// item.solid = SOLID_TRIGGER;
	// item.movetype = MOVETYPE_TOSS;
	// setmodel(item, "maps/b_bh100.bsp");
	// setsize (item, '0 0 0', '32 32 56');
	// item.noise = "items/r_item2.wav";
	// item.healamount = 100;
	// item.healtype = 2;
	// item.touch = health_touch;
	// item.nextthink = time + 20;
	// item.think = SUB_Remove;
	// sound (item, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);
};

void () wipeout_try_spawn_item =
{
	local float prnd;
	local entity spot;

	prnd = random() * (90 - 0.001);
	prnd = floor(prnd);
	if ((prnd == 15) || (prnd == 30) || (prnd == 45))
	{
		spot = find_item_spawn_spot();
		if (spot != world)
		{
			// if (prnd == 30)
			// 	do_spawn_health(spot.origin);
			// else
				do_spawn_pack(spot.origin);
		}
	}
};

// void () wipeout_try_spawn_quad =
// {
// 	local float prnd;
// 	local entity spot;

// 	if (time > boss.quadtime)
// 	{
// 		prnd = random() * (5 - 0.001);
// 		prnd = floor(prnd);
// 		if (prnd == 3)
// 		{
// 			spot = find_item_spawn_spot();
// 			if (spot != world)
// 			{
// 				do_spawn_quad(spot.origin);
// 				boss.quadtime = time + 999;
// 			}
// 		}
// 		else
// 		{
// 			wipeout_try_spawn_item();
// 		}
// 	}
// };

void () wipeout_init_teams =
{
	local entity e;

	e = boss.next_team;

	while (e)
	{
		e.teamalive = number_teammates(e);
		e.teamtotal = e.teamalive;
		e.nextspawn = 0;
		e = e.next_team;
	}
};

// entity (entity e, float spawnradius) find_player_spawn_spot =
// {
// 	local entity head;
// 	head = findradius (e.origin, spawnradius);					
// 	while (head)
// 	{
// 		if (head.classname == "info_player_deathmatch")
// 		{
// 			return head;
// 		}
// 		head = head.chain;
// 	}
// 	return world;
// };

// entity () SelectWipeoutSpawnPoint =
// {
// 	local entity e, tmp = world, localspawn = world;
// 	local float spawnradius = 0;

// 	if (self.next_team == world)
// 		return world;

// 	e = boss.next_team;

// 	while (e)
// 	{
// 		if (e.team2 == self.next_team.team2)
// 		{
// 			while (e.chain_gang)
// 			{
// 				if (e.chain_gang.deadflag == DEAD_NO && (IS_CA_OBSERVER(e.chain_gang) == FALSE) && ((e.chain_gang.style & CLANRING_CONNECTED)))
// 				{
// 					tmp = e.chain_gang;
// 					break;
// 				}
// 				e = e.chain_gang;
// 			}
// 		}
// 		if (tmp)
// 			break;
// 		e = e.next_team;
// 	}

// 	if (tmp)
// 	{
// 		while ((spawnradius < 1000) && !(localspawn))
// 		{
// 			spawnradius += 128;
// 			localspawn = find_player_spawn_spot(tmp, spawnradius);
// 		}
// 	}

// 	if (localspawn)
// 		return localspawn;

// 	return world;
// };
void () powerup_denied;

void () wipeout_drop_quad_touch =
{
	local float item_dropped, time_left;

	if (other.classname != "player")
		return;

	if ((boss.state != CA_MATCH_PLAYING) || ((boss.state == CA_MATCH_PLAYING) && (boss.wait > 0)))
		return;

	if (other.health <= 0)
		return;

	item_dropped = IT_QUAD;
	other.super_time = 1;

	if (other.super_damage_finished <= time)
	{
		other.super_damage_finished = self.cnt;
	}
	else
	{
		other.super_damage_finished= other.super_damage_finished + (self.cnt - time);
		if (other.super_damage_finished > time + 30)
			other.super_damage_finished = time + 30;
	}

	sound (other, CHAN_AUTO, self.noise, 1, ATTN_NORM);
	self.solid = SOLID_NOT;
	other.items = other.items | item_dropped;
	self.model = string_null;

	time_left = ceil(self.cnt-time);
	bprint(other.netname);
	bprint(" recovered a ");
	bprint(self.netname);
	bprint(" with ");
	utils_bprint_float (time_left);
	bprint(" second");
	if (time_left != 1)
		bprint("s");
	bprint(" remaining!\n");

	powerup_denied ();

	other.effects = other.effects | EF_DIMLIGHT;
	other.effects = other.effects | EF_BLUE;

	activator = other;

	SUB_UseTargets ();
};

void (float finish_time) wipeout_drop_quad =
{
	local entity item;
	local float time_left;

	if ((boss.state != CA_MATCH_PLAYING) || ((boss.state == CA_MATCH_PLAYING) && (boss.wait > 0)))
		return;

	time_left = floor(finish_time);
	bprint(self.netname);
	bprint(" lost a Quad with ");
	utils_bprint_float (time_left);
	bprint(" second");
	if (time_left != 1)
		bprint("s");
	bprint(" remaining\n");

	item = spawn ();
	item.origin = self.origin;
	item.classname = "item_artifact_super_damage";
	item.velocity = '0 0 0';

	item.noise = "items/damage.wav";
	item.mdl = "progs/quaddama.mdl";
	setmodel (item, item.mdl);
	item.netname = "Quad Damage";
	item.items = IT_QUAD;
	setsize (item, '-16 -16 -24', '16 16 32');

	item.count = 0;
	item.owner = world;
	item.height = 0;
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;

	item.cnt = time + finish_time;
	item.touch = wipeout_drop_quad_touch;
	item.nextthink = time + finish_time;
	item.think = SUB_Remove;
	//boss.quadtime = (item.nextthink + 5);
};