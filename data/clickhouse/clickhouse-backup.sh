docker run -u 101 --rm -it --network host -v "/data/clickhouse/data:/var/lib/clickhouse" alexakulov/clickhouse-backup $@
       
