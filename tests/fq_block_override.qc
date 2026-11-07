float fq_block_checks;

void(string cmd, float expected) fq_block_check =
{
    float args;
    string arg0 = "", arg1 = "";

    args = tokenize(cmd);
    if (args > 0)
        arg0 = argv(0);
    if (args > 1)
        arg1 = argv(1);
    if (clanring_cmd_is_fq_trigger(args, arg0, arg1, cmd) != expected)
        error(strcat("FQ BLOCK TEST FAILED: ", cmd));
    fq_block_checks++;
};

void() worldspawn =
{
    // Plain triggers and raw commands.
    fq_block_check("say f_version", TRUE);
    fq_block_check("say_team f_system", TRUE);
    fq_block_check("say \"f_config\"", TRUE);
    fq_block_check("say F_RANDOM", TRUE);
    fq_block_check("q_version", TRUE);

    // Forms that used to get past the block.
    fq_block_check("say x: f_version", TRUE);
    fq_block_check("say \"x: f_version\"", TRUE);
    fq_block_check("say_team hello there: q_sysinfo", TRUE);
    fq_block_check("s f_version", TRUE);
    fq_block_check("st x: f_modified", TRUE);
    fq_block_check("SAY f_version", TRUE);
    fq_block_check("Say_Team x: f_random", TRUE);

    // Normal chat that clients do not respond to.
    fq_block_check("say hello", FALSE);
    fq_block_check("say what is f_version", FALSE);
    fq_block_check("say f_version please", FALSE);
    fq_block_check("say x:f_version", FALSE);
    fq_block_check("say x:  f_version", FALSE);
    fq_block_check("say x: f_versions", FALSE);
    fq_block_check("say :", FALSE);
    fq_block_check("kill", FALSE);
    fq_block_check("tell bob x: f_version", FALSE);

    print(sprintf("FQ BLOCK TEST PASSED: %g checks\n", fq_block_checks));
    localcmd("quit\n");
};
