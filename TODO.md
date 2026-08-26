# TODO

Follow-ups for this config, roughly in the order they're worth doing.

Items 1-3 of the original list (make this a git repo, switch to `nixfmt-tree`,
git identity via home-manager) were resolved by the merge into this repo.

## 1. Decide on Homebrew cleanup

`homebrew.onActivation.cleanup = "uninstall"` makes the Brewfile authoritative: anything not
declared in `modules/homebrew.nix` gets removed on the next activation. It's commented out
because this machine currently has packages installed by hand that would be deleted:

- formulae: `coder`, `docker-credential-helper-ecr`, `hugo`, `node`, `pv`, `python@3.13`, `zig`
- casks: `1password-cli`, `headlamp`, `wezterm`

Either declare the ones worth keeping in `modules/homebrew.nix`, or leave cleanup off.

```sh
brew leaves                # hand-installed formulae (excludes dependencies)
brew list --cask
```

Then uncomment `onActivation.cleanup` and check what the Brewfile would do before switching:

```sh
brew bundle check --verbose \
  --file="$(nix build --no-link --print-out-paths .#darwinConfigurations.artichoke.system)/Brewfile"
```

## 2. Automatic garbage collection

Not enabled, because it starts deleting old generations on a schedule -- your call on the
retention window. In `hosts/artichoke.nix`:

```nix
nix.gc = {
  automatic = true;
  interval = {
    Weekday = 0;
    Hour = 3;
    Minute = 0;
  };
  options = "--delete-older-than 30d";
};
nix.optimise.automatic = true;
```

```sh
du -sh /nix/store                      # current size
nix store gc --dry-run 2>&1 | tail -1  # what a collection would reclaim
```

## 3. Updating inputs -- expect breakage, verify before switching

`nixpkgs` is pinned at `35d3407` and tracks `nixpkgs-unstable`, so updates are a deliberate
act. As of right now, updating breaks the build: tmux 3.7c in current unstable fails to
configure on darwin (`configure: error: must give --enable-jemalloc or --disable-jemalloc`),
and it isn't in the binary cache.

Always build before switching, so a bad input never touches the running system:

```sh
nix flake update                 # or: nix flake update nixpkgs
nix build --dry-run .#darwinConfigurations.artichoke.system
darwin-rebuild build --flake .   # builds without activating
darwin-rebuild switch --flake .  # only once the build is clean
```

To see what an update would actually change, and to roll the lock back if it goes wrong:

```sh
cp flake.lock flake.lock.bak
nix store diff-closures /run/current-system ./result   # after `darwin-rebuild build`
cp flake.lock.bak flake.lock                           # revert the pin
```

Note that `flake.lock` must stay self-consistent: each node's `original` (what `flake.nix`
asks for) has to match its `locked` (what was fetched). Hand-editing one without the other
makes Nix silently re-resolve *every* input on the next build.

## 4. Someday: `system.stateVersion`

Pinned at `4`; this nix-darwin's default is `7`. It exists for backwards compatibility, so
don't bump it casually -- read the changelog first and expect to migrate state by hand.

```sh
darwin-rebuild changelog
```
