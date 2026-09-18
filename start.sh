#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/home/container"
SRC="${ROOT}/azerothcore"
AIO_DIR="${ROOT}/.aio"
MYSQL_HOME="${AIO_DIR}/mysql"
RUNTIME_LIB="${AIO_DIR}/lib"
PROFILE_FILE="${AIO_DIR}/install-profile.env"
MYSQL_DIR="${ROOT}/mysql"
MYSQL_SOCKET="${MYSQL_DIR}/mysql.sock"
MYSQL_PIDFILE="${MYSQL_DIR}/mysqld.pid"
MYSQL_SECURE_DIR="${AIO_DIR}/mysql-files"
LOG_DIR="${ROOT}/logs"
SECRET_DIR="${ROOT}/.secrets"

# Build-profile variables. These are installation-time settings in the standalone egg.
ACORE_REPO="${ACORE_REPO:-https://github.com/azerothcore/azerothcore-wotlk.git}"
ACORE_BRANCH="${ACORE_BRANCH:-master}"
ACORE_MODULES="${ACORE_MODULES:-}"
USE_PLAYERBOTS="${USE_PLAYERBOTS:-0}"
PLAYERBOTS_CORE_BRANCH="${PLAYERBOTS_CORE_BRANCH:-Playerbot}"
PLAYERBOTS_MODULE_BRANCH="${PLAYERBOTS_MODULE_BRANCH:-master}"
MODULE_CONFIG_AUTO_COPY="${MODULE_CONFIG_AUTO_COPY:-1}"

# Database
ACORE_DB_PASSWORD="${ACORE_DB_PASSWORD:-auto}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_REMOTE_ACCESS="${MYSQL_REMOTE_ACCESS:-0}"

# Network / realm
AUTH_PORT="${AUTH_PORT:-3724}"
WORLD_PORT="${WORLD_PORT:-}"
REALM_NAME="${REALM_NAME:-AzerothCore}"
REALM_ADDRESS="${REALM_ADDRESS:-auto}"
REALM_LOCAL_ADDRESS="${REALM_LOCAL_ADDRESS:-127.0.0.1}"
REALM_LOCAL_SUBNET_MASK="${REALM_LOCAL_SUBNET_MASK:-255.255.255.0}"
REALM_TYPE="${REALM_TYPE:-0}"
REALM_ZONE="${REALM_ZONE:-1}"
REALM_ALLOWED_SECURITY_LEVEL="${REALM_ALLOWED_SECURITY_LEVEL:-0}"

# World configuration
PLAYER_LIMIT="${PLAYER_LIMIT:-1000}"
DBC_LOCALE="${DBC_LOCALE:-255}"
EXPANSION="${EXPANSION:-2}"
MAX_PLAYER_LEVEL="${MAX_PLAYER_LEVEL:-80}"
START_PLAYER_LEVEL="${START_PLAYER_LEVEL:-1}"
START_PLAYER_MONEY="${START_PLAYER_MONEY:-0}"
CHARACTERS_PER_REALM="${CHARACTERS_PER_REALM:-10}"
CHARACTERS_PER_ACCOUNT="${CHARACTERS_PER_ACCOUNT:-50}"
SKIP_CINEMATICS="${SKIP_CINEMATICS:-0}"
ALLOW_TWO_SIDE_ACCOUNTS="${ALLOW_TWO_SIDE_ACCOUNTS:-1}"
RATE_XP_KILL="${RATE_XP_KILL:-1}"
RATE_XP_QUEST="${RATE_XP_QUEST:-1}"
RATE_XP_EXPLORE="${RATE_XP_EXPLORE:-1}"
RATE_DROP_MONEY="${RATE_DROP_MONEY:-1}"
RATE_REPUTATION_GAIN="${RATE_REPUTATION_GAIN:-1}"
RATE_HONOR="${RATE_HONOR:-1}"
NETWORK_THREADS="${NETWORK_THREADS:-1}"
THREAD_POOL="${THREAD_POOL:-2}"
MAP_UPDATE_THREADS="${MAP_UPDATE_THREADS:-}"

# Auth / privacy
STRICT_VERSION_CHECK="${STRICT_VERSION_CHECK:-0}"
WRONG_PASS_MAX_COUNT="${WRONG_PASS_MAX_COUNT:-0}"
WRONG_PASS_BAN_TIME="${WRONG_PASS_BAN_TIME:-600}"
WRONG_PASS_BAN_TYPE="${WRONG_PASS_BAN_TYPE:-0}"
ALLOW_IP_LOGGING="${ALLOW_IP_LOGGING:-1}"

