#!/bin/bash

NVIM_FILES_DIR=$CONFIG_DIR/nvim
NVIM_CONFIG_DIR=$HOME/.config/nvim

configure_nvim() {
    fmt_title "Configuring nvim..."

	local dependencies=(
        neovim
        npm
        git
        tmux
	)

    install_dependencies $dependencies

    ln -s $NVIM_FILES_DIR $NVIM_CONFIG_DIR
}
