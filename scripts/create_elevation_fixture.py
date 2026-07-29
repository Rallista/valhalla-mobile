#!/usr/bin/env python3
"""
Valhalla Test Elevation Fixture Generator
=========================================
Writes apple/Tests/ValhallaTests/TestData/elevation/N42/N42E001.hgt.gz, the
skadi tile the `height` tests sample.

Real SRTM data cannot support exact assertions and a real N42E001 tile is
about 16 MB, five times the rest of TestData. This emits a synthetic tile
instead, whose height is an exact linear function of position:

    height = 3 * (3600 - row) + column      metres

so, for a point at latitude 42 + dlat and longitude 1 + dlon:

    height = 10800 * dlat + 3600 * dlon

Both axes are observable, and their coefficients differ, so a test can catch a
row/column mix-up, an off-by-one in either axis, and a swapped lat/lon pair.

The ceiling is deliberate. skadi reads any sample above NO_DATA_HIGH (16384)
as missing data, see src/valhalla/src/skadi/sample.cc:33. The maximum here is
3 * 3600 + 3600 = 14400, which stays inside that limit at every pixel.

Usage:
    ./scripts/create_elevation_fixture.py
"""

import gzip
import pathlib
import struct

# srtmgl1 tiles are 3601x3601 samples of big-endian int16, row 0 being the
# north edge. See src/valhalla/src/skadi/sample.cc:29.
DIM = 3601
ROW_METRES = 3
COLUMN_METRES = 1

OUTPUT = (
    pathlib.Path(__file__).resolve().parent.parent
    / "apple/Tests/ValhallaTests/TestData/elevation/N42/N42E001.hgt.gz"
)


def sample(row: int, column: int) -> int:
    return ROW_METRES * (DIM - 1 - row) + COLUMN_METRES * column


def build() -> bytes:
    rows = []
    for row in range(DIM):
        rows.append(
            b"".join(struct.pack(">h", sample(row, column)) for column in range(DIM))
        )
    return b"".join(rows)


def main() -> None:
    raw = build()
    assert len(raw) == DIM * DIM * 2, len(raw)

    peak = sample(0, DIM - 1)
    assert peak <= 16384, f"{peak} would read as no-data"

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(gzip.compress(raw, 9))

    print(f"wrote {OUTPUT.relative_to(OUTPUT.parents[5])}")
    print(f"  raw      {len(raw):,} bytes")
    print(f"  gzipped  {OUTPUT.stat().st_size:,} bytes")
    print(f"  peak     {peak} m at the north-east corner")


if __name__ == "__main__":
    main()
