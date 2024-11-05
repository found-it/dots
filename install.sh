# Install nix
# TODO: do not interact
function tool_exists() {
  echo "Checking for $1..."
  which $1 >/dev/null 2>&1 && return 0
  return 1
}

if ! tool_exists nix; then
  echo "Installing nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else
  echo "nix already exists at $(which nix)"
fi

mkdir -p ~/.tmux/plugins/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install LazyVim
mkdir -p ~/.config/nvim
mv ~/.config/nvim{,.bak}
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

mkdir /home/james/.config
ln -sf $PWD/home-manager $HOME/.config/
