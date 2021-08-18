{ lib, pkgs, ... }:

let
  font = {
   family = "Ubuntu";
   size = 16.0;
  };

  theme = import ../theme.nix;

  colors = {
    black = "#000000";
    white = "#ffffff";

    red = "#ff0000";
    blue = "#285577";

    gray = "#333333";
    lightgray = "#777777";
    darkgray = "#222222";
  };

  sway-config = let
    display = { width = 2560; height = 1600; };
    # scratchpad_height = builtins.floor (display_height / 1.5);
    scratchpad = rec {
      width = display.width * 0.83;
      height = width / 1.5;
      pos_y = 0.0;
      pos_x = 0.0;
      opacity = 0.75;
    };
    x = x: builtins.elemAt (builtins.match "(.*).{7}" (toString x)) 0;
    # set $scratchpad.width ${x scratchpad.width}
    # set $scratchpad.height ${x scratchpad.height}
    # set $scratchpad.pos_x ${toString scratchpad.pos_x}
    # set $scratchpad.pos_y ${x scratchpad.pos_y}
    # set $scratchpad.opacity ${x scratchpad.opacity}
  in ''
    include @sysconfdir@/sway/config.d/*

    set $display.width ${toString display.width}
    set $display.height ${toString display.height}

    set $scratchpad.pos_x ${toString scratchpad.pos_x}
    set $scratchpad.pos_y ${toString scratchpad.pos_y}
    set $scratchpad.opacity ${toString scratchpad.opacity}

    default_border none
    smart_borders on

    titlebar_padding 20 8
  '';
in {
  imports = [
    ./service.nix
  ];

  # environment.pathsToLink = [ "/libexec" ];

  # # fix "failed to take device"
  # hardware.opengl.driSupport = true;

  home-manager.users.avo = { config, ... }: {
    wayland.windowManager.sway = rec {
      enable = true;
      config = {
        modifier = "Mod4";
        menu = "find ~/.nix-profile/share -name '*.desktop' | xargs basename -s .desktop | menu";
        colors = {
          focused = {
            border = colors.blue;
            background = colors.blue;
            text = colors.white;
            indicator = colors.black;
            childBorder = colors.blue;
          };
          focusedInactive = {
            border = colors.black;
            background = colors.black;
            text = colors.gray;
            indicator = colors.black;
            childBorder = colors.black;
          };
          unfocused = {
            border = colors.black;
            background = colors.black;
            text = colors.lightgray;
            indicator = colors.black;
            childBorder = colors.black;
          };
          urgent = {
            border = colors.black;
            background = colors.black;
            text = colors.gray;
            indicator = colors.black;
            childBorder = colors.red;
          };
        };
        fonts = {
          names = [ "Ubuntu" ];
          size = 16.0;
        };
        bars = [];
        terminal = "footclient";
        startup = [
          { command = "systemctl --user restart waybar"; always = true; }
          { command = "mako"; }
          { command = "firefox"; }
          # store clipboard history
          { command = "wl-paste -t text --watch clipman store"; }
          # restore last history item at startup
          { command = "clipman restore"; }

          { command = "exec mkfifo /tmp/wob.sock"; }
          { command = "exec tail -f /tmp/wob.sock | wob"; }

          { command =
              let lock = "swaylock -f -c -000001";
              in ''exec swayidle -w timeout 1200 '${lock}' timeout 180 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"'  timeout 7200 'systemctl suspend' before-sleep '${lock}'  '';
           }
        ];
        window = {
          titlebar = true;
          commands = [
            { criteria = { app_id = "foot"; }; command = "border pixel 5"; }
            { criteria = { app_id = "scratchpad"; }; command = "floating enable"; }
            { criteria = { app_id = "scratchpad"; }; command = "move scratchpad"; }
            { criteria = { app_id = "scratchpad"; }; command = "scratchpad show"; }
            { criteria = { app_id = "scratchpad"; }; command = "resize set $display.width $display.height"; }
            { criteria = { app_id = "scratchpad"; }; command = "move position $scratchpad.pos_x $scratchpad.pos_y"; }
            { criteria = { app_id = "mpv"; }; command = "inhibit_idle visible"; }
          ];
          border = 0;
          hideEdgeBorders = "both";
        };
        floating = {
          titlebar = true;
          criteria = [
            { app_id = "imv"; }
            { app_id = "pavucontrol"; }
            { app_id = "mpv"; }
            { title = "Picture in picture"; }
          ];
        };
        keybindings = let
          modifier = config.modifier;
          resize_increment = "40px";
          left = "h";
          down = "j";
          up = "k";
          right = "l";
        in lib.mkOptionDefault {
          "${modifier}+Shift+c" = "kill";
          "twosuperior" = "scratchpad show";
          "${modifier}+x"  = "move container to scratchpad";
          "Print" = "exec grim -g $(slurp) - | wl-copy -t image/png";

          "${modifier}+p" = "exec $menu";
          "${modifier}+q" = "reload";

          "${modifier}+i" = "exec colortemp up";
          "${modifier}+o" = "exec colortemp down";

          "${modifier}+Tab" = "focus right";
          "${modifier}+Shift+Tab" = "focus left";

          "${modifier}+t" = "layout tabbed";
          "${modifier}+s" = "layout toggle split";

          "F1" = "exec pamixer --toggle-mute && ( pamixer --get-mute && echo 0 > /tmp/wob.sock ) || pamixer --get-volume > /tmp/wob.sock";
          "F2" = "exec pamixer --decrease 3 && pamixer --get-volume > /tmp/wob.sock";
          "F3" = "exec pamixer --increase 3 && pamixer --get-volume > /tmp/wob.sock";
          "F4" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

          "Home" = "exec playerctl previous";
          "End" = "exec playerctl next";
          "F5" = ''mode "default"''; # TODO

          "${modifier}+ampersand" = "workspace 1";
          "${modifier}+eacute" = "workspace 2";
          "${modifier}+quotedbl" = "workspace 3";
          "${modifier}+apostrophe" = "workspace 4";
          "${modifier}+parenleft" = "workspace 5";
          "${modifier}+egrave" = "workspace 6";
          "${modifier}+minus" = "workspace 7";
          "${modifier}+underscore" = "workspace 8";
          "${modifier}+ccedilla" = "workspace 9";
          "${modifier}+agrave" = "workspace 10";

          "${modifier}+Shift+ampersand" = "move container to workspace 1";
          "${modifier}+Shift+eacute" = "move container to workspace 2";
          "${modifier}+Shift+quotedbl" = "move container to workspace 3";
          "${modifier}+Shift+apostrophe" = "move container to workspace 4";
          "${modifier}+Shift+parenleft" = "move container to workspace 5";
          "${modifier}+Shift+egrave" = "move container to workspace 6";
          "${modifier}+Shift+minus" = "move container to workspace 7";
          "${modifier}+Shift+underscore" = "move container to workspace 8";
          "${modifier}+Shift+ccedilla" = "move container to workspace 9";
          "${modifier}+Shift+agrave" = "move container to workspace 10";

          "${modifier}+Alt+${left}" = "resize shrink width ${resize_increment}";
          "${modifier}+Alt+${down}" = "resize grow height ${resize_increment}";
          "${modifier}+Alt+${up}" = "resize shrink height ${resize_increment}";
          "${modifier}+Alt+${right}" = "resize grow width ${resize_increment}";
        };
        input = {
          "type:keyboard" = {
            xkb_layout = "fr";
            xkb_options = "ctrl:nocaps";
          };
          "type:pointer" = {
            accel_profile = "flat";
            pointer_accel = "1";
          };
          "type:touchpad" = {
            dwt = "enabled";
            tap = "enabled";
            natural_scroll = "enabled";
            middle_emulation = "enabled";
          };
        };
        output = {
          "*"  = {
            scale = "1";
            background = "#000000 solid_color";
          };
        };
      };
      extraConfig = sway-config;
      systemdIntegration = true;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export XKB_DEFAULT_LAYOUT=fr
      '';
    };

    home.packages = with pkgs; [
      gammastep
      gebaar-libinput
      grim
      # mako
      wev
      slurp
      swayidle
      swaylock
      wmfocus # window picker
      wob
      wl-clipboard
      kanshi  # display configuration
      wdisplays  # display configuration
      swaybg
      oguri # animated background
      waybar
      xwayland
    ];

    # home.file.".zprofile".text = ''
    #   if [[ $XDG_VTNR -eq 1 ]]; then
    #     exec dbus-launch --sh-syntax --exit-with-session sway
    #   fi
    # '';

    # notifications
    programs.mako = {
      enable = true;
      width = 500;
      backgroundColor = "#00000050";
      font = "${font.family} ${toString font.size}";
      layer = "overlay";
      borderSize = 0;
      margin = "20";
      padding = "20";
    };
  };

  programs.qt5ct.enable = true;
}
