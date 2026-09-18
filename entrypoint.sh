#!/usr/bin/env bash
set -Eeuo pipefail
cd /home/container
MODIFIED_STARTUP="$(eval echo "$(echo "${STARTUP:-bash ./start.sh}" | sed -e 's/{{/${/g' -e 's/}}/}/g')")"
echo ":/home/container$ ${MODIFIED_STARTUP}"
exec /bin/bash -lc "${MODIFIED_STARTUP}"
