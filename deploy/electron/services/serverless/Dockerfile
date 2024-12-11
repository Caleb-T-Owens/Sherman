FROM debian:bookworm

COPY . /app

WORKDIR /app

CMD ./pocketbase serve --http 0.0.0.0:3000 --dir pb_data --migrationsDir pb_migrations
