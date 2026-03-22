/*
==============================================================================

HEAD HUNTERS

==============================================================================
*/

void(entity client, float fragval) client_frag;
void() DeathSound;
void() respawn;
void(string gibname, float dm) ThrowGib;
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;
vector(float dm) VelocityForDamage;
void() hh_head_think;
void() hh_head_touch;
void() hh_head_settle;
void(entity holder) hh_ensure_holder_heads;
void(entity head, vector spawn_origin, vector launch_velocity) hh_release_head;
string(float n) strings_ftos_gold;
void(entity player) hh_player_prethink;
void(entity player) hh_player_postthink;
void() hh_player_die;
void(entity altar) hh_configure_altar;
void(entity player, entity target) hh_set_eyecam;
vector(float slot) hh_pile_offset;
vector(float slot) hh_pile_angles;
void(entity player) hh_finish_haunting_stats;

string() hh_random_pickup_sound =
{
	local float roll;

	roll = floor(random() * 8);

	if (roll < 1) return "hhsounds/pickup1.wav";
	if (roll < 2) return "hhsounds/pickup2.wav";
	if (roll < 3) return "hhsounds/pickup3.wav";
	if (roll < 4) return "hhsounds/pickup4.wav";
	if (roll < 5) return "hhsounds/pickup5.wav";
	if (roll < 6) return "hhsounds/pickup6.wav";
	if (roll < 7) return "hhsounds/pickup7.wav";
	return "hhsounds/pickup8.wav";
};

string() hh_random_catch_sound =
{
	local float roll;

	roll = floor(random() * 4);

	if (roll < 1) return "hhsounds/catch1.wav";
	if (roll < 2) return "hhsounds/catch2.wav";
	if (roll < 3) return "hhsounds/catch3.wav";
	return "hhsounds/catch4.wav";
};

string() hh_random_altar_sound =
{
	local float roll;

	roll = floor(random() * 4);

	if (roll < 1) return "hhsounds/altar1.wav";
	if (roll < 2) return "hhsounds/altar2.wav";
	if (roll < 3) return "hhsounds/altar3.wav";
	return "hhsounds/altar4.wav";
};

string(float n) hh_number =
{
	return strings_ftos_gold(floor(n));
};

float() hh_loose_head_lifetime =
{
	// Original HH uses RULES_LENGTH2 / lag_setting. We do not expose that
	// config path yet, so use the original default lifetime.
	return 20;
};

void(entity holder) hh_broadcast_head_total =
{
	if ((holder == world) || (holder.classname != "player"))
		return;

	if (holder.ammo_heads < 3)
		return;

	bprint(holder.netname, " has ", hh_number(holder.ammo_heads), " heads\n");
};

void(entity holder, float dropped_heads) hh_broadcast_dropheads =
{
	if (dropped_heads >= 5)
	{
		bprint("It's a sea of heads!!!\n");
		return;
	}

	if (dropped_heads >= 3)
	{
		bprint("Many heads fly free!\n");
		return;
	}

	if (dropped_heads == 2)
	{
		bprint("Two heads are dropped!\n");
		return;
	}

	if ((dropped_heads == 1) && (holder != world) && (holder.netname != ""))
		bprint(holder.netname, "'s head is fumbled!\n");
};

void(entity altar) hh_clear_altar_head =
{
	local entity e, next;

	e = altar.chain;
	while (e != world)
	{
		next = e.chain;
		remove(e);
		e = next;
	}
	altar.chain = world;
};

void(entity altar) hh_spawn_altar_head =
{
	local entity head, prev;
	local float i;
	local float count;
	local vector ground;

	ground = altar.dest;

	count = 18;
	prev = world;
	i = 0;
	while (i < count)
	{
		head = spawn();
		head.classname = "hh_altar_head";
		head.owner = altar;
		head.movetype = MOVETYPE_NONE;
		head.solid = SOLID_NOT;
		head.touch = SUB_Null;
		head.effects = 0;
		head.avelocity = '0 0 0';
		head.angles = hh_pile_angles(i);
		head.skin = floor(random() * 12);
		setmodel(head, "progs/h_player.mdl");
		setsize(head, '0 0 0', '0 0 0');
		setorigin(head, ground + hh_pile_offset(i));

		if (i == 0)
			altar.chain = head;
		else
			prev.chain = head;

		head.chain = world;
		prev = head;
		i = i + 1;
	}

	// Spinning head on top of the spike
	head = spawn();
	head.classname = "hh_altar_head";
	head.owner = altar;
	head.movetype = MOVETYPE_NOCLIP;
	head.solid = SOLID_NOT;
	head.touch = SUB_Null;
	head.scale = 1.35;
	head.effects = 0;
	head.avelocity = '0 120 0';
	head.angles = altar.angles;
	setmodel(head, "progs/h_player.mdl");
	setsize(head, '0 0 0', '0 0 0');
	setorigin(head, ground + '0 0 86');
	prev.chain = head;
	head.chain = world;
};

float(float heads) hh_score_value =
{
	if (heads <= 0)
		return 0;

	return (heads * (heads + 1)) * 0.5;
};

float(entity holder) hh_current_carry_value =
{
	if (holder == world)
		return 0;

	if (teamplay && (holder.team > 0))
		return holder.hh_head_total_value;

	return hh_score_value(holder.ammo_heads);
};

void(entity player) hh_finish_haunting_stats =
{
	if (player == world)
		return;

	if (player.hh_stats_haunt_start > 0)
	{
		if (time > player.hh_stats_haunt_start)
			player.hh_stats_haunt_time = player.hh_stats_haunt_time + (time - player.hh_stats_haunt_start);
		player.hh_stats_haunt_start = 0;
	}
};

void(entity altar) hh_disable_altar =
{
	hh_clear_altar_head(altar);
	sound(altar, CHAN_AUTO, "misc/null.wav", 1, ATTN_STATIC);
	altar.movetype = MOVETYPE_NONE;
	altar.solid = SOLID_NOT;
	altar.touch = SUB_Null;
	altar.scale = 0;
	altar.effects = 0;
	altar.avelocity = '0 0 0';
	altar.model = string_null;
	altar.modelindex = 0;
	altar.chain = world;
	setsize(altar, '0 0 0', '0 0 0');
};

void(vector altar_origin) hh_spawn_altar_origin =
{
	local entity altar;

	altar = spawn();
	altar.classname = "info_altar";
	altar.origin = altar_origin;
	setorigin(altar, altar.origin);
	hh_configure_altar(altar);
};

/* worldspawn HH altar override keys:
"hh_altar_count" "2"
"hh_altar1" "158 1140 -120"
"hh_altar2" "2459 -1532 24"
*/
float(vector origin) hh_has_altar_origin =
{
	return ((origin_x != 0) || (origin_y != 0) || (origin_z != 0));
};

