/*
==============================================================================

HEAD HUNTERS

==============================================================================
*/

void(entity client, float fragval) client_frag;
vector(float dm) VelocityForDamage;
void() hh_head_think;
void() hh_head_touch;
void(entity holder) hh_ensure_holder_heads;

float(float heads) hh_score_value =
{
	if (heads <= 0)
		return 0;

	return (heads * (heads + 1)) * 0.5;
};

void(entity altar) hh_disable_altar =
{
	altar.movetype = MOVETYPE_NONE;
	altar.solid = SOLID_NOT;
	altar.touch = SUB_Null;
	altar.scale = 0;
	altar.effects = 0;
	altar.avelocity = '0 0 0';
	altar.model = string_null;
	altar.modelindex = 0;
	setsize(altar, '0 0 0', '0 0 0');
};

float(entity head) hh_head_handler_count =
{
	local float count;

	if (head == world)
		return 0;

	if (head.hh_head_previous_owner_1 != world) count = count + 1;
	if (head.hh_head_previous_owner_2 != world) count = count + 1;
	if (head.hh_head_previous_owner_3 != world) count = count + 1;
	if (head.hh_head_previous_owner_4 != world) count = count + 1;
	if (head.hh_head_previous_owner_5 != world) count = count + 1;

	if (count <= 0)
		count = 1;

	return count;
};

void(entity head) hh_refresh_head_value =
{
	if (head == world)
		return;

	head.hh_head_value = hh_head_handler_count(head);
};

void(entity player, float fragval) hh_award_player_frag =
{
	local float old_gate;

	if ((player == world) || (fragval == 0))
		return;

	old_gate = hh_altar_scoring;
	hh_altar_scoring = TRUE;
	client_frag(player, fragval);
	hh_altar_scoring = old_gate;
};

void(entity holder) hh_refresh_holder_heads =
{
	local entity head;
	local float count;
	local float value;

	if (holder == world)
		return;

	head = holder.hh_head_list;
	while (head != world)
	{
		count = count + 1;
		hh_refresh_head_value(head);
		value = value + head.hh_head_value;
		head = head.hh_head_next;
	}

	holder.ammo_heads = count;
	holder.hh_head_total_value = value;
};

entity(entity head_owner) hh_new_head_entity =
{
	local entity head;

	head = spawn();
	head.classname = "item_hh_head";
	head.owner = world;
	head.enemy = head_owner;
	head.hh_head_next = world;
	head.hh_head_owner = head_owner;
	head.hh_head_last_owner = world;
	head.hh_head_previous_owner_1 = world;
	head.hh_head_previous_owner_2 = world;
	head.hh_head_previous_owner_3 = world;
	head.hh_head_previous_owner_4 = world;
	head.hh_head_previous_owner_5 = world;
	head.hh_head_value = 1;
	head.hh_head_total_value = 0;
	head.ammo_heads = 1;
	head.flags = 0;
	head.movetype = MOVETYPE_NONE;
	head.solid = SOLID_NOT;
	head.touch = SUB_Null;
	head.think = SUB_Null;
	head.nextthink = 0;
	head.velocity = '0 0 0';
	head.avelocity = '0 0 0';
	head.model = string_null;
	head.modelindex = 0;
	setsize(head, '0 0 0', '0 0 0');

	if (head_owner != world)
	{
		head.netname = head_owner.netname;
		head.colormap = head_owner.colormap;
		head.hh_head_original_team = head_owner.team;
	}
	else
	{
		head.netname = "";
		head.colormap = 0;
		head.hh_head_original_team = 0;
	}

	return head;
};

