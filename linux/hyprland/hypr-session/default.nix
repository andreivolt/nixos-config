{ config, lib, pkgs, hyprlandPkgs, ... }:

let
  hyprSession = pkgs.rustPlatform.buildRustPackage {
    pname = "hypr-session";
    version = "0.1.0";
    src = ./.;
    cargoLock.lockFile = ./Cargo.lock;
  };
in {
  systemd.user.services.hypr-session-watch = {
    Unit = {
      Description = "Hyprland session watcher";
      After = [ "hyprland-session.target" "hypr-session-restore.service" ];
      BindsTo = [ "hyprland-session.target" ];
    };
    Service = {
      Environment = "PATH=${lib.makeBinPath [ pkgs.kitty hyprlandPkgs.hyprland ]}:/run/current-system/sw/bin";
      ExecStart = "${hyprSession}/bin/hypr-session watch";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.hypr-session-restore = {
    Unit = {
      Description = "Restore Hyprland session";
      After = [ "hyprland-session.target" ];
      Wants = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=${lib.makeBinPath [ pkgs.kitty hyprlandPkgs.hyprland ]}:/run/current-system/sw/bin";
      ExecStart = "${hyprSession}/bin/hypr-session restore";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  home.file.".local/bin/hypr-session".source = "${hyprSession}/bin/hypr-session";
}
