//
// lockdown.qc
//
// Temporary private-lock mode:
// only clients whose IP is already connected may join while active.
//

// Globals
float lockdown_until;              // absolute server-persistent time when lock expires
float lockdown_ip_count;           // number of IPs currently allowlisted
string lockdown_ips[255];          // allowlist (normalized IPs, no ports)
string lockdown_ip_labels[255];    // stored names associated with each allowlisted IP
entity lockdown_timer;             // timer entity for expiration checks
float lockdown_auto_release_on_match_start; // if set, release when match transitions into started
float lockdown_prev_match_started;          // previous match-start state (for transition detection)

// Prototypes
void() lockdown_save_to_cvars;
void(float announce_all) lockdown_stop;
void() lockdown_timer_think;
void() lockdown_spawn_timer;
float(string ip) lockdown_find_ip_index;
void(float index, string label) lockdown_set_ip_label;
void(float index, string label) lockdown_append_ip_label;
void(string ip, string label) lockdown_add_ip_with_label;
string(string ip) lockdown_connected_names_for_ip;
string(string list, float index) lockdown_list_token_at;
void(string ip) lockdown_add_ip;
void() lockdown_clear_ips;
float(string ip, entity except_client) lockdown_ip_has_other_connected_client;
void() lockdown_release_if_server_empty;
void(float minutes) lockdown_console_start;
void() lockdown_console_status;
void(entity player) lockdown_list;
void() lockdown_console_list;
void(string arg1, string arg2, float argc) lockdown_console_command;

void() lockdown_register_cvars =
{
    registercvar("cr_lockdown_until", "0");
    registercvar("cr_lockdown_ips", "");
    registercvar("cr_lockdown_labels", "");
    registercvar("cr_lockdown_auto_release_on_match_start", "0");
};

string(string ip_with_port) lockdown_normalize_ip =
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
            return substring(ip, 1, pos - 1);
        return ip;
    }

    // IPv4:port (or hostname:port) -> strip trailing port.
    // Plain IPv6 addresses contain multiple ':' and should be kept as-is.
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
            return substring(ip, 0, pos);
    }

    return ip;
};

void() lockdown_clear_ips =
{
    local float i;

    for (i = 0; i < lockdown_ip_count && i < lockdown_ips.length; i = i + 1)
    {
        if (lockdown_ips[i] != string_null && lockdown_ips[i] != "")
            strunzone(lockdown_ips[i]);
        if (lockdown_ip_labels[i] != string_null && lockdown_ip_labels[i] != "")
            strunzone(lockdown_ip_labels[i]);
        lockdown_ips[i] = "";
        lockdown_ip_labels[i] = "";
    }
    lockdown_ip_count = 0;
};

float(string ip) lockdown_find_ip_index =
{
    local float i;

    if (!ip || ip == "")
        return -1;

    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (lockdown_ips[i] == ip)
            return i;
    }

    return -1;
};

void(float index, string label) lockdown_set_ip_label =
{
    if (index < 0 || index >= lockdown_ip_labels.length)
        return;

    if (lockdown_ip_labels[index] != string_null && lockdown_ip_labels[index] != "")
        strunzone(lockdown_ip_labels[index]);

    if (label && label != "")
        lockdown_ip_labels[index] = strzone(label);
    else
        lockdown_ip_labels[index] = "";
};

void(float index, string label) lockdown_append_ip_label =
{
    local string combined;

    if (index < 0 || index >= lockdown_ip_labels.length || !label || label == "")
        return;

    if (!lockdown_ip_labels[index] || lockdown_ip_labels[index] == "")
    {
        lockdown_set_ip_label(index, label);
        return;
    }

    if (lockdown_ip_labels[index] == label)
        return;

    combined = strcat(lockdown_ip_labels[index], ", ", label);
    lockdown_set_ip_label(index, combined);
};

void(string ip, string label) lockdown_add_ip_with_label =
{
    local float index;

    if (!ip || ip == "")
        return;

    index = lockdown_find_ip_index(ip);
    if (index >= 0)
    {
        lockdown_append_ip_label(index, label);
        return;
    }

    if (lockdown_ip_count >= lockdown_ips.length)
        return;

    lockdown_ips[lockdown_ip_count] = strzone(ip);
    lockdown_ip_labels[lockdown_ip_count] = "";
    lockdown_set_ip_label(lockdown_ip_count, label);
    lockdown_ip_count = lockdown_ip_count + 1;
};

