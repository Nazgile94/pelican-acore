# Konfigurationsreferenz

AzerothCore erzeugt `AC_*`-Umgebungsvariablen aus den Config-Keys. Das Egg nutzt dieses offizielle Override-Verhalten, statt `.conf`-Dateien bei jedem Start umzuschreiben.

## Netzwerk und Realm

| Pelican-Variable | Standard | Wirkung |
|---|---:|---|
| `REALM_NAME` | `AzerothCore` | Realmname in `acore_auth.realmlist` |
| `REALM_ADDRESS` | `auto` | externe IP/DNS; `auto` nutzt `SERVER_IP` |
| `REALM_LOCAL_ADDRESS` | `127.0.0.1` | lokale/LAN-Adresse |
| `REALM_LOCAL_SUBNET_MASK` | `255.255.255.0` | lokale Subnetzmaske |
| `WORLD_PORT` | leer | leer/0 = Pelican Primary `SERVER_PORT`; sonst Override |
| `AUTH_PORT` | `3724` | Authserver-Port |
| `REALM_TYPE` | `0` | 0/4 Normal, 1 PvP, 6 RP, 8 RP-PvP, 16 FFA-PvP |
| `REALM_ZONE` | `1` | Region/Zeichensatz; z.B. 8 English, 9 German |
| `REALM_ALLOWED_SECURITY_LEVEL` | `0` | Mindest-GM-Level zum Einloggen |

**Wichtig:** Ports sind nicht automatisch von Pelican freigeschaltet. Jeder extern benötigte Port muss als Allocation existieren.

## Gameplay

| Variable | Standard | Hinweis |
|---|---:|---|
| `PLAYER_LIMIT` | `1000` | 0 = unbegrenzt |
| `DBC_LOCALE` | `255` | Auto-Detect; 3 = deDE |
| `EXPANSION` | `2` | WotLK = 2 |
| `MAX_PLAYER_LEVEL` | `80` | WotLK-Standard |
| `START_PLAYER_LEVEL` | `1` | darf Max-Level nicht überschreiten |
| `START_PLAYER_MONEY` | `0` | Copper; 10000 = 1 Gold |
| `CHARACTERS_PER_REALM` | `10` | 3.3.5a-Clientlimit 10 |
| `CHARACTERS_PER_ACCOUNT` | `50` | >= Realm-Limit |
| `SKIP_CINEMATICS` | `0` | 0/1/2 |
| `ALLOW_TWO_SIDE_ACCOUNTS` | `1` | Horde + Allianz auf einem Account |

## Rates

Alle folgenden Werte sind Multiplikatoren. `1` entspricht Standard/Blizzlike.

| Variable | Config-Key |
|---|---|
| `RATE_XP_KILL` | `Rate.XP.Kill` |
| `RATE_XP_QUEST` | `Rate.XP.Quest` |
| `RATE_XP_EXPLORE` | `Rate.XP.Explore` |
| `RATE_DROP_MONEY` | `Rate.Drop.Money` |
| `RATE_REPUTATION_GAIN` | `Rate.Reputation.Gain` |
| `RATE_HONOR` | `Rate.Honor` |

## Auth / Sicherheit / Datenschutz

| Variable | Standard | Wirkung |
|---|---:|---|
| `STRICT_VERSION_CHECK` | `0` | strengere Client-Dateiprüfung |
| `WRONG_PASS_MAX_COUNT` | `0` | 0 deaktiviert Auto-Ban nach Fehlversuchen |
| `WRONG_PASS_BAN_TIME` | `600` | Sekunden; 0 = permanent |
| `WRONG_PASS_BAN_TYPE` | `0` | 0 IP, 1 Account |
| `ALLOW_IP_LOGGING` | `1` | IP-Adressen in DB loggen oder nicht |

## Performance

`NETWORK_THREADS=1` und `THREAD_POOL=2` sind gute Ausgangswerte. Mehr ist nicht automatisch schneller. `BUILD_THREADS` betrifft nur die Kompilierung.

Der AIO setzt `AC_PROCESS_PRIORITY=0`, weil unprivilegierte Pelican-Container keine höhere Prozesspriorität setzen dürfen. Dadurch wird die harmlose `Permission denied`-Warnung vermieden.

## Datenbank

`ACORE_DB_PASSWORD=auto` ist der empfohlene Standard. Beim ersten Start wird ein zufälliges Passwort erzeugt und unter `/home/container/.secrets/acore-db-password` persistent gespeichert. MySQL bleibt mit `MYSQL_REMOTE_ACCESS=0` nur an `127.0.0.1` gebunden.

Wenn du Remote-MySQL aktivierst, brauchst du zusätzlich eine MySQL-Allocation und solltest den Port auf Host-/Netzwerkebene einschränken.

## Module

`ACORE_MODULES` nimmt durch Leerzeichen getrennte HTTPS-Git-URLs entgegen. Beispiel:

```text
https://github.com/azerothcore/mod-transmog.git https://github.com/azerothcore/mod-autobalance.git
```

Das Entfernen einer URL löscht ein bereits vorhandenes Modul absichtlich **nicht** automatisch. So werden lokale Daten nicht überraschend entfernt. Zum Deinstallieren Modulordner manuell entfernen, `FORCE_REBUILD=1` einmal starten und danach wieder `0` setzen. Modul-spezifische SQL-Uninstall-Schritte laut jeweiliger README beachten.

## Weitere AzerothCore-Einstellungen

Nicht jede AzerothCore-Option soll als Egg-Variable enden. Für Spezialfälle kannst du `worldserver.conf`, `authserver.conf` und Dateien unter `etc/modules/` bearbeiten. Beachte: Für Optionen, die dieses Egg als `AC_*`-Variable exportiert, gewinnt die Umgebungsvariable gegenüber der `.conf`.
