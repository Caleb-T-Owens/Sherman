set -eu -o pipefail

pushd $SHERMAN_DIR/deploy/electron/services/microblog_api

cp -R $SHERMAN_DIR/projects/microblog_api microblog_api

docker compose up -d --build

rm -rf microblog_api

popd