string(string ip) lockdown_connected_names_for_ip =
{
    local entity client;
    local string client_ip;
    local string names;

    if (!ip || ip == "")
        return "";

    names = "";
    client = find(world, classname, "player");
    while (client)
    {
        if (client.style & CLANRING_CONNECTED)
        {
            client_ip = lockdown_normalize_ip(infokey(client, INFOKEY_P_IP));
            if (client_ip == ip && client.netname && client.netname != "")
            {
                if (names != "")
                    names = strcat(names, ", ");
                names = strcat(names, client.netname);
            }
        }
        client = find(client, classname, "player");
    }

    return names;
};

string(string list, float index) lockdown_list_token_at =
{
    local float start, end, current, length;

    if (!list || list == "" || index < 0)
        return "";

    start = 0;
    current = 0;
    length = strlen(list);

    while (start <= length)
    {
        end = strstrofs(list, ";", start);
        if (end < 0)
            end = length;

        if (current == index)
            return substring(list, start, end - start);

        if (end >= length)
            break;

        start = end + 1;
        current = current + 1;
    }

    return "";
};

void(string ip) lockdown_add_ip =
{
    lockdown_add_ip_with_label(ip, "");
};

float(string ip) lockdown_ip_allowed =
{
    local float i;

    if (!ip || ip == "")
        return FALSE;

    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (lockdown_ips[i] == ip)
            return TRUE;
    }
    return FALSE;
};

void() lockdown_snapshot_ips =
{
    local entity client;
    local string ip;

    lockdown_clear_ips();

    client = find(world, classname, "player");
    while (client)
    {
        if (client.style & CLANRING_CONNECTED)
        {
            ip = lockdown_normalize_ip(infokey(client, INFOKEY_P_IP));
            lockdown_add_ip_with_label(ip, client.netname);
        }
        client = find(client, classname, "player");
    }
};

void() lockdown_save_to_cvars =
{
    local float i;
    local string ip_list;
    local string label_list;
    local string label_token;

    lockdown_register_cvars();

    if (lockdown_until > 0)
        cvar_set("cr_lockdown_until", ftos(lockdown_until));
    else
        cvar_set("cr_lockdown_until", "0");

    ip_list = "";
    label_list = "";
    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (!lockdown_ips[i] || lockdown_ips[i] == "")
            continue;
        if (ip_list != "")
        {
            ip_list = strcat(ip_list, ";");
            label_list = strcat(label_list, ";");
        }
        ip_list = strcat(ip_list, lockdown_ips[i]);

        if (lockdown_ip_labels[i] && lockdown_ip_labels[i] != "")
            label_token = uri_escape(lockdown_ip_labels[i]);
        else
            label_token = "%";
        label_list = strcat(label_list, label_token);
    }
    cvar_set("cr_lockdown_ips", ip_list);
    cvar_set("cr_lockdown_labels", label_list);

    if (lockdown_auto_release_on_match_start)
        cvar_set("cr_lockdown_auto_release_on_match_start", "1");
    else
        cvar_set("cr_lockdown_auto_release_on_match_start", "0");
};

void() lockdown_spawn_timer =
{
    if (lockdown_timer != world)
        remove(lockdown_timer);

    lockdown_timer = spawn();
    lockdown_timer.classname = "cr_lockdown_timer";
    lockdown_timer.think = lockdown_timer_think;
    lockdown_timer.nextthink = time + 1;
};

void(float announce_all) lockdown_stop =
{
    if (lockdown_timer != world)
    {
        remove(lockdown_timer);
        lockdown_timer = world;
    }

    lockdown_until = 0;
    lockdown_auto_release_on_match_start = 0;
    lockdown_prev_match_started = 0;
    lockdown_clear_ips();
    lockdown_save_to_cvars();

    if (announce_all)
        announce("Private lock has ended.");
};

