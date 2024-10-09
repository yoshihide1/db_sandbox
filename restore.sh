#!/bin/bash

# .env ファイルから環境変数を読み込む
export $(cat .env | xargs)

set -e

# Docker Composeを使用してコンテナを再起動
echo "Shutting down existing containers..."
docker-compose down -v

echo "Starting up containers..."
docker-compose up -d

# PostgreSQLが起動するまで待機
echo "Waiting for PostgreSQL to be ready..."
until docker exec "$CONTAINER_NAME" pg_isready -U "$PGUSER"; do
  echo "PostgreSQL is not ready yet. Waiting..."
  sleep 2
done
echo "PostgreSQL is ready."

# データベースの復元（--no-ownerを追加して所有者を無視）
echo "Restoring database from $BACKUP_FILE..."
docker exec -e PGPASSWORD="$PGPASSWORD" "$CONTAINER_NAME" pg_restore -U "$PGUSER" -d "$PGDATABASE" -F t --no-owner "$BACKUP_FILE"
echo "Database restoration completed."