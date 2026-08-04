//
// vote_ip.qc
//
// Shared voter identity and tally helpers.  Live request polls and the
// intermission map ballot both use these rules so their denominators and
// duplicate-IP handling cannot drift apart.
//

float VOTE_IP_MODE_OFF = 0;
float VOTE_IP_MODE_ENFORCE = 1;
float VOTE_IP_MODE_MONITOR = 2;

float VOTE_BALLOT_LIVE = 1;
float VOTE_BALLOT_MAP = 2;

float VOTE_IP_NOTICE_COOLDOWN = 2;
float VOTE_MAP_CHANGE_COOLDOWN = 2;

string(string ip_with_port) clanring_normalize_ip =
{
	local string ip;
	local float pos, colon_count, i;

	ip = ip_with_port;
	if (!ip || ip == "")
		return "";

	// [IPv6]:port or [IPv6]
	if (substring(ip, 0, 1) == "[")
	{
		pos = strstrofs(ip, "]", 0);
		if (pos > 1)
			return strtolower(substring(ip, 1, pos - 1));
		return strtolower(ip);
	}

	// IPv4:port (or hostname:port) -> strip its one trailing port. Plain
	// IPv6 contains multiple colons and must remain intact.
	colon_count = 0;
	for (i = 0; i < strlen(ip); i = i + 1)
	{
		if (substring(ip, i, 1) == ":")
			colon_count = colon_count + 1;
	}

	if (colon_count == 1)
	{
		pos = strstrofs(ip, ":", 0);
		if (pos > 0)
			return strtolower(substring(ip, 0, pos));
	}

	return strtolower(ip);
};

float(string normalized_ip) VoteIP_IsPrivateAddress =
{
	local string ip;
	local float pos, octet;

	ip = strtolower(normalized_ip);
	if (!ip || ip == "")
		return FALSE;

	// Normalize an IPv4-mapped IPv6 address for the IPv4 checks below.
	if (substring(ip, 0, 7) == "::ffff:")
		ip = substring(ip, 7, strlen(ip) - 7);

	if (ip == "local" || ip == "localhost" || ip == "loopback" || ip == "::1")
		return TRUE;
	if (substring(ip, 0, 4) == "127." || substring(ip, 0, 3) == "10.")
		return TRUE;
	if (substring(ip, 0, 8) == "192.168." || substring(ip, 0, 8) == "169.254.")
		return TRUE;

	if (substring(ip, 0, 4) == "172.")
	{
		pos = strstrofs(ip, ".", 4);
		if (pos > 4)
		{
			octet = stof(substring(ip, 4, pos - 4));
			if (octet >= 16 && octet <= 31)
				return TRUE;
		}
	}

	// IPv6 unique-local (fc00::/7) and link-local (fe80::/10).
	if (strstrofs(ip, ":", 0) >= 0
		&& (substring(ip, 0, 2) == "fc" || substring(ip, 0, 2) == "fd"))
		return TRUE;
	if (strstrofs(ip, ":", 0) >= 0
		&& (substring(ip, 0, 3) == "fe8" || substring(ip, 0, 3) == "fe9"
		|| substring(ip, 0, 3) == "fea" || substring(ip, 0, 3) == "feb")
		)
		return TRUE;

	return FALSE;
};

float() VoteIP_Mode =
{
	local float mode;

	mode = floor(cvar("cr_vote_unique_ip"));
	if (mode == VOTE_IP_MODE_MONITOR)
		return VOTE_IP_MODE_MONITOR;
	if (mode >= VOTE_IP_MODE_ENFORCE)
		return VOTE_IP_MODE_ENFORCE;
	return VOTE_IP_MODE_OFF;
};

float(entity client) VoteIP_IsConnectedHuman =
{
	if (!client || client == world)
		return FALSE;
	if (client.classname != "player")
		return FALSE;
	if (!(client.style & CLANRING_CONNECTED))
		return FALSE;
	if (clienttype(client) == CLIENTTYPE_BOT)
		return FALSE;
	return TRUE;
};

