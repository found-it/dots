#!/usr/bin/env bash

function tool_exists() {
  echo "Checking for $1..."
  which $1 >/dev/null 2>&1 && return 0
  return 1
}

function directory_exists() {
  echo "Checking for $1..."
  test -d $1 >/dev/null 2>&1 && return 0
  return 1
}

function file_exists() {
  echo "Checking for $1..."
  test -f $1 >/dev/null 2>&1 && return 0
  return 1
}

# Install nix
# TODO: do not interact
if ! tool_exists nix; then
  echo "Installing nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
else
  echo "nix already exists at $(which nix)"
fi

# Install tmux plugin manager if it's not there
DIR=$HOME/.tmux/plugins/tpm
if ! directory_exists ${DIR}; then
  echo "Cloning tpm..."
  mkdir -p $DIR
  git clone https://github.com/tmux-plugins/tpm $DIR
else
  echo "tpm already exists at $DIR"
fi

# Install LazyVim if it's not there
FILE=$HOME/.config/nvim/lazyvim.json
if ! file_exists ${FILE}; then
  PATH=$(dirname $FILE)
  mkdir -p $PATH
  mv $PATH{,.bak}
  git clone https://github.com/LazyVim/starter $PATH
  rm -rf $PATH/.git
else
  echo "lazyvim already exists at $FILE"
fi

mkdir -p ~/.config
ln -sf $PWD/home-manager $HOME/.config/

# TODO: ssh keys

# Bootstrap home-manager
nix run home-manager/master -- switch
