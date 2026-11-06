{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage. On macOS these are also derived from nix-darwin's users.users.
  home.username = lib.mkDefault username;
  home.homeDirectory = lib.mkDefault (if isDarwin then "/Users/${username}" else "/home/${username}");

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    unzip
    fzf
    hello
    ripgrep
    eza
    yq
    jq
    bat
    tmux
    wget
    k3d
    fd
    opentofu
    crane
    shellcheck
    shfmt
    zizmor

    # Kubernetes
    kubectl
    kubectx
    kubecolor
    kubernetes-helm
    chart-testing
    stern
    watch
    eksctl

    # Languages
    nodejs
    go
    rustup
    protobuf
    python3

    # Client-y Things
    awscli2
    github-cli
    go-task
    tailscale
    lefthook

    # neovim
    neovim
    lazygit
    luarocks
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".tmux.conf".source = ./tmux/tmux.conf;
  };

  # Link straight to the repo checkout (~/.dots, created by install.sh) rather
  # than the read-only nix store, so LazyVim can write lazy-lock.json and
  # lazyvim.json, and edits take effect without a rebuild.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/home/nvim";

  # Ghostty is installed as a Homebrew cask on macOS (see darwin/default.nix).
  xdg.configFile."ghostty/config.ghostty" = lib.mkIf isDarwin {
    source = ./ghostty/config.ghostty;
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;

    shellAliases = {
      # Single letters
      n = "nerdctl";
      c = "chainctl";
      k = "kubecolor";
      p = "sudo protect";

      # Kubernetes
      kc = "kubecolor";
      wk = "watch -c kubecolor --force-colors";
      kim = "kubectl get pods -o custom-columns=CONTAINER:.spec.containers[0].name,IMAGE:.spec.containers[0].image";

      # File listing
      ls = "eza --icons=always";
      lsg = "eza --long --header --icons=always --git";
      lst = "eza --icons=always --tree";
      lsi = "eza --icons=always --long --octal-permissions --header";
      cat = "bat -p";
      dsh = "docker run -it --entrypoint sh";
    };

    # macOS's path_helper (run from /etc/profile-style login setup) pushes
    # /usr/bin ahead of nix paths; move the nix profiles back to the front.
    loginShellInit = lib.optionalString isDarwin ''
      fish_add_path --move --prepend --path \
        /etc/profiles/per-user/$USER/bin \
        /run/current-system/sw/bin \
        /nix/var/nix/profiles/default/bin
    '';

    interactiveShellInit = ''
      fish_add_path $HOME/.local/bin

      # TODO: Use GOPATH or GOBIN
      fish_add_path $HOME/go/bin

      # The next line updates PATH for the Google Cloud SDK.
      if test -f $HOME/.google-cloud-sdk/path.fish.inc
          source $HOME/.google-cloud-sdk/path.fish.inc
      end
    '';
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "James Petersen";
        email = "jpetersenames@gmail.com";
        signingKey = "${config.home.homeDirectory}/.ssh/signing";
      };
      core = {
        editor = "nvim";
      };
      push = {
        autoSetupRemote = true;
      };
      gpg = {
        format = "ssh";
      };
      commit = {
        gpgsign = true;
      };
    };
  };
}
