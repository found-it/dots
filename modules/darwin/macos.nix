# macOS user defaults. Discover more with `darwin-rebuild changelog` and
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults
{
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false; # don't reorder spaces by most-recently-used
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv"; # column view
    };

    loginwindow.LoginwindowText = "turnip";
  };
}
