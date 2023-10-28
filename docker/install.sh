#! /bin/bash

DOCKER_POINT=/mnt/Externo/docker
DAEMON_FILE=/etc/docker/daemon.json

function configure_docker() {
  systemctl stop docker.service
  
  sudo mkdir -p $(dirname $DAEMON_FILE)
  sudo touch $DAEMON_FILE

  sudo node configure.js $DAEMON_FILE  $DOCKER_POINT

  sudo groupadd -f docker

  sudo usermod -aG docker $USER

  newgrp docker
}

function main() {
  docker -v
  if [ $? -eq 1 ]
  then
    yay -Sy docker
  fi

  configure_docker
}

main
