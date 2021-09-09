sensiblequery deployment environment

## Deploy a Bitcoin SV node

Download the node package from `https://download.bitcoinsv.io/bitcoinsv/`, in this case, v1.0.8, and unzip it to `/bitcoin/bitcoin-sv-1.0.8/`.

You can use the follow scripts to startup and shutdown the node software `bitcoind`. Data will be stored in `/bitcoin/bitcoin-sv-blocks/`.

    main-start.sh
    main-stop.sh

You can execute `bitcoin-cli` like so:

    main.sh getsettings

For `testnet` you can instead use:

    test-start.sh
    test-stop.sh

It is recommend to use a non-root account to run the node software.

### Configure RPC settings

* bitcoin.conf

    rpcuser=ss
    rpcpassword=XXXXXXXXXXXXXXXX


# Install frpc

Start the FRPC forwarding agent to remotely expose your Bitcoin node to the Hong Kong node according to the settings in `/etc/frp/frpc.ini`.

If the machine is already publicly exposed, there is no need to use FRPC.

### FRPC Key Configuration

* frpc.ini

    token = XXXXXXXXXXXXXXXX

## Install Docker

Install Docker and set the data directory to `/data/docker/`.

## Install docker-compose

You can execute the `docker-compose` to run the instance.

## Start clickhouse

Start the clickhouse container from the `/data/clickhouse` directory.

    cd /data/clickhouse
    docker-compose up -d

## Start redis

Start the redis container from the `/data/redis` directory.

    cd /data/redis
    docker-compose up -d

## Start sensibled

First, pull in the image

    docker-compose pull

Or build the image from source yourself here: (https://github.com/sensible-contract/sensibled/tree/sensibled):

    git clone https://github.com/sensible-contract/sensibled
    cd sensibled
    git checkout sensibled
    docker-compose build

There are three stages of synchronisation that will occur: Initial synchronisation, batch synchronisation followed by continuous syncrhonisation.

Execute the following commands from the `/data/sensibled` directory to complete the three phases of synchronisation.

    cd /data/sensibled

    # Initialisation
    docker-compose -f docker-compose-init.yaml up
    ...

    # Batch synchronisation
    docker-compose -f docker-compose-batch.yaml up
    ...

    # Continuous synchronisation in the background
    docker-compose up -d

### Key configuration

* The intranet IP address (172.31.88.41) should be replaced with the actual node address.
* chain.yaml

    zmq: "tcp://172.31.88.41:16331"
    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"

* db.yaml

    address: "172.31.88.41:9000"
    database: "bsv"

* redis.yaml

    addrs: ["172.31.88.41:6379"]

## Run sensiblequery

Pull in the docker image：

    docker-compose pull

Or build it yourself from source (https://github.com/sensible-contract/sensiblequery):

    git clone https://github.com/sensible-contract/sensiblequery
    cd sensiblequery
    docker-compose build


Start the docker image from the `/data/sensiblequery`directory.

    cd /data/sensiblequery
    docker-compose up -d

### Key configuration

* Intranet IP address (172.31.88.41  should be replaced with the actual node address.
* chain.yaml

    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"

* db.yaml

    address: "172.31.88.41:9000"
    database: "bsv"

* redis.yaml

    addrs: ["172.31.88.41:6379"]


## Filebeat logger settings

Settings are configurable in `/etc/filebeat/filebeat.yaml`

Container logs will be lost after restart and will need to be persisted if you want to keep them.

# Install nginx

Settings are configurable in `/etc/nginx/conf.d/`.


## Caution

The block synchronisation process is divided into two steps: First, the blocks will be scanned (either individually or in batches) and will update the db and redis all at once.

If the program crashes while writing to the db or redis, they will enter an error state. In an error state, the db can no longer be used. There is currently no way to fix this, it can only be restored from a backup.

At present, redis has turned off the automatic backup of rdb/aof, so manual operations are required to back up and restore its data.

It is recommended that you run multiple copies of the service. During the backup/restore process, it is preferable that the service be taken offline.
