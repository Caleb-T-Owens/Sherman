#!/bin/sh
set -eu

MATRIX_SERVER_NAME="${MATRIX_SERVER_NAME:-matrix.localhost}"
export MATRIX_SERVER_NAME

python /synapse-config/render_homeserver.py

if [ ! -f "/data/${MATRIX_SERVER_NAME}.signing.key" ]; then
  python -m synapse.app.homeserver --config-path /data/homeserver.yaml --generate-keys
fi

exec /start.py
