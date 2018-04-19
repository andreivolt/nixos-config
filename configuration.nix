{ config, pkgs, ... }:

let
  hostName = "${builtins.readFile ./.hostname}";

  overlays =
    let path = "/etc/nixos/overlays"; content = builtins.readDir path; in
      map (n: import (path + ("/" + n)))
          (builtins.filter (n: builtins.match ".*\\.nix" n != null)
                           (builtins.attrNames content));

in {
  imports =
    [
      ./hardware-configuration.nix
      ./packages.nix

      ./autocutsel.nix
      ./docker-nginx-proxy.nix
      ./udiskie.nix
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Paris";

  i18n = {
    consoleKeyMap = "fr";
    defaultLocale = "en_US.UTF-8";
  };

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs = {
    overlays = overlays;
    config.allowUnfree = true;
  };

  hardware = {
    bluetooth.enable = true;

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
   };
  };

  networking = {
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = hostName;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "webkitgtk-2.4.11"
  ];

  services = {
    ipfs.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = [ pkgs.mopidy-gmusic ];
      configuration = ''
        [gmusic]
        username = username
        password = "${builtins.readFile /home/avo/.google-passwd.txt}";
        bitrate = 320
      '';
    };

    udisks2.enable = true;

    unclutter-xfixes.enable = true;

    emacs.enable = true;

    offlineimap.enable = true;

    tor.client.enable = true;

    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    openvpn.servers = {
      us = {
        config = '' config /home/avo/.openvpn.conf '';
        autoStart = false;
      };
    };

    xserver = {
      enable = true;

      videoDrivers = [ "nvidia" ];

      xkbOptions = "ctrl:nocaps";

      layout = "fr";

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      displayManager = {
        lightdm = {
          enable = true;
          autoLogin = { enable = true; user = "avo"; };
        };
        sessionCommands = with pkgs; ''
          xrandr --output DP-4 --auto --primary --output DP-2 --left-of DP-4 --auto --output DP-0 --above DP-4 &
          #nvidia-settings --assign CurrentMetaMode='
          #  DP-0: nvidia-auto-select +3840+0 {ForceCompositionPipeline=On},
          #  DP-2: nvidia-auto-select +0+2160 {ForceCompositionPipeline=On},
          #  DP-4: nvidia-auto-select +3840+2160 {ForceCompositionPipeline=On}
          #' &
          xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 42 &
          dropbox start &
        '';
      };
    };

    compton = {
      enable = true;
      shadow = true;
      shadowOffsets = [ (-20) (-20) ];
      shadowOpacity = "0.9";
      shadowExclude = [
        ''!focused && !(_NET_WM_WINDOW_TYPE@[0]:a = "_NET_WM_WINDOW_TYPE_DIALOG") && !(_NET_WM_STATE@[0]:a = "_NET_WM_STATE_MODAL")''
      ];
      extraOptions = ''
        blur-background = true;
        blur-background-frame = true;
        blur-background-fixed = true;
        blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
        clear-shadow = true;
      '';
    };

    printing = {
      enable = true;
      clientConf = ''
        <Printer default>
          UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
          Info DCPL2520DW
          MakeModel everywhere
          DeviceURI ipp://192.168.1.15/ipp/print
        </Printer>
      '';
    };

    dnsmasq = {
      enable = true;
      servers = ["8.8.8.8" "8.8.4.4"];

      extraConfig = ''
        address=/test/127.0.0.1
      '';
    };

    openssh.enable = true;
  };

  users.users.avo = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "adbusers"
      "docker"
      "ipfs"
      "libvirtd"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2lzQAHzKnmiCQ9Ocb2PTMAQH9HR2x7KO7SV+og2a1nRH+T9bfQjgMW7SuPFbPN7Y4SoAgeBo+FFy7EczxyB7BW+z0u8uHlTJkQ4M1jmj5CQxdkuY/JLkbfJGhSw4eB4iJL7hhxwPvME9DgvdfN4ncxQZWiwrS0diLmydtUXcrEq1uqcaaTijJRADQpTxGUoEi9gNQDCHOWpPfKWAr6APS34MfWAfrc97n862xSPmwHFuCKuHG7WBzBhCSEPCFAI/mo+Wf9L6KWgz0jRRdwCPkMAxoYHmfZZqqRyoILr9CGKSFaN57kJevTMHDzoQgEskMS5Ln3qyFPvggpWWfGODL avo@watts"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    docker = {
      enable = true;
      extraOptions = "--experimental";
      autoPrune.enable = true;
    };

    libvirtd.enable = true;
  };

  environment.variables = {
    "IPFS_PATH" = "/var/lib/ipfs/.ipfs";
    "LIBVIRT_DEFAULT_URI" = "qemu:///system";
  };

  # cursor
  environment.etc."X11/Xresources".text = ''
      Xcursor.theme: Adwaita
      Xcursor.size: 42
  '';

  programs = {
    adb.enable = true;

    ssh.extraConfig = ''
      Host *
        ControlMaster auto
        ControlPersist 0
        ControlPath /tmp/ssh-%C
    '';

    zsh = {
      enable = true;
      enableCompletion = true;
    };
  };

  fonts = {
    fontconfig.ultimate.enable = false;
    enableCoreFonts = true;
    fonts = with pkgs; [
      google-fonts
      vistafonts
      input-fonts
    ];
  };

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';

  # cursor
  environment.profileRelativeEnvVars.XCURSOR_PATH = [ "/share/icons" ];
  environment.sessionVariables.GTK_PATH = "${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0";

  # libvirt
  networking.bridges = { br0 = { interfaces = [ "enp0s31f6" ]; }; };
}
