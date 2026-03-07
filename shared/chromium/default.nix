# Chromium extension management:
# - extensions: self-contained packages with signed CRX (persistent across restarts)
# - loadExtensions: --load-extension flag (transient, reloaded every launch)
{ config, lib, pkgs, ... }:
let
  cfg = config.chromium;
  chromeExtensionIds = import ./chrome-extensions.nix;

in {
  imports = [
    ./extensions.nix
    ./flags.nix
  ];

  options.chromium = {
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extensions installed as signed CRX (persistent).";
    };

    loadExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extensions loaded via --load-extension (transient).";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.extensions != []) {
      environment.systemPackages = cfg.extensions;
      environment.pathsToLink = [ "/share/chromium/extensions" ];
      home-manager.users.andrei.programs.chromium.nativeMessagingHosts = cfg.extensions;
    })

    {
      programs.chromium.enable = true;
      programs.chromium.extensions = chromeExtensionIds;
    }

    (lib.mkIf (cfg.loadExtensions != []) {
      home-manager.users.andrei.programs.chromium = {
        commandLineArgs =
          let paths = lib.concatStringsSep "," (map (pkg: "${pkg}/share/chromium-extension") cfg.loadExtensions);
          in [ "--load-extension=${paths}" ];
        nativeMessagingHosts = cfg.loadExtensions;
      };
    })
  ];
}
