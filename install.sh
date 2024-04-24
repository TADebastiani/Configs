#! /bin/bash

##################################
# Tiago's Default configurations #
##################################

# Variables
TMPDIR=$(mktemp -d)
CURRENT_DIR=$(pwd)
CONFIG_DIR=$CURRENT_DIR

DISK_LABEL=OldHome
DISK_FORMAT=ext4
MOUNT_POINT=/mnt/Externo
UUID_REGEX='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'

MAIN_PACKAGES=(
  vim
  git
  lazygit
)

install_main_packages() {
  fmt_title "Installing main packages..."

  install_dependencies $MAIN_PACKAGES
}

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

configure_external_disk() {
  fmt_title "Configuring external disks..."

  dependencies=(
    github-cli
    vim
    cmake
    gcc
    make
    python3
    npm
    docker
    jq
  )

  fmt_message "configuring $DISK_LABEL..."
  
  uuid=$(lsblk -f | grep $DISK_LABEL | grep -Eo "$UUID_REGEX")

  if sudo grep -q $uuid /etc/fstab
  then
    sudo cp -b /etc/fstab /etc/fstab.bkp

    echo -e "UUID=$uuid $MOUNT_POINT\t$DISK_FORMAT\tdefaults,noatime 0 2" | sudo tee -a /etc/fstab
  fi
}

configure_keyboard() {
  fmt_title "Configuring keyboard layout 'English (US, intl., with dead keys)'..."
  
  fmt_message "Downloading configuration packages..."
  wget https://raw.githubusercontent.com/raelgc/win_us_intl/master/.XCompose
  sudo cp .XCompose $HOME/.XCompose
  gsettings set org.gnome.settings-daemon.plugins.xsettings disabled-gtk-modules '["'keyboard'"]'
  yay -S uim

  fmt_message "Configuring XProfile..."
  touch $HOME/.xprofile
  echo "export GTK_IM_MODULE=uim" >> $HOME/.xprofile
  echo "export QT_IM_MODULE=uim" >> $HOME/.xprofile
  echo "uim-xim &" >> $HOME/.xprofile
  echo "export XMODIFIERS=@im=uim" >> $HOME/.xprofile
}

ask_menu() {
  declare -g $1="$2"
  if [ -z "${!1}" ]
  then
    echo -n "$3"
    read answer
    if [[ $answer =~ ^(y|Y|s|S)$ ]]
    then
      declare -g $1=true
    else
      declare -g $1=false
    fi
  fi
}

#menu() {
  # ask_menu VIM_OPT      "$VIM_OPT"      "Configure Vim? [s/N] "
  # if $VIM_OPT 
  # then
  #   echo "configure_vim"
  # fi
  
  # ask_menu DESKTOP_OPT  "$DESKTOP_OPT"  "Configure Desktop Entries? [s/N] "
  # if $DESKTOP_OPT
  # then
  #   echo "configure_desktop_entries"
  # fi
  
  # ask_menu DOCKER_OPT   "$DOCKER_OPT"   "Configure Docker? [s/N] "
  # if $DOCKER_OPT
  # then
  #   echo "configure_docker"
  # fi
  
  # ask_menu DISKS_OPT    "$DISKS_OPT"    "Configure External Disks? [s/N] "
  # if $DISKS_OPT
  # then
  #   echo "configure_external_disk"
  # fi
#}

main() {
    source ./utils.sh
  cd $TMPDIR

  setup_colors

  # Install options
  ALL_OPT=0
  VIM_OPT=0
  NVIM_OPT=0
  DESKTOP_OPT=0
  DOCKER_OPT=0
  DISKS_OPT=0
  KEYBOARD_OPT=0
  TMUX_OPT=0
  ZSH_OPT=0

  # Flag to not ask if some option was passed
  NO_MENU=0

  while [[ ! -z "$1" ]]
  do
      case "$1" in
          -a|--all) 
              ALL_OPT=1
              NO_MENU=1
              ;;
          -v|--vim) 
              VIM_OPT=1
              NO_MENU=1
              ;;
          -n|--nvim)
              NVIM_OPT=1
              NO_MENU=1
              ;;
          -D|--desktop-entries) 
              DESKTOP_OPT=1
              NO_MENU=1
              ;;
          -d|--docker)
              DOCKER_OPT=1
              NO_MENU=1
              ;;
          -e|--external-disks)
              DISKS_OPT=1
              NO_MENU=1
              ;;
          -k|--keyboard)
              KEYBOARD_OPT=1
              NO_MENU=1
              ;;
          -t|--tmux)
              TMUX_OPT=1
              NO_MENU=1
              ;;
          -z|--zsh)
              ZSH_OPT=1
              NO_MENU=1
              ;;
          -h|--help) echo "USAGE" ;;
      esac
      shift
  done
  
 # if [[ ! -z "$NO_MENU" ]]
 # then
 #   menu
 # fi

  if [ $NVIM_OPT -eq 1 ]
  then
      source $CONFIG_DIR/scripts/install_nvim.sh
      configure_nvim
  fi

  if [ $VIM_OPT -eq 1 ]
  then
      source $CONFIG_DIR/vim/install.sh
      configure_vim
  fi
  
  if [ $DESKTOP_OPT -eq 1 ]
  then
      source $CONFIG_DIR/desktop-entries/install.sh
      configure_desktop_entries
  fi
  
  if [ $DOCKER_OPT -eq 1 ]
  then
      source $CONFIG_DIR/docker/install.sh
      configure_docker
  fi

  if [ $TMUX_OPT -eq 1 ]
  then
      source $CONFIG_DIR/scripts/install_tmux.sh
      configure_tmux
  fi

  if [ $ZSH_OPT -eq 1 ]
  then
      source $CONFIG_DIR/scripts/install_zsh.sh
      configure_zsh
  fi
  
  # if $DISKS_OPT
  # then
  #   echo "configure_external_disk"
  # fi

  cd $CURRENT_DIR  
  rm -r $TMPDIR

}

main $@
