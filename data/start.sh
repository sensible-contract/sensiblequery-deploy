#!/usr/bin/env sh

docker-compose -f bitcoind/docker-compose.yaml up bitcoind -d
docker-compose -f clickhouse/docker-compose.yaml up clickhouse -d
docker-compose -f cache/docker-compose.yaml up cache -d
docker-compose -f redis/docker-compose.yaml up redis -d
docker-compose -f pika/docker-compose.yaml up pika -d
docker-compose -f sensiblequery/docker-compose.yaml up sensiblequery -d

# docker-compose -f sensibled/docker-compose-init.yaml up sensibled
# docker-compose -f sensibled/docker-compose-batch.yaml up sensibled
# docker-compose -f sensibled/docker-compose.yaml up sensibled -d
