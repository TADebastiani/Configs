#!/bin/bash

configure_zsh() {
  fmt_title "Configuring OhMyZsh..."

  local dependencies=(
    zsh
    curl
  )

  if [ -z $ZSH ]; then
    install_dependencies $dependencies
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    for theme in $CONFIG_DIR/zsh/themes/*;
    do
      local filename=$(basename -- $theme)
      fmt_message "Installing theme: "${filename%.zsh-theme}
      ln -s "$theme" "$ZSH/custom/themes/$filename"
    done
  fi

}
