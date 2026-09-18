#!/usr/bin/env python3
import argparse
import base64
import json
import pathlib
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]


def var(name, desc, env, default, rules, sort, view=True, edit=True):
    return {
        "name": name,
        "description": desc,
        "env_variable": env,
        "default_value": default,
        "user_viewable": view,
        "user_editable": edit,
        "rules": rules,
        "sort": sort,
        "field_type": "text",
    }


def main():
    ap = argparse.ArgumentParser(description="Generate the Pelican PTDL_v2 egg and embed start.sh.")
    ap.add_argument("--image", default="ghcr.io/nazgile94/azerothcore-pelican-aio:latest")
    ap.add_argument("--output", default=str(ROOT / "egg-azerothcore-aio.json"))
    args = ap.parse_args()

    start = (ROOT / "start.sh").read_bytes()
    b64 = base64.b64encode(start).decode("ascii")
    install = f'''#!/bin/bash
set -euo pipefail
cd /mnt/server

echo "Installing AzerothCore All-in-One runtime files ..."
printf '%s' '{b64}' | base64 -d > start.sh
chmod +x start.sh
mkdir -p logs mysql .secrets
chmod 700 .secrets || true

cat > AIO-INFO.txt <<'INFO'
AzerothCore Pelican All-in-One v2.2
================================
Persistent data under /home/container:
- azerothcore/  source, build, configs and client data
- mysql/        local MySQL database
- logs/         MySQL logs
- .secrets/     generated internal DB password (when ACORE_DB_PASSWORD=auto)

Ports:
- Primary Allocation: Worldserver by default (WORLD_PORT empty/0)
- Additional TCP allocation: AUTH_PORT (default 3724)
- Optional MySQL allocation only when MYSQL_REMOTE_ACCESS=1
INFO

echo "AzerothCore AIO installer finished."
'''

    variables = [
        var("Realm Name", "Name des Realms in acore_auth.realmlist.", "REALM_NAME", "AzerothCore", "required|string|max:32", 1),
        var("Realm Address", "Oeffentliche IP oder DNS fuer WoW-Clients. 'auto' nutzt Pelicans SERVER_IP.", "REALM_ADDRESS", "auto", "required|string|max:253", 2),
        var("Local Realm Address", "LAN/interne Realm-Adresse; meist 127.0.0.1.", "REALM_LOCAL_ADDRESS", "127.0.0.1", "required|string|max:253", 3),
        var("Local Subnet Mask", "Subnetzmaske fuer lokale Clients/realmlist.", "REALM_LOCAL_SUBNET_MASK", "255.255.255.0", "required|string|max:32", 4),
        var("Worldserver Port Override", "Leer/0 = Primary Allocation (SERVER_PORT). Bei anderem Wert muss der Port als Pelican-Allocation existieren.", "WORLD_PORT", "", "nullable|integer|between:1,65535", 5),
        var("Authserver Port", "Authserver TCP-Port. Standard und empfohlen fuer WoW 3.3.5a: 3724. Als Allocation bereitstellen.", "AUTH_PORT", "3724", "required|integer|between:1,65535", 6),
        var("Realm Type", "Realmtyp: 0/4 Normal, 1 PvP, 6 RP, 8 RP-PvP, 16 FFA-PvP.", "REALM_TYPE", "0", "required|integer|in:0,1,4,6,8,16", 7),
        var("Realm Zone", "Realm-Region/Zeichensatz. 1=Development, 8=English, 9=German, 10=French, 11=Spanish, 12=Russian.", "REALM_ZONE", "1", "required|integer|min:1|max:59", 8),
        var("Minimum Security Level", "0=Spieler, 1=Moderator, 2=GM, 3=Admin. Hoehere Werte sperren normale Spieler aus.", "REALM_ALLOWED_SECURITY_LEVEL", "0", "required|integer|between:0,3", 9),

        var("Player Limit", "Maximale normale Spieler gleichzeitig; 0 = unbegrenzt.", "PLAYER_LIMIT", "1000", "required|integer|min:0|max:100000", 20),
        var("DBC Locale", "255=Auto; 0=enUS, 2=frFR, 3=deDE, 6=esES, 8=ruRU.", "DBC_LOCALE", "255", "required|integer|in:0,1,2,3,4,5,6,7,8,255", 21),
        var("Expansion", "0=Classic, 1=TBC, 2=WotLK. Fuer 3.3.5a normalerweise 2.", "EXPANSION", "2", "required|integer|between:0,2", 22),
        var("Max Player Level", "Maximales Spielerlevel. WotLK-Standard: 80.", "MAX_PLAYER_LEVEL", "80", "required|integer|min:1|max:100", 23),
        var("Start Player Level", "Level neu erstellter normaler Charaktere.", "START_PLAYER_LEVEL", "1", "required|integer|min:1|max:100", 24),
        var("Start Player Money", "Startgeld in Copper (10000 = 1 Gold).", "START_PLAYER_MONEY", "0", "required|integer|min:0", 25),
        var("Characters Per Realm", "Charaktere pro Realm; der 3.3.5a-Client zeigt maximal 10.", "CHARACTERS_PER_REALM", "10", "required|integer|between:1,10", 26),
        var("Characters Per Account", "Gesamtlimit pro Account; muss >= Characters Per Realm sein.", "CHARACTERS_PER_ACCOUNT", "50", "required|integer|between:1,50", 27),
        var("Skip Cinematics", "0=nie ueberspringen, 1=nur bereits gesehene, 2=immer ueberspringen.", "SKIP_CINEMATICS", "0", "required|integer|between:0,2", 28),
        var("Allow Two-Side Accounts", "1 erlaubt Horde und Allianz auf demselben Account/Realm.", "ALLOW_TWO_SIDE_ACCOUNTS", "1", "required|boolean", 29),

        var("XP Rate - Kills", "XP-Multiplikator fuer Kills. 1 = Blizzlike.", "RATE_XP_KILL", "1", "required|numeric|min:0|max:1000", 40),
        var("XP Rate - Quests", "XP-Multiplikator fuer Quests. 1 = Blizzlike.", "RATE_XP_QUEST", "1", "required|numeric|min:0|max:1000", 41),
        var("XP Rate - Exploration", "XP-Multiplikator fuer Exploration. 1 = Blizzlike.", "RATE_XP_EXPLORE", "1", "required|numeric|min:0|max:1000", 42),
        var("Money Drop Rate", "Gold/Geld-Drop-Multiplikator. 1 = Blizzlike.", "RATE_DROP_MONEY", "1", "required|numeric|min:0|max:1000", 43),
        var("Reputation Rate", "Ruf-Multiplikator. 1 = Blizzlike.", "RATE_REPUTATION_GAIN", "1", "required|numeric|min:0|max:1000", 44),
        var("Honor Rate", "Ehre-Multiplikator. 1 = Blizzlike.", "RATE_HONOR", "1", "required|numeric|min:0|max:1000", 45),

        var("Network Threads", "AzerothCore Network.Threads. Standard 1; laut Upstream etwa 1 Thread je 1000 Verbindungen.", "NETWORK_THREADS", "1", "required|integer|between:1,64", 60),
        var("Global Thread Pool", "AzerothCore ThreadPool. Standard 2.", "THREAD_POOL", "2", "required|integer|between:1,64", 61),
        var("Map Update Threads", "MapUpdate.Threads. Normal 1; bei PlayerBots werden bei leerem Wert automatisch 4 genutzt.", "MAP_UPDATE_THREADS", "", "nullable|integer|between:1,64", 62),
        var("Strict Client Version Check", "1 prueft Client-Dateien strenger; fuer normale 3.3.5a-Setups meist 0.", "STRICT_VERSION_CHECK", "0", "required|boolean", 63),
        var("Wrong Password Max Count", "Fehlversuche vor Temp-Ban; 0 deaktiviert diese Funktion.", "WRONG_PASS_MAX_COUNT", "0", "required|integer|min:0|max:1000", 64),
        var("Wrong Password Ban Time", "Ban-Dauer in Sekunden; 0 = permanent (nur relevant wenn Max Count > 0).", "WRONG_PASS_BAN_TIME", "600", "required|integer|min:0", 65),
        var("Wrong Password Ban Type", "0 = IP bannen, 1 = Account bannen.", "WRONG_PASS_BAN_TYPE", "0", "required|integer|between:0,1", 66),
        var("Log IP Addresses in Database", "1 erlaubt IP-Logging in der Datenbank, 0 deaktiviert es.", "ALLOW_IP_LOGGING", "1", "required|boolean", 67),

        var("AzerothCore DB Password", "'auto' erzeugt beim ersten Start ein persistentes zufaelliges internes Passwort. Optional explizit setzen.", "ACORE_DB_PASSWORD", "auto", "required|string|min:4|max:128", 80),
        var("MySQL Port", "Interner MySQL-Port. Nur extern benoetigt, wenn MYSQL_REMOTE_ACCESS=1.", "MYSQL_PORT", "3306", "required|integer|between:1,65535", 81),
        var("MySQL Remote Access", "0 = nur 127.0.0.1; 1 = 0.0.0.0. Bei 1 Port als Allocation + Firewall absichern.", "MYSQL_REMOTE_ACCESS", "0", "required|boolean", 82),

        var("Use PlayerBots", "0 = normaler AzerothCore-Core. 1 = verwendet automatisch mod-playerbots/azerothcore-wotlk Branch Playerbot und installiert mod-playerbots. Vor dem ersten Start waehlen.", "USE_PLAYERBOTS", "0", "required|boolean", 90),
        var("PlayerBots Module Branch", "Branch fuer mod-playerbots. Standard: master. Fuer Tests kann z.B. test-staging verwendet werden.", "PLAYERBOTS_MODULE_BRANCH", "master", "required|string|max:128", 91),

        var("Build Threads", "Parallele Compiler-Threads fuer AzerothCore.", "BUILD_THREADS", "2", "required|integer|between:1,64", 100),
        var("Auto Update", "1 = Core/Module beim Start per Fast-Forward aktualisieren. Lokale Aenderungen werden nicht ueberschrieben.", "AUTO_UPDATE", "1", "required|boolean", 101),
        var("Force Rebuild", "1 erzwingt bei jedem Start einen vollen Build. Nach Verwendung wieder auf 0 setzen.", "FORCE_REBUILD", "0", "required|boolean", 102),
        var("AzerothCore Modules", "Module als HTTPS-Git-URLs. Optional direkt dahinter --branch=BRANCH oder --branch BRANCH. Beispiel: https://github.com/mod-playerbots/mod-playerbots.git --branch=master", "ACORE_MODULES", "", "nullable|string|max:8192", 103),
        var("Auto-create Module Configs", "1 kopiert neue *.conf.dist aus etc/modules automatisch nach *.conf, ohne bestehende Configs zu ueberschreiben.", "MODULE_CONFIG_AUTO_COPY", "1", "required|boolean", 104),
        var("Auto-download Client Data", "1 laedt fehlende DBC/Maps/VMaps/MMaps automatisch. 0 erwartet manuell bereitgestellte Daten.", "CLIENT_DATA_AUTO_DOWNLOAD", "1", "required|boolean", 105),
        var("Force Client Data Refresh", "1 fuehrt client-data bei jedem Start erneut aus. Danach normalerweise wieder auf 0 setzen.", "FORCE_CLIENT_DATA_REFRESH", "0", "required|boolean", 106),
        var("AzerothCore Branch", "Git-Branch des Core-Repositories. Standard: master.", "ACORE_BRANCH", "master", "required|string|max:128", 107),
        var("AzerothCore Repository", "Core-Repository. Admin-Variable; standardmaessig offizielles AzerothCore-WotLK.", "ACORE_REPO", "https://github.com/azerothcore/azerothcore-wotlk.git", "required|string|max:255", 108, True, False),
    ]

    egg = {
        "_comment": "DO NOT EDIT: FILE GENERATED BY scripts/generate_egg.py",
        "meta": {"version": "PTDL_v2", "update_url": None},
        "exported_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "name": "AzerothCore WotLK - All in One v2.2",
        "author": "Nazgile94",
        "uuid": "b2b1b3e4-f2f7-4b61-a7f4-b122913fbd23",
        "description": "AzerothCore WotLK All-in-One fuer Pelican: MySQL 8.4, dbimport, Authserver, Worldserver, Client-Daten, Module mit Branch-Support sowie optionaler PlayerBots-Modus in einem Server.",
        "tags": ["wow", "azerothcore", "wotlk", "all-in-one"],
        "features": None,
        "docker_images": {"AzerothCore AIO Yolk": args.image},
        "file_denylist": [],
        "startup": "bash ./start.sh",
        "config": {
            "files": "{}",
            "startup": json.dumps({"done": ["World Initialized In", "World initialized in"]}, indent=2),
            "logs": "{}",
            "stop": "^C",
        },
        "scripts": {
            "installation": {
                "script": install,
                "container": "ghcr.io/pelican-eggs/installers:debian",
                "entrypoint": "bash",
            }
        },
        "variables": variables,
    }

    out = pathlib.Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(egg, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(out)

if __name__ == "__main__":
    main()
