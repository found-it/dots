{
  description = "found-it dotfiles: nix-darwin on macOS, home-manager on Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }:
    let
      username = "james";

      # Standalone home-manager for Linux machines.
      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit username; };
          modules = [ ./home ];
        };

      # nix-darwin for macOS, with home-manager applied as a module so a single
      # `darwin-rebuild switch` configures both the system and the user.
      mkDarwin =
        system:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit username; };
          modules = [
            { nixpkgs.hostPlatform = system; }
            nix-homebrew.darwinModules.nix-homebrew
            ./darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = { inherit username; };
                users.${username} = import ./home;
              };
            }
          ];
        };
    in
    {
      # install.sh selects these by `uname -m`.
      homeConfigurations = {
        "x86_64-linux" = mkHome "x86_64-linux";
        "aarch64-linux" = mkHome "aarch64-linux";
      };

      darwinConfigurations = {
        "mac" = mkDarwin "aarch64-darwin";
      };
    };
}