float() lockdown_is_active =
{
    if (lockdown_until <= 0 || lockdown_ip_count <= 0)
    {
        if (lockdown_until > 0 || lockdown_ip_count > 0)
            lockdown_stop(FALSE);
        return FALSE;
    }

    if (utils_server_time() >= lockdown_until)
    {
        lockdown_stop(TRUE);
        return FALSE;
    }

    return TRUE;
};

float(string ip, entity except_client) lockdown_ip_has_other_connected_client =
{
    local entity client;
    local string client_ip;

    if (!ip || ip == "")
        return FALSE;

    client = find(world, classname, "player");
    while (client)
    {
        if ((client != except_client) && (client.style & CLANRING_CONNECTED))
        {
            client_ip = lockdown_normalize_ip(infokey(client, INFOKEY_P_IP));
            if (client_ip == ip)
                return TRUE;
        }
        client = find(client, classname, "player");
    }

    return FALSE;
};

void() lockdown_release_if_server_empty =
{
    local entity client;

    if (!lockdown_is_active())
        return;

    client = find(world, classname, "player");
    while (client)
    {
        if (client.style & CLANRING_CONNECTED)
            return;
        client = find(client, classname, "player");
    }

    lockdown_stop(FALSE);
    cprint("Private lock ended automatically because the server is empty.\n");
};

void() lockdown_timer_think =
{
    local float current_match_started;

    if (!lockdown_is_active())
    {
        if (self == lockdown_timer)
            lockdown_timer = world;
        remove(self);
        return;
    }

    if (lockdown_auto_release_on_match_start)
    {
        current_match_started = (clanring_state & CLANRING_MATCH_STARTED);
        if ((!lockdown_prev_match_started) && current_match_started)
        {
            lockdown_stop(FALSE);
            announce("Private lock ended automatically at match start.");
            return;
        }
        lockdown_prev_match_started = current_match_started;
    }

    self.nextthink = time + 1;
};

void(string ip) lockdown_remove_ip =
{
    local float i, j;

    if (!lockdown_is_active() || !ip || ip == "")
        return;

    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (lockdown_ips[i] == ip)
        {
            if (lockdown_ips[i] != string_null && lockdown_ips[i] != "")
                strunzone(lockdown_ips[i]);
            if (lockdown_ip_labels[i] != string_null && lockdown_ip_labels[i] != "")
                strunzone(lockdown_ip_labels[i]);

            for (j = i; j < lockdown_ip_count - 1; j = j + 1)
            {
                lockdown_ips[j] = lockdown_ips[j + 1];
                lockdown_ip_labels[j] = lockdown_ip_labels[j + 1];
            }

            lockdown_ips[lockdown_ip_count - 1] = "";
            lockdown_ip_labels[lockdown_ip_count - 1] = "";
            lockdown_ip_count = lockdown_ip_count - 1;
            lockdown_save_to_cvars();
            return;
        }
    }
};

void(float minutes) lockdown_start =
{
    local float lock_minutes;
    local string sminutes;

    lock_minutes = floor(minutes);
    if (lock_minutes < 1)
        lock_minutes = 10;
    if (lock_minutes > 30)
        lock_minutes = 30;

    if ((lockdown_until > utils_server_time()) && (lockdown_ip_count > 0))
        sprint(self, "Replacing existing private lock.\n");

    lockdown_snapshot_ips();
    if (lockdown_ip_count <= 0)
    {
        sprint(self, "Lockdown failed: no connected player IPs to allow.\n");
        return;
    }

    lockdown_until = utils_server_time() + (lock_minutes * 60);
    lockdown_prev_match_started = (clanring_state & CLANRING_MATCH_STARTED);
    lockdown_spawn_timer();
    lockdown_save_to_cvars();

    sminutes = ftos(lock_minutes);
    announce5(self.netname, " enabled private lock for ", sminutes, " minute", strings_szplural(lock_minutes));
    sprint3(self, "Allowlist size: ", ftos(lockdown_ip_count), " IPs.\n");
    if (lockdown_auto_release_on_match_start)
        sprint(self, "Private lock will auto-release when match starts.\n");
};

