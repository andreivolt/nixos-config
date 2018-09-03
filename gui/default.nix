{ lib, pkgs, ... }:

let
  theme = import ../theme.nix;
  set-monitors = pkgs.stdenv.mkDerivation rec {
    name = "set-monitors";

    src = [(pkgs.writeScript name ''
      #!/usr/bin/env bash

      declare primary=DP-2 secondary=DP-0

      case $1 in
        *)
          nvidia-settings --assign CurrentMetaMode='\
            ''${secondary}: nvidia-auto-select +3840+0 {ForceFullCompositionPipeline=On},\
            ''${primary}: nvidia-auto-select +3840+0 {ForceFullCompositionPipeline=On, SameAs=DP-0}'
          ;;
      esac
        ];
    '')];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
    '';
  };

in {
  imports = [
    ./notifications.nix
  ];

  fileSystems."xmonad" = {
    device = builtins.toString ./xmonad;
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.xmonad";
  };

  environment.systemPackages = with pkgs; let
    focus-window = pkgs.stdenv.mkDerivation rec {
      name = "focus-window";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        wmctrl -i -a $1
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    nightlight = pkgs.stdenv.mkDerivation rec {
      name = "nightlight";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env zsh

        [ ! -f /tmp/.nightlight ] && echo 'REDSHIFT_TEMP=6500; REDSHIFT_BRIGTHNESS=1' > /tmp/.nightlight
        source /tmp/.nightlight

        while getopts ":t:b:-x:" o; do
        sign=$OPTARG

        case $o in
            t) (! [[ $REDSHIFT_TEMP -eq 6500 && $sign = '+' ]]) && REDSHIFT_TEMP=$(($REDSHIFT_TEMP $sign 50)) ;;
            b) (! [[ $REDSHIFT_BRIGTHNESS -eq 1 && $sign = '+' ]]) && REDSHIFT_BRIGTHNESS=$(($REDSHIFT_BRIGTHNESS $sign 0.01)) ;;
            -x) ${pkgs.redshift}/bin/redshift -x; rm /tmp/.nightlight; exit ;;
        esac
        done

        ${pkgs.redshift}/bin/redshift -O $REDSHIFT_TEMP -b $REDSHIFT_BRIGTHNESS &>/dev/null

        notify-send "
          t: $REDSHIFT_TEMP
          b: $REDSHIFT_BRIGTHNESS
        "

        echo "REDSHIFT_TEMP=$REDSHIFT_TEMP; REDSHIFT_BRIGTHNESS=$REDSHIFT_BRIGTHNESS" > /tmp/.nightlight
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

    whattimeisit = with pkgs; stdenv.mkDerivation rec {
      name = "whattimeisit";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        date +'%l:%M %p' | sed 's/^ //'
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };

  in [
    focus-window
    nightlight
    redshift
    set-monitors
    whattimeisit
    wmctrl
    xclip
    xdotool
    xrandr-invert-colors
    xsel
  ];

  services.xserver = {
    enable = true;

    displayManager.auto = { enable = true; user = "avo"; };
    displayManager.sessionCommands = let
      setMonitors = "${set-monitors}/bin/set-monitors";
      setCursor = "${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 40";
      todo = "${pkgs.emacs}/bin/emacs ~/doc/todo.org --eval '(setq mode-line-format nil)' &";
    in lib.mkAfter (lib.concatStringsSep "\n" [
      setMonitors
      setCursor
      "${pkgs.insync}/bin/insync start"
      "google-chrome-unstable &"
      todo
    ]);

    desktopManager.xterm.enable = false;
    windowManager.default = "xmonad";
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  services.compton = {
    enable = true;
    shadow = true;
    shadowOffsets = [ (-15) 15 ];
    shadowOpacity = "0.35";
    shadowExclude = [ ''
      !(focused ||
        (name = 'scratchpad') ||
        (_NET_WM_WINDOW_TYPE@[0]:a = '_NET_WM_WINDOW_TYPE_DIALOG') ||
        (_NET_WM_STATE@[0]:a = '_NET_WM_STATE_MODAL'))
    '' ];
    extraOptions = ''
      shadow-radius = 15;
      blur-background = true;
      blur-background-frame = true;
      blur-background-fixed = false;
      blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
      clear-shadow = true;
    '';
  };

  fonts = {
    fontconfig = {
      ultimate.enable = false;
      defaultFonts = {
        monospace = [(if builtins.getEnv("MONOSPACE_FONT_FAMILY") != "" then builtins.getEnv("MONOSPACE_FONT_FAMILY") else "Source Code Pro")];
        sansSerif = [(if builtins.getEnv("PROPORTIONAL_FONT_FAMILY") != "" then builtins.getEnv("PROPORTIONAL_FONT_FAMILY") else "Product Sans")];
      };
    };
    enableCoreFonts= true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      google-fonts
      open-dyslexic
      overpass
      vistafonts
    ];
  };

  home-manager.users.avo = {
    services.unclutter.enable = true;

    xresources.properties =
      let
        colors = with theme; {
          "*.background" = background; "*.foreground" = foreground;
          "*.color0" = black; "*.color8" = gray;
          "*.color1" = red; "*.color9" = lightRed;
          "*.color2" = green; "*.color10" = lightGreen;
          "*.color3" = yellow; "*.color11" = lightYellow;
          "*.color4" = blue; "*.color12" = lightBlue;
          "*.color5" = magenta; "*.color13" = lightMagenta;
          "*.color6" = cyan; "*.color14" = lightCyan;
          "*.color7" = white; "*.color15" = lightWhite;

          "*.borderColor" = background;
          "*.colorUL" = white;
          "*.cursorColor" = foreground;
        };

        cursor = {
          "Xcursor.size" = 60;
          "Xcursor.theme" = "Adwaita";
        };

        emacs = {
          "Emacs.toolBar" = 0;
          "Emacs.menuBar" = 0;
          "Emacs.scrollBar" = 0;
        };

        hdpi = {
          "Xft.dpi" = 180;
          "Xft.hintstyle" = "hintfull";
        };
      in
           colors
        // cursor
        // emacs
        // hdpi;
  };
}
