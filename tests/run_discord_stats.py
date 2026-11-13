#!/usr/bin/env python3
"""Run the real Discord stats builder in a temporary QSS-M dedicated server and check its output.

Usage: python3 tests/run_discord_stats.py --engine /path/to/QSS-M --pak0 /path/to/id1/pak0.pak
       [--compiler /path/to/fteqcc] [--preview out.txt]
"""
import argparse
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

ANSI = re.compile(r"\x1b\[[0-9;]*m")
GOLD, RED, GRAY = "\x1b[1;33m", "\x1b[1;31m", "\x1b[30m"


def build(repo, root, compiler):
    source = root / "src"
    mod = root / "testmod"
    source.mkdir()
    (mod / "maps").mkdir(parents=True)
    for path in (repo / "src").iterdir():
        if path.suffix in {".qc", ".src"}:
            shutil.copy2(path, source / path.name)

    extensions = source / "fteextensions.qc"
    code = extensions.read_text(encoding="latin1")
    code, stuff_count = re.subn(r"(\bstuffcmd\s*=)\s*#21;", r"\1 {};", code)
    code, sprint_count = re.subn(r"(\bsprint\s*=)\s*#24;", r"\1 {};", code)
    assert stuff_count == 1 and sprint_count == 2
    extensions.write_text(code, encoding="latin1")

    world = source / "world.qc"
    code, count = re.subn(r"(void\s*\(\s*\)\s*)worldspawn(\s*=)",
                          r"\1dst_original_worldspawn\2", world.read_text(encoding="latin1"))
    assert count == 1
    world.write_text(code, encoding="latin1")
    shutil.copy2(repo / "tests/discord_stats_override.qc", source / "discord_stats_override.qc")
    progs = source / "progs.src"
    progs.write_text(progs.read_text() + "\ndiscord_stats_override.qc\n")
    result = subprocess.run([str(compiler), "-src", "."], cwd=source, capture_output=True, text=True)
    assert result.returncode == 0 and (source / "progs.dat").exists(), result.stdout + result.stderr
    shutil.copy2(source / "progs.dat", mod / "progs.dat")
    return mod


def run_case(root, mod, engine, pak0, case):
    with pak0.open("rb") as pak:
        magic, directory, size = struct.unpack("<4sii", pak.read(12))
        assert magic == b"PACK"
        pak.seek(directory)
        entries = list(struct.iter_unpack("<56sii", pak.read(size)))
        _, offset, length = next(e for e in entries if e[0].split(b"\0")[0] == b"maps/start.bsp")
        pak.seek(offset)
        bsp = bytearray(pak.read(length))
    entities = b'{\n"classname" "worldspawn"\n}\n\0'
    struct.pack_into("<ii", bsp, 4, len(bsp), len(entities))
    bsp.extend(entities)
    (mod / "maps/bastard.bsp").write_bytes(bsp)

    for old in mod.rglob("stats_*.json"):
        old.unlink()
    (mod / "server.cfg").write_text(f"set dst_case {case}\nhostname \"test*host_\"\nmap bastard\n")
    for logfile in root.rglob("qconsole.log"):
        logfile.unlink()
    try:
        result = subprocess.run(
            [str(engine), "-nolauncher", "-basedir", str(root), "-nohome",
             "-dedicated", "1", "-noudp", "-nocdaudio", "-nosound",
             "-condebug", "-game", "testmod"],
            cwd=root, capture_output=True, timeout=60)
    except subprocess.TimeoutExpired as timeout:
        log = "".join(f.read_text(encoding="latin1") for f in root.rglob("qconsole.log"))
        raise AssertionError(f"engine timed out:\n{(timeout.stdout or b'').decode('latin1')}\n{log}")
    output = (result.stdout + result.stderr).decode("latin1")
    for logfile in root.rglob("qconsole.log"):
        output += logfile.read_text(encoding="latin1")
    assert result.returncode == 0 and "DISCORD TEST DONE" in output, f"Engine exit {result.returncode}:\n{output}"
    parts = [int(n) for n in re.findall(r"DISCORD TEST \w+ parts=(\d+)", output)]
    assert parts and len(set(parts)) == 1, parts   # repeated runs produce the same split
    messages = []
    for i in range(1, parts[-1] + 1):
        files = list(mod.rglob(f"discord/stats_{i}.json"))
        assert len(files) == 1, (i, files)
        raw = files[0].read_bytes()
        document = json.loads(raw.decode("utf-8"))   # escaping must produce valid JSON
        assert document["allowed_mentions"] == {"parse": []}
        messages.append(document["content"])
    return messages


def blocks(messages):
    """Return {title: [plain rows]} for every titled code block, plus the raw block text."""
    text = "\n".join(messages)
    found = {}
    for title, body in re.findall(r"\*\*([^*\n]+)\*\*\n```ansi\n(.*?)```", text, re.S):
        assert title not in found, f"section repeated: {title}"
        found[title] = body
    return found


