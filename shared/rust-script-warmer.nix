{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isLinux isDarwin;
in
lib.mkMerge [
  (lib.mkIf isDarwin {
    launchd.agents.rust-script-warmer = {
      enable = true;
      config = {
        ProgramArguments = [ "/Users/andrei/bin/rust-script-warmer" ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        StandardOutPath = "/Users/andrei/Library/Logs/rust-script-warmer.log";
        StandardErrorPath = "/Users/andrei/Library/Logs/rust-script-warmer.error.log";
        EnvironmentVariables = {
          PATH = "/run/current-system/sw/bin:/usr/bin:/bin";
        };
      };
    };
  })
  
  (lib.mkIf isLinux {
    systemd.user.services.rust-script-warmer = {
      Unit.Description = "Rust Script Cache Monitor";
      Service = {
        ExecStart = "/home/andrei/bin/rust-script-warmer";
        Restart = "always";
      };
      Install.WantedBy = [ "default.target" ];
    };
  })
]