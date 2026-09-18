# Changelog

## 2.0.0 - 2026-09-18

- Added optional `WORLD_PORT` override while keeping Pelican's primary `SERVER_PORT` as the default.
- Made Auth and MySQL ports editable.
- Added realm type, realm zone, security level and local subnet settings.
- Added player limits, level/start settings, character limits, cinematics and cross-faction account variables.
- Added XP, money, reputation and honor rate variables.
- Added network/thread-pool and auth brute-force/privacy variables.
- Added automatic internal DB password generation with persistent `.secrets` storage.
- Added client-data refresh controls and automatic module config creation.
- Disabled high process priority inside the unprivileged container to avoid the known permission warning.
- Added generated Egg workflow artifact, validation workflow, bilingual README/config docs and private-GHCR documentation.
