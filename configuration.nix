{ config, pkgs, ... }:

let
  hostName = "${builtins.readFile ./.hostname}";

in {
  imports =
    [
      ./alacritty.nix
      ./autocutsel.nix
      ./docker-gc.nix
      ./docker-nginx-proxy.nix
      ./hardware-configuration.nix
      ./packages.nix
      ./udiskie.nix
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
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

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
   };
  };

  networking = {
    hostName = hostName;
    enableIPv6 = false;
    #wireless.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  services = {
    ipfs.enable = true;
    udisks2.enable = true;
    unclutter-xfixes.enable = true;
    emacs.enable = true;
    offlineimap.enable = true;
    tor.enable = true;
    avahi = {
      enable = true;
      publish.enable = true;
      nssmdns = true;
    };
    openvpn.servers = {
      us = {
        config = '' config /home/avo/.openvpn.conf '';
        autoStart = false;
      };
    };
    redshift = {
      enable = true;
      latitude = "48.85";
      longitude = "2.35";
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
          ${pkgs.sxhkd}/bin/sxhkd &
          ${pkgs.dropbox}/bin/dropbox start &
          ${pkgs.xorg.xrandr} --output DP-4 --auto --primary --output DP-2 --left-of DP-4 --auto --output DP-0 --above DP-4 &
        '';
      };

      windowManager = {
        default = "xmonad";
        xmonad  = {
          enable = true;
          enableContribAndExtras = true;
          extraPackages = haskellPackages: [
            haskellPackages.xmobar
          ];
        };
      };
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
    docker.enable = true;
    libvirtd.enable = true;
  };

  environment.variables = {
    "IPFS_PATH" = "/var/lib/ipfs/.ipfs";
    "LIBVIRT_DEFAULT_URI" = "qemu:///system";
    "EDITOR" = "vim";
  };

  systemd.services = {
    docker-nginx-proxy.enable = true;
    docker-gc.enable = true;
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
    liberation_ttf
    vistafonts
  ];
}
