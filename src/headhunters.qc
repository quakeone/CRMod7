/*
==============================================================================

HEAD HUNTERS

==============================================================================
*/

void(entity client, float fragval) client_frag;
vector(float dm) VelocityForDamage;

void() hh_head_think =
{
	SUB_Remove();
};

void() hh_head_touch =
{
	local float room, take;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (other.classname != "player")
		return;

	if (other.deadflag || other.health <= 0)
		return;

	room = hh_maxheads - other.ammo_heads;
	if (room <= 0)
		return;

	take = self.ammo_heads;
	if (take <= 0)
		take = 1;
	if (take > room)
		take = room;

	other.ammo_heads = other.ammo_heads + take;
	self.ammo_heads = self.ammo_heads - take;

	sound(other, CHAN_ITEM, "demon/dland2.wav", 1, ATTN_NORM);
	stuffcmd(other, "bf\n");

	if (take == 1)
	{
		if (self.enemy == other)
			sprint(other, "You got your own head\n");
		else if (self.netname != "")
			sprint(other, "You got ", self.netname, "'s head\n");
		else
			sprint(other, "You got a head\n");
	}
	else
	{
		sprint(other, "You got ", ftos(take), " heads\n");
	}

	if (self.ammo_heads <= 0)
		remove(self);
};

void() hh_altar_touch =
{
	local float recovered;
	local float old_gate;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (other.classname != "player")
		return;

	if (other.deadflag || other.health <= 0)
		return;

	if (other.ammo_heads <= 0)
		return;

	recovered = other.ammo_heads;
	other.ammo_heads = 0;

	old_gate = hh_altar_scoring;
	hh_altar_scoring = TRUE;
	client_frag(other, recovered);
	hh_altar_scoring = old_gate;

	if (other.invincible_finished < time)
		other.invincible_finished = time;
	other.invincible_finished = other.invincible_finished + (3 * recovered);
	other.invincible_time = 1;
	other.items = other.items | IT_INVULNERABILITY;
	other.effects = other.effects | EF_RED | EF_DIMLIGHT;
	stuffcmd(other, "bf\n");

	if (recovered == 1)
		bprint(other.netname, " recovers 1 head\n");
	else
		bprint(other.netname, " recovers ", ftos(recovered), " heads\n");
};

void(entity altar) hh_configure_altar =
{
	setmodel(altar, "progs/v_spike.mdl");
	altar.movetype = MOVETYPE_NOCLIP;
	altar.solid = SOLID_TRIGGER;
	altar.touch = hh_altar_touch;
	altar.scale = 3;
	altar.effects = altar.effects | EF_FULLBRIGHT;
	altar.avelocity = '0 120 0';
	setsize(altar, '-128 -128 -112', '128 128 0');
	setorigin(altar, altar.origin);
};

/*QUAKED info_altar (0 .5 .8) (-128 -128 -112) (128 128 0)
Head Hunters scoring altar. Carry heads here to score and gain invulnerability.
*/
void() info_altar =
{
	hh_configure_altar(self);
};

void(entity source) hh_spawn_altar_at =
{
	local entity altar;

	altar = spawn();
	altar.classname = "info_altar";
	altar.origin = source.origin + '0 0 56';
	setorigin(altar, altar.origin);
	hh_configure_altar(altar);
};

float(string source_classname, float wanted) hh_spawn_altars_from_class =
{
	local entity source;
	local float spawned;

	source = find(world, classname, source_classname);
	while ((source != world) && (spawned < wanted))
	{
		hh_spawn_altar_at(source);
		spawned = spawned + 1;
		source = find(source, classname, source_classname);
	}

	return spawned;
};

void() hh_startup =
{
	local entity altar;
	local float existing;
	local float need;
	local float made;

	if (!(clanring_playmode & CLANRING_HH_MODE))
	{
		if (self.classname == "scheduled_event_entity")
			remove(self);
		return;
	}

	// Ensure mapper-placed altars are always activated in HH mode.
	altar = find(world, classname, "info_altar");
	while (altar != world)
	{
		hh_configure_altar(altar);
		existing = existing + 1;
		altar = find(altar, classname, "info_altar");
	}

	// Build fallback altars if map does not define any.
	if (existing == 0)
	{
		need = 3;

		if (made < need) made = made + hh_spawn_altars_from_class("item_artifact_super_damage", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_sigil", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_rocketlauncher", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_lightning", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_supernailgun", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_nailgun", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_grenadelauncher", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_key1", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_key2", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_armorInv", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_armor2", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_armor1", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("info_player_deathmatch", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("info_player_start", need - made);
	}

	if (self.classname == "scheduled_event_entity")
		remove(self);
};

void(entity dead, vector spawn_origin) hh_spawn_head_at =
{
	local entity head;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	head = spawn();
	head.classname = "item_hh_head";
	head.owner = world;
	head.enemy = dead;
	head.netname = dead.netname;
	head.colormap = dead.colormap;
	head.ammo_heads = 1;
	head.flags = FL_ITEM;
	head.movetype = MOVETYPE_BOUNCE;
	head.solid = SOLID_TRIGGER;
	head.avelocity_x = random() * 600;
	head.avelocity_y = random() * 600;
	head.avelocity_z = random() * 600;
	head.velocity = VelocityForDamage(dead.health);
	head.velocity_z = head.velocity_z + 120 + (random() * 120);
	head.origin = spawn_origin;
	head.touch = hh_head_touch;
	head.think = hh_head_think;
	head.nextthink = time + 60;

	setmodel(head, "progs/h_player.mdl");
	setsize(head, '-16 -16 0', '16 16 32');
	setorigin(head, head.origin);
};

void(entity dead) hh_spawn_head =
{
	hh_spawn_head_at(dead, dead.origin);
};
