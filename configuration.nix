{ config, pkgs, ... }:

let
  hostName = "${builtins.readFile ./.hostname}";

in {
  imports =
    [
      ./hardware-configuration.nix
      ./packages.nix

      ./alacritty.nix
      ./autocutsel.nix
      ./docker-nginx-proxy.nix
      ./udiskie.nix
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "kernel.core_pattern" = "|/run/current-stystem/sw/bin/false";
  };

  #boot.kernelParams = [ "intel_iommu=on" ];
  #boot.kernelModules = [
  #  "vfio"
  #  "vfio_pci"
  #  "vfio_iommu_type1"
  #];
  #boot.extraModprobeConfig = "options vfio-pci ids=8086:a12f";

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

  nixpkgs.config = {
    allowUnfree = true;

    zathura.useMupdf = true;
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
    hosts = { "127.0.0.1" = [ hostName ]; };
    #wireless.enable = true;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "webkitgtk-2.4.11"
  ];

  services = {
    ipfs.enable = true;

    udisks2.enable = true;

    unclutter-xfixes.enable = true;

    emacs = {
      enable = true;
      package = pkgs.emacs.override { withXwidgets = true; };
    };

    offlineimap.enable = true;

    tor.enable = true;

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

    redshift = {
      enable = true;
      latitude = "48.85"; longitude = "2.35";
      temperature.night = 4000;
    };

    xserver = {
      enable = true;

      videoDrivers = [ "nvidia" ];

      layout = "fr";

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      displayManager = {
        auto = {
          enable = true;
          user = "avo";
        };
        sessionCommands = ''
          /run/current-system/sw/bin/nvidia-settings --assign CurrentMetaMode='\
            DP-0: nvidia-auto-select +3840+0 {ForceCompositionPipeline=On},\
            DP-2: nvidia-auto-select +0+2160 {ForceCompositionPipeline=On},\
            DP-4: nvidia-auto-select +3840+2160 {ForceCompositionPipeline=On},\
          '
          ${pkgs.xorg.xrandr} --output DP-4 --auto --primary --output DP-2 --left-of DP-4 --auto --output DP-0 --above DP-4 &
          ${pkgs.sxhkd}/bin/sxhkd &
          ${pkgs.dropbox}/bin/dropbox start &
        '';
      };

      windowManager = {
        default = "xmonad";
        xmonad  = {
          enable = true;
          enableContribAndExtras = true;
        };
      };
    };
    compton = {
      enable = true;
      extraOptions = ''
        blur-background = true;
        blur-background-frame = true;
        blur-background-fixed = true;
        blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
      '';
      shadow = true;
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
      "${builtins.readFile ./ssh-keys/avo.pub}"
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
    "EDITOR" = "vim";
  };

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

  #fonts.fontconfig.ultimate.enable = false;
  fonts.fonts = with pkgs; [
    corefonts
    google-fonts
    vistafonts
    input-fonts
  ];

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';

  networking.bridges = { br0 = { interfaces = [ "enp0s31f6" ]; }; };
}