void(float minutes) lockdown_console_start =
{
    local float lock_minutes;
    local string sminutes;

    lock_minutes = floor(minutes);
    if (lock_minutes < 1)
        lock_minutes = 10;
    if (lock_minutes > 30)
        lock_minutes = 30;

    if ((lockdown_until > utils_server_time()) && (lockdown_ip_count > 0))
        cprint("Replacing existing private lock.\n");

    lockdown_snapshot_ips();
    if (lockdown_ip_count <= 0)
    {
        cprint("Lockdown failed: no connected player IPs to allow.\n");
        return;
    }

    lockdown_until = utils_server_time() + (lock_minutes * 60);
    lockdown_prev_match_started = (clanring_state & CLANRING_MATCH_STARTED);
    lockdown_spawn_timer();
    lockdown_save_to_cvars();

    sminutes = ftos(lock_minutes);
    announce5("Console", " enabled private lock for ", sminutes, " minute", strings_szplural(lock_minutes));
    cprint3("Allowlist size: ", ftos(lockdown_ip_count), " IPs.\n");
    if (lockdown_auto_release_on_match_start)
        cprint("Private lock will auto-release when match starts.\n");
};

void(entity player) lockdown_status =
{
    local float remaining, minutes, seconds;

    if (!lockdown_is_active())
    {
        sprint(player, "Private lock is off.\n");
        return;
    }

    remaining = lockdown_until - utils_server_time();
    if (remaining < 0)
        remaining = 0;

    minutes = floor(remaining / 60);
    seconds = floor(remaining - (minutes * 60));

    sprint7(player, "Private lock is on. ", ftos(minutes), "m ", ftos(seconds), "s remaining. ", ftos(lockdown_ip_count), " IPs allowed.\n");
    if (lockdown_auto_release_on_match_start)
        sprint(player, "Auto-release on match start: on\n");
};

void() lockdown_console_status =
{
    local float remaining, minutes, seconds;

    if (!lockdown_is_active())
    {
        cprint("Private lock is off.\n");
        return;
    }

    remaining = lockdown_until - utils_server_time();
    if (remaining < 0)
        remaining = 0;

    minutes = floor(remaining / 60);
    seconds = floor(remaining - (minutes * 60));

    cprint("Private lock is on. ", ftos(minutes), "m ", ftos(seconds), "s remaining. ", ftos(lockdown_ip_count), " IPs allowed.\n");
    if (lockdown_auto_release_on_match_start)
        cprint("Auto-release on match start: on\n");
};

void(entity player) lockdown_list =
{
    local float i;
    local string label;

    if (!lockdown_is_active())
    {
        sprint(player, "Private lock is off.\n");
        return;
    }

    sprint3(player, "Private lock allowlist (", ftos(lockdown_ip_count), " IPs):\n");
    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (lockdown_ips[i] && lockdown_ips[i] != "")
        {
            label = lockdown_ip_labels[i];
            if (!label || label == "")
                label = lockdown_connected_names_for_ip(lockdown_ips[i]);

            if (label && label != "")
                sprint5(player, " ", lockdown_ips[i], " - ", label, "\n");
            else
                sprint3(player, " ", lockdown_ips[i], "\n");
        }
    }
};

void() lockdown_console_list =
{
    local float i;
    local string label;

    if (!lockdown_is_active())
    {
        cprint("Private lock is off.\n");
        return;
    }

    cprint3("Private lock allowlist (", ftos(lockdown_ip_count), " IPs):\n");
    for (i = 0; i < lockdown_ip_count; i = i + 1)
    {
        if (lockdown_ips[i] && lockdown_ips[i] != "")
        {
            label = lockdown_ip_labels[i];
            if (!label || label == "")
                label = lockdown_connected_names_for_ip(lockdown_ips[i]);

            if (label && label != "")
                cprint5(" ", lockdown_ips[i], " - ", label, "\n");
            else
                cprint3(" ", lockdown_ips[i], "\n");
        }
    }
};

float() lockdown_check_connect =
{
    local string ip;

    if (!lockdown_is_active())
        return FALSE;

    ip = lockdown_normalize_ip(infokey(self, INFOKEY_P_IP));
    if (lockdown_ip_allowed(ip))
        return FALSE;

    // Notify the connecting client before dropping.
    sprint(self, "Server is under temporary private lock.\n");
    sprint(self, "Contact an admin to request access.\n");
    cprint3("Lockdown blocked connection from ", ip, "\n");
    return TRUE;
};

