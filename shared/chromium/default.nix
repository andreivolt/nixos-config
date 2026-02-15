# Chromium extension management:
# - extensions: signed CRX via external extension mechanism (persistent across restarts)
# - loadExtensions: --load-extension flag (transient, reloaded every launch)
{ config, lib, pkgs, ... }:
let
  cfg = config.chromium;

  packCrx = { package, key }:
    let
      pname = package.pname or "chromium-extension";
      extDir = "${package}/share/chromium-extension";
      manifest = builtins.fromJSON (builtins.readFile "${extDir}/manifest.json");
      version = manifest.version;

      extId = builtins.readFile (pkgs.runCommand "${pname}-id" {
        nativeBuildInputs = [ pkgs.python3 pkgs.openssl ];
      } ''
        python3 ${./crx-id.py} ${key} > $out
      '');

      crx = pkgs.runCommand "${pname}-crx" {
        nativeBuildInputs = [ pkgs.python3 pkgs.openssl ];
      } ''
        mkdir -p $out/share/chromium-extension
        python3 ${./pack-crx3.py} ${extDir} ${key} $out/share/chromium-extension/${pname}.crx
      '';
    in pkgs.writeTextDir "share/chromium/extensions/${extId}.json" (builtins.toJSON {
      external_crx = "${crx}/share/chromium-extension/${pname}.crx";
      external_version = version;
    });

in {
  imports = [
    ./extensions.nix
    ./flags.nix
  ];

  options.chromium = {
    extensions = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          package = lib.mkOption { type = lib.types.package; };
          key = lib.mkOption { type = lib.types.path; };
        };
      });
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
      environment.systemPackages = map packCrx cfg.extensions;
      environment.pathsToLink = [ "/share/chromium/extensions" ];
      home-manager.users.andrei.programs.chromium.nativeMessagingHosts =
        map (ext: ext.package) cfg.extensions;
    })

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
