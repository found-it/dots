# LazyVim writes lazy-lock.json and lazyvim.json back into ~/.config/nvim at
# runtime, so this can't be a normal `source =` link -- that would point at a
# read-only /nix/store path and plugin updates would fail. mkOutOfStoreSymlink
# links to the working copy instead, which stays writable and lets the lockfile
# changes show up as ordinary edits in this repo.
{ config, ... }:
let
  # Where this repo is checked out. Update if you move it.
  dotsDir = "${config.home.homeDirectory}/dev/found-it/dots";
in
{
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotsDir}/config/nvim";
}
