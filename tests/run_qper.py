#!/usr/bin/env python3
"""Exercise QPER v2 credit, timing and reference logic in a temporary QSS-M dedicated server.

Usage: python3 tests/run_qper.py --engine /path/to/QSS-M --pak0 /path/to/id1/pak0.pak
"""
import argparse
import json
import math
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", type=Path, required=True)
    parser.add_argument("--pak0", type=Path, required=True)
    parser.add_argument("--compiler", type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    compiler = (args.compiler or repo / "src/fteqcc").resolve()

    with tempfile.TemporaryDirectory(prefix="crmod-qper-") as work:
        root = Path(work)
        source = root / "src"
        mod = root / "testmod"
        source.mkdir()
        (mod / "maps").mkdir(parents=True)
        (mod / "configs/maps").mkdir(parents=True)
        (root / "id1").mkdir()
        (root / "id1/pak0.pak").symlink_to(args.pak0.resolve())
        pak1 = args.pak0.resolve().with_name("pak1.pak")
        if pak1.exists():
            (root / "id1/pak1.pak").symlink_to(pak1)
        engine = args.engine.resolve()
        # The macOS launcher changes cwd to its app's parent even with -basedir.
        # Copy the bundle so console logs also remain inside the temporary tree.
        bundle = next((p for p in engine.parents if p.suffix == ".app"), None)
        if bundle:
            shutil.copytree(bundle, root / bundle.name, symlinks=True)
            engine = root / bundle.name / engine.relative_to(bundle)
        for path in (repo / "src").iterdir():
            if path.suffix in {".qc", ".src"}:
                shutil.copy2(path, source / path.name)

        # Synthetic players have no network channel. Keep gameplay hooks real,
        # replacing only outbound console/client commands with inert UI sinks.
        extensions = source / "fteextensions.qc"
        code = extensions.read_text(encoding="latin1")
        code, stuff_count = re.subn(r"(\bstuffcmd\s*=)\s*#21;", r"\1 {};", code)
        code, sprint_count = re.subn(r"(\bsprint\s*=)\s*#24;", r"\1 {};", code)
        assert stuff_count == 1 and sprint_count == 2
        extensions.write_text(code, encoding="latin1")

        # Keep real BSP geometry but omit unrelated map entities and startup.
        with args.pak0.open("rb") as pak:
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
        (mod / "maps/qper_test.bsp").write_bytes(bsp)

        world = source / "world.qc"
        code, count = re.subn(r"(void\s*\(\s*\)\s*)worldspawn(\s*=)",
                              r"\1qper_original_worldspawn\2", world.read_text(encoding="latin1"))
        assert count == 1
        world.write_text(code, encoding="latin1")
        shutil.copy2(repo / "tests/qper_override.qc", source / "qper_override.qc")
        progs = source / "progs.src"
        progs.write_text(progs.read_text() + "\nqper_override.qc\n")
        build = subprocess.run([str(compiler), "-src", "."], cwd=source, capture_output=True, text=True)
        assert build.returncode == 0 and (source / "progs.dat").exists(), build.stdout + build.stderr
        print("Server QuakeC build passed")
        shutil.copy2(source / "progs.dat", mod / "progs.dat")

        (mod / "server.cfg").write_text("map qper_test\n")
        for logfile in root.rglob("qconsole.log"):
            logfile.unlink()
        result = subprocess.run(
            [str(engine), "-nolauncher", "-basedir", str(root), "-nohome",
             "-dedicated", "1", "-noudp", "-nocdaudio", "-nosound",
             "-condebug", "-game", "testmod"],
            cwd=root, capture_output=True, timeout=30)
        output = (result.stdout + result.stderr).decode("latin1")
        for logfile in root.rglob("qconsole.log"):
            output += logfile.read_text(encoding="latin1")
        assert result.returncode == 0 and "QPER TEST PASSED:" in output and "QPER TEST FAILED:" not in output, f"Engine exit {result.returncode}:\n{output}"
        ref = [p for p in mod.rglob("qper_ref.txt")]
        assert ref and ref[0].read_text().split() == ["qper2-provisional-2", "tdm_dmm3_4", "2.4000", "300.0"], ref and ref[0].read_text()
        exports = list(mod.rglob("qper_test.json"))
        assert len(exports) == 1, exports
        document = json.loads(exports[0].read_text())
        match = document["match"]
        reference = match["qper"]
        assert reference["version"] == "qper2-provisional-2"
        assert math.isclose(reference["reference"], 1.8, abs_tol=1e-6) and reference["reference_minutes"] == 0
        assert reference["reference_provisional"] == 1
        assert match["deathmatch"] == 3 and match["teamplay"] == 1
        players = match["teams"][0]["players"]
        assert match["teams"][0]["participating_players"] == 1
        assert len(players) == 1
        player = players[0]
        qper = player["qper"]
        assert qper["reference"] == reference["reference"]
        minutes = qper["active_secs"] / 60
        reconstructed = qper["prior_points"] + 15 * sum(qper["terms"].values()) / ((minutes + 3) * qper["reference"])
        assert math.isclose(reconstructed, player["per"], abs_tol=0.006), (reconstructed, player["per"])
        assert qper["raw_inputs"]["team_damage"] == 42
        assert qper["raw_inputs"]["damage"] == 14400
        assert qper["telemetry"]["team_damage"] == 42
        assert qper["telemetry"]["enemy_rl"] == 100
        assert qper["telemetry"]["spawn_lt1"] == 2
        assert player["per_v1"] > 0
        ctf_exports = list(mod.rglob("qper_ctf_metadata.json"))
        assert len(ctf_exports) == 1
        ctf = json.loads(ctf_exports[0].read_text())["match"]
        assert ctf["qper"]["cohort"] == "ctf_dmm3_4"
        assert ctf["hook_enabled"] == 1 and ctf["runes_enabled"] == 1
        print("Final JSON parsed; reference and rating reconstruction passed")
        print(next(line for line in output.splitlines() if "QPER TEST PASSED:" in line))


if __name__ == "__main__":
    main()
