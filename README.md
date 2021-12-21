sensiblequery环境部署

## 安装docker

安装docker。将docker的数据文件设置到`/data/docker/`目录(可选)。

## 安装docker-compose

程序启动全部使用`docker-compose`管理。

## 运行bitcoind (Bitcoin SV节点)

在`/data/bitcoind`目录启动docker容器即可。

    cd /data/bitcoind
    docker-compose up -d

可用如下程序执行`bitcoin-cli`命令：

    ./bitcoin-cli.sh getinfo

### 关键配置修改

* bitcoind/data/bitcoin.conf

    rpcuser=ss
    rpcpassword=XXXXXXXXXXXXXXXX

## 运行clickhouse

在`/data/clickhouse`目录启动docker容器即可。注意所有目录权限需要设置成用户101(clickhouse)。

    cd /data/clickhouse
	# chown -R 101:101 .
    docker-compose up -d

## 运行redis

在`/data/redis`目录启动docker容器即可，注意data目录权限需要设置成用户990(redis)。

    cd /data/redis
	# chown -R 990:990 data
    docker-compose up -d

## 运行sensibled

首先需要拉取镜像：

    docker-compose pull

或自行使用项目文件打包镜像(https://github.com/sensible-contract/sensibled):

    git clone https://github.com/sensible-contract/sensibled
    cd sensibled
    docker-compose build


同步分了3个阶段执行， 先初始化；再分批同步；最后连续同步。


在`/data/sensibled`目录启动docker容器，完成3阶段同步。

    cd /data/sensibled

    # 初始化
    docker-compose -f docker-compose-init.yaml up
    ...

    # 分批同步
    docker-compose -f docker-compose-batch.yaml up
    ...

    # 放入后台，进行连续同步
    docker-compose up -d

### 关键配置修改

内网IP(172.31.88.41)需要替换成正确地址，可在docker-compose中统一配置extra_hosts。

* chain.yaml

    zmq: "tcp://172.31.88.41:16331"
    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"

* db.yaml

    address: "172.31.88.41:9000"
    database: "bsv"

* redis.yaml

    addrs: ["172.31.88.41:6379"]

## 运行sensiblequery

首先需要拉取镜像：

    docker-compose pull

或者自行使用项目文件打包镜像(https://github.com/sensible-contract/sensiblequery):

    git clone https://github.com/sensible-contract/sensiblequery
    cd sensiblequery
    docker-compose build


在`/data/sensiblequery`目录启动docker容器即可。

    cd /data/sensiblequery
    docker-compose up -d

### 关键配置修改

内网IP(172.31.88.41)需要替换成正确地址，可在docker-compose中统一配置extra_hosts。

* chain.yaml

    rpc: "http://172.31.88.41:16332"
    rpc_auth: "ss:XXXXXXXXXXXXXXXX"

* db.yaml

    address: "172.31.88.41:9000"
    database: "bsv"

* redis.yaml

    addrs: ["172.31.88.41:6379"]

* cache.yaml

    addr: "172.31.88.41:6380"


## 安装filebeat容器日志收集

按`/etc/filebeat/filebeat.yaml`配置文件配置容器日志导出汇集。

容器日志在容器重启后就会丢失，需要采集持久化。

# 安装nginx

按`/etc/nginx/conf.d/`配置文件配置服务。


# 安装frpc

按`/etc/frp/frpc.ini`配置启动frpc转发代理，将bitcoin node远程暴露到对外出口机器。

如果直接从本机暴露则不用安装frpc。

### 关键配置修改

* frpc.ini

    token = XXXXXXXXXXXXXXXX


## 注意

同步区块过程分2步：先扫区块(一次扫一批区块或一个区块)；再一次性更新db和redis。

如果写db和redis过程中程序宕机，db/redis就处于错误状态。错误状态的db不能继续使用，目前也没有修复方法。只能从备份重新恢复。

目前redis关闭了自动备份rdb/aof，需要手动操作备份、恢复数据。

建议多副本提供服务。备份/恢复过程中，该副本服务最好处于下线状态。
