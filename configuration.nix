{ config, pkgs, ... }:

let
  hostName = "${builtins.getEnv "HOST"}";

  theme = import ./challenger-deep-theme.nix;

  overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null ||
                    pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

in {
  imports =
    [
      ./hardware-configuration.nix
      ./packages.nix

      ./docker-nginx-proxy.nix

      "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
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
    consoleUseXkbConfig = true;
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

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  services = {
    ipfs.enable = true;

    devmon.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = [ pkgs.mopidy-gmusic ];
      configuration = ''
        [gmusic]
        deviceid = 0123456789abcdef
        username = andreivolt
        password = ${builtins.readFile /home/avo/.google-passwd.txt}
        bitrate = 320
      '';
    };

    bitlbee = {
      enable = true;
      libpurple_plugins = with pkgs; [ telegram-purple ];
    };

    zerotierone.enable = true;

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
        config = '' config /home/avo/.config/openvpn/conf '';
        autoStart = false;
      };
    };

    xserver = {
      enable = true;

      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;

      #dpi = 276;

      videoDrivers = [ "nvidia" ];

      xkbOptions = "ctrl:nocaps";

      layout = "fr";

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      xrandrHeads = [
        {
          output = "DP-2";
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +2160+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotation=left}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
        {
          output = "DP-4";
          primary = true;
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +3840+2160 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotation=left}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
        {
          output = "DP-0";
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +3840+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
      ];

      windowManager = {
        default = "xmonad";
        xmonad  = {
          enable = true;
          enableContribAndExtras = true;
        };
      };

      desktopManager.xterm.enable = false;

      displayManager = {
        auto = {
          enable = true;
          user = "avo";
        };
        sessionCommands = with pkgs; ''

          export XDG_CACHE_HOME=~/.cache
          export QT_AUTO_SCREEN_SCALE_FACTOR=1

          ${xorg.xrdb}/bin/xrdb -merge -I$HOME ~/.Xresources

          ~/.local/bin/xmonad &
        '';
      };
    };

    compton = {
      enable = true;
      shadow = true;
      shadowOffsets = [ (-15) (-5) ];
      shadowOpacity = "0.8";
      # shadowExclude = [
      #   ''
      #     !(XMONAD_FLOATING_WINDOW ||
      #       (_NET_WM_WINDOW_TYPE@[0]:a = "_NET_WM_WINDOW_TYPE_DIALOG") ||
      #       (_NET_WM_STATE@[0]:a = "_NET_WM_STATE_MODAL"))
      #   ''
      # ];
      extraOptions = ''
        blur-background = true;
        blur-background-frame = true;
        blur-background-fixed = true;
        blur-background-exclude = [
          "class_g = 'slop'";
        ];
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

  home-manager.users.avo = rec {
    services = {
      gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        enableSshSupport = true;
      };

      dunst = {
        enable = true;
        settings = import ./dunstrc.nix { inherit theme; };
      };

      unclutter.enable = true;
    };

    home = {
      packages = with pkgs; [];
      sessionVariables = {
        ALTERNATE_EDITOR            = "${pkgs.neovim}/bin/nvim";
        COLUMNS                     = "100";
        EDITOR                      = "${pkgs.emacs}/bin/emacsclient";
        QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      };
    };

    xdg = {
      enable = true;

      configFile = {
        "mpv/mpv.conf".text = ''
          ao = pulse
          hwdec = vdpau
          profile = opengl-hq
          no-audio-display
        '';
      };
    };

    xsession = {
      windowManager.command = "xmonad";
      initExtra = ''
        xsetroot -xcf /run/current-system/sw/share/icons/Adwaita/cursors/left_ptr 42
        setroot ~/data/wallpapers/{pillars-of-creation_blue.jpg,pillars-of-creation_blue.jpg,pillars-of-creation_blue.jpg}
        xrdb -merge -I$HOME ~/.Xresources
      '';
    };

    programs = {
      home-manager.enable = true;

      git = {
        enable = true;

        userName  = "Andrei Vladescu-Olt";
        userEmail = "andrei@avolt.net";

        aliases = {
          "am" = "commit --amend -C HEAD";
          "ap" = "add -p";
          "ci" = "commit";
          "co" = "checkout";
          "dc" = "diff --cached";
          "di" = "diff";
          "root" = "!pwd";
          "st" = "status --short";
        };

        extraConfig = {
          include = { path = "~/.gitconfig-private"; };
          core = {
            editor = "";
            pager = "diff-so-fancy | less --tabs=4 -RFX";
          };

          #ghi.token = "!${pkgs.pass}/bin/pass api.github.com | head -1";
        };

        ignores = [
          "*~"
          "tags"
          ".#*"
          ".env*"
          ".nrepl*"
        ];
      };

      ssh = {
        enable = true;

        controlMaster  = "auto";
        controlPath    = "/tmp/ssh-%u-%r@%h:%p";
        controlPersist = "0";
      };

      zsh = rec {
        enable = true;

        enableCompletion = false;
        enableAutosuggestions = true;

        shellAliases = {
          "R"               = "ramda";
          "browser-history" = "qutebrowser-history";
          "e"               = "emacsclient -s scratchpad --no-wait";
          "fzf"             = "fzf --color bw";
          "gc"              = "git clone";
          "gdax"            = "webapp https://www.gdax.com/trade/BTC-USD";
          "git"             = "hub";
          "gr"              = "cd $(git root)";
          "grep"            = "grep --colorauto";
          "http"            = "http --pretty format";
          "j"               = "jobs -d | paste - -";
          "l"               = "ls";
          "la"              = "ls -a";
          "ls"              = "ls --group-directories-first --classify --dereference-command-line -v";
          "mkdir"           = "mkdir -p";
          "rg"              = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
          "rm"              = "timeout 3 rm -Iv --one-file-system";
          "stack"           = "stack --nix";
          "tree"            = "tree -F --dirsfirst";
          "vi"              = "nvim";
          "vpnoff"          = "sudo systemctl stop openvpn-us";
          "vpnon"           = "sudo systemctl start openvpn-us";
        };

        history = rec {
          size = 99999;
          save = size;
          path = ".zsh_history";
          ignoreDups = true;
          share = true;
        };

        sessionVariables = {
        };

        initExtra = ''
          setopt \
            extended_history \
            hist_ignore_space \
            hist_reduce_blanks

          setopt interactive_comments

          if [[ $TERM != eterm-color && $TERM != dumb ]]; then
            preexec() { print -Pn "\e]0;$1\a" }
          fi

          unset RPS1

          for i (~/.functions.d/*) source $i

          alias -g C='| wc -l'
          alias -g L='| less -R'
          alias -g H='| head'
          alias -g T='| tail'
          alias -g Y='| xsel -b'
          alias -g DN='2>/dev/null'
          alias -g FZ='| fzf | xargs'

          alias ..='cd ..'
          alias ...='cd .. && cd ..';
          alias ....='cd .. && cd .. && cd ..';

          source ~/.zsh.d/rlwrap.zsh
          bindkey -M viins '^x' insert-rlwrap
          bindkey -M vicmd '^x' insert-rlwrap

          ################################################################################

          # autoload -U compinit; compinit
          # setopt glob_complete
          # zstyle ':completion:*' menu select
          # zstyle ':completion:*' rehash true

          setopt \
            extended_glob \
            no_case_glob

          ################################################################################

          source ~/.zplug/init.zsh
          zplug 'willghatch/zsh-hooks'; zplug load
          zplug 'andreivolt/zsh-prompt-lean'
          zplug 'andreivolt/zsh-vim-mode', defer:2; zplug load
          zplug 'zdharma/fast-syntax-highlighting'
          zplug 'hlissner/zsh-autopair', defer:2
          zplug 'chisui/zsh-nix-shell'
          zplug 'chrismwendt/auto-nix-shell'
          zplug load

          eval "$(direnv hook zsh)"
        '';

        # plugins = [
        #   { name = "zsh-powerlevel9k";
        #     file = "powerlevel9k.zsh-theme";
        #     src = pkgs.zsh-powerlevel9k.src;
        #   }
        # ];
      };
    };
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
    "LIBVA_DRIVER_NAME" = "vdpau";
  };

  # cursor
  environment.etc."X11/Xresources".text = ''
    Xcursor.theme: Adwaita
    Xcursor.size: 42
  '';

  programs = {
    adb.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
    };
  };

  fonts = {
    fontconfig = {
      ultimate.enable = false;
      defaultFonts = {
        monospace = ["Source Code Pro"];
      };
    };
    enableCoreFonts = true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      font-awesome-ttf
      google-fonts
      hack-font
      hasklig
      (iosevka.override {
        set = "custom";
        weights = ["light"];
        design = [
          "termlig"
          "v-asterisk-low"
          "v-at-short"
          "v-i-zshaped"
          "v-tilde-low"
          "v-underscore-low"
          "v-zero-dotted"
          "v-zshaped-l"
        ];
      })
      material-icons
      nerdfonts
      overpass
      powerline-fonts
      terminus_font
      ubuntu_font_family
      vistafonts
    ];
  };

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';

  # cursor
  environment.profileRelativeEnvVars.XCURSOR_PATH = [ "/share/icons" ];
  environment.sessionVariables.GTK_PATH = "${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0";

  environment.etc."xmobar/xmobarrc".text = (import ./xmobarrc.nix { inherit theme; });

  systemd.user.services =
    let
      emacsDaemon = name : {
        enable = true;
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type      = "forking";
          Restart   = "always";
          ExecStart = ''${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.emacs}/bin/emacs --daemon=${name} --eval "(+avo/${name})"' '';
          ExecStop  = "${pkgs.emacs}/bin/emacsclient -s ${name} --eval (kill-emacs)";
        };
      };
    in {
      ircEmacsDaemon = emacsDaemon "irc";
      mailEmacsDaemon = emacsDaemon "mail";
      editorEmacsDaemon = emacsDaemon "scratchpad";

      dropbox = {
        enable = true;
        description = "Dropbox service";
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        path = [ pkgs.dropbox ];
        serviceConfig = {
          Type      = "forking";
          Restart   = "always";
          ExecStart = "${pkgs.dropbox}/bin/dropbox start";
          ExecStop  = "${pkgs.dropbox}/bin/dropbox stop";
        };
      };
    };
}
