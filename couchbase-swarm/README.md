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

```
$ docker deploy -c docker-compose.yml couchbase
Creating network couchbase_couchbase
Creating service couchbase_couchbase-worker
Creating service couchbase_couchbase-master
$
```