void() lockdown_restore_from_cvars =
{
    local float i, argc;
    local float until;
    local string ip_list, label_list, ip, label;

    lockdown_register_cvars();

    lockdown_timer = world;
    lockdown_clear_ips();

    until = cvar("cr_lockdown_until");
    if (until <= 0)
        return;

    if (utils_server_time() >= until)
    {
        cvar_set("cr_lockdown_until", "0");
        cvar_set("cr_lockdown_ips", "");
        cvar_set("cr_lockdown_labels", "");
        cvar_set("cr_lockdown_auto_release_on_match_start", "0");
        return;
    }

    ip_list = cvar_string("cr_lockdown_ips");
    label_list = cvar_string("cr_lockdown_labels");
    if (ip_list != "")
    {
        argc = tokenizebyseparator(ip_list, ";");
        for (i = 0; i < argc; i = i + 1)
        {
            ip = lockdown_normalize_ip(argv(i));
            label = lockdown_list_token_at(label_list, i);
            if (label == "%")
                label = "";
            else if (label != "")
                label = uri_unescape(label);
            lockdown_add_ip_with_label(ip, label);
        }
    }

    if (lockdown_ip_count <= 0)
    {
        cvar_set("cr_lockdown_until", "0");
        cvar_set("cr_lockdown_ips", "");
        cvar_set("cr_lockdown_labels", "");
        cvar_set("cr_lockdown_auto_release_on_match_start", "0");
        return;
    }

    lockdown_until = until;
    lockdown_auto_release_on_match_start = (cvar("cr_lockdown_auto_release_on_match_start") > 0);
    lockdown_prev_match_started = (clanring_state & CLANRING_MATCH_STARTED);
    lockdown_spawn_timer();

    cprint4("Lockdown restored (", ftos(lockdown_ip_count), " IPs, expires in ", ftos(ceil((lockdown_until - utils_server_time()) / 60)));
    cprint(" minutes)\n");
};

void(string arg1, string arg2, float argc) lockdown_command =
{
    local string opt;
    local float minutes;
    local float before_count;
    local string ip, label;

    if (argc > 3)
    {
        sprint(self, "Usage: lockdown [1-30|-1..-30|status|off|list|add/remove <ip>]\n");
        return;
    }

    opt = lowrcase(arg1);

    if (opt == "status")
    {
        lockdown_status(self);
        return;
    }
    if (opt == "list")
    {
        lockdown_list(self);
        return;
    }
    if (opt == "off")
    {
        if (!lockdown_is_active())
        {
            sprint(self, "Private lock is already off.\n");
            lockdown_stop(FALSE);
            return;
        }

        lockdown_stop(FALSE);
        announce2(self.netname, " disabled private lock.");
        return;
    }
    if (opt == "add")
    {
        if (arg2 == "")
        {
            sprint(self, "Usage: lockdown add <ip>\n");
            return;
        }

        if (!lockdown_is_active())
        {
            sprint(self, "Private lock is off.\n");
            return;
        }

        ip = lockdown_normalize_ip(arg2);
        if (ip == "")
        {
            sprint(self, "Invalid IP.\n");
            return;
        }

        before_count = lockdown_ip_count;
        label = lockdown_connected_names_for_ip(ip);
        if (label == "")
            label = "(manual)";
        lockdown_add_ip_with_label(ip, label);
        if (lockdown_ip_count > before_count)
        {
            lockdown_save_to_cvars();
            sprint3(self, "Added to private lock allowlist: ", ip, "\n");
        }
        else
            sprint3(self, "IP already allowlisted: ", ip, "\n");
        return;
    }
    if (opt == "remove")
    {
        if (arg2 == "")
        {
            sprint(self, "Usage: lockdown remove <ip>\n");
            return;
        }

        if (!lockdown_is_active())
        {
            sprint(self, "Private lock is off.\n");
            return;
        }

        ip = lockdown_normalize_ip(arg2);
        if (ip == "")
        {
            sprint(self, "Invalid IP.\n");
            return;
        }

        before_count = lockdown_ip_count;
        lockdown_remove_ip(ip);
        if (lockdown_ip_count < before_count)
        {
            if (!lockdown_is_active())
                announce("Private lock has ended.");
            sprint3(self, "Removed from private lock allowlist: ", ip, "\n");
        }
        else
            sprint3(self, "IP not in allowlist: ", ip, "\n");
        return;
    }

    if (opt == "" || opt == "on")
    {
        lockdown_auto_release_on_match_start = FALSE;
        lockdown_start(10);
        return;
    }

    minutes = floor(stof(arg1));
    if (minutes <= -1 && minutes >= -30)
    {
        lockdown_auto_release_on_match_start = TRUE;
        lockdown_start(-minutes);
        return;
    }

    if (minutes < 1 || minutes > 30)
    {
        sprint(self, "Usage: lockdown [1-30|-1..-30|status|off|list|add/remove <ip>]\n");
        return;
    }

    lockdown_auto_release_on_match_start = FALSE;
    lockdown_start(minutes);
};