float() hh_worldspawn_altar_override_count =
{
	local float wanted;
	local float count;

	wanted = floor(world.hh_altar_count);
	if (wanted < 0) wanted = 0;
	if (wanted > 4) wanted = 4;

	if (wanted > 0)
	{
		if ((wanted >= 1) && hh_has_altar_origin(world.hh_altar1))
			count = count + 1;
		if ((wanted >= 2) && hh_has_altar_origin(world.hh_altar2))
			count = count + 1;
		if ((wanted >= 3) && hh_has_altar_origin(world.hh_altar3))
			count = count + 1;
		if ((wanted >= 4) && hh_has_altar_origin(world.hh_altar4))
			count = count + 1;
		return count;
	}

	if (hh_has_altar_origin(world.hh_altar1))
		count = count + 1;
	if (hh_has_altar_origin(world.hh_altar2))
		count = count + 1;
	if (hh_has_altar_origin(world.hh_altar3))
		count = count + 1;
	if (hh_has_altar_origin(world.hh_altar4))
		count = count + 1;

	return count;
};

float() hh_spawn_worldspawn_altars =
{
	local float wanted;
	local float spawned;

	wanted = floor(world.hh_altar_count);
	if (wanted < 0) wanted = 0;
	if (wanted > 4) wanted = 4;

	if (wanted > 0)
	{
		if ((wanted >= 1) && hh_has_altar_origin(world.hh_altar1))
		{
			hh_spawn_altar_origin(world.hh_altar1);
			spawned = spawned + 1;
		}
		if ((wanted >= 2) && hh_has_altar_origin(world.hh_altar2))
		{
			hh_spawn_altar_origin(world.hh_altar2);
			spawned = spawned + 1;
		}
		if ((wanted >= 3) && hh_has_altar_origin(world.hh_altar3))
		{
			hh_spawn_altar_origin(world.hh_altar3);
			spawned = spawned + 1;
		}
		if ((wanted >= 4) && hh_has_altar_origin(world.hh_altar4))
		{
			hh_spawn_altar_origin(world.hh_altar4);
			spawned = spawned + 1;
		}
		return spawned;
	}

	if (hh_has_altar_origin(world.hh_altar1))
	{
		hh_spawn_altar_origin(world.hh_altar1);
		spawned = spawned + 1;
	}
	if (hh_has_altar_origin(world.hh_altar2))
	{
		hh_spawn_altar_origin(world.hh_altar2);
		spawned = spawned + 1;
	}
	if (hh_has_altar_origin(world.hh_altar3))
	{
		hh_spawn_altar_origin(world.hh_altar3);
		spawned = spawned + 1;
	}
	if (hh_has_altar_origin(world.hh_altar4))
	{
		hh_spawn_altar_origin(world.hh_altar4);
		spawned = spawned + 1;
	}

	return spawned;
};

float() hh_spawn_original_altars =
{
	if (mapname == string_null)
		return 0;

	if (mapname == "dm1")
	{
		hh_spawn_altar_origin('158 1140 -120');
		return 1;
	}

	if (mapname == "dm2")
	{
		hh_spawn_altar_origin('2120 -110 32');
		hh_spawn_altar_origin('2459 -1532 24');
		return 2;
	}

	if (mapname == "dm3")
	{
		hh_spawn_altar_origin('1670 -32 -168');
		hh_spawn_altar_origin('84 -702 -16');
		return 2;
	}

	if (mapname == "dm4")
	{
		hh_spawn_altar_origin('510 -180 -100');
		return 1;
	}

	if (mapname == "dm5")
	{
		hh_spawn_altar_origin('-100 -220 216');
		hh_spawn_altar_origin('330 -224 -112');
		return 2;
	}

	if (mapname == "dm6")
	{
		hh_spawn_altar_origin('68 -1640 40');
		return 1;
	}

	if (mapname == "e1m1")
	{
		hh_spawn_altar_origin('832 2040 -408');
		hh_spawn_altar_origin('130 1580 -200');
		return 2;
	}

	if (mapname == "e1m2")
	{
		hh_spawn_altar_origin('1104 208 308');
		return 1;
	}

	if (mapname == "e1m3")
	{
		hh_spawn_altar_origin('1177 -350 190');
		hh_spawn_altar_origin('-1216 -160 -60');
		return 2;
	}

	if (mapname == "e1m4")
	{
		hh_spawn_altar_origin('785 -575 840');
		hh_spawn_altar_origin('705 2570 944');
		return 2;
	}

	if (mapname == "e1m5")
	{
		hh_spawn_altar_origin('-547 1245 160');
		return 1;
	}

	if (mapname == "e1m6")
	{
		hh_spawn_altar_origin('352 864 31');
		return 1;
	}

	if (mapname == "e1m8")
	{
		hh_spawn_altar_origin('671.4 38.5 -664');
		hh_spawn_altar_origin('694 150 32');
		return 2;
	}

	if (mapname == "e2m1")
	{
		hh_spawn_altar_origin('1580 260 -8');
		hh_spawn_altar_origin('1267 1974 282');
		return 2;
	}

	if (mapname == "e2m2")
	{
		hh_spawn_altar_origin('162 896 88');
		return 1;
	}

	if (mapname == "e2m3")
	{
		hh_spawn_altar_origin('175 598 -136');
		hh_spawn_altar_origin('196.1 -911.1 -27');
		return 2;
	}

	if (mapname == "e2m4")
	{
		hh_spawn_altar_origin('1146 2600 344');
		hh_spawn_altar_origin('596 1706 104');
		return 2;
	}

	if (mapname == "e2m5")
	{
		hh_spawn_altar_origin('794.8 1149.1 -20');
		return 1;
	}

	if (mapname == "e2m6")
	{
		hh_spawn_altar_origin('1921.1 149.4 -580');
		hh_spawn_altar_origin('595.5 945.4 -480');
		return 2;
	}

	if (mapname == "e2m7")
	{
		hh_spawn_altar_origin('1676 472 -108');
		hh_spawn_altar_origin('614 197 56');
		return 2;
	}

	if (mapname == "e3m1")
	{
		hh_spawn_altar_origin('-258 -570 -104');
		return 1;
	}

	if (mapname == "e3m2")
	{
		hh_spawn_altar_origin('190 502 24');
		hh_spawn_altar_origin('193 904 -30');
		return 2;
	}

	if (mapname == "e3m4")
	{
		hh_spawn_altar_origin('216 -2010 200');
		hh_spawn_altar_origin('680 -360 24');
		hh_spawn_altar_origin('1474 -544 -40');
		return 3;
	}

	if (mapname == "e3m5")
	{
		hh_spawn_altar_origin('-244 -2272 536');
		hh_spawn_altar_origin('606 -1666 -289');
		return 2;
	}

	if (mapname == "e3m6")
	{
		hh_spawn_altar_origin('286 -1225 -136');
		hh_spawn_altar_origin('-1084 -997 104');
		return 2;
	}

	if (mapname == "e3m7")
	{
		hh_spawn_altar_origin('-492 -242 -104');
		hh_spawn_altar_origin('212 -243 24');
		return 2;
	}

	if (mapname == "e4m1")
	{
		hh_spawn_altar_origin('1312 896 104');
		hh_spawn_altar_origin('2086 11 104');
		return 2;
	}

	if (mapname == "e4m2")
	{
		hh_spawn_altar_origin('786 -2377 536');
		hh_spawn_altar_origin('-138 876 793');
		return 2;
	}

	if (mapname == "e4m4")
	{
		hh_spawn_altar_origin('405 2269 56');
		hh_spawn_altar_origin('-1236 -1495 24');
		hh_spawn_altar_origin('-120 -974 24');
		return 3;
	}

	if (mapname == "e4m5")
	{
		hh_spawn_altar_origin('417 -205 24');
		hh_spawn_altar_origin('-1549 -1599 -376');
		return 2;
	}

	if (mapname == "e4m6")
	{
		hh_spawn_altar_origin('285 350 24');
		hh_spawn_altar_origin('546 -672 24');
		return 2;
	}

	if (mapname == "e4m7")
	{
		hh_spawn_altar_origin('-1056 782 -248');
		hh_spawn_altar_origin('415 -195 24');
		return 2;
	}

	if (mapname == "e4m8")
	{
		hh_spawn_altar_origin('1940 1000 24');
		hh_spawn_altar_origin('1426 969 24');
		return 2;
	}

	if (mapname == "end")
	{
		hh_spawn_altar_origin('-448 573 48');
		return 1;
	}

	if (mapname == "death32c")
	{
		hh_spawn_altar_origin('32 -1312 26');
		hh_spawn_altar_origin('-404 172 26');
		hh_spawn_altar_origin('715 -1169 90');
		hh_spawn_altar_origin('609.5 671.8 66');
		return 4;
	}

	if (mapname == "base32b")
	{
		hh_spawn_altar_origin('-67 1701 -406');
		hh_spawn_altar_origin('-2831 -569 -102');
		hh_spawn_altar_origin('1710 -872 -6');
		return 3;
	}

	if (mapname == "zoiddm1")
	{
		hh_spawn_altar_origin('-957 324 26');
		hh_spawn_altar_origin('1924 298 -38');
		hh_spawn_altar_origin('-1214 -1164 -166');
		return 3;
	}

	if (mapname == "trimp")
	{
		hh_spawn_altar_origin('1150 -1030.5 -998');
		return 1;
	}

	if (mapname == "manson1")
	{
		hh_spawn_altar_origin('157.5 -353 -406');
		return 1;
	}

	if (mapname == "kndybase")
	{
		hh_spawn_altar_origin('725.8 243.6 252');
		hh_spawn_altar_origin('561.8 270.8 -196');
		return 2;
	}

	if (mapname == "dapak")
	{
		hh_spawn_altar_origin('-63.9 62.6 10');
		return 1;
	}

	if (mapname == "dapak1")
	{
		hh_spawn_altar_origin('-3256.3 -588.8 282');
		hh_spawn_altar_origin('-2189.8 -451.2 74');
		return 2;
	}

	if (mapname == "dapak2")
	{
		hh_spawn_altar_origin('-784.2 491.7 -518');
		hh_spawn_altar_origin('47.5 435.1 -34');
		return 2;
	}

	if (mapname == "dapak3")
	{
		hh_spawn_altar_origin('1420.7 -56.8 26');
		return 1;
	}

	if (mapname == "dapak4")
	{
		hh_spawn_altar_origin('-349.6 -133.4 122');
		return 1;
	}

	if (mapname == "dapak5")
	{
		hh_spawn_altar_origin('-712.5 391.2 -102');
		return 1;
	}

	if (mapname == "dapak6")
	{
		hh_spawn_altar_origin('50.4 132.7 22');
		return 1;
	}

	if (mapname == "dapak7")
	{
		hh_spawn_altar_origin('-596.6 743.5 -102');
		return 1;
	}

	if (mapname == "dapak8")
	{
		hh_spawn_altar_origin('241.4 588.3 282');
		return 1;
	}

	return 0;
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
	local float carry_value;

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

	if (holder.classname == "player")
	{
		carry_value = hh_current_carry_value(holder);
		if (carry_value > holder.hh_stats_peak_value)
			holder.hh_stats_peak_value = carry_value;

		forceinfokey(holder, "heads", ftos(holder.ammo_heads));
		if (teamplay && (holder.team > 0))
			forceinfokey(holder, "headvalue", ftos(value));
		else
			forceinfokey(holder, "headvalue", ftos(hh_score_value(count)));
	}
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
		head.skin = head_owner.skin;
		head.hh_head_original_team = head_owner.team;
	}
	else
	{
		head.netname = "";
		head.colormap = 0;
		head.skin = 0;
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
	head.hh_on_altar = FALSE;
	head.hh_altar_pos = '0 0 0';
	head.hh_head_pickup_block_until = 0;
	setsize(head, '0 0 0', '0 0 0');
	setorigin(head, holder.origin);
	hh_refresh_head_value(head);
};