void(entity head, entity handler) hh_record_handler =
{
	if ((head == world) || (handler == world))
		return;

	head.hh_head_last_owner = handler;

	if (handler == head.hh_head_owner)
		return;

	if ((head.hh_head_previous_owner_1 == handler)
		|| (head.hh_head_previous_owner_2 == handler)
		|| (head.hh_head_previous_owner_3 == handler)
		|| (head.hh_head_previous_owner_4 == handler)
		|| (head.hh_head_previous_owner_5 == handler))
		return;

	if (head.hh_head_previous_owner_1 == world)
		head.hh_head_previous_owner_1 = handler;
	else if (head.hh_head_previous_owner_2 == world)
		head.hh_head_previous_owner_2 = handler;
	else if (head.hh_head_previous_owner_3 == world)
		head.hh_head_previous_owner_3 = handler;
	else if (head.hh_head_previous_owner_4 == world)
		head.hh_head_previous_owner_4 = handler;
	else if (head.hh_head_previous_owner_5 == world)
		head.hh_head_previous_owner_5 = handler;

	hh_refresh_head_value(head);
};

void(entity head, entity holder, float record_handler) hh_stow_head =
{
	if ((head == world) || (holder == world))
		return;

	if (record_handler && (holder.classname == "player"))
		hh_record_handler(head, holder);

	head.owner = holder;
	head.hh_head_next = holder.hh_head_list;
	holder.hh_head_list = head;
	head.ammo_heads = 1;
	head.flags = 0;
	head.movetype = MOVETYPE_NONE;
	head.solid = SOLID_NOT;
	head.touch = SUB_Null;
	head.think = SUB_Null;
	head.nextthink = 0;
	head.velocity = '0 0 0';
	head.avelocity = '0 0 0';
	head.model = string_null;
	head.modelindex = 0;
	setsize(head, '0 0 0', '0 0 0');
	setorigin(head, holder.origin);
	hh_refresh_head_value(head);
};

float(entity head, entity player) hh_can_reclaim_head =
{
	if (!teamplay || (player.team <= 0))
		return FALSE;

	if (head.hh_head_original_team != player.team)
		return FALSE;

	if (head.hh_head_last_owner == world)
		return FALSE;

	if ((head.hh_head_last_owner.team <= 0) || (head.hh_head_last_owner.team == player.team))
		return FALSE;

	return TRUE;
};

float(entity collector, entity head) hh_collect_head =
{
	if ((collector == world) || (head == world))
		return 0;

	if ((teamplay) && (collector.team > 0) && (head.hh_head_original_team == collector.team))
	{
		if (hh_can_reclaim_head(head, collector))
		{
			hh_award_player_frag(collector, 1);
			remove(head);
			return 2;
		}

		return 0;
	}

	hh_stow_head(head, collector, TRUE);
	return 1;
};

void(entity collector, entity src) hh_collect_heads_from_holder =
{
	local entity head;
	local entity next;
	local float result;

	hh_collect_taken = 0;
	hh_collect_reclaimed = 0;

	if ((collector == world) || (src == world) || (collector == src))
		return;

	hh_ensure_holder_heads(src);
	hh_ensure_holder_heads(collector);

	head = src.hh_head_list;
	src.hh_head_list = world;
	src.ammo_heads = 0;
	src.hh_head_total_value = 0;

	while (head != world)
	{
		next = head.hh_head_next;
		head.hh_head_next = world;
		result = hh_collect_head(collector, head);

		if (result == 1)
			hh_collect_taken = hh_collect_taken + 1;
		else if (result == 2)
			hh_collect_reclaimed = hh_collect_reclaimed + 1;
		else
			hh_stow_head(head, src, FALSE);

		head = next;
	}

	hh_refresh_holder_heads(src);
	hh_refresh_holder_heads(collector);
};

void(entity holder) hh_ensure_holder_heads =
{
	local entity head;
	local float count;

	if (holder == world)
		return;

	if (holder.hh_head_list != world)
	{
		hh_refresh_holder_heads(holder);
		return;
	}

	if (holder.ammo_heads <= 0)
	{
		holder.ammo_heads = 0;
		holder.hh_head_total_value = 0;
		return;
	}

	count = holder.ammo_heads;
	holder.ammo_heads = 0;
	holder.hh_head_total_value = 0;

	while (count > 0)
	{
		head = hh_new_head_entity(world);
		hh_stow_head(head, holder, FALSE);
		count = count - 1;
	}

	hh_refresh_holder_heads(holder);
};

