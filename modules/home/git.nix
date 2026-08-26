# git. Matches the ~/.gitconfig that was on the Mac, which had already drifted
# into agreement with the Linux copy.
{ config, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "James Petersen";
        email = "jpetersenames@gmail.com";
        signingKey = "${config.home.homeDirectory}/.ssh/signing";
      };
      core.editor = "nvim";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgsign = true;
      color.ui = true;
    };
  };
}