void(entity head) hh_hide_carried_head_visual =
{
	if (head == world)
		return;

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
};

void(entity head) hh_show_carried_head_visual =
{
	if (head == world)
		return;

	head.flags = 0;
	head.movetype = MOVETYPE_NONE;
	head.solid = SOLID_NOT;
	head.touch = SUB_Null;
	head.think = SUB_Null;
	head.nextthink = 0;
	head.avelocity = '0 0 0';
	head.frame = 0;
	head.effects = head.effects | EF_NOMODELFLAGS; // suppress blood trail while carried

	if (head.modelindex == 0)
		setmodel(head, "progs/h_player.mdl");

	setsize(head, '0 0 0', '0 0 0');
};

float(entity holder) hh_carried_head_forward_offset =
{
	local float offset;

	offset = 14;

	if ((holder.frame >= 29) && (holder.frame <= 40))
	{
		if (holder.frame == 29) offset = offset + 2;
		else if (holder.frame == 30) offset = offset + 8;
		else if (holder.frame == 31) offset = offset + 12;
		else if (holder.frame == 32) offset = offset + 11;
		else if (holder.frame == 33) offset = offset + 10;
		else if (holder.frame == 34) offset = offset + 4;
		else if (holder.frame == 35) offset = offset + 2;
		else if (holder.frame == 36) offset = offset + 10;
		else if (holder.frame == 37) offset = offset + 10;
		else if (holder.frame == 38) offset = offset + 8;
		else if (holder.frame == 39) offset = offset + 4;
		else if (holder.frame == 40) offset = offset + 2;
	}
	else if ((holder.frame >= 103) && (holder.frame <= 118))
	{
		if (holder.frame <= 104) offset = offset + 6;
		else if (holder.frame <= 106) offset = offset + 6;
		else if (holder.frame <= 112) offset = offset + 7;
		else offset = offset + 7;
	}

	return offset;
};

void(entity holder) hh_update_carried_head_visuals =
{
	local entity head;
	local vector head_origin;
	local vector carry_forward;
	local float forward_offset;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if ((holder == world) || (holder.classname != "player"))
		return;

	hh_ensure_holder_heads(holder);

	head = holder.hh_head_list;
	if (head == world)
		return;

	if ((holder.style & CLANRING_OBSERVER) || (holder.deadflag != DEAD_NO) || (holder.health <= 0))
	{
		while (head != world)
		{
			hh_hide_carried_head_visual(head);
			head = head.hh_head_next;
		}
		return;
	}

	makevectors(holder.angles);
	carry_forward = v_forward;
	carry_forward_z = (-1 * carry_forward_z);
	forward_offset = hh_carried_head_forward_offset(holder);

	// Only show one head visually to reduce entity overhead
	hh_show_carried_head_visual(head);
	head.angles = holder.angles + '0 0 -45';
	head_origin = holder.origin + '0 0 -16';
	head_origin = head_origin - (forward_offset * carry_forward);
	head_origin_z = head_origin_z + 4;
	head.velocity = '0 0 0';
	setorigin(head, head_origin);

	head = head.hh_head_next;
	while (head != world)
	{
		hh_hide_carried_head_visual(head);
		head = head.hh_head_next;
	}
};