entity(entity holder) hh_pop_holder_head =
{
	local entity head;

	hh_ensure_holder_heads(holder);

	if ((holder == world) || (holder.hh_head_list == world))
		return world;

	head = holder.hh_head_list;
	holder.hh_head_list = head.hh_head_next;
	head.hh_head_next = world;
	head.owner = world;
	hh_refresh_holder_heads(holder);
	return head;
};

void(entity dst, entity src, float record_handler) hh_transfer_all_heads =
{
	local entity head;
	local entity next;

	if ((dst == world) || (src == world) || (dst == src))
		return;

	hh_ensure_holder_heads(src);
	hh_ensure_holder_heads(dst);

	head = src.hh_head_list;
	src.hh_head_list = world;
	src.ammo_heads = 0;
	src.hh_head_total_value = 0;

	while (head != world)
	{
		next = head.hh_head_next;
		hh_stow_head(head, dst, record_handler);
		head = next;
	}

	hh_refresh_holder_heads(dst);
};

void(entity holder) hh_destroy_holder_heads =
{
	local entity head;
	local entity next;

	hh_ensure_holder_heads(holder);

	if (holder == world)
		return;

	head = holder.hh_head_list;
	holder.hh_head_list = world;
	holder.ammo_heads = 0;
	holder.hh_head_total_value = 0;

	while (head != world)
	{
		next = head.hh_head_next;
		remove(head);
		head = next;
	}
};

void(entity head, vector spawn_origin, vector launch_velocity) hh_release_head =
{
	if (head == world)
		return;

	head.owner = world;
	head.hh_head_next = world;
	head.ammo_heads = 1;
	head.flags = FL_ITEM;
	head.movetype = MOVETYPE_BOUNCE;
	head.solid = SOLID_TRIGGER;
	head.touch = hh_head_touch;
	head.think = hh_head_think;
	head.nextthink = time + 60;
	head.avelocity_x = random() * 600;
	head.avelocity_y = random() * 600;
	head.avelocity_z = random() * 600;
	head.velocity = launch_velocity;
	head.origin = spawn_origin;
	setmodel(head, "progs/h_player.mdl");
	setsize(head, '-16 -16 0', '16 16 32');
	setorigin(head, head.origin);
};

