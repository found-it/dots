{
  description = "james's nix-darwin and home-manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
    }:
    let
      # Wires home-manager in as a nix-darwin module, so `darwin-rebuild switch`
      # activates both the system and the user environment in one step.
      homeManagerModule = {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users.james = import ./modules/home;
          backupFileExtension = "hm-bak";
        };
      };
    in
    {
      # macOS. $ darwin-rebuild switch --flake .#artichoke
      darwinConfigurations."artichoke" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit self inputs; };
        modules = [
          ./hosts/artichoke.nix
          home-manager.darwinModules.home-manager
          homeManagerModule
        ];
      };

      # Linux hosts, where we don't own the system.
      # $ home-manager switch --flake .#james
      homeConfigurations."james" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./modules/home ];
      };

      # $ nix fmt
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