string(entity client) VoteIP_ClientAddress =
{
	if (!VoteIP_IsConnectedHuman(client))
		return "";
	return clanring_normalize_ip(infokey(client, INFOKEY_P_IP));
};

float(string normalized_ip, float mult) VoteIP_HashAddress =
{
	local float h, i;

	if (!normalized_ip || normalized_ip == "")
		return 0;

	h = clanring_ghost_key;
	for (i = 0; i < strlen(normalized_ip); i = i + 1)
		h = (h * mult + str2chr(normalized_ip, i)) % 65536;
	return h;
};

void(entity client) VoteIP_RefreshClientIdentity =
{
	local string ip;

	client.vote_ip_hash = 0;
	client.vote_ip_hash2 = 0;
	client.vote_ip_address_valid = FALSE;
	client.vote_ip_private = FALSE;

	if (!VoteIP_IsConnectedHuman(client))
		return;

	ip = VoteIP_ClientAddress(client);
	if (!ip || ip == "")
		return;

	client.vote_ip_hash = VoteIP_HashAddress(ip, 31);
	client.vote_ip_hash2 = VoteIP_HashAddress(ip, 131);
	client.vote_ip_address_valid = TRUE;
	client.vote_ip_private = VoteIP_IsPrivateAddress(ip);
};

float(entity first, entity second) VoteIP_SameEnforcedGroup =
{
	if (first == second)
		return VoteIP_IsConnectedHuman(first);
	if (!VoteIP_IsConnectedHuman(first) || !VoteIP_IsConnectedHuman(second))
		return FALSE;

	// Administrators already have an explicit force-vote path. Keep their
	// authority independent of a housemate's ordinary ballot when configured.
	if (cvar("cr_vote_unique_ip_admin_exempt") > 0)
	{
		if ((first.style & CLANRING_ADMINISTRATOR) || (second.style & CLANRING_ADMINISTRATOR))
			return FALSE;
	}

	// Fail open: an engine that cannot report an address must not collapse all
	// such clients into one empty-string group.
	if (!first.vote_ip_address_valid || !second.vote_ip_address_valid)
		return FALSE;
	if (first.vote_ip_hash != second.vote_ip_hash
		|| first.vote_ip_hash2 != second.vote_ip_hash2)
		return FALSE;

	if (cvar("cr_vote_unique_ip_exempt_private") > 0 && first.vote_ip_private)
		return FALSE;

	return TRUE;
};

float(entity client, float ballot_kind) VoteIP_ClientHasBallot =
{
	if (!VoteIP_IsConnectedHuman(client))
		return FALSE;

	if (ballot_kind == VOTE_BALLOT_LIVE)
	{
		// The request owner is an implicit YES before vote_init's caller makes
		// its immediate vote_yes() call.
		if (clanring_request != world && client == clanring_request.owner)
			return TRUE;
		return (client.vote == 1 || client.vote == 2);
	}

	if (ballot_kind == VOTE_BALLOT_MAP)
		return (client.map_vote_slot >= 1 && client.map_vote_slot <= 5);

	return FALSE;
};

float(entity client, float ballot_kind) VoteIP_IndividualEligible =
{
	if (!VoteIP_IsConnectedHuman(client))
		return FALSE;
	if (!(client.style & CLANRING_AFK_CLIENT))
		return TRUE;
	return VoteIP_ClientHasBallot(client, ballot_kind);
};

float(entity client) VoteIP_IsGroupLeader =
{
	local entity scan;

	if (!VoteIP_IsConnectedHuman(client))
		return FALSE;

	scan = find(world, classname, "player");
	while (scan && scan != client)
	{
		if (VoteIP_SameEnforcedGroup(scan, client))
			return FALSE;
		scan = find(scan, classname, "player");
	}
	return TRUE;
};

entity(entity group_member, float ballot_kind) VoteIP_FindBallotOwner =
{
	local entity scan;

	if (!VoteIP_IsConnectedHuman(group_member))
		return world;

	// A request owner reserves the YES ballot for their IP group.
	if (ballot_kind == VOTE_BALLOT_LIVE && clanring_request != world
		&& VoteIP_IsConnectedHuman(clanring_request.owner)
		&& VoteIP_SameEnforcedGroup(group_member, clanring_request.owner))
		return clanring_request.owner;

	scan = find(world, classname, "player");
	while (scan)
	{
		if (VoteIP_SameEnforcedGroup(scan, group_member)
			&& VoteIP_ClientHasBallot(scan, ballot_kind))
			return scan;
		scan = find(scan, classname, "player");
	}

	return world;
};

