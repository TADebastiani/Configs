#!/bin/bash

TPM_DIR=$HOME/.tmux/plugins
TMUX_CONFIG_DIR=$HOME/.config/tmux
TMUXIFIER_BIN_DIR=$TMUX_CONFIG_DIR/plugins/tmuxifier/bin

configure_tmux() {
    fmt_title "Configuring Tmux..."

    local dependencies=( tmux )

    install_dependencies $dependencies

    mkdir -p $TPM_DIR
    if [ ! -d $TPM_DIR/tpm ]
    then
        git clone -fq https://github.com/tmux-plugins/tpm $TPM_DIR/tpm
    fi
    
    ln -s $CONFIG_DIR/tmux $TMUX_CONFIG_DIR
    
    source $TPM_DIR/tpm/scripts/install_plugins.sh
}
