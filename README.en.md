# AzerothCore WotLK – Pelican All-in-One v2

[Deutsche README](README.md)

A complete repository template for running an **AzerothCore WotLK 3.3.5a private server inside a single Pelican server**. The runtime image contains the build toolchain and MySQL; AzerothCore, client data, databases, authserver and worldserver are persisted below `/home/container`.

> This repository does **not** bundle AzerothCore source code or WoW client files. AzerothCore is cloned from the official repository on first start and client data is obtained through `acore.sh client-data`.

## Included

- `egg-azerothcore-aio.json` – importable Pelican `PTDL_v2` egg
- `Dockerfile` / `entrypoint.sh` – custom Pelican Yolk
- `start.sh` – all-in-one runtime orchestration
- automatic MySQL 8.4 initialization
- automatic `dbimport` migrations
- automatic client data (`dbc`, `maps`, `vmaps`, `mmaps`)
- AzerothCore modules through `ACORE_MODULES`
- automatic module config creation from `*.conf.dist`
- useful Pelican variables for realm, gameplay, rates, security and performance
- GitHub Actions for validation, GHCR publishing and a ready-to-import egg artifact

## Quick start

1. Copy this repository to your GitHub account.
2. Run **Build & publish Pelican Yolk**, or push to `main`.
3. Download the `pelican-azerothcore-aio-egg` artifact from the workflow run. It already contains your lower-case GHCR image path.
4. Import the egg into Pelican.
5. Create a server with a primary TCP allocation for the worldserver; `8085` is the usual value.
6. Add TCP allocation `3724` for the authserver, unless you changed `AUTH_PORT`.
7. Set `REALM_ADDRESS` to a public IP/DNS name reachable by your clients.
8. Start the server. The first boot compiles AzerothCore and is much slower than subsequent boots.

## Ports

| Service | Default | Pelican |
|---|---:|---|
| Worldserver | Primary allocation / `8085` | Primary allocation; leave `WORLD_PORT` empty or use it as an override |
| Authserver | `3724` | additional TCP allocation |
| MySQL | `3306` | internal by default; expose only with `MYSQL_REMOTE_ACCESS=1` |

`WORLD_PORT` is intentionally an **override**. Empty or `0` means “use Pelican's primary `SERVER_PORT`”. When overriding it, the selected port must also exist as a Pelican allocation.

## Important variables

v2 exposes, among others:

- Realm/network: `REALM_NAME`, `REALM_ADDRESS`, `WORLD_PORT`, `AUTH_PORT`, `REALM_TYPE`, `REALM_ZONE`
- Gameplay: `PLAYER_LIMIT`, `MAX_PLAYER_LEVEL`, `START_PLAYER_LEVEL`, `START_PLAYER_MONEY`, `CHARACTERS_PER_REALM`, `SKIP_CINEMATICS`
- Rates: `RATE_XP_KILL`, `RATE_XP_QUEST`, `RATE_XP_EXPLORE`, `RATE_DROP_MONEY`, `RATE_REPUTATION_GAIN`, `RATE_HONOR`
- Performance: `NETWORK_THREADS`, `THREAD_POOL`, `BUILD_THREADS`
- Auth/security: `STRICT_VERSION_CHECK`, `WRONG_PASS_MAX_COUNT`, `WRONG_PASS_BAN_TIME`, `ALLOW_IP_LOGGING`
- Operations: `AUTO_UPDATE`, `FORCE_REBUILD`, `ACORE_MODULES`, `FORCE_CLIENT_DATA_REFRESH`

See [docs/CONFIGURATION.en.md](docs/CONFIGURATION.en.md) for the full reference.

## Modules / plugins

Example `ACORE_MODULES` value:

```text
https://github.com/azerothcore/mod-transmog.git https://github.com/azerothcore/mod-autobalance.git
```

New modules are cloned and trigger a rebuild. By default, generated module `*.conf.dist` files are copied to their matching `*.conf` file if the latter does not exist. Existing module configuration is never overwritten.

## Private GHCR package

The package can remain private. Configure `ghcr.io` registry credentials on the Wings node. See [docs/PRIVATE-GHCR.en.md](docs/PRIVATE-GHCR.en.md).

## Accounts

Once the worldserver is running, use the Pelican console:

```text
account create USERNAME PASSWORD
account set gmlevel USERNAME 3 -1
```

## Persistence

```text
/home/container/
├── azerothcore/   # source, build, configs, client data
├── mysql/         # local MySQL data directory
├── logs/          # MySQL logs
├── .secrets/      # generated internal DB password
└── start.sh
```

Stop the server before file-level backups. At minimum back up `mysql/`, `.secrets/`, `azerothcore/env/dist/etc/` and any custom source/modules.

## Development

Generate the egg with your own image URI:

```bash
python3 scripts/generate_egg.py \
  --image ghcr.io/youruser/azerothcore-pelican-aio:latest
```

Validate:

```bash
make validate
```

An optional local Compose example is available at [examples/compose.example.yml](examples/compose.example.yml).

AzerothCore supports `AC_*` environment overrides. They take precedence over `.conf` files. Settings not exposed by this egg can still be changed in `azerothcore/env/dist/etc/worldserver.conf`, `authserver.conf`, or module configs.

This is a community template and is not part of AzerothCore or Pelican.
