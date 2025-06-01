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
    hammerspoon-spoons = {
      url = "github:Hammerspoon/Spoons/3f6bb38a4b1d98ec617e1110450cbc53b15513ec";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    mac-app-util,
    hammerspoon-spoons,
  }: {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.overlays = [
            (import "${inputs.self}/pkgs")
            (final: prev: {
              unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
            })
          ];

          networking.hostName = "mac";
          system.stateVersion = 4;
          system.primaryUser = "andrei";
          nix.enable = false; # using Determinate Nix
        }
        "${inputs.self}/darwin"
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
      ];
      specialArgs = {inherit inputs;};
    };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowBroken = true;
          nixpkgs.config.permittedInsecurePackages = [
            "openssl-1.1.1w"
            "python3.12-youtube-dl-2021.12.17"
          ];
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.overlays = [
            (import "${inputs.self}/pkgs")
            (final: prev: {
              unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
            })
          ];
        }
        "${inputs.self}/linux"
        home-manager.nixosModules.home-manager
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
