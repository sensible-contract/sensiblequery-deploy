#!/usr/bin/env sh

cd sensibled
docker-compose kill -s SIGINT sensibled

cd ../bitcoind/
./bitcoin-cli.sh stop

cd ..
# docker-compose stop bitcoind
docker-compose  -f clickhouse/docker-compose.yaml stop clickhouse
docker-compose  -f cache/docker-compose.yaml stop cache
docker-compose  -f redis/docker-compose.yaml stop redis
docker-compose  -f pika/docker-compose.yaml stop pika
docker-compose  -f sensiblequery/docker-compose.yaml stop sensiblequery
