pushd $SHERMAN_DIR/deploy/electron/services/wiki

docker compose up -d --build

popd
