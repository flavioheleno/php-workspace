#!/bin/bash

set -o pipefail

NAME="php-workspace-${PWD##*/}"
IMAGE=php:8.0.2-cli

# ensure CTRL+D and other signals are properly handled
trap "" SIGINT SIGTERM ERR EXIT

# ping docker daemon
curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null 2&>1
if [ $? -eq 7 ]; then
  echo "[E] Docker daemon is not running!"

  exit
fi

if [ ! "$(docker ps -aq -f name=${NAME})" ]; then
  echo "[I] Creating a new php workspace"
  docker run \
    --volume $(pwd):/usr/src/workspace \
    --workdir /usr/src/workspace \
    --name "${NAME}" \
    --interactive \
    --tty \
    "${IMAGE}" bash

  exit
fi

if [ "$(docker ps -aq -f status=created -f status=exited -f name=${NAME})" ]; then
  echo "[I] Starting workspace"
  if [ "$(docker start ${NAME})" != "${NAME}" ]; then
    echo "[E] Failed to start workspace!"

    exit
  fi
fi

echo "[I] Attaching to workspace"
docker exec --tty --interactive "${NAME}" bash

if [ "$(docker ps -aq -f status=exited -f name=${NAME})" ]; then
  exit
fi

if [ "$(docker exec ${NAME} bash -c 'ls /proc/ | grep -E "[0-9]+" | wc -l')" -eq 5 ]; then
  echo "[I] Stopping workspace"
  if [ "$(docker stop ${NAME})" != "${NAME}" ]; then
    echo "[W] Failed to stop workspace!"
  fi
fi
