set -eu -o pipefail

pushd $SHERMAN_DIR/deploy/electron/services/website3

cp -R $SHERMAN_DIR/projects/website3 website3

docker compose up -d --build

rm -rf website3

popd