void(entity player) hh_reset_player_head_state =
{
	if (player == world)
		return;

	if (player.hh_eyecam_target != world)
		hh_set_eyecam(player, world);

	hh_finish_haunting_stats(player);
	player.hh_spirit_head = world;
	player.hh_altar_pos = '0 0 0';
	player.hh_is_head = FALSE;
	player.hh_on_altar = FALSE;
	player.hh_haunting = FALSE;
	player.hh_haunt_over = 0;
	player.hh_can_bite = 0;
	player.hh_eyecam_target = world;
	player.hh_help_state = 0;
	player.hh_help_context = 0;
};

void(entity player) hh_hide_spirit_player =
{
	if (player == world)
		return;

	setmodel(player, string_null);
	player.frame = 0;
	player.solid = SOLID_NOT;
	player.movetype = MOVETYPE_NONE;
	player.finaldest_y = MOVETYPE_NONE;
	player.touch = SUB_Null;
	player.velocity = '0 0 0';
	player.avelocity = '0 0 0';
	player.takedamage = DAMAGE_NO;
	player.view_ofs = '0 0 8';
	setsize(player, '0 0 0', '0 0 0');
};

void(entity player) hh_show_spirit_player =
{
	if (player == world)
		return;

	setmodel(player, "progs/spike.mdl");
	player.frame = 0;
	player.solid = SOLID_NOT;
	player.movetype = MOVETYPE_NOCLIP;
	player.finaldest_y = MOVETYPE_NOCLIP;
	player.touch = SUB_Null;
	player.takedamage = DAMAGE_NO;
	player.view_ofs = '0 0 8';
	setsize(player, '-16 -16 0', '0 0 16');
};

void(entity head, float reclaimed) hh_unlink_spirit_head =
{
	local entity player, oself;

	if (head == world)
		return;

	player = head.hh_head_owner;
	if ((player != world) && (player.classname == "player") && (player.hh_spirit_head == head))
	{
		player.hh_spirit_head = world;

		hh_set_eyecam(player, world);

		// Force a clean respawn — never leave the player in limbo
		// (hh_is_head with no spirit head and no altar/haunt state)
		if (player.hh_is_head && !player.hh_on_altar && !player.hh_haunting)
		{
			if (reclaimed)
				centerprint(player, "Your head was recovered by your team");

			oself = self;
			self = player;
			respawn();
			self = oself;
		}
	}

	head.hh_on_altar = FALSE;
	head.hh_altar_pos = '0 0 0';
};

float(entity player) hh_player_in_altar_camp =
{
	local entity ent;
	local vector altar_origin;

	if (player == world)
		return FALSE;

	ent = findradius(player.origin, 128);
	while (ent != world)
	{
		if (((ent.classname == "info_altar") || (ent.classname == "altar")) && (ent.solid == SOLID_TRIGGER))
		{
			altar_origin = ent.origin + '0 0 64';
			traceline(altar_origin, player.origin, TRUE, player);
			if (trace_fraction == 1)
				return TRUE;
		}

		ent = ent.chain;
	}

	ent = findradius(player.origin, 200);
	while (ent != world)
	{
		if (((ent.classname == "info_altar") || (ent.classname == "altar")) && (ent.solid == SOLID_TRIGGER))
			return TRUE;

		ent = ent.chain;
	}

	return FALSE;
};

void(entity player) hh_check_camp =
{
	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if ((player == world) || (player.classname != "player"))
		return;

	if (player.hh_is_head || (player.style & CLANRING_OBSERVER) || (player.deadflag != DEAD_NO) || (player.health <= 0))
		return;

	if (player.hh_camp_countdown == 0)
	{
		if (player.hh_camp_check < time)
		{
			player.hh_camp_check = time + 2;
			if (hh_player_in_altar_camp(player))
			{
				player.hh_camp_countdown = time + 11;
				player.hh_camp_check = time + 11;
			}
		}
		return;
	}

	if (player.hh_camp_countdown > time)
		return;

	player.hh_camp_countdown = player.hh_camp_countdown + 1;
	if (hh_player_in_altar_camp(player))
	{
		centerprint(player, "The Gods punish campers!\n\nGet away from the altar!");
		if (time > (player.hh_camp_check + 4))
			T_Damage(player, world, world, 10);
		else
			T_Damage(player, world, world, 1);
		return;
	}

	player.hh_camp_countdown = 0;
	player.hh_camp_check = time + 2;
};

vector(float slot) hh_pile_offset =
{
	local float i, layer;
	local vector v;

	layer = floor(slot / 18);
	i = slot - (layer * 18);
	if (i > 17) i = 17;

	// Bottom row: wide spread, 9 heads
	if (i == 0)       v = '-34 -20 0';
	else if (i == 1)  v = '-18 -26 2';
	else if (i == 2)  v = '0 -22 1';
	else if (i == 3)  v = '16 -18 3';
	else if (i == 4)  v = '30 -12 0';
	else if (i == 5)  v = '-26 -4 1';
	else if (i == 6)  v = '34 2 2';
	else if (i == 7)  v = '-10 8 0';
	else if (i == 8)  v = '12 10 2';
	// Middle row: 5 heads
	else if (i == 9)  v = '-24 -10 13';
	else if (i == 10) v = '-8 -14 15';
	else if (i == 11) v = '8 -6 16';
	else if (i == 12) v = '22 1 14';
	else if (i == 13) v = '-2 4 13';
	// Upper row: 3 heads
	else if (i == 14) v = '-12 3 27';
	else if (i == 15) v = '6 6 29';
	else if (i == 16) v = '-4 -8 28';
	// Top
	else              v = '0 0 39';

	// Extra layers stack higher and pull inward
	v_x = v_x * 0.82;
	v_y = v_y * 0.82;
	v_z = v_z + (layer * 14);

	return v;
};

vector(float slot) hh_pile_angles =
{
	local float i;

	i = slot - (floor(slot / 18) * 18);

	if (i == 0)       return '72 18 -34';
	else if (i == 1)  return '96 140 -12';
	else if (i == 2)  return '84 250 16';
	else if (i == 3)  return '66 40 48';
	else if (i == 4)  return '92 310 -26';
	else if (i == 5)  return '78 195 30';
	else if (i == 6)  return '86 85 -18';
	else if (i == 7)  return '62 155 -40';
	else if (i == 8)  return '100 290 36';
	else if (i == 9)  return '48 75 -58';
	else if (i == 10) return '110 180 8';
	else if (i == 11) return '58 12 66';
	else if (i == 12) return '88 285 -44';
	else if (i == 13) return '74 330 22';
	else if (i == 14) return '36 120 -72';
	else if (i == 15) return '52 230 54';
	else if (i == 16) return '94 50 42';

	return '12 0 -90';
};