entity(entity client, float ballot_kind) VoteIP_FindOtherBallotOwner =
{
	local entity scan;

	if (!VoteIP_IsConnectedHuman(client))
		return world;

	if (ballot_kind == VOTE_BALLOT_LIVE && clanring_request != world
		&& clanring_request.owner != client
		&& VoteIP_IsConnectedHuman(clanring_request.owner)
		&& VoteIP_SameEnforcedGroup(client, clanring_request.owner))
		return clanring_request.owner;

	scan = find(world, classname, "player");
	while (scan)
	{
		if (scan != client && VoteIP_SameEnforcedGroup(scan, client)
			&& VoteIP_ClientHasBallot(scan, ballot_kind))
			return scan;
		scan = find(scan, classname, "player");
	}

	return world;
};

float(entity group_member, float ballot_kind) VoteIP_GroupEligible =
{
	local entity scan;

	scan = find(world, classname, "player");
	while (scan)
	{
		if (VoteIP_SameEnforcedGroup(scan, group_member)
			&& VoteIP_IndividualEligible(scan, ballot_kind))
			return TRUE;
		scan = find(scan, classname, "player");
	}
	return FALSE;
};

void(string message) VoteIP_MonitorReport =
{
	local entity admin;

	// Keep the authoritative record in the server console/log, while making
	// monitor mode useful during a live test for admins already in the server.
	print(message);
	admin = find(world, classname, "player");
	while (admin)
	{
		if (VoteIP_IsConnectedHuman(admin)
			&& (admin.style & CLANRING_ADMINISTRATOR))
			sprint(admin, message);
		admin = find(admin, classname, "player");
	}
};

float(entity client, float ballot_kind) VoteIP_BallotRejected =
{
	local float mode;
	local entity owner;
	local string owner_name, address, ballot_name;

	mode = VoteIP_Mode();
	if (mode == VOTE_IP_MODE_OFF)
		return FALSE;
	if (!VoteIP_IsConnectedHuman(client))
		return TRUE;

	// Infokeys can briefly lag during connection setup. Retry lazily so a
	// transiently empty address does not leave this client fail-open for the map.
	if (!client.vote_ip_address_valid)
		VoteIP_RefreshClientIdentity(client);

	// A client with an existing ballot must be able to change or remove that
	// ballot even if the enforcement mode changed after both ballots were cast.
	if (VoteIP_ClientHasBallot(client, ballot_kind))
		return FALSE;

	if (mode == VOTE_IP_MODE_MONITOR)
		owner = VoteIP_FindOtherBallotOwner(client, ballot_kind);
	else
		owner = VoteIP_FindBallotOwner(client, ballot_kind);

	if (owner == world || owner == client)
		return FALSE;

	owner_name = owner.netname;
	if (!owner_name || owner_name == "")
		owner_name = "another client";

	if (mode == VOTE_IP_MODE_MONITOR)
	{
		if (time >= client.vote_ip_notice_until)
		{
			address = VoteIP_ClientAddress(client);
			if (ballot_kind == VOTE_BALLOT_MAP)
				ballot_name = "map";
			else
				ballot_name = "request";
			VoteIP_MonitorReport(sprintf("[vote-ip monitor] %s shares %s with %s during %s voting\n",
				client.netname, address, owner_name, ballot_name));
			client.vote_ip_notice_until = time + VOTE_IP_NOTICE_COOLDOWN;
		}
		return FALSE;
	}

	if (time >= client.vote_ip_notice_until)
	{
		sprint(client, sprintf("Vote not counted: %s is already voting from your IP address.\n", owner_name));
		client.vote_ip_notice_until = time + VOTE_IP_NOTICE_COOLDOWN;
	}
	return TRUE;
};

