{
  description = "My Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.url = "github:hraban/mac-app-util/link-contents";
    hammerspoon-spoons = {
      url = "github:Hammerspoon/Spoons/3f6bb38a4b1d98ec617e1110450cbc53b15513ec";
      flake = false;
    };
    json2nix = {
      url = "github:sempruijs/json2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Impermanence and disko for NixOS
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned for hyprland-plugins compatibility (7e1e24f from Nov 27 - last known working)
    hyprland = {
      url = "github:hyprwm/Hyprland/7e1e24fea615503a3cc05218c12b06c1b6cabdc7";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/84659a2502df6b2fd245441c16a8365f5e1cd16d";
      inputs.hyprland.follows = "hyprland";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      # Don't follow our nixpkgs - use their tested version
    };
    lan-mouse = {
      url = "github:feschber/lan-mouse";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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
    json2nix,
    impermanence,
    disko,
    hyprland,
    hyprland-plugins,
    nixos-apple-silicon,
    lan-mouse,
    nix-on-droid,
    sops-nix,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    rust-overlay,
  }:
  let
    # Helper to build PEP-723 inline scripts using uv2nix
    # Creates a virtualenv at build time - no uv needed at runtime
    mkPep723Script = pkgs: scriptPath:
      let
        script = uv2nix.lib.scripts.loadScript { script = scriptPath; };
        baseSet = pkgs.callPackage pyproject-nix.build.packages {
          python = pkgs.python3;
        };
        overlay = script.mkOverlay { sourcePreference = "wheel"; };
        pythonSet = baseSet.overrideScope (
          pkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay
          ]
        );
        venv = script.mkVirtualEnv { inherit pythonSet; };
      in
        pkgs.writeScriptBin (pkgs.lib.removeSuffix ".py" (baseNameOf scriptPath))
          (script.renderScript { inherit venv; });

    commonNixpkgsConfig = {
      config.allowUnfree = true;
      overlays = [
        rust-overlay.overlays.default
        (import "${inputs.self}/pkgs")
        (final: prev: {
          unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
          json2nix = inputs.json2nix.packages.${prev.stdenv.hostPlatform.system}.default;
          mkPep723Script = mkPep723Script final;
        })
        # Use lan-mouse from flake (latest with CLI/daemon support) with pointer speed patch
        (final: prev: {
          lan-mouse = inputs.lan-mouse.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [
              ./pkgs/lan-mouse-pointer-speed.patch
            ];
          });
        })
      ];
    };
  in {
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs = commonNixpkgsConfig // {
            hostPlatform = "aarch64-darwin";
          };

          networking.hostName = "mac";
          system.stateVersion = 4;
          system.primaryUser = "andrei";
          nix.enable = false; # using Determinate Nix
        }
        "${inputs.self}/hosts/mac"
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
        sops-nix.darwinModules.sops
      ];
      specialArgs = {inherit inputs;};
    };

    nixosConfigurations.watts = nixpkgs-unstable.lib.nixosSystem {
      modules = [
        {
          nixpkgs = commonNixpkgsConfig // {
            hostPlatform = "x86_64-linux";
            config = commonNixpkgsConfig.config // {
              allowBroken = true;
              permittedInsecurePackages = [
                "openssl-1.1.1w"
                "python3.12-youtube-dl-2021.12.17"
              ];
            };
          };

          # Configure the disk device for this machine
          # Change this to match your actual disk (e.g., /dev/sda, /dev/nvme0n1, etc.)
          nixos.diskDevice = "/dev/nvme0n1";
        }
        "${inputs.self}/hosts/watts"
        home-manager.nixosModules.home-manager
        hyprland.nixosModules.default
        sops-nix.nixosModules.sops
      ];
      specialArgs = {inherit inputs;};
    };

    # Use nixpkgs-unstable for riva (Apple Silicon) to match nixos-apple-silicon expectations
    nixosConfigurations.riva = nixpkgs-unstable.lib.nixosSystem {
      modules = [
        {
          nixpkgs.hostPlatform = "aarch64-linux";
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "openssl-1.1.1w"
          ];
          nixpkgs.overlays = [
            nixos-apple-silicon.overlays.default
          ] ++ commonNixpkgsConfig.overlays;
        }
        nixos-apple-silicon.nixosModules.apple-silicon-support
        "${inputs.self}/hosts/riva"
        home-manager.nixosModules.home-manager
        hyprland.nixosModules.default
        sops-nix.nixosModules.sops
      ];
      specialArgs = {inherit inputs;};
    };

    # Oracle Cloud Infrastructure (OCI) free tier server - Headscale
    nixosConfigurations.ampere = nixpkgs-unstable.lib.nixosSystem {
      modules = [
        {
          nixpkgs = commonNixpkgsConfig // {
            hostPlatform = "x86_64-linux";
          };
        }
        "${inputs.self}/hosts/ampere"
        home-manager.nixosModules.home-manager
      ];
      specialArgs = {inherit inputs;};
    };

    # Android phone via nix-on-droid
    nixOnDroidConfigurations.phone = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs-unstable {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = commonNixpkgsConfig.overlays;
      };
      modules = [
        "${inputs.self}/hosts/phone"
      ];
      extraSpecialArgs = {inherit inputs;};
    };

    # Dev shells for Rust packages
    devShells = let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in forAllSystems (system: let
      pkgs = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      rust = pkgs.mkShell {
        buildInputs = with pkgs; [
          cargo
          rustc
          rust-analyzer
          pkg-config
          alsa-lib
          openssl
        ];
      };
    });
  };
}