void() hh_altar_head_expire =
{
	SUB_Remove();
};

void(entity altar, entity head, float slot) hh_send_head_to_altar =
{
	local vector altar_pos;

	if ((altar == world) || (head == world))
		return;

	altar_pos = altar.dest + hh_pile_offset(slot);

	head.owner = world;
	head.hh_head_next = world;
	head.hh_on_altar = TRUE;
	head.hh_altar_pos = altar_pos;
	head.flags = 0;
	head.movetype = MOVETYPE_NONE;
	head.solid = SOLID_NOT;
	head.touch = SUB_Null;
	head.think = hh_altar_head_expire;
	head.nextthink = time + 30;
	head.velocity = '0 0 0';
	head.avelocity = '0 0 0';
	head.angles = hh_pile_angles(slot);
	head.frame = 0;
	setmodel(head, "progs/h_player.mdl");
	setsize(head, '0 0 0', '0 0 0');
	setorigin(head, altar_pos);
};

void(entity player, entity target) hh_set_eyecam =
{
	local float target_changed;

	if (player == world)
		return;

	target_changed = (player.hh_eyecam_target != target);

	// Sync position, angles, weapon viewmodel, and HUD stats every frame
	if (target != world)
	{
		setorigin(player, target.origin);
		player.v_angle = player.angles = target.v_angle;
		player.fixangle = TRUE;
		player.view_ofs = '0 0 22';
		player.weaponmodel = target.weaponmodel;
		player.weaponframe = target.weaponframe;
		player.items = target.items;
		player.weapon = target.weapon;
		player.currentammo = target.currentammo;
		player.ammo_shells = target.ammo_shells;
		player.ammo_nails = target.ammo_nails;
		player.ammo_rockets = target.ammo_rockets;
		player.ammo_cells = target.ammo_cells;
		player.health = target.health;
		player.armorvalue = target.armorvalue;
	}
	else
	{
		player.weaponmodel = string_null;
		player.weaponframe = 0;
	}

	// Only send viewport message when the target actually changes
	if (!target_changed)
		return;

	player.hh_eyecam_target = target;
	msg_entity = player;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	if (target != world)
	{
		WriteEntity(MSG_ONE, target);
		forceinfokey(player, "*observer", "eyecam");
		forceinfokey(player, "observer", "eyecam");
		forceinfokey(player, "observing", target.netname);
	}
	else
	{
		WriteEntity(MSG_ONE, player);
		forceinfokey(player, "*observer", "off");
		forceinfokey(player, "observer", "off");
		forceinfokey(player, "observing", "off");
	}
};

void(entity player) hh_head_takeover =
{
	local entity head;

	if ((player == world) || !player.hh_is_head)
		return;

	head = player.hh_spirit_head;
	if (head == world)
		return;

	hh_set_eyecam(player, world);

	if (vlen(head.hh_altar_pos) > 0)
		player.hh_altar_pos = head.hh_altar_pos;
	else
		player.hh_altar_pos = head.origin;

	setmodel(player, "progs/h_player.mdl");
	player.skin = head.skin;
	player.frame = 0;
	player.solid = SOLID_NOT;
	player.movetype = MOVETYPE_NONE;
	player.finaldest_y = MOVETYPE_NONE;
	player.touch = SUB_Null;
	player.velocity = '0 0 0';
	player.avelocity = '0 0 0';
	player.takedamage = DAMAGE_NO;
	player.view_ofs = '0 0 8';
	setsize(player, '-16 -16 0', '0 0 16');
	setorigin(player, player.hh_altar_pos);
	player.hh_spirit_head = world;
	player.hh_on_altar = TRUE;
	player.hh_haunting = FALSE;
	remove(head);
	centerprint(player, "You can haunt other players\nby holding jump to fly.\nKill the campers.");
};

void() hh_haunt_touch =
{
	if (other.classname != "player")
		return;

	if ((other == self) || other.deadflag || (other.health <= 0) || !other.takedamage)
		return;

	if (self.hh_can_bite > time)
		return;

	if (random() < 0.5)
		sound(self, CHAN_VOICE, "hhsounds/bite1.wav", 1, ATTN_NONE);
	else
		sound(self, CHAN_VOICE, "hhsounds/bite2.wav", 1, ATTN_NONE);

	T_Damage(other, self, self, 5);
	self.hh_stats_haunt_bites = self.hh_stats_haunt_bites + 1;
	if (other.deadflag || (other.health <= 0))
		self.hh_stats_haunt_kills = self.hh_stats_haunt_kills + 1;
	self.hh_can_bite = time + 0.25;
};

void(entity player) hh_start_haunting =
{
	local float haunt_limit;

	if ((player == world) || !player.hh_is_head)
		return;

	hh_finish_haunting_stats(player);
	player.hh_haunting = TRUE;
	player.hh_stats_haunts_started = player.hh_stats_haunts_started + 1;
	player.solid = SOLID_NOT;
	player.movetype = MOVETYPE_NOCLIP;
	player.finaldest_y = MOVETYPE_NOCLIP;
	player.origin_z = player.origin_z + 24;
	player.touch = SUB_Null;
	player.velocity = '0 0 0';
	player.takedamage = DAMAGE_NO;
	player.hh_can_bite = time + 1;
	haunt_limit = player.frags + 10;
	if (haunt_limit < 10)
		haunt_limit = 10;
	player.hh_haunt_over = time + haunt_limit;
	player.hh_stats_haunt_start = time;
	player.angles_x = -90;
	player.angles_z = 0;
	setsize(player, '-16 -16 0', '16 16 16');
	setorigin(player, player.origin);
	player.effects = player.effects | EF_GREEN;
};

void(entity player) hh_check_haunt =
{
	if ((player == world) || !player.hh_is_head || player.hh_haunting || !player.hh_on_altar)
		return;

	if (!player.button2)
		return;

	hh_start_haunting(player);
};

void(entity player) hh_hauntmove =
{
	local entity head, oself;
	local float spd;

	if ((player == world) || !player.hh_haunting)
		return;

	if ((player.hh_haunt_over <= 0) || (time >= player.hh_haunt_over))
	{
		player.effects = player.effects - (player.effects & EF_GREEN);
		hh_set_eyecam(player, world);
		oself = self;
		self = player;
		respawn();
		self = oself;
		return;
	}

	// Keep the head model upright and facing the look direction
	player.angles_x = -90;
	player.angles_y = player.v_angle_y;
	player.angles_z = 0;

	// Fly movement matching observer camera style
	makevectors(player.v_angle);
	player.velocity = v_forward * player.movement_x + v_right * player.movement_y;
	if (player.button2)
		player.velocity_z = player.velocity_z + 200;
	else
		player.velocity_z = player.velocity_z + player.movement_z;

	spd = vlen(player.velocity);
	if (spd > 2000)
		player.velocity = normalize(player.velocity) * 2000;

	// Proximity bite check (replaces touch-based biting since NOCLIP has no collision)
	if (player.hh_can_bite > time)
		return;

	head = findradius(player.origin, 48);
	while (head != world)
	{
		if (head.classname == "player" && head != player && !head.deadflag && head.health > 0 && head.takedamage)
		{
			if (random() < 0.5)
				sound(player, CHAN_VOICE, "hhsounds/bite1.wav", 1, ATTN_NONE);
			else
				sound(player, CHAN_VOICE, "hhsounds/bite2.wav", 1, ATTN_NONE);

			T_Damage(head, player, player, 5);
			player.hh_stats_haunt_bites = player.hh_stats_haunt_bites + 1;
			if (head.deadflag || (head.health <= 0))
				player.hh_stats_haunt_kills = player.hh_stats_haunt_kills + 1;
			player.hh_can_bite = time + 0.25;
			break;
		}
		head = head.chain;
	}
};

