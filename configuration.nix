{ config, pkgs, ... }:

let
  hostName = "${builtins.readFile ./.hostname}";

  wsta = pkgs.callPackage ./packages/wsta.nix {};

  emacs26 = with pkgs; stdenv.lib.overrideDerivation
    (emacs25.override { srcRepo = true; }) (attrs: rec {
      name = "emacs-${version}${versionModifier}";
      version = "26.0";
      versionModifier = ".90";

      buildInputs = emacs25.buildInputs ++
        [ git libpng.dev libjpeg.dev libungif libtiff.dev librsvg.dev
          imagemagick.dev ];

      patches = lib.optionals stdenv.isDarwin
        [ ./emacs/patches/at-fdcwd.patch
          ./emacs/patches/emacs-26.patch ];

      CFLAGS = "-Ofast -momit-leaf-frame-pointer -DMAC_OS_X_VERSION_MAX_ALLOWED=101200";

      src = fetchgit {
        url = https://git.savannah.gnu.org/git/emacs.git;
        rev = "aa40014ba373ac633b118dc63647f323ef0cedb5";
        sha256 = "1asv0m76phm9hm22wnknsrkp1hgxw5cmm8fk2d2iyar9mcw29c0n";
      };

      postPatch = ''
        rm -fr .git
      '';

      postInstall = ''
        mkdir -p $out/share/emacs/site-lisp
        rm -rf $out/var
        rm -rf $out/share/emacs/${version}/site-lisp
        for srcdir in src lisp lwlib ; do
          dstdir=$out/share/emacs/${version}/$srcdir
          mkdir -p $dstdir
          find $srcdir -name "*.[chm]" -exec cp {} $dstdir \;
          cp $srcdir/TAGS $dstdir
          echo '((nil . ((tags-file-name . "TAGS"))))' > $dstdir/.dir-locals.el
        done
      '' + lib.optionalString stdenv.isDarwin ''
        mkdir -p $out/Applications
        mv nextstep/Emacs.app $out/Applications
      '';
    });

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

  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs.config = {
    allowUnfree = true;

    #overlays = [ (self: super: {
    #  openssh = super.openssh.override { hpnSupport = true; withKerberos = true; kerberos = self.libkrb5; };
    #  };
    #) ];

    #chromium.enableWideVine = true;

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
      package = emacs26;
    };

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

      layout = "fr";

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      displayManager = {
        lightdm = {
          enable = true;
          autoLogin.user = "avo";
          autoLogin.enable = true;
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
      shadow = true;
      shadowOffsets = [ (-20) (-20) ];
      shadowOpacity = "0.9";
      shadowExclude = [
        "i:e:xmobar"
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
  };

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
    fonts = with pkgs; [
      corefonts
      google-fonts
      vistafonts
      input-fonts
    ];
  };

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';

  environment.profileRelativeEnvVars.XCURSOR_PATH = [ "/share/icons" ];
  environment.sessionVariables.GTK_PATH = "${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0";

  networking.bridges = { br0 = { interfaces = [ "enp0s31f6" ]; }; };
}
