# SSH client configuration for home-manager
{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  hostname = config.networking.hostName or "";
  isLinuxWorkstation = !isDarwin && (hostname == "riva" || hostname == "watts");
in {
  home-manager.sharedModules = [{
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = lib.optionals isDarwin [ "~/.orbstack/ssh/config" ];
      matchBlocks = {
        "*" = {
          compression = true;
        };
      } // lib.optionalAttrs isLinuxWorkstation {
        phone = {
          hostname = "phone";
          user = "u0_a779";
          port = 8022;
        };
      };
    };

    home.activation.fixSshConfigPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -L "$HOME/.ssh/config" ]; then
        $DRY_RUN_CMD cp --remove-destination "$(readlink "$HOME/.ssh/config")" "$HOME/.ssh/config"
        $DRY_RUN_CMD chmod 600 "$HOME/.ssh/config"
      fi
    '';
  }];
}
