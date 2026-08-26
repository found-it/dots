# artichoke -- Apple Silicon MacBook Pro
{ self, ... }:
{
  imports = [
    ../modules/darwin/homebrew.nix
    ../modules/darwin/macos.nix
    ../modules/darwin/packages.nix
    ../modules/darwin/shells.nix
  ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # The user that `system.defaults` and other per-user settings apply to.
  system.primaryUser = "james";

  # home-manager reads the home directory from here.
  users.users.james.home = "/Users/james";

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