float(entity scorer, entity head) hh_score_teamplay_head =
{
	local float value;

	if ((scorer == world) || (head == world))
		return 0;

	hh_record_handler(head, scorer);
	hh_refresh_head_value(head);
	value = head.hh_head_value;

	if ((head.hh_head_previous_owner_1 != world)
		&& (head.hh_head_previous_owner_1.classname == "player")
		&& (head.hh_head_previous_owner_1.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_1, value);
		if (head.hh_head_previous_owner_1 != scorer)
			sprint(head.hh_head_previous_owner_1, scorer.netname, " scores a head you handled for ", ftos(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_2 != world)
		&& (head.hh_head_previous_owner_2.classname == "player")
		&& (head.hh_head_previous_owner_2.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_2, value);
		if (head.hh_head_previous_owner_2 != scorer)
			sprint(head.hh_head_previous_owner_2, scorer.netname, " scores a head you handled for ", ftos(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_3 != world)
		&& (head.hh_head_previous_owner_3.classname == "player")
		&& (head.hh_head_previous_owner_3.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_3, value);
		if (head.hh_head_previous_owner_3 != scorer)
			sprint(head.hh_head_previous_owner_3, scorer.netname, " scores a head you handled for ", ftos(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_4 != world)
		&& (head.hh_head_previous_owner_4.classname == "player")
		&& (head.hh_head_previous_owner_4.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_4, value);
		if (head.hh_head_previous_owner_4 != scorer)
			sprint(head.hh_head_previous_owner_4, scorer.netname, " scores a head you handled for ", ftos(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_5 != world)
		&& (head.hh_head_previous_owner_5.classname == "player")
		&& (head.hh_head_previous_owner_5.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_5, value);
		if (head.hh_head_previous_owner_5 != scorer)
			sprint(head.hh_head_previous_owner_5, scorer.netname, " scores a head you handled for ", ftos(value), " frags\n");
	}

	return value;
};

void() hh_head_think =
{
	SUB_Remove();
};

void() hh_head_touch =
{
	local float result;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (other.classname != "player")
		return;

	if (other.deadflag || other.health <= 0)
		return;

	result = hh_collect_head(other, self);
	if (result <= 0)
		return;

	sound(other, CHAN_ITEM, "demon/dland2.wav", 1, ATTN_NORM);
	stuffcmd(other, "bf\n");

	if (result == 2)
	{
		sprint(other, "You reclaimed your team's head for 1 frag\n");
		return;
	}

	hh_refresh_holder_heads(other);

	if (self.hh_head_owner == other)
		sprint(other, "You got your own head\n");
	else if (self.netname != "")
		sprint(other, "You got ", self.netname, "'s head\n");
	else
	{
		sprint(other, "You got a head\n");
	}
};

void() hh_altar_touch =
{
	local entity head;
	local entity next;
	local float recovered, score;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (other.classname != "player")
		return;

	if (other.deadflag || other.health <= 0)
		return;

	hh_ensure_holder_heads(other);

	if (other.ammo_heads <= 0)
		return;

	recovered = other.ammo_heads;
	score = 0;

	if (teamplay && (other.team > 0))
	{
		head = other.hh_head_list;
		other.hh_head_list = world;
		other.ammo_heads = 0;
		other.hh_head_total_value = 0;

		while (head != world)
		{
			next = head.hh_head_next;
			score = score + hh_score_teamplay_head(other, head);
			remove(head);
			head = next;
		}
	}
	else
	{
		hh_destroy_holder_heads(other);
		score = hh_score_value(recovered);
		hh_award_player_frag(other, score);
	}

	if (other.invincible_finished < time)
		other.invincible_finished = time;
	other.invincible_finished = other.invincible_finished + (3 * recovered);
	other.invincible_time = 1;
	other.items = other.items | IT_INVULNERABILITY;
	other.effects = other.effects | EF_RED | EF_DIMLIGHT;
	stuffcmd(other, "bf\n");

	if (teamplay && (other.team > 0))
	{
		if (recovered == 1)
			bprint(other.netname, " scores 1 head for the team\n");
		else
			bprint(other.netname, " scores ", ftos(recovered), " heads for the team\n");
	}
	else if (recovered == 1)
		bprint(other.netname, " scores 1 head for 1 frag\n");
	else
		bprint(other.netname, " scores ", ftos(recovered), " heads for ", ftos(score), " frags\n");
};

void() hh_backpack_expire =
{
	hh_destroy_holder_heads(self);
	SUB_Remove();
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
	if (clanring_playmode & CLANRING_HH_MODE)
		hh_configure_altar(self);
	else
		hh_disable_altar(self);
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
	local vector launch_velocity;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	head = hh_new_head_entity(dead);
	launch_velocity = VelocityForDamage(dead.health);
	launch_velocity_z = launch_velocity_z + 120 + (random() * 120);
	hh_release_head(head, spawn_origin, launch_velocity);
};

void(entity dead) hh_spawn_head =
{
	hh_spawn_head_at(dead, dead.origin);
};

entity(entity passer) hh_find_pass_target =
{
	local entity player;
	local entity best;
	local vector pass_origin;
	local vector target_origin;
	local vector delta;
	local float dist;
	local float bestdist;

	if (!teamplay || (passer.team <= 0))
		return world;

	pass_origin = passer.origin + passer.view_ofs;
	bestdist = 256;
	player = find(world, classname, "player");

	while (player != world)
	{
		if ((player != passer)
			&& !(player.style & CLANRING_OBSERVER)
			&& (player.deadflag == DEAD_NO)
			&& (player.health > 0)
			&& (player.team == passer.team))
		{
			target_origin = player.origin + player.view_ofs;
			delta = target_origin - pass_origin;
			dist = vlen(delta);

			if (dist <= bestdist)
			{
				delta = normalize(delta);

				if ((delta * v_forward) > 0.55)
				{
					traceline(pass_origin, target_origin, FALSE, passer);
					if ((trace_ent == player) || (trace_fraction == 1))
					{
						best = player;
						bestdist = dist;
					}
				}
			}
		}

		player = find(player, classname, "player");
	}

	return best;
};

float(entity passer, entity receiver) hh_pass_one_head =
{
	local entity head;

	if (receiver == world)
		return FALSE;

	head = hh_pop_holder_head(passer);
	if (head == world)
		return FALSE;

	hh_stow_head(head, receiver, TRUE);
	hh_refresh_holder_heads(receiver);
	sound(receiver, CHAN_ITEM, "demon/dland2.wav", 1, ATTN_NORM);
	stuffcmd(receiver, "bf\n");

	if (head.hh_head_value == 1)
		sprint(receiver, passer.netname, " passes you a head worth 1 frag\n");
	else
		sprint(receiver, passer.netname, " passes you a head worth ", ftos(head.hh_head_value), " frags\n");

	if (passer.ammo_heads <= 0)
		sprint(passer, "You pass your last head to ", receiver.netname, "\n");
	else
		sprint(passer, "You pass a head to ", receiver.netname, ". ", ftos(passer.ammo_heads), " remain\n");

	return TRUE;
};

void() hh_toss_head =
{
	local entity head;
	local entity receiver;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if ((self.style & CLANRING_OBSERVER) || (self.health <= 0))
		return;

	hh_ensure_holder_heads(self);

	if (self.ammo_heads <= 0)
	{
		sprint(self, "You do not have any heads to toss\n");
		return;
	}

	makevectors(self.v_angle);
	receiver = hh_find_pass_target(self);
	if ((receiver != world) && hh_pass_one_head(self, receiver))
		return;

	head = hh_pop_holder_head(self);
	if (head == world)
	{
		sprint(self, "You do not have any heads to toss\n");
		return;
	}

	hh_release_head(head, self.origin + '0 0 16', (v_forward * 320) + '0 0 180');

	if (self.ammo_heads <= 0)
		sprint(self, "You toss your last head\n");
	else
		sprint(self, "You toss a head. ", ftos(self.ammo_heads), " remain\n");
};

void() hh_call_teammate =
{
	local entity player;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (!teamplay || (self.team <= 0))
	{
		sprint(self, "Call teammate only works in teamplay Head Hunters\n");
		return;
	}

	player = find(world, classname, "player");
	while (player != world)
	{
		if ((player != self) && !(player.style & CLANRING_OBSERVER) && (player.team == self.team))
			sprint(player, self.netname, " calls for support\n");

		player = find(player, classname, "player");
	}

	sprint(self, "You call to your teammates\n");
};

void() hh_auto_help_tip =
{
	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (teamplay)
	{
		sprint(self, "Head Hunters teamplay: enemy heads gain value with unique teammate hand-offs, scoring pays every handler, and reclaimed stolen team heads are worth 1 frag each.\n");
		return;
	}

	sprint(self, "Head Hunters: collect heads and score them at the altar. Batch scoring is progressive: 1=1, 2=3, 3=6, 4=10, 5=15.\n");
};