float(float ballot_kind) VoteIP_EligibleCount =
{
	local entity client;
	local float count, mode;

	count = 0;
	mode = VoteIP_Mode();
	client = find(world, classname, "player");
	while (client)
	{
		if (mode == VOTE_IP_MODE_ENFORCE)
		{
			if (VoteIP_IsGroupLeader(client) && VoteIP_GroupEligible(client, ballot_kind))
				count = count + 1;
		}
		else if (VoteIP_IndividualEligible(client, ballot_kind))
			count = count + 1;

		client = find(client, classname, "player");
	}
	return count;
};

float(float eligible_count) VoteIP_MajorityNeeded =
{
	return floor(eligible_count * 0.5) + 1;
};

float(float ballot) VoteIP_LiveVotesNeeded =
{
	local entity client, ballot_owner;
	local float eligible_count, matching_count, needed, mode, effective_ballot;

	eligible_count = VoteIP_EligibleCount(VOTE_BALLOT_LIVE);
	matching_count = 0;
	mode = VoteIP_Mode();

	client = find(world, classname, "player");
	while (client)
	{
		ballot_owner = world;
		if (mode == VOTE_IP_MODE_ENFORCE)
		{
			if (VoteIP_IsGroupLeader(client) && VoteIP_GroupEligible(client, VOTE_BALLOT_LIVE))
				ballot_owner = VoteIP_FindBallotOwner(client, VOTE_BALLOT_LIVE);
		}
		else if (VoteIP_IndividualEligible(client, VOTE_BALLOT_LIVE))
			ballot_owner = client;

		if (ballot_owner != world)
		{
			if (clanring_request != world && ballot_owner == clanring_request.owner)
				effective_ballot = 1;
			else
				effective_ballot = ballot_owner.vote;

			if (effective_ballot == ballot)
				matching_count = matching_count + 1;
		}

		client = find(client, classname, "player");
	}

	needed = VoteIP_MajorityNeeded(eligible_count) - matching_count;
	if (needed < 1)
		return 0;
	return needed;
};

void() VoteMap_Recount =
{
	local entity client, owner;
	local float i, mode, slot;

	for (i = 0; i < 6; i = i + 1)
		map_choices[i] = 0;

	mode = VoteIP_Mode();
	client = find(world, classname, "player");
	while (client)
	{
		owner = world;
		if (mode == VOTE_IP_MODE_ENFORCE)
		{
			if (VoteIP_IsGroupLeader(client) && VoteIP_GroupEligible(client, VOTE_BALLOT_MAP))
				owner = VoteIP_FindBallotOwner(client, VOTE_BALLOT_MAP);
		}
		else if (VoteIP_IndividualEligible(client, VOTE_BALLOT_MAP))
			owner = client;

		if (owner != world)
		{
			slot = owner.map_vote_slot;
			if (slot >= 1 && slot <= 5)
				map_choices[slot] = map_choices[slot] + 1;
		}

		client = find(client, classname, "player");
	}
};

void() VoteMap_ResetBallots =
{
	local entity client;
	local float i;

	for (i = 0; i < 6; i = i + 1)
		map_choices[i] = 0;

	client = find(world, classname, "player");
	while (client)
	{
		client.map_vote_slot = 0;
		// next_vote_time is scoped to the map ballot; it is not a live-poll timer.
		client.next_vote_time = 0;
		client = find(client, classname, "player");
	}
};

float(float slot) VoteMap_VotesNeeded =
{
	local float needed;

	needed = VoteIP_MajorityNeeded(VoteIP_EligibleCount(VOTE_BALLOT_MAP)) - map_choices[slot];
	if (needed < 0)
		return 0;
	return needed;
};

float() VoteMap_HasMajority =
{
	local float eligible_count, majority, slot;

	eligible_count = VoteIP_EligibleCount(VOTE_BALLOT_MAP);
	if (eligible_count <= 0)
		return FALSE;

	majority = VoteIP_MajorityNeeded(eligible_count);
	for (slot = 1; slot <= 5; slot = slot + 1)
	{
		if (map_choices[slot] >= majority)
			return TRUE;
	}
	return FALSE;
};
