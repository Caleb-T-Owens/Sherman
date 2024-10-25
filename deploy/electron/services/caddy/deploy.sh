set -eu -o pipefail

pushd $SHERMAN_DIR/deploy/electron/services/caddy

docker compose up -d --build

popd
