//
// Options.qc
//
// This is purely bells and whistles, and wouldn't even be here if I
// wan't bored one night when I was waiting for my girlfriend to call.
//
// All code by J.P. Grossman unless otherwise commented.
//
// fields used:
//
// .delay    - time to update display (shared with observer.qc)
//
// .pos1_x    - timelimit
// .pos1_y    - fraglimit/overtime
// .pos1_z    - mode
// .pos2_x    - gibs
// .pos2_y    - teamplay
// .pos2_z    - noexit
// .worldtype - sys_ticrate
// .light_lev - deathmatch
// .aflag     - pausable/quad/pent/ring/mode vote
// .t_length  - which option is currently selected
//

// constants
float OPTIONS_NO_GIBS   = 0;
float OPTIONS_LOW_GIBS  = 1;
float OPTIONS_HIGH_GIBS = 2;
float OPTIONS_PAUSABLE  = 1;

//
//  S Z M O D E
//
//  Return the heading and mode string, e.g.
//
//  "Press jump to select,\nattack to change.\n\nMode      > Normal  \n"
//
string (float mode) options_szmode =
{
    if (self.t_length == 0)
    {
        if (mode == ADMIN_NORMAL_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5      \xFF \xCE\xEF\xF2\xED\xE1\xEC  \n";
        else if (mode == ADMIN_PRACTICE_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5      \xFF \xD0\xF2\xE1\xE3\xF4\xE9\xE3\xE5\n";
        else if (mode == ADMIN_MATCH_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5      \xFF \xCD\xE1\xF4\xE3\xE8   \n";
        else
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n  \xCD\xEF\xE4\xE5      \xFF \xC9\xEE\xE4\xE9\xF6\xE9\xE4\xF5\xE1\xEC\n";
    }
    else
    {
        if (mode == ADMIN_NORMAL_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5        \xCE\xEF\xF2\xED\xE1\xEC  \n";
        else if (mode == ADMIN_PRACTICE_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5        \xD0\xF2\xE1\xE3\xF4\xE9\xE3\xE5\n";
        else if (mode == ADMIN_MATCH_MODE)
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n\xCD\xEF\xE4\xE5        \xCD\xE1\xF4\xE3\xE8   \n";
        else
            return "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n  \xCD\xEF\xE4\xE5        \xC9\xEE\xE4\xE9\xF6\xE9\xE4\xF5\xE1\xEC\n";
    }
};

//
//  S Z T I M E L I M I T
//
//  Return the timelimit string, e.g. "Timelimit > 15      \n"
//
string (float value) options_sztimelimit =
{
    if (self.t_length == 1)
    {
        if (value == 0)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB0       \n";
        else if (value <= 5)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB5       \n";
        else if (value <= 10)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB1\xB0      \n";
        else if (value <= 15)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB1\xB5      \n";
        else if (value <= 20)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB2\xB0      \n";
        else if (value <= 25)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB2\xB5      \n";
        else if (value <= 30)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB3\xB0      \n";
        else if (value <= 40)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB4\xB0      \n";
        else if (value <= 50)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB5\xB0      \n";
        else
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4 \xFF \xB6\xB0      \n";
    }
    else
    {
        if (value == 0)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB0       \n";
        else if (value <= 5)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB5       \n";
        else if (value <= 10)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB1\xB0      \n";
        else if (value <= 15)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB1\xB5      \n";
        else if (value <= 20)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB2\xB0      \n";
        else if (value <= 25)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB2\xB5      \n";
        else if (value <= 30)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB3\xB0      \n";
        else if (value <= 40)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB4\xB0      \n";
        else if (value <= 50)
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB5\xB0      \n";
        else
            return "\xD4\xE9\xED\xE5\xEC\xE9\xED\xE9\xF4   \xB6\xB0      \n";
    }
};

//
//  S Z F R A G L I M I T
//
//  Return the fraglimit string, e.g. "Fraglimit > 30      \n"
//
string (float value) options_szfraglimit =
{
    if (self.t_length == 2)
    {
        if (value == 0)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB0       \n";
        else if (value <= 10)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB1\xB0      \n";
        else if (value <= 20)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB2\xB0      \n";
        else if (value <= 30)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB3\xB0      \n";
        else if (value <= 40)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB4\xB0      \n";
        else
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4 \xFF \xB5\xB0      \n";
    }
    else
    {
        if (value == 0)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB0       \n";
        else if (value <= 10)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB1\xB0      \n";
        else if (value <= 20)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB2\xB0      \n";
        else if (value <= 30)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB3\xB0      \n";
        else if (value <= 40)
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB4\xB0      \n";
        else
            return "\xC6\xF2\xE1\xE7\xEC\xE9\xED\xE9\xF4   \xB5\xB0      \n";
    }
};

//
//  S Z O V E R T I M E
//
//  Return the overtime string, e.g. "Overtime  > 5       \n"
//
string (float value) options_szovertime =
{
    if (self.t_length == 2)
    {
        if (value == -1)
            return "    \xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xD3\xF5\xE4\xE4\xE5\xEE \xC4\xE5\xE1\xF4\xE8\n";
        else if (value == 0)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
        else if (value == 1)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB1       \n";
        else if (value == 2)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB2       \n";
        else if (value == 3)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB3       \n";
        else if (value == 4)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB4       \n";
        else if (value == 5)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB5       \n";
        else if (value == 10)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5  \xFF \xB1\xB0      \n";
    }
    else
    {
        if (value == -1)
            return "    \xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xD3\xF5\xE4\xE4\xE5\xEE \xC4\xE5\xE1\xF4\xE8\n";
        else if (value == 0)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
        else if (value == 1)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB1       \n";
        else if (value == 2)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB2       \n";
        else if (value == 3)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB3       \n";
        else if (value == 4)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB4       \n";
        else if (value == 5)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB5       \n";
        else if (value == 10)
            return "\xCF\xF6\xE5\xF2\xF4\xE9\xED\xE5    \xB1\xB0      \n";
    }
    return "";
};

//
//  S Z G I B S
//
//  Return the gibs string, e.g. "Gibs      > Disabled\n"
//
string (float gibs) options_szgibs =
{
    if (self.t_length == 3)
    {
        if (gibs == OPTIONS_NO_GIBS)
            return "\xC7\xE9\xE2\xF3      \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
        else if (gibs == OPTIONS_LOW_GIBS)
            return "\xC7\xE9\xE2\xF3      \xFF \xCC\xEF\xF7     \n";
        else
            return "\xC7\xE9\xE2\xF3      \xFF \xC8\xE9\xE7\xE8    \n";
    }
    else
    {
        if (gibs == OPTIONS_NO_GIBS)
            return "\xC7\xE9\xE2\xF3        \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
        else if (gibs == OPTIONS_LOW_GIBS)
            return "\xC7\xE9\xE2\xF3        \xCC\xEF\xF7     \n";
        else
            return "\xC7\xE9\xE2\xF3        \xC8\xE9\xE7\xE8    \n";
    }
    return "";
};

//
//  S Z T E A M P L A Y
//
//  Return the teamplay string, e.g. "Teamplay  > 2       \n"
//
string (float value) options_szteamplay =
{
    if (self.t_length == 4)
    {
        if (value == 0)
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9  \xFF \xB0       \n";
        else if (value == 1)
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9  \xFF \xB1       \n";
        else
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9  \xFF \xB2       \n";
    }
    else
    {
        if (value == 0)
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9    \xB0       \n";
        else if (value == 1)
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9    \xB1       \n";
        else
            return "\xD4\xE5\xE1\xED\xF0\xEC\xE1\xF9    \xB2       \n";
    }
    return "";
};

//
//  S Z N O E X I T
//
//  Return the noexit string, e.g. "Noexit    > 1       \n"
//
string (float value) options_sznoexit =
{
    if (self.t_length == 5)
    {
        if (value == 0)
            return "\xCE\xEF\xE5\xF8\xE9\xF4    \xFF \xB0       \n";
        else if (value == 1)
            return "\xCE\xEF\xE5\xF8\xE9\xF4    \xFF \xB1       \n";
        else
            return "\xCE\xEF\xE5\xF8\xE9\xF4    \xFF \xB2       \n";
    }
    else
    {
        if (value == 0)
            return "\xCE\xEF\xE5\xF8\xE9\xF4      \xB0       \n";
        else if (value == 1)
            return "\xCE\xEF\xE5\xF8\xE9\xF4      \xB1       \n";
        else
            return "\xCE\xEF\xE5\xF8\xE9\xF4      \xB2       \n";
    }
    return "";
};

//
//  S Z P A U S A B L E
//
//  Return the pausable/done string, e.g.
//
//  "Pausable    1       \nMore..              \n      > Done\n"
//
string (float value) options_szpausable =
{
    if (self.t_length == 6)
    {
        if (value)
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5  \xFF \xD9\xE5\xF3     \n\xCD\xEF\xF2\xE5\xAE\xAE              \n        \xC4\xEF\xEE\xE5";
        else
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5  \xFF \xCE\xEF      \n\xCD\xEF\xF2\xE5\xAE\xAE              \n        \xC4\xEF\xEE\xE5";
    }
    else if (self.t_length == 7)
    {
        if (value)
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xD9\xE5\xF3     \n\xCD\xEF\xF2\xE5\xAE\xAE    \xFF         \n        \xC4\xEF\xEE\xE5";
        else
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xCE\xEF      \n\xCD\xEF\xF2\xE5\xAE\xAE    \xFF         \n        \xC4\xEF\xEE\xE5";
    }
    else if (self.t_length == 8)
    {
        if (value)
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xD9\xE5\xF3     \n\xCD\xEF\xF2\xE5\xAE\xAE              \n      \xFF \xC4\xEF\xEE\xE5";
        else
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xCE\xEF      \n\xCD\xEF\xF2\xE5\xAE\xAE              \n      \xFF \xC4\xEF\xEE\xE5";
    }
    else
    {
        if (value)
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xD9\xE5\xF3     \n\xCD\xEF\xF2\xE5\xAE\xAE              \n        \xC4\xEF\xEE\xE5";
        else
            return "\xD0\xE1\xF5\xF3\xE1\xE2\xEC\xE5    \xCE\xEF      \n\xCD\xEF\xF2\xE5\xAE\xAE              \n        \xC4\xEF\xEE\xE5";
    }
    return "";
};

//
//  S Z D E A T H M A T C H
//
//  Return the deathmatch string, e.g.  "deathmatch> 3       \n"
//
string (float value) options_szdeathmatch =
{
    if (self.t_length == 18)
    {
        if (value == 1)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8 \xFF \xB1       \n";
        else if (value == 2)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8 \xFF \xB2       \n";
        else if (value == 3)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8 \xFF \xB3       \n";
    }
    else
    {
        if (value == 1)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8   \xB1       \n";
        else if (value == 2)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8   \xB2       \n";
        else if (value == 3)
            return "\xC4\xE5\xE1\xF4\xE8\xED\xE1\xF4\xE3\xE8   \xB3       \n";
    }
    return "";
};

//
//  S Z T I C R A T E
//
//  Return the sys_ticrate string, e.g. "ticrate   > 0.07    \n"
//
string (float value) options_szticrate =
{
    if (self.t_length == 19)
    {
        if (value <= 0.05)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB0\xB5    \n";
        else if (value <= 0.06)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB0\xB6    \n";
        else if (value <= 0.07)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB0\xB7    \n";
        else if (value <= 0.08)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB0\xB8    \n";
        else if (value <= 0.09)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB0\xB9    \n";
        else
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5    \xFF \xB0\xAE\xB1     \n";
    }
    else
    {
        if (value <= 0.05)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB0\xB5    \n";
        else if (value <= 0.06)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB0\xB6    \n";
        else if (value <= 0.07)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB0\xB7    \n";
        else if (value <= 0.08)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB0\xB8    \n";
        else if (value <= 0.09)
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB0\xB9    \n";
        else
            return "\xD4\xE9\xE3\xF2\xE1\xF4\xE5      \xB0\xAE\xB1     \n";
    }
    return "";    
};

//
//  S Z Q U A D
//
//  Return the quad string, e.g. "Quad      > Enabled \n"
//
string (float value) options_szquad =
{
    if (self.t_length == 20)
    {
        if (!value)
            return "\xD1\xF5\xE1\xE4       \xFF \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xD1\xF5\xE1\xE4       \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    else
    {
        if (!value)
            return "\xD1\xF5\xE1\xE4         \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xD1\xF5\xE1\xE4         \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    return "";    
};

//
//  S Z P E N T
//
//  Return the pent string, e.g. "Pentagram > Enabled \n"
//
string (float value) options_szpent =
{
    if (self.t_length == 21)
    {
        if (!value)
            return "\xD0\xE5\xEE\xF4\xE1\xE7\xF2\xE1\xED  \xFF \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xD0\xE5\xEE\xF4\xE1\xE7\xF2\xE1\xED  \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    else
    {
        if (!value)
            return "\xD0\xE5\xEE\xF4\xE1\xE7\xF2\xE1\xED    \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xD0\xE5\xEE\xF4\xE1\xE7\xF2\xE1\xED    \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    return "";    
};

//
//  S Z R I N G
//
//  Return the ring string, e.g. "Ring      > Enabled \n"
//
string (float value) options_szring =
{
    if (self.t_length == 22)
    {
        if (!value)
            return "\xFF\xE9\xEE\xE7       \xFF \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xFF\xE9\xEE\xE7       \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    else
    {
        if (!value)
            return "\xFF\xE9\xEE\xE7         \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n";
        else
            return "\xFF\xE9\xEE\xE7         \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n";
    }
    return "";    
};

//
//  S Z M O D E  V O T E
//
//  Return the mode vote string, e.g.
//
//  "Mode Vote > Enabled \n        Back\n"
//
string (float value) options_szmode_vote =
{
    if (self.t_length == 23)
    {
        if (value)
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5  \xFF \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n         \xC2\xE1\xE3\xEB\n";
        else
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5  \xFF \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n         \xC2\xE1\xE3\xEB\n";
    }
    else if (self.t_length == 24)
    {
        if (value)
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5    \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n       \xFF \xC2\xE1\xE3\xEB\n";
        else
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5    \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n       \xFF \xC2\xE1\xE3\xEB\n";
    }
    else
    {
        if (value)
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5    \xC5\xEE\xE1\xE2\xEC\xE5\xE4 \n         \xC2\xE1\xE3\xEB\n";
        else
            return "\xCD\xEF\xE4\xE5 \xD6\xEF\xF4\xE5    \xC4\xE9\xF3\xE1\xE2\xEC\xE5\xE4\n         \xC2\xE1\xE3\xEB\n";
    }
    return "";    
};

//
//  D I S P L A Y
//
//  Refresh the display according to the current set of options and the
//  current cursor position.
//
void () options_display =
{
    self.delay = time + 0.5;

    if ((clanring_state & CLANRING_MATCH_PAUSED) || (self.style & CLANRING_MOTD))
        return;

    if ((self.t_length & 127) < 10)
    {
        local string szmode, sztimelimit, szfraglimit, szovertime, szgibs;
        local string szteamplay, sznoexit, szpausable;
    
        szmode = options_szmode(self.pos1_z);
        sztimelimit = options_sztimelimit(self.pos1_x);
        szgibs = options_szgibs(self.pos2_x);
        szteamplay = options_szteamplay(self.pos2_y);
        sznoexit = options_sznoexit(self.pos2_z);
        szpausable = options_szpausable(self.aflag & OPTIONS_PAUSABLE);
    
        if (self.pos1_z >= ADMIN_MATCH_MODE)
        {
            szovertime = options_szovertime(self.pos1_y);
            centerprint6(self, szmode, sztimelimit, szovertime, szgibs,
                         szteamplay, szpausable);
        }
        else
        {
            szfraglimit = options_szfraglimit(self.pos1_y);
            centerprint7(self, szmode, sztimelimit, szfraglimit,
                         szgibs, szteamplay, sznoexit, szpausable);
        }
    }
    else
    {
        local string szticrate, szdeathmatch, szquad, szpent, szring, szmodevote;

        szticrate = options_szticrate(self.worldtype);
        szdeathmatch = options_szdeathmatch(self.light_lev);
        szquad = options_szquad(self.aflag & CLANRING_NO_QUAD);
        szpent = options_szpent(self.aflag & CLANRING_NO_PENT);
        szring = options_szring(self.aflag & CLANRING_NO_RING);
        szmodevote = options_szmode_vote(self.aflag & CLANRING_MODE_VOTE);
        centerprint7(self, "\xD0\xF2\xE5\xF3\xF3 \xEA\xF5\xED\xF0 \xF4\xEF \xF3\xE5\xEC\xE5\xE3\xF4\xAC\n\xE1\xF4\xF4\xE1\xE3\xEB \xF4\xEF \xE3\xE8\xE1\xEE\xE7\xE5\xAE\n\n",
                     szdeathmatch, szticrate, szquad, szpent, szring, szmodevote);
    }

    // Hack to create flashing cursor
    self.t_length = (self.t_length + 128) & 255;
};

//
//  G E T  M O D E
//
//  Returns the current mode.
//
float () options_get_mode =
{
    if (clanring_playmode & CLANRING_HH_MODE)
        return ADMIN_HH_MODE;
    if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
        return ADMIN_CTF_MODE;
    if (clanring_playmode & CLANRING_WIPEOUT_MODE)
        return ADMIN_WIPEOUT_MODE;
    if (clanring_playmode & CLANRING_DMM4_MODE)
        return ADMIN_DMM4_MODE;
    if (clanring_playmode & CLANRING_CA_MODE)
        return ADMIN_CA_MODE;
    if (clanring_playmode & CLANRING_RA_MODE)
        return ADMIN_RA_MODE;
    if (clanring_playmode & CLANRING_AIRSHOT_MODE)
        return ADMIN_AIRSHOT_MODE;
    if (clanring_playmode & CLANRING_PRACTICE_MODE)
        return ADMIN_PRACTICE_MODE;
    if (clanring_playmode & CLANRING_MATCH_MODE)
		return ADMIN_MATCH_MODE;
    return ADMIN_NORMAL_MODE;
};

//
//  G E T  G I B S
//
//  Returns the current gib mode.
//
float () options_get_gibs =
{
    if (clanring_playmode & CLANRING_NO_GIBS)
        return OPTIONS_NO_GIBS;
    if (clanring_playmode & CLANRING_LOW_GIBS)
        return OPTIONS_LOW_GIBS;
    return OPTIONS_HIGH_GIBS;
};

//
//  S T A R T  S E T T I N G
//
//  Called from Admin.qc when the options command is entered.
//
void () options_start_setting =
{
//FIXME:    if (self.style & CLANRING_SETTING_OPTIONS)
    {
        // cancel
        stuffcmd(self, "play misc/menu2.wav\n");
        self.style = self.style - (self.style & CLANRING_SETTING_OPTIONS);
        centerprint(self, " ");
        return;
    }
    /*           
    // Initialize stuff
    self.t_length = 0;
    self.style = self.style | CLANRING_SETTING_OPTIONS;

    // get values
    if (clanring_playmode & CLANRING_MATCH_MODE)
    {
        self.pos1_x = clanring_timelimit;
        self.pos1_y = clanring_overtime;
    }
    else
    {
        self.pos1_x = cvar("timelimit");
        self.pos1_y = cvar("fraglimit");
    }

    self.pos1_z = options_get_mode();
    self.pos2_x = options_get_gibs();

    self.pos2_y = teamplay;
    if (!(teamplay == 0 || teamplay == 1 || teamplay == 2))
        self.pos2_y = 0;

    self.pos2_z = cvar("noexit");
    if (!(self.pos2_z == 0 || self.pos2_z == 1 || self.pos2_z == 2))
        self.pos2_z = 0;

    if (cvar("pausable"))
        self.aflag = OPTIONS_PAUSABLE;
    else
        self.aflag = 0;
    self.aflag = self.aflag | (clanring_playmode &
        (CLANRING_NO_QUAD | CLANRING_NO_PENT | CLANRING_NO_RING | CLANRING_MODE_VOTE));

    self.light_lev = cvar("deathmatch");
    if (!(self.light_lev == 1 || self.light_lev == 2 || self.light_lev == 3))
        self.light_lev = 1;

    self.worldtype = cvar("sys_ticrate");

    // show choice
    options_display();

    // play sound
    stuffcmd(self, "play misc/menu2.wav\n");
    */
};

//
//  C H A N G E
//
//  Called when attack is pressed for one of the options.
//
void () options_change =
{
    if (self.t_length == 0)
    {
        // change mode
        if (self.pos1_z == ADMIN_NORMAL_MODE)
        {
            self.pos1_z = ADMIN_PRACTICE_MODE;
            if (clanring_playmode & CLANRING_PRACTICE_MODE)
                self.pos1_x = cvar("timelimit");
            else
                self.pos1_x = 0;
        }
        else if (self.pos1_z == ADMIN_PRACTICE_MODE)
        {
            self.pos1_z = ADMIN_MATCH_MODE;
            self.pos1_x = clanring_timelimit;
            self.pos1_y = clanring_overtime;
			self.pos2_y = 2; // teamplay
        }
        else
        {
            self.pos1_z = ADMIN_NORMAL_MODE;
            if (!(clanring_playmode & (CLANRING_PRACTICE_MODE | CLANRING_MATCH_MODE)))
                self.pos1_x = cvar("timelimit");
            else
                self.pos1_x = 30;
            self.pos1_y = cvar("fraglimit");
        }
    }
    else if (self.t_length == 1)
    {
        // change timelimit
        if (self.pos1_z >= ADMIN_MATCH_MODE)
        {
            self.pos1_x = 5 * ceil(self.pos1_x / 5) + 5;
            if (self.pos1_x > 30)
                self.pos1_x = 5;
        }
        else
        {
            self.pos1_x = 10 * ceil(self.pos1_x / 10) + 10;
            if (self.pos1_x > 60)
                self.pos1_x = 0;
        }
    }
    else if (self.t_length == 2)
    {
        if (self.pos1_z >= ADMIN_MATCH_MODE)
        {
            // change overtime
            if (self.pos1_y == -1)
                self.pos1_y = 10;
            else if (self.pos1_y == 10)
                self.pos1_y = 5;
            else
                self.pos1_y = self.pos1_y - 1;
        }
        else
        {
            // change fraglimit
            self.pos1_y = 10 * ceil(self.pos1_y / 10);
            if (self.pos1_y > 40)
                self.pos1_y = 0;
            else
                self.pos1_y = self.pos1_y + 10;
        }
    }
    else if (self.t_length == 3)
    {
        // change gibs
        if (self.pos2_x == OPTIONS_HIGH_GIBS)
            self.pos2_x = OPTIONS_NO_GIBS;
        else
            self.pos2_x = self.pos2_x + 1;
    }
    else if (self.t_length == 4)
    {
        // change teamplay
        if (self.pos2_y == 2)
		{
			if (self.pos1_z == ADMIN_MATCH_MODE)
				self.pos2_y = 1;
			else
				self.pos2_y = 0;
		}
        else
            self.pos2_y = self.pos2_y + 1;
    }
    else if (self.t_length == 5)
    {
        // change noexit
        if (self.pos2_z == 2)
            self.pos2_z = 0;
        else
            self.pos2_z = self.pos2_z + 1;
    }
    else if (self.t_length == 6)
    {
        // change pausable
        if (self.aflag & OPTIONS_PAUSABLE)
            self.aflag = self.aflag - OPTIONS_PAUSABLE;
        else
            self.aflag = self.aflag | OPTIONS_PAUSABLE;
    }
    else if (self.t_length == 18)
    {
        // change deathmatch
        self.light_lev = self.light_lev + 1;
        if (self.light_lev == 4)
            self.light_lev = 1;
    }
    else if (self.t_length == 19)
    {
        // change ticrate
        self.worldtype = (ceil(self.worldtype * 100) + 1) / 100;
        if (self.worldtype > 0.1 || self.worldtype < 0.05)
            self.worldtype = 0.05;
    }
    else if (self.t_length == 20)
    {
        // change quad
        if (self.aflag & CLANRING_NO_QUAD)
            self.aflag = self.aflag - CLANRING_NO_QUAD;
        else
            self.aflag = self.aflag | CLANRING_NO_QUAD;
    }
    else if (self.t_length == 21)
    {
        // change pent
        if (self.aflag & CLANRING_NO_PENT)
            self.aflag = self.aflag - CLANRING_NO_PENT;
        else
            self.aflag = self.aflag | CLANRING_NO_PENT;
    }
    else if (self.t_length == 22)
    {
        // change ring
        if (self.aflag & CLANRING_NO_RING)
            self.aflag = self.aflag - CLANRING_NO_RING;
        else
            self.aflag = self.aflag | CLANRING_NO_RING;
    }
    else if (self.t_length == 23)
    {
        // change mode vote
        if (self.aflag & CLANRING_MODE_VOTE)
            self.aflag = self.aflag - CLANRING_MODE_VOTE;
        else
            self.aflag = self.aflag | CLANRING_MODE_VOTE;
    }

    // play sound
    stuffcmd(self, "play misc/menu3.wav\n");
};

//
//  F I N I S H  S E T T I N G
//
//  Called when 'done' is selected.
//
void () options_finish_setting =
{
	local float mode;

	// do this now so that setting teamplay doesn't confuse it
	mode = options_get_mode();

    centerprint(self, " ");

    // play sound
    stuffcmd(self, "play misc/menu2.wav\n");

    // make requested changes
    if (self.pos1_z >= ADMIN_MATCH_MODE)
    {
        // match mode
        if (self.pos1_x != clanring_timelimit)
            votables_request_set_timelimit(self.pos1_x);
        if (self.pos1_y != clanring_overtime)
            votables_request_set_overtime(self.pos1_y);
    }
    else
    {
        // normal or practice mode
        if (self.pos1_x != cvar("timelimit"))
            utils_set_cvar("timelimit", self.pos1_x);
        if (self.pos1_y != cvar("fraglimit"))
            clanring_set_fraglimit(self.pos1_y);
        if (self.pos2_z != cvar("noexit"))
            utils_set_cvar("noexit", self.pos2_z);
    }
    if (self.pos2_y != teamplay)
        clanring_set_teamplay(self.pos2_y);

    if (self.pos2_x != options_get_gibs())
    {
        // gibs has changed
        votables_request_set_gibs(self.pos2_x);
    }
    if ((self.aflag & OPTIONS_PAUSABLE) != cvar("pausable"))
    {
        // pausable has changed
        utils_set_cvar("pausable", self.aflag & OPTIONS_PAUSABLE);
        bprint("pausable changed to ");
        utils_bprint_float(self.aflag & OPTIONS_PAUSABLE);
    }
    if (self.light_lev != cvar("deathmatch"))
		admin_dmset(self.light_lev);
    if (self.worldtype != cvar("sys_ticrate"))
    {
        // ticrate has changed
        local string newtic;
        if (self.worldtype == 0.05)
            newtic = "0.05";
        else if (self.worldtype == 0.06)
            newtic = "0.06";
        else if (self.worldtype == 0.07)
            newtic = "0.07";
        else if (self.worldtype == 0.08)
            newtic = "0.08";
        else if (self.worldtype == 0.09)
            newtic = "0.09";
        else
            newtic = "0.1";
        cvar_set("sys_ticrate", newtic);
        bprint3("sys_ticrate changed to ", newtic, "\n");
    }
    if ((self.aflag & CLANRING_NO_QUAD) != (clanring_playmode & CLANRING_NO_QUAD))
        votables_set_quad(); // quad has changed
    if ((self.aflag & CLANRING_NO_PENT) != (clanring_playmode & CLANRING_NO_PENT))
        votables_set_pent(); // pent has changed
    if ((self.aflag & CLANRING_NO_RING) != (clanring_playmode & CLANRING_NO_RING))
        votables_set_ring(); // ring has changed
    if ((self.aflag & CLANRING_MODE_VOTE) != (clanring_playmode & CLANRING_MODE_VOTE))
		utils_toggle_sflag(CLANRING_MODE_VOTE, "Mode voting"); // mode vote has changed
    if (self.pos1_z != mode)
        votables_request_set_gametype_mode_map(-1, self.pos1_z, 0);

    self.style = self.style - CLANRING_SETTING_OPTIONS;
    self.style = self.style - (self.style & CLANRING_OK_TO_SHOOT);
};

//
//  P R E  T H I N K
//
//  Called from Client.qc while options are being set.
//
void () options_pre_think =
{
    if (!(self.flags & FL_JUMPRELEASED))
    {
        if (time >= self.delay)
            options_display();
        if (!self.button0 && !self.button2)
            self.flags = self.flags | FL_JUMPRELEASED;
    }
    else if (self.button2)
    {
        // go to the next option
        self.flags = self.flags - FL_JUMPRELEASED;
        self.t_length = (self.t_length & 127) + 1;
        if (self.t_length == 9)
            self.t_length = 0;
        if (self.t_length == 25)
            self.t_length = 18;
		if (self.pos1_z == ADMIN_MATCH_MODE && self.t_length == 5)
			self.t_length = 6;
        else if (self.pos1_z == ADMIN_MATCH_MODE && self.t_length == 4)
            self.t_length = 6;
        options_display();
        stuffcmd(self, "play misc/menu1.wav\n");
    }
    else if (self.button0)
    {
        // change option
        self.flags = self.flags - FL_JUMPRELEASED;
        self.t_length = self.t_length & 127;
        if (self.t_length == 8)
        {
            options_finish_setting();
            return;
        }
        else if (self.t_length == 7)
        {
            self.t_length = 18; // go to next screen
            stuffcmd(self, "play misc/menu2.wav\n");
        }
        else if (self.t_length == 24)
        {
            self.t_length = 7;  // go back to main options
            stuffcmd(self, "play misc/menu2.wav\n");
        }
        else
            options_change();
        options_display();            
    }
    else
    {
        // just check to see if we need to update the display
        if (time >= self.delay)
            options_display();
        return;
    }
};
