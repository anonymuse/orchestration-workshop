#!/bin/bash

set -x
set -m

/entrypoint.sh couchbase-server &

sleep 15

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=300 -d \
    indexMemoryQuota=300

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d \
    services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d \
    username=admin -d password=password

# Setup Memory Optimized Indexes
curl -i -u admin:password -X POST \
    http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'

# Delete the travel sample bucket
curl -v -u administrator:password -X DELETE \
    http://127.0.0.1:8091/pools/default/buckets/travel-sample

# Load smaller beer sample bucket
curl -v -u admin:password -X POST \
    http://127.0.0.1:8091/sampleBuckets/install -d '["beer-sample"]'

echo "Type: $TYPE"

if [ "$TYPE" = "WORKER" ]; then
  echo "Sleeping ..."
  sleep 15

  #IP=`hostname -s`
  IP=`hostname -I | cut -d ' ' -f1`
  echo "IP: " $IP

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    couchbase-cli rebalance --cluster=$COUCHBASE_MASTER:8091 \
        --user=admin --password=password --server-add=$IP \
        --server-add-username=admin --server-add-password=password
  else
    couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 \
        --user=admin --password=password --server-add=$IP \
        --server-add-username=admin --server-add-password=password
  fi;
fi;

fg 1

