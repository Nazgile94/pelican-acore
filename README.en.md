# AzerothCore WotLK – Pelican All-in-One

[Deutsche README](README.md)

A publicly usable **all-in-one Pelican egg for AzerothCore WotLK 3.3.5a**. A single Pelican server manages AzerothCore, MySQL 8.4, database migrations, authserver, worldserver, client data and optional AzerothCore modules.

**Regular users do not need to build their own Docker image or fork this repository.** The included egg uses the public runtime image:

```text
ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

> This repository does not bundle AzerothCore source code or WoW client files. AzerothCore is cloned from the official upstream repository on first boot. Required server client-data is obtained through AzerothCore's `acore.sh client-data` workflow.

## Features

- importable Pelican `PTDL_v2` egg
- MySQL 8.4 inside the same Pelican server
- automatic setup of `acore_auth`, `acore_characters` and `acore_world`
- automatic `dbimport` migrations
- automatic client data: `dbc`, `maps`, `vmaps`, `mmaps`
- authserver + worldserver managed together
- optional worldserver port override or automatic use of Pelican's primary allocation
- persistent data below `/home/container`
- automatically generated internal database password
- AzerothCore modules through `ACORE_MODULES`
- automatic module config creation from `*.conf.dist`
- useful Pelican variables for realm, rates, gameplay, security and performance
- GitHub Actions for validation, Docker/GHCR builds and release eggs
- German and English documentation

## Quick start for server administrators

### 1. Import the egg

Download `egg-azerothcore-aio.json` from this repository or a release and import it into Pelican.

The default egg already points to:

```text
ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

When that GHCR package is public, your Pelican/Wings node does **not** need GitHub credentials to pull it.

### 2. Create allocations

Recommended defaults:

| Service | Default | Pelican |
|---|---:|---|
| Worldserver | `8085` | primary TCP allocation |
| Authserver | `3724` | additional TCP allocation |
| MySQL | `3306` | **do not expose externally** by default |

`WORLD_PORT` is optional. Empty or `0` means “use Pelican's primary `SERVER_PORT`”. If you select another `WORLD_PORT`, that exact port must also exist as a Pelican allocation.

### 3. Review important startup variables

For a normal public or private realm, review at least:

```text
REALM_NAME=AzerothCore
REALM_ADDRESS=your.domain.tld
AUTH_PORT=3724
WORLD_PORT=
ACORE_DB_PASSWORD=auto
MYSQL_REMOTE_ACCESS=0
```

`REALM_ADDRESS=auto` uses Pelican's `SERVER_IP`. With NAT, an external IP, DNS or unusual networking, explicitly setting the public address is usually clearer.

### 4. Start the server

The first boot takes considerably longer because it will, among other tasks:

1. clone AzerothCore,
2. compile the core,
3. provide DBC/Maps/VMaps/MMaps,
4. initialize MySQL,
5. import/update the AzerothCore databases,
6. launch authserver and worldserver.

Subsequent boots are much faster.

## Resources

A practical starting point for the **initial build** is:

| Resource | Recommendation |
|---|---:|
| RAM | 4–8 GB |
| CPU | 2–4 threads or more |
| Storage | 30 GB or more |
| Architecture | `linux/amd64` |

The running server can use less depending on player count, modules and database size. Large modules such as PlayerBots may significantly increase resource use.

## Important variables

The egg exposes, among others:

- **Realm/network:** `REALM_NAME`, `REALM_ADDRESS`, `REALM_LOCAL_ADDRESS`, `WORLD_PORT`, `AUTH_PORT`, `REALM_TYPE`, `REALM_ZONE`
- **Gameplay:** `PLAYER_LIMIT`, `MAX_PLAYER_LEVEL`, `START_PLAYER_LEVEL`, `START_PLAYER_MONEY`, `CHARACTERS_PER_REALM`, `SKIP_CINEMATICS`
- **Rates:** `RATE_XP_KILL`, `RATE_XP_QUEST`, `RATE_XP_EXPLORE`, `RATE_DROP_MONEY`, `RATE_REPUTATION_GAIN`, `RATE_HONOR`
- **Performance:** `NETWORK_THREADS`, `THREAD_POOL`, `BUILD_THREADS`
- **Auth/security:** `STRICT_VERSION_CHECK`, `WRONG_PASS_MAX_COUNT`, `WRONG_PASS_BAN_TIME`, `ALLOW_IP_LOGGING`
- **Operations:** `AUTO_UPDATE`, `FORCE_REBUILD`, `ACORE_MODULES`, `CLIENT_DATA_AUTO_DOWNLOAD`, `FORCE_CLIENT_DATA_REFRESH`
- **Database:** `ACORE_DB_PASSWORD`, `MYSQL_PORT`, `MYSQL_REMOTE_ACCESS`

