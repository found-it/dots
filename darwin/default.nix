{ pkgs, username, ... }:

{
  # Nix itself is installed and managed by the Determinate Systems installer,
  # so nix-darwin must not try to manage the daemon or /etc/nix/nix.conf.
  # Custom nix settings belong in /etc/nix/nix.custom.conf.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # Required for options that apply to a user (homebrew, system.defaults).
  system.primaryUser = username;

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  # Installs fish system-wide, adds it to /etc/shells, and wires up the
  # nix-darwin environment for fish sessions. install.sh runs chsh.
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  security.pam.services.sudo_local.touchIdAuth = true;

  # Installed to /Library/Fonts/Nix Fonts.
  fonts.packages = with pkgs; [
    monaspace
    (callPackage ../pkgs/serious-shanns-nerd-font-mono.nix { })
  ];

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };

    finder = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      "com.apple.mouse.tapBehavior" = 1; # tap to click
    };

    trackpad.Clicking = true; # tap to click
  };

  # Installs and pins Homebrew itself.
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  # Packages Homebrew installs. Apps no longer listed here are left installed.
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [
      "1password"
      "firefox"
      "rectangle"
      "slack"
      "ghostty"
      "tailscale"
    ];
  };

  # Used for backwards compatibility; read the nix-darwin changelog before changing.
  system.stateVersion = 6;
}
