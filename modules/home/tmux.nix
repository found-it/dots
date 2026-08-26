# tmux. The only difference between the Mac and Linux copies of this file was
# `default-shell`, which is now derived from the fish package itself rather than
# hardcoded to a per-platform path.
{ pkgs, ... }:
{
  home.file.".tmux.conf".text = ''
    set-option -g default-shell "${pkgs.fish}/bin/fish"
  ''
  + builtins.readFile ../../config/tmux/tmux.conf;
}
