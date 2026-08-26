# Homebrew is declared here but not installed by Nix -- install it once by hand:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
# nix-darwin renders these lists into a Brewfile and runs `brew bundle` on
# activation. It only ever *adds*; see onActivation.cleanup below to also prune.
{
  homebrew = {
    enable = true;

    taps = [
      "dagger/tap"
      "hashicorp/tap"
    ];

    # Tap formulae stay fully qualified: homebrew-core also has a `dagger`, and a
    # bare name would silently resolve to that one instead.
    brews = [
      "dagger/tap/dagger"
      "frizbee"
      "hashicorp/tap/packer"
      "node"
    ];

    casks = [
      "ghostty"
      "secretive"
    ];

    # Uncomment to have activation uninstall anything not listed above. Check
    # `brew leaves` and `brew list --cask` first -- this machine has packages
    # installed by hand that would be removed.
    # onActivation.cleanup = "uninstall";
  };
}
