#!/usr/bin/env bash
#
# Bootstrap a new machine from this repo:
#   macOS -> nix-darwin (with home-manager as a module)
#   Linux -> standalone home-manager
#
# Usage: bash install.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"

function log() {
  printf 'INFO: %s\n' "${1}"
}

function die() {
  printf 'ERROR: %s\n' "${1}" >&2
  exit 1
}

function tool_exists() {
  log "Checking for $1..."
  command -v "$1" >/dev/null 2>&1
}

function directory_exists() {
  log "Checking for $1..."
  test -d "$1"
}

function file_exists() {
  log "Checking for $1..."
  test -f "$1"
}

function logged_into_github() {
  gh auth token >/dev/null 2>&1
}

# Install nix
if ! tool_exists nix; then
  log "Installing nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm

  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
else
  log "nix already exists at $(command -v nix)"
fi

# Install tmux plugin manager if it's not there
DIR=$HOME/.tmux/plugins/tpm
if ! directory_exists "${DIR}"; then
  log "Cloning tpm..."
  mkdir -p "$DIR"
  git clone https://github.com/tmux-plugins/tpm "$DIR"
else
  log "tpm already exists at $DIR"
fi

# Stable path to this checkout. home-manager links configs that need to stay
# writable (e.g. ~/.config/nvim) through it, wherever the repo was cloned.
DOTS_LINK=$HOME/.dots
if [ -e "$DOTS_LINK" ] && [ ! -L "$DOTS_LINK" ]; then
  die "$DOTS_LINK exists and is not a symlink; move it aside and re-run"
fi
log "Linking $DOTS_LINK -> $REPO_DIR"
ln -sfn "$REPO_DIR" "$DOTS_LINK"

# Apply the nix configuration. Tool versions come from this repo's flake.lock.
case "$OS" in
Darwin)
  [ "$ARCH" = "arm64" ] || die "Only Apple Silicon Macs are supported (got $ARCH)"

  log "Running darwin-rebuild switch (requires sudo)"
  NIX_BIN="$(command -v nix)"
  sudo "$NIX_BIN" run --inputs-from "$REPO_DIR" nix-darwin#darwin-rebuild -- \
    switch --flake "$REPO_DIR#mac"

  export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

  # nix-darwin can't change an existing user's login shell, so do it here.
  FISH=/run/current-system/sw/bin/fish
  CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
  if [ "$CURRENT_SHELL" != "$FISH" ]; then
    log "Changing login shell to $FISH"
    sudo chsh -s "$FISH" "$USER"
  else
    log "Login shell is already $FISH"
  fi
  ;;
Linux)
  case "$ARCH" in
  x86_64 | aarch64) ;;
  *) die "Unsupported Linux architecture: $ARCH" ;;
  esac

  log "Running home-manager switch"
  nix run --inputs-from "$REPO_DIR" home-manager -- \
    switch -b hm-backup --flake "$REPO_DIR#$ARCH-linux"

  export PATH="$HOME/.nix-profile/bin:$HOME/.local/state/nix/profile/bin:$PATH"
  ;;
*)
  die "Unsupported OS: $OS"
  ;;
esac

for type in authentication signing; do
  KEYFILE=$HOME/.ssh/$type
  if ! file_exists "$KEYFILE"; then
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -N '' -f "$KEYFILE"

    if ! logged_into_github; then
      gh auth login
    fi

    log "gh ssh-key add $KEYFILE.pub --title $(hostname)-$type --type $type"
    gh ssh-key add "$KEYFILE.pub" --title "$(hostname)-$type" --type "$type"
  else
    log "$KEYFILE exists"
  fi
done
