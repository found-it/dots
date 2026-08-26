# One package list for every machine. Platform-specific entries are kept in the
# two `optionals` blocks so a `home.packages` edit doesn't silently change what
# the other platform installs.
{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      # Shell and CLI
      bat
      crane
      eza
      fd
      fzf
      jq
      opentofu
      ripgrep
      shellcheck
      shfmt
      starship
      tmux
      unzip
      watch
      wget
      yq

      # Kubernetes
      chart-testing
      eksctl
      k3d
      kubecolor
      kubectl
      kubectx
      kubernetes-helm
      stern

      # Languages
      go
      protobuf
      rustup # manages rustc/cargo/rustfmt/rust-analyzer itself

      # Client-y Things
      awscli2
      github-cli
      go-task
      lefthook
      tailscale

      # neovim
      lazygit
      luarocks
      neovim
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      (azure-cli.withExtensions [ azure-cli.extensions.quota ])
      cloudsmith-cli
      fluxcd
      kubebuilder
      kustomize
      openstackclient-full
      sonobuoy
      sops
      # nodejs -- installed via Homebrew instead, see ../darwin/homebrew.nix
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      nodejs
    ];
}
