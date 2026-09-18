# AzerothCore WotLK – Pelican All-in-One

[English README](README.en.md)

Ein öffentlich nutzbares **All-in-One-Egg für AzerothCore WotLK 3.3.5a auf Pelican**. Ein einzelner Pelican-Server verwaltet AzerothCore, MySQL 8.4, Datenbankmigrationen, Authserver, Worldserver, Client-Daten und optionale AzerothCore-Module.

**Für normale Nutzer ist kein eigener Docker-Build und kein GitHub-Fork erforderlich.** Das mitgelieferte Egg verwendet das öffentliche Runtime-Image:

```text
ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

> Das Repository enthält weder den AzerothCore-Quellcode noch WoW-Clientdateien. AzerothCore wird beim ersten Start aus dem offiziellen Upstream-Repository geklont. Benötigte Server-Client-Daten werden über AzerothCores `acore.sh client-data` bezogen.


> [!NOTE]
> **KI-Transparenz:** Dieses Projekt wurde zu großen Teilen mit Unterstützung von **OpenAI ChatGPT** erstellt und iterativ weiterentwickelt. Umgangssprachlich lässt sich das als „Vibe Coding“ bezeichnen; präziser ist **KI-unterstützte Entwicklung**. Anforderungen, Tests und Entscheidungen wurden menschlich gesteuert, während KI bei Code, Dokumentation und Fehlersuche unterstützt hat. Details: [AI-NOTICE.md](AI-NOTICE.md).

## Funktionen

- importierbares Pelican-`PTDL_v2`-Egg
- MySQL 8.4 direkt im gleichen Pelican-Server
- automatische Einrichtung von `acore_auth`, `acore_characters` und `acore_world`
- automatische `dbimport`-Migrationen
- automatische Client-Daten: `dbc`, `maps`, `vmaps`, `mmaps`
- Authserver + Worldserver gemeinsam verwaltet
- optionaler Worldserver-Port oder automatisch Pelicans Primary Allocation
- persistente Daten unter `/home/container`
- automatisches internes Datenbankpasswort
- AzerothCore-Module über `ACORE_MODULES`
- automatische Erstellung von Modul-Configs aus `*.conf.dist`
- zahlreiche Pelican-Variablen für Realm, Rates, Gameplay, Sicherheit und Performance
- GitHub Actions für Validierung, Docker/GHCR-Builds und Release-Eggs
- deutsch- und englischsprachige Dokumentation

## Schnellstart für Server-Admins

### 1. Egg importieren

Lade `egg-azerothcore-aio.json` aus diesem Repository bzw. einem Release herunter und importiere es in Pelican.

Das Standard-Egg zeigt bereits auf:

```text
ghcr.io/nazgile94/azerothcore-pelican-aio:latest
```

Wenn dieses GHCR-Package öffentlich ist, benötigt dein Pelican/Wings-Node **keine GitHub-Zugangsdaten** zum Pull.

### 2. Allocations anlegen

Empfohlen:

| Dienst | Standard | Pelican |
|---|---:|---|
| Worldserver | `8085` | Primary TCP Allocation |
| Authserver | `3724` | zusätzliche TCP Allocation |
| MySQL | `3306` | standardmäßig **nicht extern freigeben** |

`WORLD_PORT` ist optional. Leer oder `0` bedeutet: Nutze automatisch Pelicans `SERVER_PORT` der Primary Allocation. Wenn du einen anderen `WORLD_PORT` setzt, muss dieser Port ebenfalls als Allocation existieren.

### 3. Wichtige Startup-Werte setzen

Für einen normalen öffentlichen oder privaten Realm solltest du mindestens prüfen:

```text
REALM_NAME=AzerothCore
REALM_ADDRESS=deine.domain.tld
AUTH_PORT=3724
WORLD_PORT=
ACORE_DB_PASSWORD=auto
MYSQL_REMOTE_ACCESS=0
```

`REALM_ADDRESS=auto` verwendet Pelicans `SERVER_IP`. Bei NAT, Reverse Proxy, externer IP oder DNS ist eine explizite öffentliche IP/Domain meist sinnvoller.

### 4. Server starten

Der erste Start dauert deutlich länger, weil dabei unter anderem:

1. AzerothCore geklont wird,
2. der Core kompiliert wird,
3. DBC/Maps/VMaps/MMaps bereitgestellt werden,
4. MySQL initialisiert wird,
5. die AzerothCore-Datenbanken importiert bzw. aktualisiert werden,
6. Authserver und Worldserver gestartet werden.

Folgestarts sind wesentlich schneller.

## Ressourcen

Für den **ersten Build** sind als praxisnaher Ausgangspunkt etwa folgende Ressourcen sinnvoll:

| Ressource | Empfehlung |
|---|---:|
| RAM | 4–8 GB |
| CPU | 2–4 Threads oder mehr |
| Speicher | 30 GB oder mehr |
| Architektur | `linux/amd64` |

Der laufende Server kann je nach Spielerzahl, Modulen und Datenbankgröße mit weniger Ressourcen auskommen. Große Module wie PlayerBots können den Bedarf deutlich erhöhen.

## Wichtige Variablen

Das Egg stellt unter anderem bereit:

- **Realm/Netzwerk:** `REALM_NAME`, `REALM_ADDRESS`, `REALM_LOCAL_ADDRESS`, `WORLD_PORT`, `AUTH_PORT`, `REALM_TYPE`, `REALM_ZONE`
- **Gameplay:** `PLAYER_LIMIT`, `MAX_PLAYER_LEVEL`, `START_PLAYER_LEVEL`, `START_PLAYER_MONEY`, `CHARACTERS_PER_REALM`, `SKIP_CINEMATICS`
- **Rates:** `RATE_XP_KILL`, `RATE_XP_QUEST`, `RATE_XP_EXPLORE`, `RATE_DROP_MONEY`, `RATE_REPUTATION_GAIN`, `RATE_HONOR`
- **Performance:** `NETWORK_THREADS`, `THREAD_POOL`, `BUILD_THREADS`
- **Auth/Sicherheit:** `STRICT_VERSION_CHECK`, `WRONG_PASS_MAX_COUNT`, `WRONG_PASS_BAN_TIME`, `ALLOW_IP_LOGGING`
- **Betrieb:** `AUTO_UPDATE`, `FORCE_REBUILD`, `ACORE_MODULES`, `CLIENT_DATA_AUTO_DOWNLOAD`, `FORCE_CLIENT_DATA_REFRESH`
- **Datenbank:** `ACORE_DB_PASSWORD`, `MYSQL_PORT`, `MYSQL_REMOTE_ACCESS`

Die vollständige Referenz steht in [docs/CONFIGURATION.de.md](docs/CONFIGURATION.de.md).

## Module / Plugins

AzerothCore-Erweiterungen werden als **Module** eingebunden. Beispiel für `ACORE_MODULES`:

```text
https://github.com/azerothcore/mod-transmog.git https://github.com/azerothcore/mod-autobalance.git
```

Neue Module werden beim Start geklont und lösen einen Rebuild aus. Wenn ein Modul eine `*.conf.dist` unter `env/dist/etc/modules/` erzeugt, kann das AIO automatisch die zugehörige `*.conf` anlegen. Bestehende Konfigurationen werden nicht überschrieben.

Beim Entfernen eines Moduls reicht das Löschen der URL aus `ACORE_MODULES` absichtlich nicht: Entferne den Modulordner manuell, setze einmal `FORCE_REBUILD=1` und danach wieder `0`. Modul-spezifische SQL-Deinstallationsschritte müssen nach der jeweiligen Modul-Dokumentation durchgeführt werden.

## Accounts erstellen

Sobald der Worldserver läuft, kannst du in der Pelican-Konsole zum Beispiel einen Account anlegen:

```text
account create USERNAME PASSWORT
account set gmlevel USERNAME 3 -1
```

## Persistente Dateien

```text
/home/container/
├── azerothcore/   # Source, Build, Configs und Client-Daten
├── mysql/         # lokale MySQL-Daten
├── logs/          # MySQL-Logs
├── .secrets/      # automatisch erzeugtes internes DB-Passwort
└── start.sh
```

Für dateibasierte Backups den Server vorher stoppen. Mindestens `mysql/`, `.secrets/`, `azerothcore/env/dist/etc/` sowie eigene Module bzw. Quellcodeänderungen sichern.

## Updates

Mit `AUTO_UPDATE=1` versucht das AIO beim Start Fast-Forward-Updates für AzerothCore und konfigurierte Git-Module. Lokale Änderungen werden dabei nicht automatisch überschrieben.

Wenn du eine neue Version des Runtime-Images verwenden möchtest, starte den Server nach dem Image-Update neu. Bei größeren Änderungen empfiehlt sich vorher ein Backup.

## Für Forks und eigene Builds

Du kannst dieses Repository forken und dein eigenes Image veröffentlichen. Der enthaltene Workflow erzeugt automatisch einen lowercase GHCR-Namen nach diesem Schema:

```text
ghcr.io/<github-owner>/azerothcore-pelican-aio:latest
```

Nach einem Workflow-Lauf findest du unter **Actions → Build & publish Pelican Yolk → Artifacts** ein `pelican-azerothcore-aio-egg`, das bereits auf das Image deines Forks zeigt.

Wichtig: Ein neu veröffentlichtes GHCR-Container-Package ist zunächst typischerweise privat. Wenn andere Nutzer es ohne Registry-Credentials verwenden sollen, stelle das Package in den GitHub-Package-Einstellungen einmalig auf **Public**. Eine Anleitung liegt unter [docs/PUBLIC-GHCR.de.md](docs/PUBLIC-GHCR.de.md). Für absichtlich private Images siehe [docs/PRIVATE-GHCR.de.md](docs/PRIVATE-GHCR.de.md).

Eigenes Egg lokal erzeugen:

```bash
python3 scripts/generate_egg.py \
  --image ghcr.io/deinuser/azerothcore-pelican-aio:latest
