# Postgresql on Swarm

This has been adapted from [this post](http://info.crunchydata.com/blog/easy-postgresql-cluster-recipe-using-docker-1.12), with many thanks!

This example is going to set you up to run a PostgreSQL service on Docker Swarm.

First, let's run through the steps to create this service manually. Make sure you have a running Docker Swarm as described in previous sections. You'll need to run all of these commands on your Swarm master 'node1', or substitute your node name in the following commands where necessary.

Next, we'll create an overlay network to be shared by a set of database containers.

```
docker network create --driver overlay postgres
```

Next, we'll use labels to constrain where the databases run. We can set the Swarm leader as the master, and make sure that we deploy the replicas to non-master servers.

```
$ docker node update node1 --label-add type=master
```

## PostgreSQL Cluster

Once we have the networking and labels set up, we can deploy our services using a manual deployment method. Our cluster will be a PostgreSQL master service and a PostgreSQL replica service.

We can create the service with the following commands.

```
docker service create \
--mount type=volume,src=$MASTER_SERVICE_NAME-volume,dst=/pgdata,volume-driver=local \
--name $MASTER_SERVICE_NAME \
--network postgres \
--constraint 'node.labels.type == master' \
--env PGHOST=/tmp \
--env PG_USER=testuser \
--env PG_MODE=master \
--env PG_MASTER_USER=master \
--env PG_ROOT_PASSWORD=password \
--env PG_PASSWORD=password \
--env PG_DATABASE=userdb \
--env PG_MASTER_PORT=5432 \
--env PG_MASTER_PASSWORD=password \
crunchydata/crunchy-postgres:centos7-9.5-1.2.5
```

Now we can create the replica service.

```
docker service create \
--mount type=volume,src=$VOLUME_NAME,dst=/pgdata,volume-driver=local \
--name $SERVICE_NAME \
--network postgres \
--constraint 'node.labels.type != master' \
--env PGHOST=/tmp \
--env PG_USER=testuser \
--env PG_MODE=slave \
--env PG_MASTER_USER=master \
--env PG_ROOT_PASSWORD=password \
--env PG_PASSWORD=password \
--env PG_DATABASE=userdb \
--env PG_MASTER_PORT=5432 \
--env PG_MASTER_PASSWORD=password \
--env PG_MASTER_HOST=$MASTER_SERVICE_NAME \
crunchydata/crunchy-postgres:centos7-9.5-1.2.5
```

Note the following lines from the examples above when creating the Docker services:

```
--constraint 'node.labels.type == master'
```

This line supplies a constraint to the Swarm manager when choosing what Swarm node to run the container, in this case, we want the master database container to always run on a host with the master label type, in our case this is the worker1 host.

```
--network postgres
```

```
--mount type=volume,src=$VOLUME_NAME,dst=/pgdata,volume-driver=local
```

This line specifies a dynamically created Docker volume be created using the local driver and which will be mounted to the /pgdata directory within the PostgreSQL container. The /pgdata volume is where PostgreSQL will store it’s data files.

```
--env PG_MASTER_HOST=$MASTER_SERVICE_NAME
```

This line specifies the master PostgreSQL database host and in this case is the Docker service name used for the master database service. This name is resolved by means of the overlay network we created, crunchynet.

# Test your cluster

Docker 1.12 provides the service abstraction around the underlying deployed containers. You can view the deployed services as follows:

```
docker service ps master
```

```
docker service ps replica
```

Given the PostgreSQL replica service is named replica, you can scale up the number of replica containers by running this command:

```
docker service scale replica=2
```

```
docker service ls
```

You can verify you have two replicas within PostgreSQL by viewing the pg_stat_replication table. You'll need to get the name of the master container in order to run this command.

In our case, this meant running the following on the Swarm master node.

```
$ docker container ps |grep master
```

And then using that output to run a remote Postgresql command.

```
docker exec -it master.1.x769um05kllwbx742ix3yrna7 psql -U postgres -c 'table pg_stat_replication' postgres
```

You should see a row for each replica along with its replication status.

