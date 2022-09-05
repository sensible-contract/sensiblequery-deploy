sensiblequery deployment environment

Recommended OS: centos7+ / ubuntu 18.04+

## Install Docker

Install Docker and set the data directory to `/data/docker/`.

## Install docker-compose

You can execute the `docker-compose` to run the instance.


## One-click start script

First execute start.sh to start all parts except the sensibled component.

     cd /data/
     sh ./start.sh

Next, you need to wait for bitcoind to complete the block synchronization. You can use the command to view the block information:

     cd /data/bitcoind
     sh ./bitcoin-cli.sh getinfo

When synchronization is complete, execute sync.sh to start sensibled.

     cd /data/
     sh ./sync.sh

Once executed, sensiblequery will be served on local port 6666. Note: The initial sync takes 10 hours.

     curl http://localhost:6666

The detailed command is as follows:


## start bitcoind (Bitcoin SV node)

Start the bitcoind container from the `/data/bitcoind` directory.

    cd /data/bitcoind
    docker-compose up -d

You can execute `bitcoin-cli` like so:

    ./bitcoin-cli.sh getinfo

### Configure RPC settings

* bitcoind/data/bitcoin.conf
```
    rpcuser=ss
    rpcpassword=XXXXXXXXXXXXXXXX
```
## Start clickhouse

Start the clickhouse container from the `/data/clickhouse` directory.

    cd /data/clickhouse
	# chown -R 101:101 .
    docker-compose up -d

## Start redis

Start the redis container from the `/data/redis` directory.

    cd /data/redis
    docker-compose up -d

## Start redis-cache

Start the cache container from the `/data/cache` directory.

    cd /data/cache
    docker-compose up -d

## Start pika

Start the pika container from the `/data/pika` directory.

    cd /data/pika
    docker-compose up -d


## Start sensibled

First, pull in the image

    cd /data/sensibled
    docker-compose pull

Or build the image from source yourself here: (https://github.com/sensible-contract/sensibled):

    git clone https://github.com/sensible-contract/sensibled
    cd sensibled
    docker-compose build

There are three stages of synchronisation that will occur: Initial synchronisation, batch synchronisation followed by continuous syncrhonisation.

Execute the following commands from the `/data/sensibled` directory to complete the three phases of synchronisation.

    cd /data/sensibled

    # Initialisation, > 10 minutes
    docker-compose -f docker-compose-init.yaml up
    ...

    # Batch synchronisation, > 10 hours
    docker-compose -f docker-compose-batch.yaml up
    ...

    # Continuous synchronisation in the background
    docker-compose up -d

### Key configuration

The intranet IP address (172.31.88.41) should be replaced with the actual node address.

You also can change `extra_hosts` in docker-compose.yaml.

* chain.yaml
```
    zmq: "tcp://172.31.88.41:16331"
    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"
```
* db.yaml
```
    address: "172.31.88.41:9000"
    database: "bsv"
```
* redis.yaml
```
    addrs: ["172.31.88.41:6379"]
```
* pika.yaml
```
    addrs: ["172.31.88.41:9221"]
```

## Run sensiblequery

Pull in the docker image：

    cd sensiblequery
    docker-compose pull

Or build it yourself from source (https://github.com/sensible-contract/sensiblequery):

    git clone https://github.com/sensible-contract/sensiblequery
    cd sensiblequery
    docker-compose build


Start the docker image from the `/data/sensiblequery`directory.

    cd /data/sensiblequery
    docker-compose up -d

### Key configuration

Intranet IP address (172.31.88.41  should be replaced with the actual node address.

You also can change `extra_hosts` in docker-compose.yaml.

* chain.yaml
```
    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"
```
* db.yaml
```
    address: "172.31.88.41:9000"
    database: "bsv"
```
* redis.yaml
```
    addrs: ["172.31.88.41:6379"]
```
* pika.yaml
```
    addrs: ["172.31.88.41:9221"]
```
* cache.yaml
```
    addr: "172.31.88.41:6380"
```

# Install nginx

Settings are configurable in `/etc/nginx/conf.d/`.

## Deployment resource requirements

| deploy               | DISK(minimum) | DISK(recommended) | MEM(minimum) | MEM(recommended) |
|----------------------|---------------|-------------------|--------------|------------------|
| sensiblequery        | 10 GB         | 20 GB             | 1 GB         | 4 GB             |
| bsv-node + sensibled | 512 GB        | 1000 GB           | 16 GB        | 32 GB            |
| clickhouse           | 1000 GB       | 1500 GB           | 16 GB        | 32 GB            |
| redis x 1            | 20 GB         | 50 GB             | 16 GB        | 32 GB            |
| pika x 1             | 20 GB         | 50 GB             | 4 GB         | 8 GB             |
| cache x 1            | 10 GB         | 20 GB             | 1 GB         | 2 GB             |

Where sensible is used to provide API services to the outside world, multiple instances can be deployed. the mindd is a single-instance run. Redis can deploy single nodes or clusters.


## Caution

The block synchronisation process is divided into two steps: First, the blocks will be scanned (either individually or in batches) and will update the db and redis all at once.

If the program crashes while writing to the db or redis, they will enter an error state. In an error state, the db can no longer be used. There is currently no way to fix this, it can only be restored from a backup.

At present, redis has turned off the automatic backup of rdb/aof, so manual operations are required to back up and restore its data.

It is recommended that you run multiple copies of the service. During the backup/restore process, it is preferable that the service be taken offline.
