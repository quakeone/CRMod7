# Wipeout rules

Wipeout uses KTX's team elimination rules: when a team has nobody alive, its
queued returns are cancelled and it loses the round. A solo player gets an
immediate return on their first death. Their next death ends the round.
Using `kill` forfeits all remaining returns for the round.

Players start each life with 100 health, 200 red armor, all weapons, 100 shells,
200 nails, 50 rockets, 150 cells, and six grenades. Grenades have a separate
allowance and do not consume rockets. Solo recovery replenishes these resources
and restores an exhausted grenade launcher. There are no random backpacks.
Scoreboard points are awarded for each 100 damage dealt to enemies.

Return delays depend on team size and the player's deaths in the current round:

| Team size | First return | Second | Third | Fourth |
| --- | --- | --- | --- | --- |
| 1 | Immediate | 6 s | 12 s | 18 s |
| 2 | 3 s | 6 s | 12 s | 18 s |
| 3 | 4 s | 8 s | 16 s | 24 s |
| 4 | 5 s | 10 s | 20 s | 30 s |
| 5 or more | 6 s | 12 s | 24 s | 36 s |

All queued returns require a living teammate, except the solo first return.
Surviving until a teammate returns, then dying less than 300 milliseconds later,
earns an extra life and reduces the next delay accordingly.

`cr_wipeout_max_respawns` controls the maximum number of returns per player per
round. The default is `4`; `0` disables returns, including the solo first return.
Nonnegative whole numbers are supported; fractional values are rounded down.
Set it in `configs/clanring.cfg` before starting a match.

Falling and drowning do no damage. Fresh returns cannot take or deal damage
for one second, while retaining self rocket/grenade movement. Damage stops
during the round-end wait. Pausing freezes return delays, regeneration,
protection, escape grace, projectile fuses, and the round-end wait.

Solo players regenerate health, armor, and ammunition after an enemy frag if
they avoid enemy damage. The delay is five seconds per kill earned that round;
damage during the first second does not cancel recovery. Recovery is cleared
on death and respawn, and it does not progress during pauses or after a round
ends. Menus do not prevent recovery during active play.

These loadout, grenade, scoring, and damage changes apply to Wipeout. Ordinary
CA retains its existing rules.

## Regression tests

The test runner compiles an isolated copy of the server and exercises production
gameplay functions in a dedicated QSS-M server. Synthetic players use inert
outbound UI/audio calls. A real `id1/pak0.pak` is required; `pak1.pak` is used
when present. Set `TMPDIR` to a directory with sufficient space if needed.

```sh
python3 tests/run_wipeout.py --engine /path/to/quakespasm \
  --pak0 /path/to/id1/pak0.pak --compiler /path/to/fteqcc
```
