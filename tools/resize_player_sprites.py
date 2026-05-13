#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


SOURCE_ROOT_DEFAULT = Path("sprites/主角动画")
OUTPUT_ROOT_DEFAULT = Path("sprites/主角动画_256x144")
TARGET_WIDTH = 256
TARGET_HEIGHT = 144


def collect_pngs(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.png") if path.is_file())


def resize_png(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "sips",
            "-z",
            str(TARGET_HEIGHT),
            str(TARGET_WIDTH),
            str(source),
            "--out",
            str(target),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Resize player animation sprite sheets to 256x144 using macOS sips."
    )
    parser.add_argument(
        "--source-root",
        type=Path,
        default=SOURCE_ROOT_DEFAULT,
        help=f"Source animation root. Default: {SOURCE_ROOT_DEFAULT}",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=OUTPUT_ROOT_DEFAULT,
        help=f"Output animation root. Default: {OUTPUT_ROOT_DEFAULT}",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Remove the output root before resizing.",
    )
    args = parser.parse_args()

    source_root: Path = args.source_root
    output_root: Path = args.output_root

    if shutil.which("sips") is None:
        raise SystemExit("sips not found. This script currently requires macOS sips.")
    if not source_root.exists():
        raise SystemExit(f"source root does not exist: {source_root}")

    if args.clean and output_root.exists():
        shutil.rmtree(output_root)

    png_files = collect_pngs(source_root)
    if not png_files:
        raise SystemExit(f"no png files found under: {source_root}")

    for source_path in png_files:
        relative_path = source_path.relative_to(source_root)
        target_path = output_root / relative_path
        resize_png(source_path, target_path)

    print(f"resized {len(png_files)} png files into {output_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
