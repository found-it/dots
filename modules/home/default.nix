# The shared user environment, imported by both the nix-darwin host and the
# standalone Linux homeConfigurations. Platform differences are handled inside
# each module with `pkgs.stdenv.isDarwin`.
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./packages.nix
    ./fish.nix
    ./git.nix
    ./nvim.nix
    ./tmux.nix
  ];

  home.username = "james";

  # Under nix-darwin this comes from `users.users.james.home`; mkDefault lets
  # that definition win and only applies on standalone Linux.
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.isDarwin then "/Users/james" else "/home/james"
  );

  # Read the home-manager release notes before changing this.
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
