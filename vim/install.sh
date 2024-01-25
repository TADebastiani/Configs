#! /bin/bash

VUNDLE_REPOSITORY=http://github.com/VundleVim/Vundle.vim.git
BUNDLE_DIR=$HOME/.vim/bundle

configure_vim() {
  fmt_title "Configuring vim..."

  dependencies=(
    vim
  )

  install_dependencies $dependencies

  cp -b $CONFIG_DIR/vim/.vimrc $HOME

  fmt_message "Cloning Vundle repository..."
  git clone $VUNDLE_REPOSITORY $BUNDLE_DIR/Vundle.vim

  fmt_message "Installing Vim GitGutter plugin..."
  git clone https://github.com/airblade/vim-gitgutter.git $HOME/.vim/pack/airblade/start/vim-gitgutter
  vim -u NONE -c "helptags vim-gitgutter/doc" -c q
  
  fmt_message "Installing VIM plugins..."
  vim +PluginInstall +qall
}
