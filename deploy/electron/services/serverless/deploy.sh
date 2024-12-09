pushd $SHERMAN_DIR/deploy/electron/services/serverless

docker compose up -d --build

popd
