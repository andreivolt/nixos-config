{
  description = "My Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.url = "github:hraban/mac-app-util/link-contents";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    mac-app-util,
  }: {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs.overlays = [
            (import "${inputs.self}/pkgs")
            (final: prev: {
              unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
            })
          ];
        }
        "${inputs.self}/darwin-configuration.nix"
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
      ];
      specialArgs = {inherit inputs;};
    };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [
            (import "${inputs.self}/pkgs")
            (final: prev: {
              unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
            })
          ];
        }
        "${inputs.self}/configuration.nix"
        home-manager.nixosModules.home-manager
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