# PlayerBots DB/runtime
PLAYERBOTS_DB_WORKER_THREADS="${PLAYERBOTS_DB_WORKER_THREADS:-1}"
PLAYERBOTS_DB_SYNCH_THREADS="${PLAYERBOTS_DB_SYNCH_THREADS:-1}"
PLAYERBOTS_DB_UPDATES="${PLAYERBOTS_DB_UPDATES:-1}"

say() { printf '\n[AzerothCore Standalone AIO] %s\n' "$*"; }
die() { printf '\n[AzerothCore Standalone AIO] FEHLER: %s\n' "$*" >&2; exit 1; }

is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }
is_port() { is_uint "$1" && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }
is_bool() { [[ "$1" == "0" || "$1" == "1" ]]; }
is_nonneg_number() { [[ "$1" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; }
sha256_text() { printf '%s' "$1" | sha256sum | awk '{print $1}'; }

if [[ -z "$WORLD_PORT" || "$WORLD_PORT" == "0" ]]; then
    WORLD_PORT="${SERVER_PORT:-8085}"
fi

for b in MODULE_CONFIG_AUTO_COPY MYSQL_REMOTE_ACCESS ALLOW_TWO_SIDE_ACCOUNTS STRICT_VERSION_CHECK ALLOW_IP_LOGGING USE_PLAYERBOTS PLAYERBOTS_DB_UPDATES; do
    is_bool "${!b}" || die "$b muss 0 oder 1 sein."
done
for p in MYSQL_PORT AUTH_PORT WORLD_PORT; do
    is_port "${!p}" || die "$p ist ungueltig."
done
[[ "$MYSQL_PORT" != "$AUTH_PORT" && "$MYSQL_PORT" != "$WORLD_PORT" && "$AUTH_PORT" != "$WORLD_PORT" ]] || die "MYSQL_PORT, AUTH_PORT und WORLD_PORT muessen unterschiedlich sein."
[[ "$ACORE_BRANCH" =~ ^[A-Za-z0-9._/-]+$ ]] || die "ACORE_BRANCH enthaelt ungueltige Zeichen."
[[ "$PLAYERBOTS_CORE_BRANCH" =~ ^[A-Za-z0-9._/-]+$ ]] || die "PLAYERBOTS_CORE_BRANCH enthaelt ungueltige Zeichen."
[[ "$PLAYERBOTS_MODULE_BRANCH" =~ ^[A-Za-z0-9._/-]+$ ]] || die "PLAYERBOTS_MODULE_BRANCH enthaelt ungueltige Zeichen."
[[ "$REALM_NAME" != *$'\n'* && ${#REALM_NAME} -le 32 ]] || die "REALM_NAME darf maximal 32 Zeichen enthalten."
[[ "$REALM_LOCAL_SUBNET_MASK" =~ ^[0-9.]+$ ]] || die "REALM_LOCAL_SUBNET_MASK hat ein ungueltiges Format."
is_uint "$REALM_TYPE" && (( REALM_TYPE == 0 || REALM_TYPE == 1 || REALM_TYPE == 4 || REALM_TYPE == 6 || REALM_TYPE == 8 || REALM_TYPE == 16 )) || die "REALM_TYPE muss 0, 1, 4, 6, 8 oder 16 sein."
is_uint "$REALM_ZONE" && (( REALM_ZONE >= 1 && REALM_ZONE <= 59 )) || die "REALM_ZONE muss zwischen 1 und 59 liegen."
is_uint "$REALM_ALLOWED_SECURITY_LEVEL" && (( REALM_ALLOWED_SECURITY_LEVEL >= 0 && REALM_ALLOWED_SECURITY_LEVEL <= 3 )) || die "REALM_ALLOWED_SECURITY_LEVEL muss 0-3 sein."
is_uint "$PLAYER_LIMIT" || die "PLAYER_LIMIT muss eine Ganzzahl >= 0 sein."
is_uint "$DBC_LOCALE" && (( DBC_LOCALE == 255 || DBC_LOCALE <= 8 )) || die "DBC_LOCALE muss 0-8 oder 255 sein."
is_uint "$EXPANSION" && (( EXPANSION <= 2 )) || die "EXPANSION muss 0, 1 oder 2 sein."
is_uint "$MAX_PLAYER_LEVEL" && (( MAX_PLAYER_LEVEL >= 1 && MAX_PLAYER_LEVEL <= 100 )) || die "MAX_PLAYER_LEVEL muss 1-100 sein."
is_uint "$START_PLAYER_LEVEL" && (( START_PLAYER_LEVEL >= 1 && START_PLAYER_LEVEL <= MAX_PLAYER_LEVEL )) || die "START_PLAYER_LEVEL muss zwischen 1 und MAX_PLAYER_LEVEL liegen."
is_uint "$START_PLAYER_MONEY" || die "START_PLAYER_MONEY muss eine Ganzzahl >= 0 sein."
is_uint "$CHARACTERS_PER_REALM" && (( CHARACTERS_PER_REALM >= 1 && CHARACTERS_PER_REALM <= 10 )) || die "CHARACTERS_PER_REALM muss 1-10 sein."
is_uint "$CHARACTERS_PER_ACCOUNT" && (( CHARACTERS_PER_ACCOUNT >= CHARACTERS_PER_REALM && CHARACTERS_PER_ACCOUNT <= 50 )) || die "CHARACTERS_PER_ACCOUNT muss zwischen CHARACTERS_PER_REALM und 50 liegen."
is_uint "$SKIP_CINEMATICS" && (( SKIP_CINEMATICS <= 2 )) || die "SKIP_CINEMATICS muss 0-2 sein."
for r in RATE_XP_KILL RATE_XP_QUEST RATE_XP_EXPLORE RATE_DROP_MONEY RATE_REPUTATION_GAIN RATE_HONOR; do
    is_nonneg_number "${!r}" || die "$r muss eine Zahl >= 0 sein."
done
for n in NETWORK_THREADS THREAD_POOL; do
    is_uint "${!n}" && (( ${!n} >= 1 && ${!n} <= 64 )) || die "$n muss 1-64 sein."
done
if [[ "$USE_PLAYERBOTS" == "1" ]]; then
    # PlayerBots expects enUS server-side DBC data.
    DBC_LOCALE="0"
    [[ -n "$MAP_UPDATE_THREADS" ]] || MAP_UPDATE_THREADS="4"
fi
if [[ -z "$MAP_UPDATE_THREADS" ]]; then MAP_UPDATE_THREADS="1"; fi
is_uint "$MAP_UPDATE_THREADS" && (( MAP_UPDATE_THREADS >= 1 && MAP_UPDATE_THREADS <= 64 )) || die "MAP_UPDATE_THREADS muss 1-64 sein."
for n in PLAYERBOTS_DB_WORKER_THREADS PLAYERBOTS_DB_SYNCH_THREADS; do
    is_uint "${!n}" && (( ${!n} >= 1 && ${!n} <= 64 )) || die "$n muss 1-64 sein."
done
is_uint "$WRONG_PASS_MAX_COUNT" || die "WRONG_PASS_MAX_COUNT muss eine Ganzzahl >= 0 sein."
is_uint "$WRONG_PASS_BAN_TIME" || die "WRONG_PASS_BAN_TIME muss eine Ganzzahl >= 0 sein."
is_uint "$WRONG_PASS_BAN_TYPE" && (( WRONG_PASS_BAN_TYPE <= 1 )) || die "WRONG_PASS_BAN_TYPE muss 0 oder 1 sein."

[[ -f "$PROFILE_FILE" ]] || die "Installationsprofil fehlt (${PROFILE_FILE}). Bitte den Server ueber das Standalone-Egg installieren."
# shellcheck disable=SC1090
source "$PROFILE_FILE"

current_modules_sha="$(sha256_text "$ACORE_MODULES")"
[[ "${PROFILE_USE_PLAYERBOTS:-}" == "$USE_PLAYERBOTS" ]] || die "USE_PLAYERBOTS wurde nach der Installation geaendert. In der Standalone-Variante ist dies eine Installationsoption. Stelle den alten Wert wieder her oder installiere/migriere mit passendem Profil."
[[ "${PROFILE_PLAYERBOTS_CORE_BRANCH:-}" == "$PLAYERBOTS_CORE_BRANCH" ]] || die "PLAYERBOTS_CORE_BRANCH wurde nach der Installation geaendert. Diese Standalone-Option erfordert einen neuen Build."
[[ "${PROFILE_PLAYERBOTS_MODULE_BRANCH:-}" == "$PLAYERBOTS_MODULE_BRANCH" ]] || die "PLAYERBOTS_MODULE_BRANCH wurde nach der Installation geaendert. Diese Standalone-Option erfordert einen neuen Build."
[[ "${PROFILE_MODULES_SHA256:-}" == "$current_modules_sha" ]] || die "ACORE_MODULES wurde nach der Installation geaendert. Module werden in der Standalone-Variante waehrend der Installation kompiliert; fuer Aenderungen ist ein neuer Build erforderlich."
if [[ "$USE_PLAYERBOTS" == "0" ]]; then
    [[ "${PROFILE_ACORE_REPO:-}" == "$ACORE_REPO" ]] || die "ACORE_REPO wurde nach der Installation geaendert. Diese Standalone-Option erfordert einen neuen Build."
    [[ "${PROFILE_ACORE_BRANCH:-}" == "$ACORE_BRANCH" ]] || die "ACORE_BRANCH wurde nach der Installation geaendert. Diese Standalone-Option erfordert einen neuen Build."
fi

WORLD_BIN="$SRC/env/dist/bin/worldserver"
AUTH_BIN="$SRC/env/dist/bin/authserver"
DBIMPORT_BIN="$SRC/env/dist/bin/dbimport"
MYSQLD_BIN="$MYSQL_HOME/bin/mysqld"
MYSQL_BIN="$MYSQL_HOME/bin/mysql"
MYSQLADMIN_BIN="$MYSQL_HOME/bin/mysqladmin"

for f in "$WORLD_BIN" "$AUTH_BIN" "$DBIMPORT_BIN" "$MYSQLD_BIN" "$MYSQL_BIN" "$MYSQLADMIN_BIN"; do
    [[ -x "$f" ]] || die "Erforderliche Binary fehlt oder ist nicht ausfuehrbar: $f"
done
[[ -d "$RUNTIME_LIB" ]] || die "Gebundelte Runtime-Libraries fehlen: $RUNTIME_LIB"

export LD_LIBRARY_PATH="$RUNTIME_LIB:$MYSQL_HOME/lib:$MYSQL_HOME/lib/private:${LD_LIBRARY_PATH:-}"
if [[ -d "$AIO_DIR/ossl-modules" ]]; then
    export OPENSSL_MODULES="$AIO_DIR/ossl-modules"
fi
if [[ -f "$AIO_DIR/openssl.cnf" ]]; then
    export OPENSSL_CONF="$AIO_DIR/openssl.cnf"
fi

mkdir -p "$MYSQL_DIR" "$MYSQL_SECURE_DIR" "$LOG_DIR" "$SECRET_DIR" "$SRC/env/dist/logs" "$SRC/env/dist/temp"
chmod 700 "$MYSQL_SECURE_DIR" 2>/dev/null || true
chmod 700 "$SECRET_DIR" 2>/dev/null || true

if [[ -z "$ACORE_DB_PASSWORD" || "$ACORE_DB_PASSWORD" == "auto" ]]; then
    DB_SECRET_FILE="$SECRET_DIR/acore-db-password"
    if [[ -s "$DB_SECRET_FILE" ]]; then
        ACORE_DB_PASSWORD="$(cat "$DB_SECRET_FILE")"
    else
        ACORE_DB_PASSWORD="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
        printf '%s' "$ACORE_DB_PASSWORD" > "$DB_SECRET_FILE"
        chmod 600 "$DB_SECRET_FILE" 2>/dev/null || true
    fi
else
    [[ "$ACORE_DB_PASSWORD" =~ ^[A-Za-z0-9._@%+=,:/-]{8,128}$ ]] || die "ACORE_DB_PASSWORD: 8-128 Zeichen; erlaubt A-Z a-z 0-9 . _ @ % + = , : / -"
fi

if [[ "$REALM_ADDRESS" == "auto" || -z "$REALM_ADDRESS" ]]; then
    REALM_ADDRESS="${SERVER_IP:-127.0.0.1}"
    [[ "$REALM_ADDRESS" == "0.0.0.0" ]] && REALM_ADDRESS="127.0.0.1"
fi

sql_escape() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\'/\'\'}"
    printf '%s' "$value"
}

CLIENT_DATA_DIR="$SRC/env/dist/bin"
for data_dir in dbc maps vmaps mmaps; do
    [[ -d "$CLIENT_DATA_DIR/$data_dir" ]] || die "Client-Daten fehlen: ${CLIENT_DATA_DIR}/${data_dir}. In der Standalone-Variante werden sie waehrend der Installation geladen."
    find "$CLIENT_DATA_DIR/$data_dir" -type f -print -quit | grep -q . || die "Client-Daten-Verzeichnis ist leer: ${CLIENT_DATA_DIR}/${data_dir}"
done

ETC="$SRC/env/dist/etc"
[[ -f "$ETC/authserver.conf" ]] || { [[ -f "$ETC/authserver.conf.dist" ]] && cp "$ETC/authserver.conf.dist" "$ETC/authserver.conf"; }
[[ -f "$ETC/worldserver.conf" ]] || { [[ -f "$ETC/worldserver.conf.dist" ]] && cp "$ETC/worldserver.conf.dist" "$ETC/worldserver.conf"; }
if [[ -f "$ETC/dbimport.conf.dist" && ! -f "$ETC/dbimport.conf" ]]; then
    cp "$ETC/dbimport.conf.dist" "$ETC/dbimport.conf"
fi

if [[ "$MODULE_CONFIG_AUTO_COPY" == "1" && -d "$ETC/modules" ]]; then
    while IFS= read -r -d '' dist_conf; do
        real_conf="${dist_conf%.dist}"
        if [[ ! -f "$real_conf" ]]; then
            cp "$dist_conf" "$real_conf"
            say "Modul-Konfiguration angelegt: ${real_conf#$ETC/}"
        fi
    done < <(find "$ETC/modules" -type f -name '*.conf.dist' -print0)
fi

MYSQL_EXTRA=(
    --basedir="$MYSQL_HOME"
    --plugin-dir="$MYSQL_HOME/lib/plugin"
    --secure-file-priv="$MYSQL_SECURE_DIR"
)
if [[ -d "$MYSQL_HOME/share" ]]; then
    MYSQL_EXTRA+=(--lc-messages-dir="$MYSQL_HOME/share")
    [[ -d "$MYSQL_HOME/share/charsets" ]] && MYSQL_EXTRA+=(--character-sets-dir="$MYSQL_HOME/share/charsets")
fi

if [[ ! -d "$MYSQL_DIR/mysql" ]]; then
    say "Initialisiere lokale MySQL-8.4-Datenbank ..."
    rm -rf "${MYSQL_DIR:?}"/*
    "$MYSQLD_BIN" --no-defaults "${MYSQL_EXTRA[@]}" --initialize-insecure --datadir="$MYSQL_DIR" --log-error="$LOG_DIR/mysql-init.log"
fi

MYSQL_BIND="127.0.0.1"
[[ "$MYSQL_REMOTE_ACCESS" == "1" ]] && MYSQL_BIND="0.0.0.0"

say "Starte MySQL auf ${MYSQL_BIND}:${MYSQL_PORT} ..."
"$MYSQLD_BIN" --no-defaults \
    "${MYSQL_EXTRA[@]}" \
    --datadir="$MYSQL_DIR" \
    --socket="$MYSQL_SOCKET" \
    --pid-file="$MYSQL_PIDFILE" \
    --port="$MYSQL_PORT" \
    --bind-address="$MYSQL_BIND" \
    --mysqlx=OFF \
    --skip-log-bin \
    --skip-name-resolve \
    --log-error="$LOG_DIR/mysql.log" &
MYSQL_PID=$!

for _ in $(seq 1 120); do
    if "$MYSQLADMIN_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot ping >/dev/null 2>&1; then
        break
    fi
    if ! kill -0 "$MYSQL_PID" >/dev/null 2>&1; then
        tail -n 100 "$LOG_DIR/mysql.log" || true
        die "MySQL ist beim Start beendet worden."
    fi
    sleep 1
done
"$MYSQLADMIN_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot ping >/dev/null 2>&1 || die "MySQL wurde nicht rechtzeitig bereit."

say "Richte AzerothCore-Datenbanken und DB-Benutzer ein ..."
"$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`acore_world\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS \`acore_characters\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS \`acore_auth\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'acore'@'localhost' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
ALTER USER 'acore'@'localhost' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
CREATE USER IF NOT EXISTS 'acore'@'127.0.0.1' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
ALTER USER 'acore'@'127.0.0.1' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`acore_world\`.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON \`acore_characters\`.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON \`acore_auth\`.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON \`acore_world\`.* TO 'acore'@'127.0.0.1';
GRANT ALL PRIVILEGES ON \`acore_characters\`.* TO 'acore'@'127.0.0.1';
GRANT ALL PRIVILEGES ON \`acore_auth\`.* TO 'acore'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

if [[ "$USE_PLAYERBOTS" == "1" ]]; then
    say "Richte PlayerBots-Datenbank acore_playerbots ein ..."
    "$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`acore_playerbots\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON \`acore_playerbots\`.* TO 'acore'@'localhost';
GRANT ALL PRIVILEGES ON \`acore_playerbots\`.* TO 'acore'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
fi

if [[ "$MYSQL_REMOTE_ACCESS" == "1" ]]; then
    "$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot <<SQL
CREATE USER IF NOT EXISTS 'acore'@'%' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
ALTER USER 'acore'@'%' IDENTIFIED BY '${ACORE_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`acore_world\`.* TO 'acore'@'%';
GRANT ALL PRIVILEGES ON \`acore_characters\`.* TO 'acore'@'%';
GRANT ALL PRIVILEGES ON \`acore_auth\`.* TO 'acore'@'%';
SQL
    if [[ "$USE_PLAYERBOTS" == "1" ]]; then
        "$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot -e "GRANT ALL PRIVILEGES ON \`acore_playerbots\`.* TO 'acore'@'%';"
    fi
    "$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot -e "FLUSH PRIVILEGES;"
fi

export AC_DISABLE_INTERACTIVE=1
export AC_DATA_DIR="$CLIENT_DATA_DIR"
export AC_LOGS_DIR="$SRC/env/dist/logs"
export AC_TEMP_DIR="$SRC/env/dist/temp"
export AC_LOGIN_DATABASE_INFO="127.0.0.1;${MYSQL_PORT};acore;${ACORE_DB_PASSWORD};acore_auth"
export AC_WORLD_DATABASE_INFO="127.0.0.1;${MYSQL_PORT};acore;${ACORE_DB_PASSWORD};acore_world"
export AC_CHARACTER_DATABASE_INFO="127.0.0.1;${MYSQL_PORT};acore;${ACORE_DB_PASSWORD};acore_characters"
export AC_REALM_ID=1
export AC_REALM_SERVER_PORT="$AUTH_PORT"
export AC_WORLD_SERVER_PORT="$WORLD_PORT"
export AC_PLAYER_LIMIT="$PLAYER_LIMIT"
export AC_GAME_TYPE="$REALM_TYPE"
export AC_REALM_ZONE="$REALM_ZONE"
export AC_DBC_LOCALE="$DBC_LOCALE"
export AC_EXPANSION="$EXPANSION"
export AC_MAX_PLAYER_LEVEL="$MAX_PLAYER_LEVEL"
export AC_START_PLAYER_LEVEL="$START_PLAYER_LEVEL"
export AC_START_PLAYER_MONEY="$START_PLAYER_MONEY"
export AC_CHARACTERS_PER_REALM="$CHARACTERS_PER_REALM"
export AC_CHARACTERS_PER_ACCOUNT="$CHARACTERS_PER_ACCOUNT"
export AC_SKIP_CINEMATICS="$SKIP_CINEMATICS"
export AC_ALLOW_TWO_SIDE_ACCOUNTS="$ALLOW_TWO_SIDE_ACCOUNTS"
export AC_RATE_XP_KILL="$RATE_XP_KILL"
export AC_RATE_XP_QUEST="$RATE_XP_QUEST"
export AC_RATE_XP_EXPLORE="$RATE_XP_EXPLORE"
export AC_RATE_DROP_MONEY="$RATE_DROP_MONEY"
export AC_RATE_REPUTATION_GAIN="$RATE_REPUTATION_GAIN"
export AC_RATE_HONOR="$RATE_HONOR"
export AC_NETWORK_THREADS="$NETWORK_THREADS"
export AC_THREAD_POOL="$THREAD_POOL"
export AC_MAP_UPDATE_THREADS="$MAP_UPDATE_THREADS"
export AC_PROCESS_PRIORITY=0
export AC_STRICT_VERSION_CHECK="$STRICT_VERSION_CHECK"
export AC_WRONG_PASS_MAX_COUNT="$WRONG_PASS_MAX_COUNT"
export AC_WRONG_PASS_BAN_TIME="$WRONG_PASS_BAN_TIME"
export AC_WRONG_PASS_BAN_TYPE="$WRONG_PASS_BAN_TYPE"
export AC_ALLOW_LOGGING_IP_ADDRESSES_IN_DATABASE="$ALLOW_IP_LOGGING"

if [[ "$USE_PLAYERBOTS" == "1" ]]; then
    export AC_PLAYERBOTS_DATABASE_INFO="127.0.0.1;${MYSQL_PORT};acore;${ACORE_DB_PASSWORD};acore_playerbots"
    export AC_PLAYERBOTS_DATABASE_WORKER_THREADS="$PLAYERBOTS_DB_WORKER_THREADS"
    export AC_PLAYERBOTS_DATABASE_SYNCH_THREADS="$PLAYERBOTS_DB_SYNCH_THREADS"
    export AC_PLAYERBOTS_UPDATES_ENABLE_DATABASES="$PLAYERBOTS_DB_UPDATES"
fi

say "Fuehre Datenbank-Import/Migrationen aus ..."
cd "$SRC/env/dist/bin"
"$DBIMPORT_BIN"

if [[ "$USE_PLAYERBOTS" == "1" ]]; then
    [[ -d "$SRC/modules/mod-playerbots" ]] || die "PlayerBots-Modul fehlt trotz USE_PLAYERBOTS=1."
    [[ -f "$ETC/modules/playerbots.conf" || -f "$ETC/modules/mod_playerbots.conf" ]] || say "WARNUNG: Keine playerbots.conf gefunden. Pruefe ${ETC}/modules/."
fi

sql_realm_name="$(sql_escape "$REALM_NAME")"
sql_realm_address="$(sql_escape "$REALM_ADDRESS")"
sql_local_address="$(sql_escape "$REALM_LOCAL_ADDRESS")"
sql_local_mask="$(sql_escape "$REALM_LOCAL_SUBNET_MASK")"
REALM_ICON="$REALM_TYPE"
[[ "$REALM_TYPE" == "16" ]] && REALM_ICON=1

say "Erstelle/aktualisiere Realm '${REALM_NAME}' auf ${REALM_ADDRESS}:${WORLD_PORT} ..."
"$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot acore_auth <<SQL
INSERT INTO realmlist
    (id, name, address, localAddress, localSubnetMask, port, icon, flag, timezone, allowedSecurityLevel, population, gamebuild)
VALUES
    (1, '${sql_realm_name}', '${sql_realm_address}', '${sql_local_address}', '${sql_local_mask}', ${WORLD_PORT}, ${REALM_ICON}, 0, ${REALM_ZONE}, ${REALM_ALLOWED_SECURITY_LEVEL}, 0, 12340)
ON DUPLICATE KEY UPDATE
    name='${sql_realm_name}', address='${sql_realm_address}', localAddress='${sql_local_address}',
    localSubnetMask='${sql_local_mask}', port=${WORLD_PORT}, icon=${REALM_ICON}, flag=0,
    timezone=${REALM_ZONE}, allowedSecurityLevel=${REALM_ALLOWED_SECURITY_LEVEL}, gamebuild=12340;
SQL

realm_row="$("$MYSQL_BIN" --protocol=socket --socket="$MYSQL_SOCKET" -uroot -Nse "SELECT CONCAT(id,'|',name,'|',address,'|',localAddress,'|',port,'|',icon,'|',timezone,'|',allowedSecurityLevel,'|',flag,'|',gamebuild) FROM acore_auth.realmlist WHERE id=1 LIMIT 1;")"
[[ -n "$realm_row" ]] || die "Realm-ID 1 konnte nicht in acore_auth.realmlist angelegt werden."
say "Realm-Datensatz: ${realm_row}"

say "Starte Authserver auf Port ${AUTH_PORT} ..."
"$AUTH_BIN" &
AUTH_PID=$!
sleep 2
if ! kill -0 "$AUTH_PID" >/dev/null 2>&1; then
    die "Authserver ist direkt nach dem Start beendet worden."
fi

say "Starte Worldserver auf Port ${WORLD_PORT}. Pelican-Konsole ist jetzt die Worldserver-Konsole."
say "Account anlegen: account create <user> <pass>"
say "Admin setzen:    account set gmlevel <user> 3 -1"
exec "$WORLD_BIN"
