{
  description = "My Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.url = "github:hraban/mac-app-util/link-contents";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    mac-app-util,
  }: {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        ./darwin-configuration.nix
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
