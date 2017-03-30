#!/bin/bash
# This has been adpated from:
# http://info.crunchydata.com/blog/easy-postgresql-cluster-recipe-using-docker-1.12

echo "starting master container..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

MASTER_SERVICE_NAME=master

# Set the required labels
docker node update node1 --label-add type=master

# Create the network
docker network create --driver overlay postgres


# Create the Master service
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

echo "sleep for a bit before starting the replica..."

sleep 30

SERVICE_NAME=replica
VOLUME_NAME=$SERVICE_NAME-volume


# Create the Replica Service
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
