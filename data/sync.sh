#!/usr/bin/env sh

docker-compose -f sensibled/docker-compose-init.yaml up sensibled
docker-compose -f sensibled/docker-compose-batch.yaml up sensibled
docker-compose -f sensibled/docker-compose.yaml up sensibled -d
