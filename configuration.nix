{ config, pkgs, ... }:

let
  hostName = "${builtins.readFile ./.hostname}";

in {
  imports =
    [
      (./hosts + "/${hostName}.nix")
      ./dnsmasq.nix
      ./docker.nix
      ./hardware-configuration.nix
      ./ipfs.nix
      ./libvirt.nix
      ./packages.nix
      ./ssh.nix
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
  };

  time.timeZone = "Europe/Paris";

  i18n = {
    consoleKeyMap = "fr";
    defaultLocale = "en_US.UTF-8";
  };

  system = {
    stateVersion = "18.03";
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  nixpkgs.config.allowUnfree = true;

  users.users.avo = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "adbusers"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "${builtins.readFile ./ssh-keys/avo.pub}"
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  environment.variables."EDITOR" = "vim";

  security.sudo.wheelNeedsPassword = false;

  services.offlineimap.enable = true;

  services.tor = {
    enable = true;
    torsocks.enable = true;
  };

  networking.hostName = hostName;

  environment.etc."/tsocks.conf".text = ''
    server = 127.0.0.1
    server_port = 19999
    server_type = 5
  '';

  services.avahi = {
    enable = true;
    publish.enable = true;
    nssmdns = true;
  };

  fonts.fontconfig.ultimate.enable = false;

  fonts.fonts = with pkgs; [
    corefonts
    google-fonts
    liberation_ttf
    vistafonts
  ];

  networking.wireless = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [
    80 443
    10000
    9999
    19000 19001
  ];

}
