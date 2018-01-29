{ config, pkgs, ... }:

{
  programs.ssh = {
    knownHosts."megawatts" = {
      hostNames = [ "avolt.net" "megawatts" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlooYqJvZZE0jfosalHpNJpjgnTzeDiUuFwvLPG0ejC";
    };
    extraConfig = ''
      Host *
        ControlMaster auto
        ControlPersist 0
        ControlPath /tmp/ssh-%C
    '';
  };
}
