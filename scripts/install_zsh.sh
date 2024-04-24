#!/bin/bash

configure_zsh() {
  fmt_title "Configuring OhMyZsh..."

  local dependencies=(
    zsh
    curl
  )

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  if [ -n $ZSH_CUSTOM ]; then
    return
  fi

  ln -s $CONFIG_DIR/zsh/themes/*.zsh-theme $ZSH_CUSTOM/themes/
}