void(string arg1, string arg2, float argc) lockdown_console_command =
{
    local string opt;
    local float minutes;
    local float before_count;
    local string ip, label;

    if (argc > 3)
    {
        cprint("Usage: lockdown [1-30|-1..-30|status|off|list|add/remove <ip>]\n");
        return;
    }

    opt = lowrcase(arg1);

    if (opt == "status")
    {
        lockdown_console_status();
        return;
    }
    if (opt == "list")
    {
        lockdown_console_list();
        return;
    }
    if (opt == "off")
    {
        if (!lockdown_is_active())
        {
            cprint("Private lock is already off.\n");
            lockdown_stop(FALSE);
            return;
        }

        lockdown_stop(FALSE);
        cprint("Private lock disabled by console.\n");
        announce("Console disabled private lock.");
        return;
    }
    if (opt == "add")
    {
        if (arg2 == "")
        {
            cprint("Usage: lockdown add <ip>\n");
            return;
        }

        if (!lockdown_is_active())
        {
            cprint("Private lock is off.\n");
            return;
        }

        ip = lockdown_normalize_ip(arg2);
        if (ip == "")
        {
            cprint("Invalid IP.\n");
            return;
        }

        before_count = lockdown_ip_count;
        label = lockdown_connected_names_for_ip(ip);
        if (label == "")
            label = "(manual)";
        lockdown_add_ip_with_label(ip, label);
        if (lockdown_ip_count > before_count)
        {
            lockdown_save_to_cvars();
            cprint3("Added to private lock allowlist: ", ip, "\n");
        }
        else
            cprint3("IP already allowlisted: ", ip, "\n");
        return;
    }
    if (opt == "remove")
    {
        if (arg2 == "")
        {
            cprint("Usage: lockdown remove <ip>\n");
            return;
        }

        if (!lockdown_is_active())
        {
            cprint("Private lock is off.\n");
            return;
        }

        ip = lockdown_normalize_ip(arg2);
        if (ip == "")
        {
            cprint("Invalid IP.\n");
            return;
        }

        before_count = lockdown_ip_count;
        lockdown_remove_ip(ip);
        if (lockdown_ip_count < before_count)
        {
            if (!lockdown_is_active())
                announce("Private lock has ended.");
            cprint3("Removed from private lock allowlist: ", ip, "\n");
        }
        else
            cprint3("IP not in allowlist: ", ip, "\n");
        return;
    }

    if (opt == "" || opt == "on")
    {
        lockdown_auto_release_on_match_start = FALSE;
        lockdown_console_start(10);
        return;
    }

    minutes = floor(stof(arg1));
    if (minutes <= -1 && minutes >= -30)
    {
        lockdown_auto_release_on_match_start = TRUE;
        lockdown_console_start(-minutes);
        return;
    }

    if (minutes < 1 || minutes > 30)
    {
        cprint("Usage: lockdown [1-30|-1..-30|status|off|list|add/remove <ip>]\n");
        return;
    }

    lockdown_auto_release_on_match_start = FALSE;
    lockdown_console_start(minutes);
};
