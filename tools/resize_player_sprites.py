#!/usr/bin/env python3
from __future__ import annotations

import argparse
import binascii
import shutil
import struct
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
SOURCE_ROOT_DEFAULT = Path("sprites/主角动画")
OUTPUT_ROOT_DEFAULT = Path("sprites/主角动画_256x144")
TARGET_WIDTH = 256
TARGET_HEIGHT = 144


def collect_pngs(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.png") if path.is_file())


def paeth_predictor(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def unfilter_scanlines(raw: bytes, width: int, height: int, bytes_per_pixel: int) -> bytes:
    stride = width * bytes_per_pixel
    output = bytearray(height * stride)
    cursor = 0
    out_cursor = 0
    for _row in range(height):
        filter_type = raw[cursor]
        cursor += 1
        row = bytearray(raw[cursor:cursor + stride])
        cursor += stride

        if filter_type == 1:
            for i in range(bytes_per_pixel, stride):
                row[i] = (row[i] + row[i - bytes_per_pixel]) & 0xFF
        elif filter_type == 2:
            if out_cursor > 0:
                prev = output[out_cursor - stride:out_cursor]
                for i in range(stride):
                    row[i] = (row[i] + prev[i]) & 0xFF
        elif filter_type == 3:
            prev = output[out_cursor - stride:out_cursor] if out_cursor > 0 else None
            for i in range(stride):
                left = row[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
                up = prev[i] if prev is not None else 0
                row[i] = (row[i] + ((left + up) // 2)) & 0xFF
        elif filter_type == 4:
            prev = output[out_cursor - stride:out_cursor] if out_cursor > 0 else None
            for i in range(stride):
                left = row[i - bytes_per_pixel] if i >= bytes_per_pixel else 0
                up = prev[i] if prev is not None else 0
                up_left = prev[i - bytes_per_pixel] if prev is not None and i >= bytes_per_pixel else 0
                row[i] = (row[i] + paeth_predictor(left, up, up_left)) & 0xFF
        elif filter_type != 0:
            raise ValueError(f"Unsupported PNG filter type: {filter_type}")

        output[out_cursor:out_cursor + stride] = row
        out_cursor += stride
    return bytes(output)


def decode_png_rgba(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"Not a PNG file: {path}")

    cursor = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = interlace = None
    palette: bytes | None = None
    transparency: bytes | None = None
    idat_parts: list[bytes] = []

    while cursor < len(data):
        length = struct.unpack(">I", data[cursor:cursor + 4])[0]
        cursor += 4
        chunk_type = data[cursor:cursor + 4]
        cursor += 4
        chunk_data = data[cursor:cursor + length]
        cursor += length
        _crc = data[cursor:cursor + 4]
        cursor += 4

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, interlace = struct.unpack(">IIBBBBB", chunk_data)
        elif chunk_type == b"PLTE":
            palette = chunk_data
        elif chunk_type == b"tRNS":
            transparency = chunk_data
        elif chunk_type == b"IDAT":
            idat_parts.append(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or color_type is None or bit_depth is None or interlace is None:
        raise ValueError(f"Incomplete PNG: {path}")
    if bit_depth != 8:
        raise ValueError(f"Only 8-bit PNG is supported: {path}")
    if interlace != 0:
        raise ValueError(f"Interlaced PNG is not supported: {path}")

    channels_by_type = {
        0: 1,  # grayscale
        2: 3,  # rgb
        3: 1,  # indexed
        4: 2,  # grayscale + alpha
        6: 4,  # rgba
    }
    if color_type not in channels_by_type:
        raise ValueError(f"Unsupported PNG color type {color_type}: {path}")

    raw = zlib.decompress(b"".join(idat_parts))
    bytes_per_pixel = channels_by_type[color_type]
    scanlines = unfilter_scanlines(raw, width, height, bytes_per_pixel)
    rgba = bytearray(width * height * 4)

    if color_type == 0:
        for i, value in enumerate(scanlines):
            rgba[i * 4:i * 4 + 4] = bytes((value, value, value, 255))
    elif color_type == 2:
        for i in range(width * height):
            r, g, b = scanlines[i * 3:i * 3 + 3]
            rgba[i * 4:i * 4 + 4] = bytes((r, g, b, 255))
    elif color_type == 3:
        if palette is None:
            raise ValueError(f"Indexed PNG without palette: {path}")
        alpha_palette = transparency or b""
        for i, index in enumerate(scanlines):
            palette_index = index * 3
            r = palette[palette_index]
            g = palette[palette_index + 1]
            b = palette[palette_index + 2]
            a = alpha_palette[index] if index < len(alpha_palette) else 255
            rgba[i * 4:i * 4 + 4] = bytes((r, g, b, a))
    elif color_type == 4:
        for i in range(width * height):
            gray, alpha = scanlines[i * 2:i * 2 + 2]
            rgba[i * 4:i * 4 + 4] = bytes((gray, gray, gray, alpha))
    elif color_type == 6:
        rgba[:] = scanlines

    return width, height, bytes(rgba)


def resize_rgba_nearest(src_width: int, src_height: int, rgba: bytes, dst_width: int, dst_height: int) -> bytes:
    output = bytearray(dst_width * dst_height * 4)
    for y in range(dst_height):
        src_y = y * src_height // dst_height
        for x in range(dst_width):
            src_x = x * src_width // dst_width
            src_index = (src_y * src_width + src_x) * 4
            dst_index = (y * dst_width + x) * 4
            output[dst_index:dst_index + 4] = rgba[src_index:src_index + 4]
    return bytes(output)


def make_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    crc = binascii.crc32(chunk_type)
    crc = binascii.crc32(payload, crc) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", crc)


def write_png_rgba(path: Path, width: int, height: int, rgba: bytes) -> None:
    stride = width * 4
    raw = bytearray()
    for row in range(height):
        raw.append(0)
        start = row * stride
        raw.extend(rgba[start:start + stride])

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw), level=9)
    png = bytearray(PNG_SIGNATURE)
    png.extend(make_chunk(b"IHDR", ihdr))
    png.extend(make_chunk(b"IDAT", idat))
    png.extend(make_chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(png))


def resize_png(source: Path, target: Path) -> None:
    width, height, rgba = decode_png_rgba(source)
    resized_rgba = resize_rgba_nearest(width, height, rgba, TARGET_WIDTH, TARGET_HEIGHT)
    write_png_rgba(target, TARGET_WIDTH, TARGET_HEIGHT, resized_rgba)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Resize player animation PNG sheets to 256x144 using nearest-neighbor sampling."
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

    print(f"resized {len(png_files)} png files into {output_root} with nearest-neighbor sampling")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