def check_common(messages):
    for i, message in enumerate(messages, 1):
        assert len(message) <= 2000, (i, len(message))
        assert message.count("```") % 2 == 0, f"unbalanced fences in message {i}"
        assert "\x1b" not in ANSI.sub("", message), "stray escape"


def rows(body):
    lines = ANSI.sub("", body).splitlines()
    return lines[1:]   # drop column header


def check_ctf(messages):
    check_common(messages)
    head = messages[0]
    assert head.startswith("## \U0001F535 Blue 651 – 56 Red \U0001F534\n"), head[:80]
    assert "-# bastard · 20 min 3v3 · CTF Match · test\\*host\\_ ·" in head
    assert "MVP **omicr0n**" in head
    assert "\U0001F4A5 Top dmg **omicr0n 10,359**" in head
    assert "Most caps **omicr0n, penguin 5**" in head
    assert "Longest hold **omicr0n 9:19**" in head

    found = blocks(messages)
    expected = ["Scoreboard", "Efficiency", "Kills and damage", "Quad", "Bad stats", "Items", "QPER (top 5)", "CTF"]
    assert list(found) == expected, list(found)
    order = ["new 2 quake", "omicr0n", "penguin", "woods", "r00k", "Faded"]
    for title in expected:
        if title in ("QPER (top 5)",):
            continue
        names = [r[:12].strip() for r in rows(found[title])]
        want = [n for n in order if title != "Quad" or n in ("new 2 quake", "omicr0n", "woods")]
        assert names == want, (title, names)

    eff, bad = found["Efficiency"], found["Bad stats"]
    assert GOLD + " 81%" in eff                      # omicr0n kill%
    assert GRAY + " N/A" in eff                      # penguin nails
    assert eff.count(GOLD + " 2.1") == 1 or eff.count(GOLD + " 2.0") == 2
    assert RED + "   3" in bad                       # penguin paks
    assert "\x1b[34mnew 2 quake" in found["Scoreboard"]
    assert "\x1b[31mwoods" in found["Scoreboard"]
    quad = rows(found["Quad"])
    assert len(quad) == 3
    assert GOLD + " 210s" in found["Quad"]
    ctf = found["CTF"]
    assert GOLD + " 9:19" in ctf
    qper = found["QPER (top 5)"]
    assert "why omicr0n led:" in ANSI.sub("", qper)
    assert "spec" not in "\n".join(messages)


def check_ffa(messages):
    check_common(messages)
    head = messages[0]
    assert head.startswith("## \U0001F3C6 q\"uote\\\\back wins · 30 frags\n"), head[:80]
    text = "\n".join(messages)
    assert "q\"uote\\back" in text and "@everyone" in text
    assert "\\*bold\\*\\_x\\_" in head or "\\*bold\\*\\_x\\_" not in text
    found = blocks(messages)
    assert "CTF" not in found and "Scoreboard" in found
    names = [r[:12].strip() for r in rows(found["Scoreboard"])]
    assert names == ["q\"uote\\back", "*bold*_x_", "@everyone"], names
    assert " team" not in found["Scoreboard"].splitlines()[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--pak0", type=Path, required=True)
    parser.add_argument("--compiler", type=Path)
    parser.add_argument("--preview", type=Path, help="write the CTF messages here for a visual check")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    compiler = (args.compiler or repo / "src/fteqcc").resolve()

    with tempfile.TemporaryDirectory(prefix="crmod-discord-") as work:
        root = Path(work)
        (root / "id1").mkdir()
        (root / "id1/pak0.pak").symlink_to(args.pak0.resolve())
        pak1 = args.pak0.resolve().with_name("pak1.pak")
        if pak1.exists():   # without it the engine runs as shareware and won't load custom maps
            (root / "id1/pak1.pak").symlink_to(pak1)
        engine = args.engine.resolve()
        bundle = next((p for p in engine.parents if p.suffix == ".app"), None)
        if bundle:
            shutil.copytree(bundle, root / bundle.name, symlinks=True)
            engine = root / bundle.name / engine.relative_to(bundle)
        mod = build(repo, root, compiler)
        print("Server QuakeC build passed")

        ctf = run_case(root, mod, engine, args.pak0, 1)
        if args.preview:
            args.preview.write_text("\n\n===== next message =====\n\n".join(ctf), encoding="utf-8")
        check_ctf(ctf)
        print(f"CTF match: {len(ctf)} messages, sections and highlights passed")

        ffa = run_case(root, mod, engine, args.pak0, 2)
        check_ffa(ffa)
        print(f"FFA match: {len(ffa)} messages, escaping and mentions passed")


if __name__ == "__main__":
    main()
