# AzerothCore WotLK – Pelican All-in-One v2

[English README](README.en.md)

Eine komplette Repo-Vorlage für einen **AzerothCore WotLK 3.3.5a Privatserver in einem einzigen Pelican-Server**. Das Runtime-Image enthält den Build-Stack und MySQL; der Server verwaltet AzerothCore, Client-Daten, Datenbanken, Authserver und Worldserver persistent unter `/home/container`.

> Dieses Repository enthält **nicht** den AzerothCore-Quellcode oder WoW-Clientdateien. AzerothCore wird beim ersten Start aus dem offiziellen Repository geklont; Client-Daten werden über `acore.sh client-data` bezogen.

## Enthalten

- `egg-azerothcore-aio.json` – importierbares Pelican `PTDL_v2` Egg
- `Dockerfile` / `entrypoint.sh` – eigenes Pelican-Yolk
- `start.sh` – AIO-Orchestrierung
- automatische MySQL-8.4-Initialisierung
- automatische `dbimport`-Migrationen
- automatische Client-Daten (`dbc`, `maps`, `vmaps`, `mmaps`)
- AzerothCore-Module über `ACORE_MODULES`
- automatische Modul-Konfigurationsdateien aus `*.conf.dist`
- viele sinnvolle Pelican-Variablen für Realm, Gameplay, Rates, Security und Performance
- GitHub Actions für Validierung, GHCR-Build und ein fertig generiertes Egg-Artefakt

## Schnellstart

1. Dieses Repository in dein GitHub-Konto übernehmen.
2. Workflow **Build & publish Pelican Yolk** starten oder auf `main` pushen.
3. Unter **Actions → Build & publish Pelican Yolk → Artifacts** `pelican-azerothcore-aio-egg` herunterladen. Dieses Egg enthält bereits deine korrekte lowercase GHCR-URL.
4. Egg in Pelican importieren.
5. Server mit einer Primary TCP Allocation für den Worldserver anlegen; üblich ist `8085`.
6. Zusätzliche TCP Allocation `3724` für den Authserver anlegen (oder `AUTH_PORT` entsprechend ändern).
7. `REALM_ADDRESS` auf deine öffentlich erreichbare IP oder Domain setzen.
8. Starten. Der erste Start kompiliert AzerothCore und dauert deutlich länger als Folgestarts.

## Ports

| Dienst | Standard | Pelican |
|---|---:|---|
| Worldserver | Primary Allocation / `8085` | Primary Allocation; `WORLD_PORT` leer lassen oder als Override setzen |
| Authserver | `3724` | zusätzliche TCP Allocation |
| MySQL | `3306` | standardmäßig nur intern; extern nur mit `MYSQL_REMOTE_ACCESS=1` |

`WORLD_PORT` ist absichtlich ein **Override**. Leer bzw. `0` bedeutet: Nutze Pelicans `SERVER_PORT` der Primary Allocation. Wenn du `WORLD_PORT` auf einen anderen Wert setzt, muss genau dieser Port ebenfalls als Allocation vorhanden sein.

## Wichtigste Variablen

Die v2-Version stellt unter anderem direkt im Startup-Tab bereit:

- Realm/Netzwerk: `REALM_NAME`, `REALM_ADDRESS`, `WORLD_PORT`, `AUTH_PORT`, `REALM_TYPE`, `REALM_ZONE`
- Gameplay: `PLAYER_LIMIT`, `MAX_PLAYER_LEVEL`, `START_PLAYER_LEVEL`, `START_PLAYER_MONEY`, `CHARACTERS_PER_REALM`, `SKIP_CINEMATICS`
- Rates: `RATE_XP_KILL`, `RATE_XP_QUEST`, `RATE_XP_EXPLORE`, `RATE_DROP_MONEY`, `RATE_REPUTATION_GAIN`, `RATE_HONOR`
- Performance: `NETWORK_THREADS`, `THREAD_POOL`, `BUILD_THREADS`
- Auth/Security: `STRICT_VERSION_CHECK`, `WRONG_PASS_MAX_COUNT`, `WRONG_PASS_BAN_TIME`, `ALLOW_IP_LOGGING`
- Betrieb: `AUTO_UPDATE`, `FORCE_REBUILD`, `ACORE_MODULES`, `FORCE_CLIENT_DATA_REFRESH`

Die vollständige Tabelle mit Erklärungen steht in [docs/CONFIGURATION.de.md](docs/CONFIGURATION.de.md).

## Module / Plugins

Beispiel für `ACORE_MODULES`:

```text
https://github.com/azerothcore/mod-transmog.git https://github.com/azerothcore/mod-autobalance.git
```

Beim nächsten Start werden neue Module geklont und der Core neu gebaut. Wenn ein Modul unter `env/dist/etc/modules/` eine `*.conf.dist` erzeugt, wird standardmäßig automatisch die passende `*.conf` angelegt, sofern sie noch nicht existiert. Bestehende Modul-Konfigurationen werden nicht überschrieben.

## Privates GHCR-Package

Du kannst das Container-Package privat lassen. Hinterlege dafür auf dem Wings-Node Registry-Credentials für `ghcr.io`. Siehe [docs/PRIVATE-GHCR.de.md](docs/PRIVATE-GHCR.de.md).

## Accounts

Nach erfolgreichem Worldserver-Start in der Pelican-Konsole:

```text
account create USERNAME PASSWORT
account set gmlevel USERNAME 3 -1
```

## Dateien und Persistenz

```text
/home/container/
├── azerothcore/   # Source, Build, Configs, Client-Daten
├── mysql/         # komplette lokale MySQL-Daten
├── logs/          # MySQL-Logs
├── .secrets/      # automatisch erzeugtes internes DB-Passwort
└── start.sh
```

Für Backups den Server stoppen und mindestens `mysql/`, `.secrets/`, `azerothcore/env/dist/etc/` sowie eigene Module/Quellcodeänderungen sichern.

## Lokale Entwicklung

Egg mit eigener Image-URL generieren:

```bash
python3 scripts/generate_egg.py \
  --image ghcr.io/deinuser/azerothcore-pelican-aio:latest
```

Validieren:

```bash
make validate
```

Optionales Compose-Beispiel: [examples/compose.example.yml](examples/compose.example.yml).

## Hinweise

AzerothCore unterstützt aktuelle Config-Overrides per `AC_*`-Umgebungsvariablen. Diese haben Vorrang vor den `.conf`-Dateien. Werte, die dieses Egg nicht als Variable anbietet, kannst du weiterhin direkt in `azerothcore/env/dist/etc/worldserver.conf`, `authserver.conf` oder Modul-Configs ändern.

Dieses Projekt ist eine Community-Vorlage und nicht Teil von AzerothCore oder Pelican.
