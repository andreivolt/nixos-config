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
    mac-app-util = {
      url = "github:hraban/mac-app-util/link-contents";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hammerspoon-spoons = {
      url = "github:Hammerspoon/Spoons/3f6bb38a4b1d98ec617e1110450cbc53b15513ec";
      flake = false;
    };
    # Impermanence and disko for NixOS
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland";
    };
    hyprsunset = {
      url = "github:hyprwm/hyprsunset";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      # Don't follow our nixpkgs - uses specific kernel/mesa versions
    };
    lan-mouse = {
      url = "github:feschber/lan-mouse";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    crane.url = "github:ipetkov/crane";
    monolith = {
      url = "git+file:/home/andrei/dev/monolith";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    launcher = {
      url = "git+file:/home/andrei/dev/launcher";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    ff2mpv = {
      url = "github:andreivolt/ff2mpv";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dearrow = {
      url = "github:andreivolt/DeArrow";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    bypass-paywalls = {
      url = "github:andreivolt/bypass-paywalls";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sci-hub-now = {
      url = "github:andreivolt/sci-hub-now";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    ironbar = {
      url = "github:andreivolt/ironbar/window-rewrite";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    impermanence,
    disko,
    hyprland,
    hyprland-plugins,
    hyprgrass,
    hyprsunset,
    nixos-apple-silicon,
    lan-mouse,
    sops-nix,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    rust-overlay,
    crane,
    monolith,
    launcher,
    ff2mpv,
    dearrow,
    bypass-paywalls,
    sci-hub-now,
    nixpak,
    ironbar,
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
        (final: prev: { craneLib = crane.mkLib final; })
        (import "${inputs.self}/pkgs")
        (final: prev: {
          unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system};
          mkPep723Script = mkPep723Script final;
        })
        # PipeWire 1.6.0 + tg_owt + arrow-cpp overlays (commented - wait for nixpkgs-unstable)
        # Fixes: zeroramp plugin, convolver latency for Asahi DSP, tg_owt PipeWire 1.6 API compat
        # Re-enable when nixpkgs-unstable includes PipeWire >= 1.6.0 with updated tg_owt
        # (final: prev: {
        #   pipewire = prev.pipewire.overrideAttrs (old: {
        #     version = "1.6.0";
        #     src = prev.fetchFromGitLab {
        #       domain = "gitlab.freedesktop.org";
        #       owner = "pipewire";
        #       repo = "pipewire";
        #       rev = "1.6.0";
        #       hash = "sha256-Xc5ouBvT8v0hA3lPfCjhCicoem0jk4knevj7LJJipJ4=";
        #     };
        #     mesonFlags = map (flag:
        #       builtins.replaceStrings ["-Dsystemd="] ["-Dlibsystemd="] flag
        #     ) old.mesonFlags ++ [
        #       "-Dbluez5-codec-ldac-dec=disabled"
        #       "-Dbluez5-plc-spandsp=disabled"
        #       "-Donnxruntime=disabled"
        #     ];
        #   });
        # })
        # (final: prev: let
        #   tg_owt_new = prev.callPackage
        #     "${prev.path}/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/tg_owt.nix"
        #     { stdenv = prev.stdenv; };
        #   tg_owt_updated = tg_owt_new.overrideAttrs (old: {
        #     version = "0-unstable-2025-12-12";
        #     src = prev.fetchFromGitHub {
        #       owner = "desktop-app";
        #       repo = "tg_owt";
        #       rev = "d888bc3f79b4aa80333d8903410fa439db5f6696";
        #       hash = "sha256-ZiZ0HD4UNPJj1ZtoGroJRQBYeL/nwpp4B9GtXFcCA7M=";
        #       fetchSubmodules = true;
        #     };
        #   });
        # in {
        #   telegram-desktop = prev.telegram-desktop.override {
        #     unwrapped = prev.telegram-desktop.unwrapped.override {
        #       tg_owt = tg_owt_updated;
        #     };
        #   };
        # })
        # (final: prev: {
        #   arrow-cpp = prev.arrow-cpp.override {
        #     enableS3 = false;
        #     enableAzure = false;
        #   };
        # })
        # Update yt-dlp to fix YouTube live stream HLS 403 errors
        (final: prev: {
          yt-dlp = prev.yt-dlp.overrideAttrs (old: {
            version = "2026.02.04";
            src = prev.fetchFromGitHub {
              owner = "yt-dlp";
              repo = "yt-dlp";
              rev = "2026.02.04";
              hash = "sha256-KXnz/ocHBftenDUkCiFoBRBxi6yWt0fNuRX+vKFWDQw=";
            };
            postPatch = builtins.replaceStrings
              [ "if curl_cffi_version != (0, 5, 10) and not (0, 10) <= curl_cffi_version < (0, 14)" ]
              [ "if curl_cffi_version != (0, 5, 10) and not (0, 10) <= curl_cffi_version < (0, 15)" ]
              old.postPatch;
          });
        })
        # Disable E501 line length check in writers.writePython3
        (final: prev: {
          writers = prev.writers // {
            writePython3 = name: attrOrCode:
              if builtins.isString attrOrCode
              then prev.writers.writePython3 name { flakeIgnore = ["E501"]; } attrOrCode
              else code: prev.writers.writePython3 name (attrOrCode // {
                flakeIgnore = (attrOrCode.flakeIgnore or []) ++ ["E501"];
              }) code;
          };
        })
        # Use lan-mouse from flake (latest with CLI/daemon support) with pointer speed patch
        (final: prev: {
          lan-mouse = inputs.lan-mouse.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [
              ./pkgs/lan-mouse-pointer-speed.patch
            ];
          });
        })
        # Fix batsignal signal handler signature for newer gcc
        (final: prev: {
          batsignal = prev.batsignal.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [
              ./pkgs/batsignal-signal-handler.patch
            ];
          });
        })
        # WasIstLos: tray icon click toggles window visibility
        (final: prev: {
          wasistlos = prev.wasistlos.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [
              ./pkgs/wasistlos-tray-toggle.patch
            ];
          });
        })
        # Fix openssl_1_1 patch after 3.0.19 update (nixpkgs#485055, pending nixos-unstable)
        (final: prev: {
          openssl_1_1 = prev.openssl_1_1.overrideAttrs (oldAttrs: {
            patches = [
              (builtins.elemAt oldAttrs.patches 0) # nix-ssl-cert-file.patch
            ];
            postPatch = (oldAttrs.postPatch or "") + ''
              substituteInPlace include/internal/cryptlib.h \
                --replace-fail 'OPENSSLDIR "/cert.pem"' '"/etc/ssl/certs/ca-certificates.crt"'
            '';
          });
        })
        # Ignore XF86 keys (power button) in hyprlock password input
        (final: prev: {
          hyprlock = prev.hyprlock.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or []) ++ [
              ./linux/hyprland/hyprlock-ignore-xf86.patch
            ];
          });
        })
        # Use ironbar fork with window-rewrite support
        (final: prev: {
          ironbar = inputs.ironbar.packages.${prev.stdenv.hostPlatform.system}.default;
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
        launcher.nixosModules.default
        {
          services.launcher.enable = true;
          systemd.user.services = let ui = import ./shared/ui.nix; fontEnv = {
            LAUNCHER_FONT_SIZE = toString ui.fontSizePx;
            LAUNCHER_FONT_FAMILY = ui.fontFamily;
          }; in {
            launcher.environment = fontEnv;
            clipboard.environment = fontEnv;
          };
        }
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
        launcher.nixosModules.default
        {
          services.launcher.enable = true;
          systemd.user.services = let ui = import ./shared/ui.nix; fontEnv = {
            LAUNCHER_FONT_SIZE = toString ui.fontSizePx;
            LAUNCHER_FONT_FAMILY = ui.fontFamily;
          }; in {
            launcher.environment = fontEnv;
            clipboard.environment = fontEnv;
          };
        }
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
        sops-nix.nixosModules.sops
      ];
      specialArgs = {inherit inputs;};
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
