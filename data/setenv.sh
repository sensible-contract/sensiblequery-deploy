#!/usr/bin/env sh

echo $1
echo COMPOSE_PROJECT_NAME=$1 > .env
echo COMPOSE_PROJECT_NAME=$1 > bitcoind/.env
echo COMPOSE_PROJECT_NAME=$1 > sensibled/.env
echo COMPOSE_PROJECT_NAME=$1 > sensiblequery/.env
echo COMPOSE_PROJECT_NAME=$1 > redis/.env
echo COMPOSE_PROJECT_NAME=$1 > pika/.env
echo COMPOSE_PROJECT_NAME=$1 > cache/.env
echo COMPOSE_PROJECT_NAME=$1 > clickhouse/.env

sudo chown -R bsv:bsv redis/data cache/data
sudo chown 101:101 clickhouse/data clickhouse/log clickhouse/data/.clickhouse-client-history