```

Repository prüfen:

```bash
make validate
```

## Repository-Struktur

```text
.github/workflows/        GitHub Actions
docs/                     Konfigurations- und GHCR-Dokumentation
examples/                 optionale Beispiele
scripts/                  Egg-Generator und Validierung
Dockerfile                Pelican-kompatibles Runtime-Image
entrypoint.sh             Container-Entrypoint
start.sh                  AIO-Orchestrierung
egg-azerothcore-aio.json  direkt importierbares Egg
AI-NOTICE.md              KI-/AI-Transparenzhinweis
```

## Sicherheit

- MySQL ist standardmäßig nur intern gebunden (`MYSQL_REMOTE_ACCESS=0`).
- Nutze nach Möglichkeit `ACORE_DB_PASSWORD=auto`.
- Prüfe Drittanbieter-Module vor der Installation; sie werden in den Server kompiliert und laufen mit dessen Rechten.
- Committe keine Tokens, Datenbank-Dumps oder `.secrets/`-Inhalte.
- Ein öffentliches GHCR-Image benötigt zum **Pullen** keine GitHub-Credentials; private Images schon.

Weitere Hinweise: [SECURITY.md](SECURITY.md).

## KI-Transparenz

Dieses Repository ist ausdrücklich ein **KI-unterstützt entwickeltes Community-Projekt**. Große Teile von Code, Egg, Workflows und Dokumentation wurden mit OpenAI ChatGPT erstellt oder überarbeitet. Der umgangssprachliche Begriff „Vibe Coding“ passt teilweise; wir verwenden im Projekt bevorzugt **AI-assisted development / KI-unterstützte Entwicklung**, weil menschliche Anforderungen, Tests und Entscheidungen Teil des Entwicklungsprozesses sind.

Der vollständige Hinweis steht in [AI-NOTICE.md](AI-NOTICE.md).

## Mitwirken

Issues und Pull Requests sind willkommen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz und Hinweise

Der Code dieser Vorlage steht unter der in [LICENSE](LICENSE) angegebenen Lizenz. AzerothCore, Pelican, World of Warcraft und zugehörige Marken/Projekte sind eigenständige Projekte bzw. Rechteinhaber.

Dieses Repository ist eine **Community-Vorlage** und nicht offiziell mit AzerothCore, Pelican oder Blizzard Entertainment verbunden. Es werden keine Blizzard-Clientdateien in diesem Repository ausgeliefert. Nutzer sind selbst dafür verantwortlich, die für ihren Einsatz geltenden Lizenzen und rechtlichen Vorgaben einzuhalten.
