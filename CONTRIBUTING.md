# Contributing

1. Edit `start.sh`, Docker/runtime files, docs or `scripts/generate_egg.py`.
2. Regenerate the egg with `make egg`.
3. Run `make validate`.
4. Do not edit the embedded installer payload in `egg-azerothcore-aio.json` manually; it is generated from `start.sh`.
