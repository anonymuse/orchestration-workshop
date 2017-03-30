# Couchbase on Swarm

This document shows you how to build a simple Couchbase cluster with a master and worker node. You can use Docker for Mac, or [Play with Docker](http://labs.play-with-docker.com/) to complete this exercise.

## Prerequisites

[Docker for Mac](https://docs.docker.com/docker-for-mac/) or [Play with Docker](http://labs.play-with-docker.com/)
Docker engine 1.13+

## Getting Started

To run this lab, make sure that you have a swarm setup as described in "Creating our first swarm" as detailed in slide 55. If you have a running swarm already, we can deploy our Couchbase service.

Otherwise, go back to the "Creating our first swarm" and bring up a new swarm with Docker for Mac or Play with Docker.

Once that's complete, let's explore deploying a highly available Couchbase cluster to our new swarm.

As you know, Docker 1.12 introduced Services. These are replicated and loadbalanced that can be easily created using `docker service create` command. Leveraging the power of declarative state, we can tell the swarm to run 3 containers of Couchbase, and rely on Docker swarm to self-heal the infrastructure in the case of a container going offline. 

We'll create a "semi-automatic" cluster in this exercise, due to the stateful nature of database services, and walk through how we'd use it.

Navigate to the couchbase-swarm/ directory

```
$ cd couchbase-swarm/
```

Next, we'll deploy the Couchbase service. We'll use what we've learned in previous slides about `services` in compose files, to now deploy a stack!

What's a stack, or 'service stack?'

A stack is a collection of services that make up an application in a specific environment. A stack file is a file in YAML format, similar to a docker-compose.yml file, that defines one or more services. The YAML reference is documented here.
Stacks are a convenient way to automatically deploy multiple services that are linked to each other, without needing to define each one separately.
Stack files define environment variables, deployment tags, the number of containers, and related environment-specific configuration. Because of this, you should use a separate stack file for development, staging, production, and other environments.

```
$ docker deploy -c docker-compose.yml couchbase
Creating network couchbase_couchbase
Creating service couchbase_couchbase-worker
Creating service couchbase_couchbase-master
$
```

Let's see what's running.

```
$ docker stack ls
NAME       SERVICES
couchbase  2
```

This makes sense, because using our `docker-compose.yml` file, we defined a Couchbase `worker` and `master` service, which we've combined into a single deployed service stack.

If we check out the tasks running on each of the services, we'll see more detail.

```
$ docker stack ps couchbase
ID                  NAME                           IMAGE                        NODE
    DESIRED STATE       CURRENT STATE           ERROR               PORTS
    8pbb6zlcwhol        couchbase_couchbase-worker.1   anonymuse/couchbase:latest   node1 Running             Running 3 minutes ago
    nsntqfuluwv3        couchbase_couchbase-master.1   anonymuse/couchbase:latest   node5 Running             Running 3 minutes ago
```

If you're using PWD, you can click on the `8091` port link to open a browser to see the Couchbase administration page. Nice work! Can you guess the username and password? I'll give you a hint, it's in the node configuration file. Flag down an instructor if you're having trouble finding it.

## Managing your cluster

Now that we've spun up our cluster, let's look at what it took to create it.

First, we created an overlay network called `couchbase` that we deployed our service to.

```
networks:
  couchbase:
    driver: overlay
```

Then we created a `couchbase-master` service that leverages a public Couchbase image at `anonymuse/couchbase` to spin up our master container.

```
services:
  couchbase-master:
    image: anonymuse/couchbase
    deploy:
      replicas: 1
    ports:
      - 8091:8091
    environment:
      TPYE: "MASTER"
    networks:
      - couchbase
```
