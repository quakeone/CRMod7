# QPER calibration and telemetry

QPER measures contribution per active player-minute. The core, dmm1 weapon
control, and CTF objective layers remain in `src/qper.qc`; raw calibration
telemetry lives in `src/qper_telemetry.qc`. New telemetry does not contribute
to the rating. Applied teammate damage replaces attempted teammate damage
in the existing cost term; the legacy badstats counter is unchanged.

## References and final ratings

The formula version is `qper2-provisional-2`. Each reference file row is:

```text
qper2-provisional-2 tdm_dmm3_4 2.4000 300.0
```

The columns are formula version, cohort, observed contribution per minute,
and observed player-minutes. Rows for older formulas are ignored. Cohorts
still distinguish mode, deathmatch rules, and configured team size. Actual
participating roster counts and teamplay, hook, and rune settings are also
exported so offline analysis can distinguish matches with different rules
or uneven rosters.

At match end, ratings retain the reference rate and reference minutes used
to score them, before that match updates the reference. Explanation points
and JSON use the same snapshot. A match-level provisional footnote appears
while that reference has fewer than 300 observed player-minutes. This is an
initial data-volume threshold, not a statistical confidence guarantee. The
individual `*` still marks stints shorter than five active minutes.

Paused seconds do not age damage assists, spawn ages, flag possessions, or
CTF return/carrier-kill assist windows. Exposure sampling also excludes
paused seconds. The legacy JSON PER now uses the display's one-minute floor.

## Player JSON

The `qper` object includes active seconds, the scoring reference, reference
minutes, raw kill/assist/capture/steal credits, prior points, weighted `terms`,
and `raw_inputs` for every formula input. Calibration numbers retain float
precision. The displayed `per` is rounded to two decimal places.

The rating can be reconstructed from these inputs:

```text
minutes = active_secs / 60
per = prior_points + 15 * sum(terms) / ((minutes + 3) * reference)
```

The separate `telemetry` object records:

- Enemy kills and victim deaths in age buckets `[0,1)`, `[1,2)`, `[2,4)`,
  and `[4,infinity)` seconds. Exempt kills also count in their age bucket.
  `spawn_exempt` counts kills exempt because of a flag, quad, pent, or dmm1
  RL/LG inventory. `kill_pool_full` and `kill_pool_awarded` are totals for
  the finisher's kills before and after the spawn discount, including
  contextual bonuses. Shared credits remain separate from these pool totals.
- Applied enemy and teammate damage by axe, SG, SSG, NG, SNG, GL, RL, LG,
  and other sources. Projectiles use their identity and damage type, so a
  weapon switch does not relabel a rocket or supernail. Applied damage is
  measured after damage rejection checks, including absorbed armor and
  health damage capped at remaining health.
- Living active seconds with quad, pent, ring, resistance, strength, haste,
  or regeneration; effective enemy damage dealt while each effect was
  present. Overlapping effects each report the same affected damage; their
  damage totals should not be added together.
- Living active seconds owning RL and LG, and seconds with either weapon
  and usable ammunition (`armed_secs`). Newly acquired RL/LG inventory is
  counted by world weapon, death pack, or voluntary drop. Exposure is
  sampled per server frame and flushed on relevant item, damage, weapon-use,
  and participation transitions. Rating minutes include the whole active
  stint, including time dead or unarmed.
- In dmm1, voluntary drops that give a teammate missing RL/LG inventory
  (`weapon_donations`, `weapon_donations_received`), teammate death-pack
  recoveries (`pack_recoveries`), and missing weapons acquired by enemies
  (`pack_concessions`). Recoveries do not credit the dead player as a donor.
  Tossing remains available only where the existing game rules allow it.
- Voluntary teammate ammo supplied in shells, nails, rockets, and cells,
  measured after inventory caps, including dmm3. Death packs do not earn
  ammo-supply support credit. Drop provenance retains team and connection
  identity; a reused client slot cannot inherit another donor's counters.

Cumulative telemetry resets with player stats and survives ghost restoration.
The next calibration pass should compare v1 and v2 over 50–100 matches,
reported separately for each mode/dmm/team-size combination, before adding
weights for these new metrics.

## Verification

```sh
python3 tests/run_qper.py --engine /path/to/quakespasm \
  --pak0 /path/to/id1/pak0.pak --compiler /path/to/fteqcc
```

The harness builds QuakeC and exercises real unpause, damage, item-transfer,
reference, lifecycle, and JSON-export paths in a dedicated engine. Synthetic
players have no network channel, so only `sprint` and `stuffcmd` are replaced
with inert sinks. The Python checks parse the actual final JSON and reconstruct
its frozen rating. Registered Quake assets are needed for mod execution.
