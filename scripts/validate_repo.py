#!/usr/bin/env python3
import argparse
import base64
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]


def fail(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--egg", default=str(ROOT / "egg-azerothcore-aio.json"))
    args = ap.parse_args()

    for f in (ROOT / "start.sh", ROOT / "entrypoint.sh"):
        subprocess.run(["bash", "-n", str(f)], check=True)

    egg_path = pathlib.Path(args.egg)
    with egg_path.open(encoding="utf-8") as fh:
        egg = json.load(fh)
    if egg.get("meta", {}).get("version") != "PTDL_v2":
        fail("egg is not PTDL_v2")

    vars_ = egg.get("variables", [])
    names = [v["env_variable"] for v in vars_]
    if len(names) != len(set(names)):
        fail("duplicate env_variable in egg")
    required = {"WORLD_PORT", "AUTH_PORT", "MYSQL_PORT", "REALM_NAME", "PLAYER_LIMIT", "ACORE_MODULES"}
    missing = sorted(required - set(names))
    if missing:
        fail(f"missing expected variables: {missing}")

    script = egg["scripts"]["installation"]["script"]
    m = re.search(r"printf '%s' '([A-Za-z0-9+/=]+)' \| base64 -d > start\.sh", script)
    if not m:
        fail("embedded start.sh base64 not found")
    embedded = base64.b64decode(m.group(1))
    actual = (ROOT / "start.sh").read_bytes()
    if embedded != actual:
        fail("embedded start.sh differs from repository start.sh; run generate_egg.py")

    print(f"OK: shell syntax, egg JSON, {len(vars_)} variables, embedded start.sh round-trip: {egg_path}")

if __name__ == "__main__":
    main()
