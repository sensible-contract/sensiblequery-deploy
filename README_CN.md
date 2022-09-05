sensiblequery环境部署

推荐系统centos7+或ubuntu 18.04+。

## 安装docker

安装docker。

## 安装最新版 docker-compose

程序启动全部使用`docker-compose`管理。

## 一键启动脚本 data/

先执行start.sh启动除sensibled组件之外所有部分。

    cd /data/
    sh ./start.sh


接下来需要等待bitcoind同步完成区块，可使用命令查看区块信息：

    cd /data/bitcoind
    sh ./bitcoin-cli.sh getinfo

当同步完成，可执行sync.sh开始启动sensibled。

    cd /data/
    sh ./sync.sh

执行完毕后，sensiblequery将在本地端口6666提供服务。注意：初次同步需要10小时。

	curl http://localhost:6666

详细命令见下：

## 运行bitcoind (Bitcoin SV节点)

在`/data/bitcoind`目录启动docker容器即可。

    cd /data/bitcoind
    docker-compose up -d

可用如下程序执行`bitcoin-cli`命令：

    ./bitcoin-cli.sh getinfo

### 关键配置修改

* `bitcoind/data/bitcoin.conf` RPC配置。

```
    rpcuser=ss
    rpcpassword=XXXXXXXXXXXXXXXX
```
## 运行clickhouse

在`/data/clickhouse`目录启动docker容器即可。注意所有目录权限需要设置成用户101(clickhouse)。

    cd /data/clickhouse
	# chown -R 101:101 .
    docker-compose up -d

## 运行redis

在`/data/redis`目录启动docker容器即可。

    cd /data/redis
    docker-compose up -d

## 运行redis-cache

在`/data/cache`目录启动docker容器即可。

    cd /data/cache
    docker-compose up -d

## 运行pika

在`/data/pika`目录启动docker容器即可。

    cd /data/pika
    docker-compose up -d

## 运行sensibled

首先需要拉取镜像：

    cd /data/sensibled
    docker-compose pull

或自行使用项目文件打包镜像(https://github.com/sensible-contract/sensibled):

    git clone https://github.com/sensible-contract/sensibled
    cd sensibled
    docker-compose build


同步分了3个阶段执行， 先初始化；再分批同步；最后连续同步。


在`/data/sensibled`目录启动docker容器，完成3阶段同步。

    cd /data/sensibled

    # 初始化，需要10分钟执行
    docker-compose -f docker-compose-init.yaml up
    ...

    # 分批同步，需要10小时执行
    docker-compose -f docker-compose-batch.yaml up
    ...

    # 最后放入后台，进行连续同步
    docker-compose up -d

### 关键配置修改

如果在同一机器部署各个，服务间访问走docker内部域名。否则docker容器之间需要使用内网IP(172.31.88.41)访问，也可在docker-compose中统一配置extra_hosts。

另`rpc_auth`需要和bitcoind配置一致。

* chain.yaml
```
    zmq: "tcp://172.31.88.41:16331"
    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"
```
* db.yaml
```
    address: "172.31.88.41:9000"
```
* redis.yaml
```
    addrs: ["172.31.88.41:6379"]
```
* pika.yaml
```
    addrs: ["172.31.88.41:9221"]
```

## 运行sensiblequery

首先需要拉取镜像：

    cd sensiblequery
    docker-compose pull

或者自行使用项目文件打包镜像(https://github.com/sensible-contract/sensiblequery):

    git clone https://github.com/sensible-contract/sensiblequery
    cd sensiblequery
    docker-compose build


在`/data/sensiblequery`目录启动docker容器即可。

    cd /data/sensiblequery
    docker-compose up -d

### 关键配置修改

如果在同一机器部署各个，服务间访问走docker内部域名。否则docker容器之间需要使用内网IP(172.31.88.41)访问，也可在docker-compose中统一配置extra_hosts。

另`rpc_auth`需要和bitcoind配置一致。

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

# 安装nginx

后端服务端口为sensiblequery容器的6666端口。

可按`/etc/nginx/conf.d/`配置文件配置服务。


## 部署资源需求

| 部署                 | DISK(最低) | DISK(推荐) | MEM(最低) | MEM(推荐) |
|----------------------|------------|------------|-----------|-----------|
| sensiblequery        | 10 GB      | 20 GB      | 1 GB      | 4 GB      |
| bsv-node + sensibled | 512 GB     | 1000 GB    | 16 GB     | 32 GB     |
| clickhouse           | 1000 GB    | 1500 GB    | 16 GB     | 32 GB     |
| redis x 1            | 20 GB      | 50 GB      | 16 GB     | 32 GB     |
| pika x 1             | 20 GB      | 50 GB      | 4 GB      | 8 GB      |
| cache x 1            | 10 GB      | 20 GB      | 1 GB      | 2 GB      |

其中sensiblequery用来对外提供API服务，可以部署多实例。sensibled是单实例运行。redis可以部署单节点或集群。

## 注意

同步区块过程分2步：先扫区块(一次扫一批区块或一个区块)；再一次性更新db和redis。

如果写db和redis过程中程序宕机，db/redis就处于错误状态。错误状态的db不能继续使用，目前也没有修复方法。只能从备份重新恢复。

建议多副本提供服务。备份/恢复过程中，该副本服务最好处于下线状态。
