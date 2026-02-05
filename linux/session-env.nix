# Propagate environment to systemd/dbus after rebuild
# Run `refresh-session-env` in a terminal after nixos-rebuild to update launchers
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    ({ config, lib, pkgs, ... }: {
      home.packages = [
        (pkgs.writeShellScriptBin "refresh-session-env" ''
          # Propagate current PATH to systemd/dbus so launchers see it
          ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd PATH
          echo "Session environment updated. Launchers will now use new PATH."
        '')
      ];
    })
  ];
}
