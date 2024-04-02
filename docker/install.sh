#! /bin/bash

DOCKER_POINT=/mnt/Externo
DAEMON_FILE=/etc/docker/daemon.json

function configure_docker() {
  fmt_title "Configuring docker..."

  local dependencies=(
    docker
    jq
    )

  install_dependencies $dependencies
  
  systemctl stop docker.service
  
  read -p $(fmt_title "Use external point? [s/N] ") answer
  if [[ $answer =~ ^(y|Y|s|S)$ ]]
  then
    read -p $(fmt_title "Docker external point path: [$DOCKER_EXTERNAL_PATH] ") external_point
    external_point=${external_point:-$DOCKER_EXTERNAL_PATH}/docker

    sudo touch $DAEMON_FILE
    jq --arg  dataRoot $external_point '."data-root"|=$dataRoot' $DAEMON_FILE > "daemon.json"
    sudo mv -b "daemon.json" $DAEMON_FILE
  fi
 
  sudo groupadd -f docker
  sudo usermod -aG docker $USER
}

