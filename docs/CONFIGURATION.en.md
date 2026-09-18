# Configuration reference

AzerothCore supports generated `AC_*` environment overrides for config keys. This egg uses that official mechanism instead of rewriting `.conf` files on every boot.

## Network and realm

| Pelican variable | Default | Effect |
|---|---:|---|
| `REALM_NAME` | `AzerothCore` | realm name in `acore_auth.realmlist` |
| `REALM_ADDRESS` | `auto` | public IP/DNS; `auto` uses `SERVER_IP` |
| `REALM_LOCAL_ADDRESS` | `127.0.0.1` | local/LAN address |
| `REALM_LOCAL_SUBNET_MASK` | `255.255.255.0` | local subnet mask |
| `WORLD_PORT` | empty | empty/0 = Pelican primary `SERVER_PORT`; otherwise override |
| `AUTH_PORT` | `3724` | authserver port |
| `REALM_TYPE` | `0` | 0/4 Normal, 1 PvP, 6 RP, 8 RP-PvP, 16 FFA-PvP |
| `REALM_ZONE` | `1` | region/name rules; e.g. 8 English, 9 German |
| `REALM_ALLOWED_SECURITY_LEVEL` | `0` | minimum GM level allowed to log in |

External ports must exist as Pelican allocations; changing a variable alone does not publish a port.

## Gameplay

| Variable | Default | Note |
|---|---:|---|
| `PLAYER_LIMIT` | `1000` | 0 = unlimited |
| `DBC_LOCALE` | `255` | auto detect |
| `EXPANSION` | `2` | WotLK = 2 |
| `MAX_PLAYER_LEVEL` | `80` | WotLK default |
| `START_PLAYER_LEVEL` | `1` | must not exceed max level |
| `START_PLAYER_MONEY` | `0` | copper; 10000 = 1 gold |
| `CHARACTERS_PER_REALM` | `10` | 3.3.5a client limit is 10 |
| `CHARACTERS_PER_ACCOUNT` | `50` | must be >= realm limit |
| `SKIP_CINEMATICS` | `0` | 0/1/2 |
| `ALLOW_TWO_SIDE_ACCOUNTS` | `1` | Horde + Alliance on one account |

## Rates

All are multipliers; `1` is the standard value.

| Variable | AzerothCore key |
|---|---|
| `RATE_XP_KILL` | `Rate.XP.Kill` |
| `RATE_XP_QUEST` | `Rate.XP.Quest` |
| `RATE_XP_EXPLORE` | `Rate.XP.Explore` |
| `RATE_DROP_MONEY` | `Rate.Drop.Money` |
| `RATE_REPUTATION_GAIN` | `Rate.Reputation.Gain` |
| `RATE_HONOR` | `Rate.Honor` |

## Auth / security / privacy

| Variable | Default | Effect |
|---|---:|---|
| `STRICT_VERSION_CHECK` | `0` | stricter client version verification |
| `WRONG_PASS_MAX_COUNT` | `0` | 0 disables failed-password auto-ban |
| `WRONG_PASS_BAN_TIME` | `600` | seconds; 0 = permanent |
| `WRONG_PASS_BAN_TYPE` | `0` | 0 IP, 1 account |
| `ALLOW_IP_LOGGING` | `1` | allow/disallow storing IPs in DB |

## Performance

`NETWORK_THREADS=1` and `THREAD_POOL=2` are sensible starting values. More threads are not automatically faster. `BUILD_THREADS` only controls compilation parallelism.

The AIO forces `AC_PROCESS_PRIORITY=0` because an unprivileged Pelican container cannot raise process priority; this avoids the harmless permission warning.

## Database

`ACORE_DB_PASSWORD=auto` is recommended. A random internal password is generated on first boot and persisted at `/home/container/.secrets/acore-db-password`. With `MYSQL_REMOTE_ACCESS=0`, MySQL listens only on `127.0.0.1`.

## Modules

`ACORE_MODULES` accepts space-separated HTTPS Git URLs. Removing a URL does not automatically delete an already cloned module. This is deliberate to avoid destructive surprises. Remove a module directory manually, set `FORCE_REBUILD=1` for one boot, then set it back to `0`; follow the module's own SQL uninstall instructions if applicable.

## Other AzerothCore settings

Not every AzerothCore setting belongs in the egg UI. Advanced settings can still be edited in `worldserver.conf`, `authserver.conf`, and module configs. For settings exported by this egg, the `AC_*` environment value takes precedence over the file value.
