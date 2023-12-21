#!/bin/bash
#set -x
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

# Deploys a Docker Swarm instance with the Traefik Proxy service.
# Traefik obtains and manages Letsencrypt certs for all hosts it proxies.
# Traefik Proxy routes requests to other Docker conatiners. 
# All services operate with public DNS hostnames.

# ver: 21-dec-2023

# Setup environment
cd "$(dirname "$0")"
export myservice=traefik

if [[ ! -s "${myservice}.env" || ! -s "${myservice}.toml" ]]; then
  echo
  echo "    Missing ${myservice}.toml OR ${myservice}.env"
  echo "    Run the following commands"
  echo
  echo "    cp traefik.env.default traefik.env"
  echo "    cp traefik.toml.default traefik.toml"
  echo
  echo "    Add your custom parameters to these files before deploying this service"
  echo
  exit
fi
source ./${myservice}.env

USAGE="$(basename "$0") [-logs | -stop | -H]"

if [[ $# -gt 1 ]]; then
  echo "Too many parameters.
  ${USAGE}" >&2
  echo
  exit 1
fi

if [[ $# == 1 ]]; then
  upperARG=${1^^}
  if [[ "$upperARG" =~ ^-*H(ELP)?$ ]]; then
    echo
    echo "${USAGE}"
    echo
    exit 1
  fi

  if [[ "$upperARG" =~ ^-*L(OGS)?$ ]]; then  
    echo
    docker service logs -f ${myservice}_proxy
    exit 1
  fi

  if [[ "$upperARG" =~ ^-*S(TOP)?$ ]]; then
    if [ "$(docker stack ls --format '{{.Name}}' | grep ${myservice})" ]; then
      echo
      docker stack rm ${myservice}
      echo
      echo ".... stopping ${myservice} ....."
      echo
      sleep 7
    else
      echo
      echo  "${myservice} not running"
      echo
    fi
    exit 1
  fi
  
  echo "${USAGE}"
  exit 1
fi

main() {
  # Setup Docker Swarm Mode
  if [ "$(docker info | grep Swarm | sed 's/ Swarm: //g')" == "inactive" ]; then
    docker swarm init --advertise-addr $IPADDR
  fi

  # Pull Traefik image
  if [ ! "$(docker image ls --format '{{.Repository}}:{{.Tag}}' | grep ${myservice}:$TRAEFIK_VER)" == "traefik:$TRAEFIK_VER" ]; then
    echo
    echo  "Pulling ${myservice}:"$TRAEFIK_VER
    docker pull ${myservice}:${TRAEFIK_VER}
    sleep 1
  fi

  NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
  if [ ! ${NODE_ID} ]; then
    docker node update --label-add traefik-public.letsencrypt=true ${NODE_ID}
  fi

  if [ ! -d ../letsencrypt ]; then
    mkdir ../letsencrypt
    chmod 750 ../letsencrypt
  fi
  if [ ! -L ./letsencrypt ]; then
    ln -s ../letsencrypt/ ./letsencrypt
  fi
  if [ ! -L ./letsencrypt/dumpcerts.acme.v2.sh ]; then
    ln -sr dumpcerts.acme.v2.sh ./letsencrypt/dumpcerts.acme.v2.sh
  fi

# Extracting https certs from letsencrypt requires utility "jq"
  if [ ! -x "$(which jq)" ]; then
    yum update -y && yum -y install jq && yum clean all
  fi

  if [ ! -d ./dynamic ]; then
    mkdir dynamic
    touch dynamic/middlewares.toml
    cp ./tlsoptions.yaml ./dynamic/tlsoptions.yaml
  fi

  # Traefik requires an overlay network for services to attached to.
  # Check for the existance of that overlay network.
  target=$(docker network ls |grep traefik-public)
  if [ ! "${target}" ]; then
    echo
    echo "Traefik Proxy Network not present ... creating"
    echo
    docker network prune -f
    docker network create --driver overlay --attachable traefik-public
  fi

  echo
  echo "    Want to control when to display logging to stdout"
  echo "    To access the logs in stdout:"
  echo "    ./deploy_traefik.sh -logs"
  echo "        OR"
  echo "    docker service logs -f ${myservice}_proxy"
  echo

  docker stack deploy -c docker-compose.yml ${myservice}
  docker service logs -f ${myservice}_proxy


}

main 