See [docs/CONFIGURATION.en.md](docs/CONFIGURATION.en.md) for the full reference.

## Modules / plugins

AzerothCore extensions are normally installed as **modules**. Example `ACORE_MODULES` value:

```text
https://github.com/azerothcore/mod-transmog.git https://github.com/azerothcore/mod-autobalance.git
```

New modules are cloned on startup and trigger a rebuild. If a module creates a `*.conf.dist` below `env/dist/etc/modules/`, the AIO can automatically create the matching `*.conf`. Existing module configuration is never overwritten.

Removing a URL from `ACORE_MODULES` intentionally does not delete an existing module. Remove the module directory manually, run once with `FORCE_REBUILD=1`, then set it back to `0`. Follow the module's own documentation for any SQL uninstall steps.

## Creating accounts

Once worldserver is running, you can use the Pelican console, for example:

```text
account create USERNAME PASSWORD
account set gmlevel USERNAME 3 -1
```

## Persistent files

```text
/home/container/
├── azerothcore/   # source, build, configs and client data
├── mysql/         # local MySQL data
├── logs/          # MySQL logs
├── .secrets/      # generated internal DB password
└── start.sh
```

Stop the server before file-level backups. At minimum, back up `mysql/`, `.secrets/`, `azerothcore/env/dist/etc/` and any custom modules/source changes.

## Updates

With `AUTO_UPDATE=1`, the AIO attempts fast-forward updates for AzerothCore and configured Git modules during startup. Local changes are not automatically overwritten.

When using a newer runtime image, restart the server after the image update. Back up first before larger upgrades.

## Forks and self-hosted builds

You can fork this repository and publish your own image. The included workflow automatically generates a lowercase GHCR image name using:

```text
ghcr.io/<github-owner>/azerothcore-pelican-aio:latest
```

After a workflow run, **Actions → Build & publish Pelican Yolk → Artifacts** contains `pelican-azerothcore-aio-egg`, already configured to use your fork's image.

Important: newly published GHCR container packages are commonly private at first. If other people should be able to use your image without registry credentials, change the package visibility to **Public** once in GitHub's package settings. See [docs/PUBLIC-GHCR.en.md](docs/PUBLIC-GHCR.en.md). For intentionally private images, see [docs/PRIVATE-GHCR.en.md](docs/PRIVATE-GHCR.en.md).

Generate an egg locally with a custom image URI:

```bash
python3 scripts/generate_egg.py \
  --image ghcr.io/youruser/azerothcore-pelican-aio:latest
```

Validate the repository:

```bash
make validate
```

## Repository layout

```text
.github/workflows/        GitHub Actions
docs/                     configuration and GHCR documentation
examples/                 optional examples
scripts/                  egg generator and validation
Dockerfile                Pelican-compatible runtime image
entrypoint.sh             container entrypoint
start.sh                  AIO orchestration
egg-azerothcore-aio.json  directly importable egg
```

## Security

- MySQL binds internally by default (`MYSQL_REMOTE_ACCESS=0`).
- Prefer `ACORE_DB_PASSWORD=auto`.
- Review third-party modules before installation; they are compiled into the server and run with its permissions.
- Never commit tokens, database dumps or `.secrets/` contents.
- A public GHCR image requires no GitHub credentials to **pull**; a private image does.

See [SECURITY.md](SECURITY.md) for more.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License and notices

The code in this template is distributed under the license in [LICENSE](LICENSE). AzerothCore, Pelican, World of Warcraft and related trademarks/projects belong to their respective projects or rights holders.

This repository is a **community template** and is not officially affiliated with AzerothCore, Pelican or Blizzard Entertainment. No Blizzard client files are distributed in this repository. Users are responsible for complying with licenses and laws applicable to their own use.
