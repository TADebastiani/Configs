#! /bin/bash

CURRENT_DIR=$(dirname $(readlink -f "$0"))
REPOSITORY_URL=http://github.com/VundleVim/Vundle.vim.git
BUNDLE_DIR=~/.vim/bundle

function clone_repo() {
  git clone ${REPOSITORY_URL} ${BUNDLE_DIR}/Vundle.vim
}

function install_dependencies() {
  echo "Assuming you still using Arch btw!"

  sudo pacman -S cmake gcc make vim python3 npm
}

function install_plugins() {
  echo "Installing plugins"

  vim +PluginInstall +qall

  echo "Compiling YCM"
  python3 ${BUNDLE_DIR}/YouCompleteMe/install.py --clang-completer --ts-completer
}

function main() {
  ln -bv ${CURRENT_DIR}/.vimrc ~
  
  clone_repo
  install_dependencies
  install_plugins
}

main
