# Shells need to be enabled here (not just installed) so nix-darwin writes the
# /etc/ dropins that put the Nix profile on PATH.
{
  programs.zsh.enable = true; # macOS default shell
  programs.fish.enable = true;
}
