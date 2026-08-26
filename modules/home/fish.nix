# fish, merged from the two hand-maintained config.fish copies. The Mac-only
# blocks (Homebrew, Secretive's SSH agent, the Google Cloud SDK) used to be the
# entire diff between them, and are now conditional instead of forked.
{ pkgs, lib, ... }:
{
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
      ls = "eza --icons";
      lsg = "eza --long --header --icons --git";
      lst = "eza --icons --tree";
      lsi = "eza --icons --long --octal-permissions --header";
      cat = "bat -p";

      # Misc
      cm = "cargo make";
      dsh = "docker run -it --entrypoint sh";
      broccoli = "ssh james@broccoli";
    };

    interactiveShellInit = ''
      fish_add_path $HOME/.local/bin

      # TODO: Use GOPATH or GOBIN
      fish_add_path $HOME/go/bin

      if command -q starship
          starship init fish | source
      end
    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''

      if test -x /opt/homebrew/bin/brew
          eval (/opt/homebrew/bin/brew shellenv)
      end

      set -x SSH_AUTH_SOCK $HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

      # The next line updates PATH for the Google Cloud SDK.
      if test -f $HOME/.google-cloud-sdk/path.fish.inc
          source $HOME/.google-cloud-sdk/path.fish.inc
      end
    '';
  };

  # Was living only on the Mac, untracked, until now.
  xdg.configFile."starship.toml".source = ../../config/starship.toml;
}
