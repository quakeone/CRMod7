#!/usr/bin/env python3

import subprocess
import sys
import json
from pathlib import Path

MAX_CLIP_LENGTH = 19.0
FADE_LENGTH = 2.0

# Hardcoded from protect.wav, with valid loudnorm settings
TARGET_I = -13.62
TARGET_TP = -1.0
TARGET_LRA = 7.0


def get_duration_seconds(input_path: Path) -> float:
    cmd = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "json",
        str(input_path)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    return float(data["format"]["duration"])


def mp4_to_wav_with_clip_and_fade(input_file: str, output_file: str | None = None):
    input_path = Path(input_file)

    if not input_path.exists():
        print(f"  Error: file not found: {input_path}")
        sys.exit(1)

    if output_file is None:
        output_path = input_path.with_suffix(".wav")
    else:
        output_path = Path(output_file)

    try:
        full_duration = get_duration_seconds(input_path)
    except FileNotFoundError:
        print("  Error: ffprobe not found. Install ffmpeg first.")
        sys.exit(1)
    except Exception as e:
        print(f"  Error reading duration: {e}")
        sys.exit(1)

    clip_length = min(full_duration, MAX_CLIP_LENGTH)
    fade_start = max(0.0, clip_length - FADE_LENGTH)

    audio_filter = (
        f"loudnorm=I={TARGET_I}:LRA={TARGET_LRA}:TP={TARGET_TP}:linear=true,"
        f"afade=t=out:st={fade_start:.3f}:d={FADE_LENGTH:.3f}"
    )

    cmd = [
        "ffmpeg",
        "-y",
        "-i", str(input_path),
        "-vn",
        "-t", f"{clip_length:.3f}",
        "-af", audio_filter,
        "-acodec", "pcm_s16le",
        "-ar", "11025",
        "-ac", "1",
        str(output_path)
    ]

    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"  Input:     {input_path}")
        print(f"  Output:    {output_path}")
        print(f"  Duration:  {full_duration:.1f}s -> {clip_length:.1f}s")
        print(f"  Fade-out:  {fade_start:.1f}s - {clip_length:.1f}s ({FADE_LENGTH:.1f}s)")
        print(f"  Format:    PCM 16-bit, 11025 Hz, mono")
        print(f"  Loudness:  matched to protect.wav profile")
        print(f"             I={TARGET_I} LUFS, TP={TARGET_TP} dBTP, LRA={TARGET_LRA}")
        print()
        print("  Done!")
        print()
    except FileNotFoundError:
        print("  Error: ffmpeg not found. Install ffmpeg first.")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print("  Error: conversion failed.")
        if e.stderr:
            print(e.stderr)
        sys.exit(1)


def print_banner():
    print()
    print("  +----------------------------------------------+")
    print("  |       MATCHSOUNDS - Audio Converter      |")
    print("  |   mp4/webm/etc -> Quake .wav (11025 Hz)  |")
    print("  |   Hardcoded loudness match to protect.wav    |")
    print("  +----------------------------------------------+")
    print()


def prompt_for_input() -> tuple[str, str | None]:
    print_banner()
    print(f"  Max clip length: {MAX_CLIP_LENGTH}s | Fade-out: {FADE_LENGTH}s")
    print()
    input_file = input("  Input file path: ").strip()
    if not input_file:
        print("\n  No input file provided. Exiting.")
        sys.exit(1)
    output_file = input("  Output file path (Enter for default .wav): ").strip() or None
    print()
    return input_file, output_file


if __name__ == "__main__":
    if len(sys.argv) < 2:
        input_file, output_file = prompt_for_input()
    else:
        print_banner()
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else None

    mp4_to_wav_with_clip_and_fade(input_file, output_file)