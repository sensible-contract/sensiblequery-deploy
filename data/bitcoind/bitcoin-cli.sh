#!/usr/bin/env sh

docker-compose exec -T bitcoind bitcoin-cli -datadir=/data $@
