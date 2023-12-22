#!/bin/bash

if [ "$(docker info | grep Swarm | sed 's/ Swarm: //g')" == "active" ]; then
  docker stack rm traefik
  sleep 5
  docker swarm leave --force
fi


#docker stack ls |grep traefik | grep Swarm

