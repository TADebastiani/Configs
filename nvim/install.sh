#!/bin/bash


FILES_DIR=$CONFIG_REPO_DIR/nvim/files
NVIM_CONFIG_DIR=$HOME/.config/nvim

configure_nvim() {
    fmt_title "Configuring nvim..."

	local dependencies=(
        neovim
        npm
        git
		lua-language-server
        tmux
	)

    install_dependencies $dependencies

    mkdir -p $NVIM_CONFIG_DIR

    fmt_message "Installing nvim plugin manager..."
    
	# Install packer plugin manager
	git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 		~/.local/share/nvim/site/pack/packer/start/packer.nvim

    cp -r $CONFIG_REPO_DIR/nvim/files/{init.lua,lua} $NVIM_CONFIG_DIR

    fmt_message "Installing nvim plugins..."
    nvim -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

	sudo npm i -g bash-language-server \
             typescript typescript-language-server \
	         vscode-langservers-extracted \
	         svelte-language-server
    
    cp -r $CONFIG_REPO_DIR/nvim/files/after $NVIM_CONFIG_DIR

}
