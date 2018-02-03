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

  nixpkgs.config = {
    packageOverrides = pkgs: rec {
      st = pkgs.stdenv.lib.overrideDerivation pkgs.st (oldAttrs : {
          configFile = ''
          static const char *colorname[] = {

          /* 8 normal colors */
          [0] = "#3c3e42", /* black   */
          [1] = "#dd6880", /* red     */
          [2] = "#83b879", /* green   */
          [3] = "#dec790", /* yellow  */
          [4] = "#95b5e4", /* blue    */
          [5] = "#c1a3e0", /* magenta */
          [6] = "#64c1d4", /* cyan    */
          [7] = "#9a9da3", /* white   */

          /* 8 bright colors */
          [8]  = "#4f5558", /* black   */
          [9]  = "#de889a", /* red     */
          [10] = "#99c490", /* green   */
          [11] = "#e7d09a", /* yellow  */
          [12] = "#a0beea", /* blue    */
          [13] = "#cbacea", /* magenta */
          [14] = "#88d1df", /* cyan    */
          [15] = "#b4b7bb", /* white   */

          /* special colors */
          [256] = "#212121", /* background */
          [257] = "#aeb1b7", /* foreground */
          };

          /*
           * default colors (colorname index)
           * foreground, background, cursor
           */
          static unsigned int defaultfg = 257;
          static unsigned int defaultbg = 256;
          static unsigned int defaultcs = 257;

          /*
           * colors used, when the specific fg == defaultfg. so in reverse mode this
           * will reverse too. another logic would only make the simple feature too
           * complex.
           */
          static unsigned int defaultitalic = 7;
          static unsigned int defaultunderline = 7;

          static char font[] = "GohuFont:pixelsize=12:antialias=false";
          '';
      });
    };
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
    networks = { };
  };

  networking.firewall.allowedTCPPorts = [
    80 443
    10000
    9999
    19000 19001
  ];

}
