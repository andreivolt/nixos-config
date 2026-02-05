# Merges extension packages into a single --load-extension flag and
# wires up native messaging hosts automatically.
{ config, lib, ... }:
let
  cfg = config.chromium;
in {
  imports = [
    ./extensions.nix
    ./flags.nix
  ];

  options.chromium.extensions = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
    description = ''
      Chromium extension packages. Each must provide share/chromium-extension/.
      Packages with etc/chromium/native-messaging-hosts/ get native messaging wired up automatically.
    '';
  };

  config.home-manager.users.andrei.programs.chromium = lib.mkIf (cfg.extensions != []) {
    commandLineArgs =
      let paths = lib.concatStringsSep "," (map (pkg: "${pkg}/share/chromium-extension") cfg.extensions);
      in [ "--load-extension=${paths}" ];

    nativeMessagingHosts = cfg.extensions;
  };
}
