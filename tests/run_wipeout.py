#!/usr/bin/env python3
"""Run Wipeout gameplay regressions in a temporary QSS-M dedicated server.

Usage: python3 tests/run_wipeout.py --engine /path/to/QSS-M --pak0 /path/to/id1/pak0.pak
"""
import argparse
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

    with tempfile.TemporaryDirectory(prefix="crmod-wipeout-") as work:
        root = Path(work)
        source = root / "src"
        mod = root / "testmod"
        source.mkdir()
        (mod / "maps").mkdir(parents=True)
        (mod / "configs/maps").mkdir(parents=True)
        (root / "id1").mkdir()
        for name in ("pak0.pak", "pak1.pak"):
            path = args.pak0.resolve().with_name(name)
            if path.exists():
                (root / "id1" / name).symlink_to(path)
        engine = args.engine.resolve()
        bundle = next((p for p in engine.parents if p.suffix == ".app"), None)
        if bundle:
            shutil.copytree(bundle, root / bundle.name, symlinks=True)
            engine = root / bundle.name / engine.relative_to(bundle)
        for path in (repo / "src").iterdir():
            if path.suffix in {".qc", ".src"}:
                shutil.copy2(path, source / path.name)

        # Synthetic players have no channel. Sink outbound UI/audio only,
        # retaining a per-recipient count of the last-alive sound.
        extensions = source / "fteextensions.qc"
        code = extensions.read_text(encoding="latin1")
        code, count = re.subn(r"(\bvoid\s+end_sys_fields\s*;)",
                             r"\1\n.float wipeout_test_cues;", code)
        assert count == 1
        for name in ("stuffcmd", "sprint", "centerprint", "WriteByte", "WriteChar",
                     "WriteShort", "WriteLong", "WriteCoord", "WriteAngle",
                     "WriteString", "WriteEntity", "sound"):
            body = " {};"
            if name == "stuffcmd":
                body = ' { if (s == "play misc/medkey.wav\\n") client.wipeout_test_cues += 1; };'
            code, count = re.subn(r"(\b" + name + r"\s*=)\s*#\d+;",
                                 lambda m: m[1] + body, code)
            assert count > 0, name
        extensions.write_text(code, encoding="latin1")

        # Real BSP geometry, without unrelated map startup/entities.
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
        (mod / "maps/wipeout_test.bsp").write_bytes(bsp)
        world = source / "world.qc"
        code, count = re.subn(r"(void\s*\(\s*\)\s*)worldspawn(\s*=)",
                              r"\1wipeout_original_worldspawn\2", world.read_text(encoding="latin1"))
        assert count == 1
        world.write_text(code, encoding="latin1")
        shutil.copy2(repo / "tests/wipeout_override.qc", source / "wipeout_override.qc")
        progs = source / "progs.src"
        progs.write_text(progs.read_text() + "\nwipeout_override.qc\n")
        build = subprocess.run([str(compiler), "-src", "."], cwd=source, capture_output=True, text=True)
        assert build.returncode == 0 and (source / "progs.dat").exists(), build.stdout + build.stderr
        print("Server QuakeC build passed", flush=True)
        shutil.copy2(source / "progs.dat", mod / "progs.dat")
        (mod / "server.cfg").write_text("map wipeout_test\n")
        result = subprocess.run(
            [str(engine), "-nolauncher", "-basedir", str(root), "-nohome",
             "-dedicated", "1", "-noudp", "-nocdaudio", "-nosound",
             "-condebug", "-game", "testmod"], cwd=root, capture_output=True, timeout=30)
        output = (result.stdout + result.stderr).decode("latin1")
        for logfile in root.rglob("qconsole.log"):
            output += logfile.read_text(encoding="latin1")
        assert result.returncode == 0 and "WIPEOUT TEST PASSED:" in output and "WIPEOUT TEST FAILED:" not in output, output
        print(next(line for line in output.splitlines() if "WIPEOUT TEST PASSED:" in line))


if __name__ == "__main__":
    main()
