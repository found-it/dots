#!/usr/bin/env bash

function log() {
  printf 'INFO: %s\n' "${1}"
}

function tool_exists() {
  log "Checking for $1..."
  which $1 >/dev/null 2>&1 && return 0
  return 1
}

function directory_exists() {
  log "Checking for $1..."
  test -d $1 >/dev/null 2>&1 && return 0
  return 1
}

function file_exists() {
  log "Checking for $1..."
  test -f $1 >/dev/null 2>&1 && return 0
  return 1
}

function logged_into_github() {
  gh auth token >/dev/null 2>&1 && return 0
  return 1
}

# Install nix
# TODO: do not interact
if ! tool_exists nix; then
  log "Installing nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm

  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  log "nix already exists at $(which nix)"
fi

# Install tmux plugin manager if it's not there
DIR=$HOME/.tmux/plugins/tpm
if ! directory_exists ${DIR}; then
  log "Cloning tpm..."
  mkdir -p $DIR
  git clone https://github.com/tmux-plugins/tpm $DIR
else
  log "tpm already exists at $DIR"
fi

# Install LazyVim if it's not there
FILE=$HOME/.config/nvim/lazyvim.json
if ! file_exists ${FILE}; then
  LAZYVIM_PATH=$(dirname $FILE)
  mkdir -p $LAZYVIM_PATH
  mv $LAZYVIM_PATH{,.bak}
  git clone https://github.com/LazyVim/starter $LAZYVIM_PATH
  rm -rf $LAZYVIM_PATH/.git
else
  log "lazyvim already exists at $FILE"
fi

# Bootstrap home-manager
log "Running home-manager switch"
mkdir -p ~/.config
ln -sf $PWD/home-manager $HOME/.config/
nix run home-manager/master -- switch

for type in authentication signing; do
  KEYFILE=$HOME/.ssh/$type
  if ! file_exists $KEYFILE; then
    ssh-keygen -t ed25519 -N '' -f $KEYFILE

    if ! logged_into_github; then
      gh auth login
    fi

    log "gh ssh-key add $KEYFILE.pub --title "$(hostname)-$type" --type $type"
    gh ssh-key add $KEYFILE.pub --title "$(hostname)-$type" --type $type
  else
    log "$KEYFILE exists"
  fi
done