void(entity player) hh_player_prethink =
{
	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (player == world)
		return;

	if (!player.hh_is_head)
	{
		hh_check_camp(player);
		return;
	}

	hh_check_haunt(player);
	if (player.hh_haunting)
		hh_hauntmove(player);
};

void(entity player) hh_player_postthink =
{
	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if ((player == world) || !player.hh_is_head)
		return;

	if (player.hh_haunting)
		return;

	if (player.hh_spirit_head != world)
	{
		local entity carrier;

		if (player.hh_spirit_head.hh_on_altar)
		{
			hh_head_takeover(player);
			return;
		}

		carrier = player.hh_spirit_head.owner;

		if ((carrier != world)
			&& (carrier.classname == "player")
			&& (carrier.health > 0)
			&& !carrier.deadflag
			&& (carrier.style & CLANRING_CONNECTED)
			&& !(carrier.style & CLANRING_OBSERVER))
		{
			// Head is being carried — eyecam on the carrier
			hh_hide_spirit_player(player);
			player.velocity = '0 0 0';
			hh_set_eyecam(player, carrier);
		}
		else
		{
			// Head on ground or carrier invalid — own view, follow head
			if (carrier != world)
				player.hh_spirit_head.owner = world;
		hh_show_spirit_player(player);
		setorigin(player, player.hh_spirit_head.origin);
		player.velocity = '0 0 0';
			hh_set_eyecam(player, world);
		}
		return;
	}

	if (player.hh_on_altar)
	{
		setorigin(player, player.hh_altar_pos);
		return;
	}

	hh_hide_spirit_player(player);
};

void() hh_player_die =
{
	local float damage;
	local entity head;
	local vector launch_velocity;

	damage = self.health;
	head = hh_new_head_entity(self);
	launch_velocity = VelocityForDamage(damage);
	launch_velocity_z = launch_velocity_z + 120 + (random() * 120);
	hh_release_head(head, self.origin + '0 0 16', launch_velocity);

	hh_reset_player_head_state(self);
	self.hh_is_head = TRUE;
	self.hh_spirit_head = head;
	self.deadflag = DEAD_DEAD;
	self.nextthink = -1;
	self.think = SUB_Null;
	self.health = 1;
	self.classname = "player";
	self.weaponmodel = "";
	self.weaponframe = 0;
	self.weapon = IT_AXE;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	hh_show_spirit_player(self);
	setorigin(self, head.origin);

	if ((damage < -40) && !(clanring_playmode & CLANRING_NO_GIBS))
	{
		ThrowGib("progs/gib1.mdl", damage);
		ThrowGib("progs/gib2.mdl", damage);
		if (!(clanring_playmode & CLANRING_LOW_GIBS))
			ThrowGib("progs/gib3.mdl", damage);

		if (random() < 0.5)
			sound(self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NORM);
		else
			sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
	}
	else
	{
		DeathSound();
	}
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
			if (collector.classname == "player")
				collector.hh_stats_heads_reclaimed = collector.hh_stats_heads_reclaimed + 1;
			hh_unlink_spirit_head(head, TRUE);
			remove(head);
			return 2;
		}

		return 0;
	}

	hh_stow_head(head, collector, TRUE);
	if (collector.classname == "player")
		collector.hh_stats_heads_picked = collector.hh_stats_heads_picked + 1;
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

	if (src.classname == "player")
	{
		forceinfokey(src, "heads", "0");
		forceinfokey(src, "headvalue", "0");
	}

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

	if (holder.classname == "player")
	{
		forceinfokey(holder, "heads", "0");
		forceinfokey(holder, "headvalue", "0");
	}

	while (head != world)
	{
		next = head.hh_head_next;
		hh_unlink_spirit_head(head, FALSE);
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
	head.lip = time + hh_loose_head_lifetime();
	head.think = hh_head_settle;
	head.nextthink = time + 0.5;
	head.hh_on_altar = FALSE;
	head.hh_altar_pos = '0 0 0';
	head.hh_head_pickup_block_until = 0;
	head.effects = head.effects - (head.effects & EF_NOMODELFLAGS); // restore blood trail
	head.avelocity_x = random() * 600;
	head.avelocity_y = random() * 600;
	head.avelocity_z = random() * 600;
	head.velocity = launch_velocity;
	head.origin = spawn_origin;
	setmodel(head, "progs/h_player.mdl");
	setsize(head, '-16 -16 0', '16 16 24');
	setorigin(head, head.origin);
};

