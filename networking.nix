{ config, ... }:

let credentials = import ./credentials.nix;
in {
  networking = {
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = builtins.getEnv "HOST";
  };

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    openvpn.servers = {
      us = {
        config = "config ${config.users.users.avo.home}/.config/openvpn/conf";
        autoStart = false;
        authUserPass = with credentials.openvpn; { inherit username password; };
      };
    };

    openssh.enable = true;

    tor.client.enable = true;

    zerotierone.enable = true;

    dnsmasq = {
      enable = true;
      servers = ["8.8.8.8" "8.8.4.4"];

      extraConfig = ''
        address=/test/127.0.0.1
      '';
    };
  };

  users.users.avo
    .openssh.authorizedKeys.keyFiles = [ ./avo.pub ];

  home-manager.users.avo.home.sessionVariables
    .SSH_AUTH_SOCK = "${config.home-manager.users.avo.xdg.configHome}/gnupg/S.gpg-agent.ssh";

  home-manager.users.avo.programs.ssh = {
    enable = true;

    controlMaster  = "auto";
    controlPath    = "/tmp/ssh-%u-%r@%h:%p";
    controlPersist = "0";
  };

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';
}
