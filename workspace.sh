#!/bin/sh

set -eo pipefail

if [ ! "$(docker ps -aq -f name=php-workspace)" ]; then
  # create a new container
  docker create \
    --volume $(pwd):/usr/src/workspace \
    --workdir /usr/src/workspace \
    --name php-workspace \
    php:8.0.2-cli bash
fi

if [ "$(docker ps -aq -f status=exited -f name=php-workspace)" ]; then
  # start container if it is not running
  docker start php-workspace
fi

docker exec --tty --interactive php-workspace bash && \
docker stop php-workspace
