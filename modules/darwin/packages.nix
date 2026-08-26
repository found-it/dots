# System-wide packages, for every user on the machine.
#
# Almost everything lives in ../home/packages.nix instead -- that layer works
# identically on the Linux hosts where we aren't root. Only things that must be
# system-wide belong here.
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    monaspace
  ];
}
