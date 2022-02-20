#!/usr/bin/env bash

# https://sipb.mit.edu/doc/safe-shell/
set -eufo pipefail

shopt -s failglob

CONTAINER="php-workspace-${PWD##*/}"
NETWORK="${PWD##*/}-network"
IMAGE=php:8.1.3-cli-alpine3.15

# ensure CTRL+D and other signals are properly handled
trap "" SIGINT SIGTERM ERR EXIT

cd "$(dirname "$0")"

# ping docker daemon
curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null
if [ $? -eq 7 ]; then
  echo "[E] Docker daemon is not running!"

  exit
fi

# there is no network with name $NETWORK, so create a new one
if [ -z "$(docker network ls --filter name="${NETWORK}" --quiet)" ]; then
  echo "[I] Creating network"
  if [ -z "$(docker network create "${NETWORK}")" ]; then
    echo "[E] Failed to create network"

    exit
  fi
fi

# there is no container with name $CONTAINER, so create a new one
if [ -z "$(docker ps --all --quiet --filter name="${CONTAINER}")" ]; then
  echo "[I] Creating container"
  docker run \
    --interactive \
    --tty \
    --volume "$(PWD)":/usr/src/workspace \
    --network "${NETWORK}" \
    --workdir /usr/src/workspace \
    --name "${CONTAINER}" \
    "${IMAGE}" \
    sh

  echo "[I] Stopping container"

  exit
fi

# start a stopped container
if [ "$(docker ps --all --quiet --filter status=created --filter status=exited --filter name="${CONTAINER}")" ]; then
  echo "[I] Starting container"
  if [ "$(docker start "${CONTAINER}")" != "${CONTAINER}" ]; then
    echo "[E] Failed to start container"

    exit
  fi
fi

echo "[I] Attaching to container"
docker exec \
  --tty \
  --interactive \
  "${CONTAINER}" \
  sh

if [ "$(docker ps --all --quiet --filter status=exited --filter name="${CONTAINER}")" ]; then
  exit
fi

if [ "$(docker container inspect --format='{{ .ExecIDs }}' "${CONTAINER}")" == "[]" ]; then
  echo "[I] Stopping container"
  if [ "$(docker stop "${CONTAINER}")" != "${CONTAINER}" ]; then
    echo "[E] Failed to stop container"
  fi
fi