void(entity holder, vector spawn_origin, float damage) hh_release_holder_heads =
{
	local entity head;
	local entity next;
	local vector head_origin;
	local vector launch_velocity;
	local float dropped_heads;

	if (holder == world)
		return;

	hh_ensure_holder_heads(holder);
	dropped_heads = holder.ammo_heads;
	if ((holder.classname == "player") && (dropped_heads > 0))
		holder.hh_stats_heads_dropped = holder.hh_stats_heads_dropped + dropped_heads;

	head = holder.hh_head_list;
	holder.hh_head_list = world;
	holder.ammo_heads = 0;
	holder.hh_head_total_value = 0;

	if (holder.classname == "player")
	{
		forceinfokey(holder, "heads", "0");
		forceinfokey(holder, "headvalue", "0");
	}

	while (head != world)
	{
		next = head.hh_head_next;
		head.hh_head_next = world;

		head_origin = spawn_origin;
		head_origin_x = head_origin_x - 20 + (random() * 40);
		head_origin_y = head_origin_y - 20 + (random() * 40);
		head_origin_z = head_origin_z + 8 + (random() * 16);

		launch_velocity = VelocityForDamage(damage);
		launch_velocity_x = launch_velocity_x - 220 + (random() * 440);
		launch_velocity_y = launch_velocity_y - 220 + (random() * 440);
		launch_velocity_z = launch_velocity_z + 120 + (random() * 120);

		hh_release_head(head, head_origin, launch_velocity);
		head = next;
	}

	hh_broadcast_dropheads(holder, dropped_heads);
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
			sprint(head.hh_head_previous_owner_1, scorer.netname, " scores a head you handled for ", hh_number(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_2 != world)
		&& (head.hh_head_previous_owner_2.classname == "player")
		&& (head.hh_head_previous_owner_2.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_2, value);
		if (head.hh_head_previous_owner_2 != scorer)
			sprint(head.hh_head_previous_owner_2, scorer.netname, " scores a head you handled for ", hh_number(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_3 != world)
		&& (head.hh_head_previous_owner_3.classname == "player")
		&& (head.hh_head_previous_owner_3.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_3, value);
		if (head.hh_head_previous_owner_3 != scorer)
			sprint(head.hh_head_previous_owner_3, scorer.netname, " scores a head you handled for ", hh_number(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_4 != world)
		&& (head.hh_head_previous_owner_4.classname == "player")
		&& (head.hh_head_previous_owner_4.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_4, value);
		if (head.hh_head_previous_owner_4 != scorer)
			sprint(head.hh_head_previous_owner_4, scorer.netname, " scores a head you handled for ", hh_number(value), " frags\n");
	}

	if ((head.hh_head_previous_owner_5 != world)
		&& (head.hh_head_previous_owner_5.classname == "player")
		&& (head.hh_head_previous_owner_5.team == scorer.team))
	{
		hh_award_player_frag(head.hh_head_previous_owner_5, value);
		if (head.hh_head_previous_owner_5 != scorer)
			sprint(head.hh_head_previous_owner_5, scorer.netname, " scores a head you handled for ", hh_number(value), " frags\n");
	}

	return value;
};

void() hh_head_settle =
{
	if (self.flags & FL_ONGROUND)
	{
		// Flatten angles and nudge above floor so model doesn't clip through
		self.angles_x = 0;
		self.angles_z = 0;
		self.movetype = MOVETYPE_NONE;
		self.avelocity = '0 0 0';
		self.velocity = '0 0 0';
		setorigin(self, self.origin + '0 0 6');
		self.think = hh_head_think;
		self.nextthink = self.lip;
		return;
	}

	if (time >= self.lip)
	{
		hh_head_think();
		return;
	}

	self.nextthink = time + 0.1;
};

void() hh_head_think =
{
	hh_unlink_spirit_head(self, FALSE);
	SUB_Remove();
};

void() hh_head_touch =
{
	local float result;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if (other.classname != "player")
		return;

	if (other.hh_is_head)
		return;

	if ((self.hh_head_last_owner == other) && (self.hh_head_pickup_block_until > time))
		return;

	if (other.deadflag || other.health <= 0)
		return;

	result = hh_collect_head(other, self);
	if (result <= 0)
		return;

	sound(other, CHAN_ITEM, hh_random_pickup_sound(), 1, ATTN_NORM);
	stuffcmd(other, "bf\n");

	if (result == 2)
	{
		sprint(other, "You reclaimed your team's head for ", hh_number(1), " frag\n");
		return;
	}

	hh_refresh_holder_heads(other);

	if (self.hh_head_owner == other)
		sprint(other, "You got your own head\n");
	else if (self.netname != "")
		sprint(other, "You got ", self.netname, "'s head\n");
	else
		sprint(other, "You got a head\n");

	// Notify the head owner that their head was picked up (only if still dead/spectating as head)
	if (self.hh_head_owner != world && self.hh_head_owner != other && self.hh_head_owner.classname == "player" && self.hh_head_owner.hh_is_head)
		centerprint(self.hh_head_owner, other.netname, " picked up your head");

	hh_broadcast_head_total(other);
};

void() hh_altar_touch =
{
	local entity head;
	local entity next;
	local float recovered, score;
	local float altar_slot;

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
		forceinfokey(other, "heads", "0");
		forceinfokey(other, "headvalue", "0");

		while (head != world)
		{
			next = head.hh_head_next;
			score = score + hh_score_teamplay_head(other, head);
			if (!((head.hh_head_owner != world) && (head.hh_head_owner.classname == "player") && head.hh_head_owner.hh_is_head))
				hh_unlink_spirit_head(head, FALSE);
			hh_send_head_to_altar(self, head, altar_slot);
			altar_slot = altar_slot + 1;
			head = next;
		}
	}
	else
	{
		head = other.hh_head_list;
		other.hh_head_list = world;
		other.ammo_heads = 0;
		other.hh_head_total_value = 0;
		forceinfokey(other, "heads", "0");
		forceinfokey(other, "headvalue", "0");
		score = hh_score_value(recovered);
		hh_award_player_frag(other, score);

		while (head != world)
		{
			next = head.hh_head_next;
			if (!((head.hh_head_owner != world) && (head.hh_head_owner.classname == "player") && head.hh_head_owner.hh_is_head))
				hh_unlink_spirit_head(head, FALSE);
			hh_send_head_to_altar(self, head, altar_slot);
			altar_slot = altar_slot + 1;
			head = next;
		}
	}

	if (other.invincible_finished < time)
		other.invincible_finished = time;
	other.invincible_finished = other.invincible_finished + (3 * recovered);
	other.hh_stats_heads_scored = other.hh_stats_heads_scored + recovered;
	other.hh_stats_score_value = other.hh_stats_score_value + score;
	other.invincible_time = 1;
	other.items = other.items | IT_INVULNERABILITY;
	other.effects = other.effects | EF_RED | EF_DIMLIGHT;
	sound(self, CHAN_ITEM, hh_random_altar_sound(), 1, ATTN_NORM);
	stuffcmd(other, "bf\n");

	if (teamplay && (other.team > 0))
	{
		if (recovered == 1)
			bprint(other.netname, " scores ", hh_number(1), " head for the team\n");
		else
			bprint(other.netname, " scores ", hh_number(recovered), " heads for the team\n");
	}
	else if (recovered == 1)
		bprint(other.netname, " scores ", hh_number(1), " head for ", hh_number(1), " frag\n");
	else
		bprint(other.netname, " scores ", hh_number(recovered), " heads for ", hh_number(score), " frags\n");
};

void() hh_backpack_expire =
{
	hh_destroy_holder_heads(self);
	SUB_Remove();
};

void(entity altar) hh_configure_altar =
{
	local vector ground;

	hh_clear_altar_head(altar);

	// Find the ground below the altar
	traceline(altar.origin, altar.origin - '0 0 256', TRUE, altar);
	ground = trace_endpos;
	altar.dest = ground;

	// Position the spike model above the ground
	setmodel(altar, "progs/v_spike.mdl");
	altar.movetype = MOVETYPE_NOCLIP;
	altar.solid = SOLID_TRIGGER;
	altar.touch = hh_altar_touch;
	altar.scale = 3;
	altar.effects = altar.effects | EF_FULLBRIGHT | EF_RED;
	altar.avelocity = '0 120 0';
	setorigin(altar, ground + '0 0 80');
	setsize(altar, '-128 -128 -80', '128 128 48');
	sound(altar, CHAN_AUTO, "hhsounds/altamb.wav", 0.7, ATTN_STATIC);
	hh_spawn_altar_head(altar);
};

/*QUAKED info_altar (0 .5 .8) (-128 -128 -112) (128 128 0)
Head Hunters scoring altar. Carry heads here to score and gain invulnerability.
*/
void() info_altar =
{
	if ((clanring_playmode & CLANRING_HH_MODE) && (hh_worldspawn_altar_override_count() <= 0))
		hh_configure_altar(self);
	else
		hh_disable_altar(self);
};

void(entity source) hh_spawn_altar_at =
{
	hh_spawn_altar_origin(source.origin + '0 0 56');
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
	local float active;
	local float existing;
	local float need;
	local float made;

	if (!(clanring_playmode & CLANRING_HH_MODE))
	{
		if (self.classname == "scheduled_event_entity")
			remove(self);
		return;
	}

	// Worldspawn overrides take priority over mapper entities and the built-in
	// original-table fallback.
	if (hh_worldspawn_altar_override_count() > 0)
	{
		altar = find(world, classname, "info_altar");
		while (altar != world)
		{
			if (altar.solid == SOLID_TRIGGER)
				active = active + 1;
			altar = find(altar, classname, "info_altar");
		}

		if (active > 0)
			existing = active;
		else
			existing = hh_spawn_worldspawn_altars();
	}

	// Ensure mapper-placed altars are always activated in HH mode.
	altar = find(world, classname, "info_altar");
	while ((altar != world) && (existing <= 0))
	{
		hh_configure_altar(altar);
		existing = existing + 1;
		altar = find(altar, classname, "info_altar");
	}

	// Prefer the original HH map table before falling back to a generic single altar.
	if (existing == 0)
		existing = hh_spawn_original_altars();

	if (existing == 0)
	{
		need = 1;

		if (made < need) made = made + hh_spawn_altars_from_class("item_armor1", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_nailgun", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_supernailgun", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_armor2", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_artifact_super_damage", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_sigil", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_rocketlauncher", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_lightning", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("weapon_grenadelauncher", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_key1", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_key2", need - made);
		if (made < need) made = made + hh_spawn_altars_from_class("item_armorInv", need - made);
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

void() hh_unlock_passed_head =
{
	self.hh_head_pickup_block_until = 0;
	self.hh_head_last_owner = world;
	self.lip = time + hh_loose_head_lifetime();
	self.think = hh_head_settle;
	self.nextthink = time + 0.5;
};

void() hh_toss_head =
{
	local entity head;
	local vector launch_velocity;

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

	head = hh_pop_holder_head(self);
	if (head == world)
	{
		sprint(self, "You do not have any heads to toss\n");
		return;
	}

	makevectors(self.v_angle);
	launch_velocity = aim(self, 1000) * 600;
	launch_velocity_z = launch_velocity_z + 120;
	head.hh_head_last_owner = self;
	head.hh_head_pickup_block_until = time + 0.2;
	hh_release_head(head, self.origin + '0 0 16', launch_velocity);
	head.think = hh_unlock_passed_head;
	head.nextthink = time + 0.2;
	sound(self, CHAN_VOICE, "player/pain2.wav", 1, ATTN_NONE);
};

void() hh_call_teammate =
{
	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	sound(self, CHAN_VOICE, hh_random_catch_sound(), 1, ATTN_NONE);
};

void() hh_auto_help_tip =
{
	local float context;
	local float state;

	if (!(clanring_playmode & CLANRING_HH_MODE))
		return;

	if ((self.hh_camp_countdown <= time) && (self.hh_camp_countdown != 0))
	{
		centerprint(self, "You are taking altar\ncamping damage!\nClear the altar area.");
		return;
	}

	if (self.hh_haunting)
		context = 3;
	else if (self.hh_on_altar)
		context = 4;
	else if (self.hh_is_head)
		context = 5;
	else if (hh_player_in_altar_camp(self))
		context = 2;
	else if (!teamplay && (self.ammo_heads <= 0))
		context = 6;
	else if (!teamplay)
		context = 7;
	else if (self.ammo_heads <= 0)
		context = 8;
	else
		context = 9;

	if (self.hh_help_context != context)
	{
		self.hh_help_context = context;
		self.hh_help_state = 0;
	}

	state = floor(self.hh_help_state);

	if (context == 2)
	{
		centerprint(self, "If you camp at the altar\nthe gods will punish you");
		return;
	}

	if (context == 3)
	{
		if (state == 0)
			centerprint(self, "You are haunting. Fly\ninto other players to bite them");
		else if (state == 1)
			centerprint(self, "Hold jump and use\nmlook to fly");
		else
			centerprint(self, "Bite the campers");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 2)
			self.hh_help_state = 0;
		return;
	}

	if (context == 4)
	{
		if (state == 0)
			centerprint(self, "You have been taken to\nthe altar");
		else if (state == 1)
			centerprint(self, "You can haunt by holding\njump and mlooking to fly");
		else
			centerprint(self, "When haunting be sure to\nbite the campers");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 2)
			self.hh_help_state = 0;
		return;
	}

	if (context == 5)
	{
		if (state == 0)
			centerprint(self, "You are a head!");
		else
			centerprint(self, "Get carried to the altar\nto haunt other players");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 1)
			self.hh_help_state = 0;
		return;
	}

	if (context == 6)
	{
		if (state == 0)
			centerprint(self, "Kill players and run over\ntheir heads to pick them up");
		else if (state == 1)
			centerprint(self, "Get frags by taking\nheads to the altar");
		else if (state == 2)
			centerprint(self, "Each head you pick up\nis worth more frags.");
		else
			centerprint(self, "Gather a lot of heads\nfor big scores.");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 3)
			self.hh_help_state = 0;
		return;
	}

	if (context == 7)
	{
		if (state == 0)
			centerprint(self, "You have heads\nLook down to see them.");
		else if (state == 1)
			centerprint(self, "Take the heads you have\nto the altar to get frags");
		else if (state == 2)
			centerprint(self, "The value of the heads\nis shown on the HUD.");
		else
			centerprint(self, "Gather more heads\nfor huge scores.");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 3)
			self.hh_help_state = 0;
		return;
	}

	if (context == 8)
	{
		if (state == 0)
			centerprint(self, "Kill players and run over\ntheir heads to pick them up");
		else if (state == 1)
			centerprint(self, "Get frags by taking\nheads to the altar");
		else if (state == 2)
			centerprint(self, "Each head you pick up\nis worth a frag.");
		else if (state == 3)
			centerprint(self, "Pass heads to teammates\nusing 9.");
		else if (state == 4)
			centerprint(self, "Heads gain value\nfor each holder.");
		else if (state == 5)
			centerprint(self, "Heads give frags to\neveryone who held them");
		else if (state == 6)
			centerprint(self, "Use your hhcall bind to\nyell to your teammate.");
		else if (state == 7)
			centerprint(self, "Run over your own team's heads\nto take them out of play");
		else
			centerprint(self, "Reclaim your own team's head\nand get a bonus frag.");

		self.hh_help_state = state + 1;
		if (self.hh_help_state > 8)
			self.hh_help_state = 0;
		return;
	}

	if (state == 0)
		centerprint(self, "You have heads\nLook down to see them.");
	else if (state == 1)
		centerprint(self, "Take the heads you have\nto the altar to get frags");
	else if (state == 2)
		centerprint(self, "The value of the heads\nis shown on the HUD.");
	else if (state == 3)
		centerprint(self, "Pass the heads to teammates\nusing 9.");
	else if (state == 4)
		centerprint(self, "Heads gain value\nfor each holder.");
	else if (state == 5)
		centerprint(self, "Heads give frags to\neveryone who held them");
	else if (state == 6)
		centerprint(self, "So pass the head and\nguard your teammate");
	else if (state == 7)
		centerprint(self, "Because he's carrying\nyour frags!");
	else
		centerprint(self, "Passing is the route\nto big scores");

	self.hh_help_state = state + 1;
	if (self.hh_help_state > 8)
		self.hh_help_state = 0;
};
