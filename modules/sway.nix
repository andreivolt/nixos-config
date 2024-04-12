{ lib, pkgs, ... }:

let theme = import (dirOf <nixos-config> + /modules/theme.nix);
in {
  hardware.opengl.enable = true;

  home-manager.users.andrei = { config, ... }:
    let
      startsway = pkgs.writeShellScriptBin "startsway" ''
        exec systemd-cat --identifier sway \
          sway --debug
      '';
    in
    {
      nixpkgs.overlays = [
        (_: _: { inherit startsway; })
        # (import (dirOf <nixos-config> + /modules/wayland-overlay.nix))
      ];

      wayland.windowManager.sway =
        let
          mouseButtonBindings = ''
            # Close window by middle clicking title bar:
            bindsym button2 kill
            # Toggle float by right clicking window title:
            bindsym button3 floating toggle
          '';

          windowRules = ''
            # Set the title bar for floating windows
            for_window [floating] title_format "%title"
          '';

          autohideCursor = ''
            seat * hide_cursor 5000
            seat * hide_cursor when-typing enable
          '';
        in
        rec {
          enable = true;
          config = {
            modifier = "Mod4";
            menu = "find ~/.nix-profile/share -name '*.desktop' | xargs basename -s .desktop | menu | xargs ${pkgs.gtk3-x11}/bin/gtk-launch";
            colors = {
              focused = {
                border = "#${theme.colors.normal.green}";
                background = "#${theme.dark.active.background}";
                text = "#${theme.dark.active.foreground}";
                indicator = "#${theme.dark.active.background}";
                childBorder = "#${theme.colors.normal.green}";
              };
              focusedInactive = {
                border = "#${theme.dark.active.background}";
                background = "#${theme.dark.active.background}";
                text = "#${theme.dark.active.foreground}";
                indicator = "#${theme.dark.active.background}";
                childBorder = "#${theme.dark.active.background}";
              };
              unfocused = {
                border = "#${theme.dark.inactive.background}";
                background = "#${theme.dark.inactive.background}";
                text = "#${theme.dark.inactive.foreground}";
                indicator = "#${theme.dark.inactive.background}";
                childBorder = "#${theme.dark.inactive.background}";
              };
              urgent = {
                border = "#${theme.dark.urgent.background}";
                background = "#${theme.dark.urgent.background}";
                text = "#${theme.dark.urgent.foreground}";
                indicator = "#${theme.dark.urgent.background}";
                childBorder = "#${theme.dark.urgent.background}";
              };
            };
            fonts = {
              names = [ "Ubuntu" ];
              size = 16.0;
            };
            bars = [ ];
            terminal = "wezterm";
            startup = [
              { command = "${pkgs.autotiling}/bin/autotiling"; }
              { command = "${pkgs.wezterm}/bin/wezterm start --class scratchpad"; }
            ];
            window = {
              titlebar = false;
              commands =
                let
                  display = { width = 2560; height = 1600; };
                  scratchpad = rec {
                    width = display.width * 0.83;
                    height = width / 1.5;
                    pos_x = 0.0;
                    pos_y = 0.0;
                  };
                in
                [
                  { criteria.app_id = "scratchpad"; command = "floating enable"; }
                  { criteria.app_id = "scratchpad"; command = "move scratchpad"; }
                  { criteria.app_id = "scratchpad"; command = "scratchpad show"; }
                  { criteria.app_id = "scratchpad"; command = "resize set ${toString display.width} ${toString display.height}"; }
                  { criteria.app_id = "scratchpad"; command = "move position ${toString scratchpad.pos_x} ${toString scratchpad.pos_y}"; }
                ]
                ++ [
                  { criteria.app_id = "mpv"; command = "inhibit_idle visible"; }
                ]
                # ++ (
                #   let app_ids = [
                #     "firefox-nightly" "scratchpad" "tidal-hifi"
                #   ];
                #   in map (app_id: { criteria.app_id = app_id; command = "border none"; })
                # )
                ++ [
                  { criteria.title = "Volume Control"; command = "resize set 1000 1000"; } # pavucontrol-qt
                ];
              border = 0;
              hideEdgeBorders = "both";
            };
            floating = {
              titlebar = true;
              criteria = [
                { window_role = "pop-up"; }
                { title = "Volume Control"; } # pavucontrol-qt
                { app_id = "imv"; }
                { app_id = "pavucontrol"; }
                { app_id = "mpv"; }
                { title = "Picture in picture"; } # Chrome PIP
                { title = "LastPass: Free Password Manager"; } # Chrome LastPass
              ];
            };
            keybindings =
              let
                modifier = config.modifier;
                resize_increment = "40px";
                left = "h";
                down = "j";
                up = "k";
                right = "l";
              in
              lib.mkOptionDefault {
                "${modifier}+Shift+c" = "kill";
                "twosuperior" = "scratchpad show";
                "${modifier}+x" = "move container to scratchpad";
                "Print" = "exec screenshot --notify copy area";

                "${modifier}+p" = "exec $menu";
                "${modifier}+q" = "reload";

                "${modifier}+i" = "exec colortemp up";
                "${modifier}+o" = "exec colortemp down";

                "${modifier}+Tab" = "focus right";
                "${modifier}+Shift+Tab" = "focus left";

                "${modifier}+t" = "layout tabbed";
                "${modifier}+s" = "layout toggle split";

                "F1" = "exec pamixer --toggle-mute && ( pamixer --get-mute && echo 0 > $XDG_RUNTIME_DIR/wob.sock ) || pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
                "F2" = "exec pamixer --decrease 2 && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
                "F3" = "exec pamixer --increase 2 --allow-boost && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
                "F4" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

                "Home" = "exec playerctl previous";
                "End" = "exec playerctl next";
                "F5" = ''mode "default"''; # TODO

                "${modifier}+ampersand" = "workspace 1";
                "${modifier}+eacute" = "workspace 2";
                "${modifier}+quotedbl" = "workspace 3";
                "${modifier}+apostrophe" = "workspace 4";
                "${modifier}+parenleft" = "workspace 5";
                "${modifier}+minus" = "workspace 6";
                "${modifier}+egrave" = "workspace 7";
                "${modifier}+underscore" = "workspace 8";
                "${modifier}+ccedilla" = "workspace 9";
                "${modifier}+agrave" = "workspace 10";

                "${modifier}+Shift+ampersand" = "move container to workspace 1";
                "${modifier}+Shift+eacute" = "move container to workspace 2";
                "${modifier}+Shift+quotedbl" = "move container to workspace 3";
                "${modifier}+Shift+apostrophe" = "move container to workspace 4";
                "${modifier}+Shift+parenleft" = "move container to workspace 5";
                "${modifier}+Shift+minus" = "move container to workspace 6";
                "${modifier}+Shift+egrave" = "move container to workspace 7";
                "${modifier}+Shift+underscore" = "move container to workspace 8";
                "${modifier}+Shift+ccedilla" = "move container to workspace 9";
                "${modifier}+Shift+agrave" = "move container to workspace 10";

                "${modifier}+Alt+Left" = "workspace prev";
                "${modifier}+Alt+Right" = "workspace next";

                "F12" = "exec randomtab";
                "Pause" = "exec playerctl play-pause";
                # "${modifier}+l" = "lock";

                "${modifier}+Alt+${left}" = "resize shrink width ${resize_increment}";
                "${modifier}+Alt+${down}" = "resize grow height ${resize_increment}";
                "${modifier}+Alt+${up}" = "resize shrink height ${resize_increment}";
                "${modifier}+Alt+${right}" = "resize grow width ${resize_increment}";
              };
            input = {
              "type:keyboard" = {
                xkb_layout = "fr";
                xkb_options = "caps:swapescape";
              };
              "type:pointer" = {
                accel_profile = "adaptive";
                pointer_accel = "0.8";
              };
              "type:touchpad" = {
                dwt = "enabled";
                tap = "enabled";
                natural_scroll = "enabled";
                middle_emulation = "enabled";
              };
            };
            output = {
              "*" = {
                scale = "1";
                background = "#000000 solid_color";
              };
            };
          };
          extraConfig = ''
            # default_border none
            default_border pixel 1

            # smart_borders on

            default_floating_border normal 1
            # hide_edge_borders --i3 smart
            hide_edge_borders none
            smart_borders on
            smart_gaps on
            titlebar_border_thickness 0
          '' + mouseButtonBindings + windowRules + autohideCursor;
          systemdIntegration = true;
          wrapperFeatures.gtk = true;
          wrapperFeatures.base = true;
        };

      home.packages = with pkgs; with sway-contrib; [
        # kanshi  # display configuration # TODO: needed?
        # oguri # animated background # TODO: needed?
        bemenu
        gammastep
        grim
        grimshot # screenshots
        inactive-windows-transparency
        slurp
        startsway # start sway with logs going to systemd
        sway-audio-idle-inhibit
        swaybg # set background
        swayidle
        swaylock
        swaywsr # automatically rename workspaces with contents
        waybar
        wdisplays # display configuration
        wev
        wf-recorder # screen recorder
        wl-clipboard
        wmfocus
        xwayland
      ];
    };
}

# font pango:Ubuntu 16.000000
# floating_modifier Mod4
# default_border normal 0
# default_floating_border normal 2
# hide_edge_borders both
# focus_wrapping no
# focus_follows_mouse yes
# focus_on_window_activation smart
# mouse_warping output
# workspace_layout default
# workspace_auto_back_and_forth no

# client.focused #3c3c3c #3c3c3c #ffffff #3c3c3c #3c3c3c
# client.focused_inactive #3c3c3c #3c3c3c #ffffff #3c3c3c #3c3c3c
# client.unfocused #181818 #181818 #aaaaaa #181818 #181818
# client.urgent #f0c674 #f0c674 #000000 #f0c674 #f0c674
# client.placeholder #000000 #0c0c0c #ffffff #000000 #0c0c0c
# client.background #ffffff

# bindsym End exec playerctl next
# bindsym F1 exec pamixer --toggle-mute && ( pamixer --get-mute && echo 0 > $XDG_RUNTIME_DIR/wob.sock ) || pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock
# bindsym F2 exec pamixer --decrease 3 && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock
# bindsym F3 exec pamixer --increase 3 --allow-boost && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock
# bindsym F4 exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
# bindsym F5 mode "default"
# bindsym Home exec playerctl previous
# bindsym Mod4+1 workspace number 1
# bindsym Mod4+2 workspace number 2
# bindsym Mod4+3 workspace number 3
# bindsym Mod4+4 workspace number 4
# bindsym Mod4+5 workspace number 5
# bindsym Mod4+6 workspace number 6
# bindsym Mod4+7 workspace number 7
# bindsym Mod4+8 workspace number 8
# bindsym Mod4+9 workspace number 9
# bindsym Mod4+Alt+h resize shrink width 40px
# bindsym Mod4+Alt+j resize grow height 40px
# bindsym Mod4+Alt+k resize shrink height 40px
# bindsym Mod4+Alt+l resize grow width 40px
# bindsym Mod4+Down focus down
# bindsym Mod4+Left focus left
# bindsym Mod4+Return exec foot -o colors.alpha=0.80
# bindsym Mod4+Right focus right
# bindsym Mod4+Shift+1 move container to workspace number 1
# bindsym Mod4+Shift+2 move container to workspace number 2
# bindsym Mod4+Shift+3 move container to workspace number 3
# bindsym Mod4+Shift+4 move container to workspace number 4
# bindsym Mod4+Shift+5 move container to workspace number 5
# bindsym Mod4+Shift+6 move container to workspace number 6
# bindsym Mod4+Shift+7 move container to workspace number 7
# bindsym Mod4+Shift+8 move container to workspace number 8
# bindsym Mod4+Shift+9 move container to workspace number 9
# bindsym Mod4+Shift+Down move down
# bindsym Mod4+Shift+Left move left
# bindsym Mod4+Shift+Right move right
# bindsym Mod4+Shift+Tab focus left
# bindsym Mod4+Shift+Up move up
# bindsym Mod4+Shift+agrave move container to workspace 10
# bindsym Mod4+Shift+ampersand move container to workspace 1
# bindsym Mod4+Shift+apostrophe move container to workspace 4
# bindsym Mod4+Shift+c kill
# bindsym Mod4+Shift+ccedilla move container to workspace 9
# bindsym Mod4+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'
# bindsym Mod4+Shift+eacute move container to workspace 2
# bindsym Mod4+Shift+egrave move container to workspace 6
# bindsym Mod4+Shift+h move left
# bindsym Mod4+Shift+j move down
# bindsym Mod4+Shift+k move up
# bindsym Mod4+Shift+l move right
# bindsym Mod4+Shift+minus move container to workspace 7
# bindsym Mod4+Shift+parenleft move container to workspace 5
# bindsym Mod4+Shift+q kill
# bindsym Mod4+Shift+quotedbl move container to workspace 3
# bindsym Mod4+Shift+space floating toggle
# bindsym Mod4+Shift+underscore move container to workspace 8
# bindsym Mod4+Tab focus right
# bindsym Mod4+Up focus up
# bindsym Mod4+a focus parent
# bindsym Mod4+agrave workspace 10
# bindsym Mod4+ampersand workspace 1
# bindsym Mod4+apostrophe workspace 4
# bindsym Mod4+b splith
# bindsym Mod4+ccedilla workspace 9
# bindsym Mod4+d exec find ~/.nix-profile/share -name '*.desktop' | xargs basename -s .desktop | menu | xargs /nix/store/7qp9y0jshnyjr2aswnc3fi9db1crjy68-gtk+3-3.24.30/bin/gtk-launch
# bindsym Mod4+e layout toggle split
# bindsym Mod4+eacute workspace 2
# bindsym Mod4+egrave workspace 6
# bindsym Mod4+f fullscreen toggle
# bindsym Mod4+h focus left
# bindsym Mod4+i exec colortemp up
# bindsym Mod4+j focus down
# bindsym Mod4+k focus up
# bindsym Mod4+l focus right
# bindsym Mod4+minus workspace 7
# bindsym Mod4+o exec colortemp down
# bindsym Mod4+p exec $menu
# bindsym Mod4+parenleft workspace 5
# bindsym Mod4+q reload
# bindsym Mod4+quotedbl workspace 3
# bindsym Mod4+r mode resize
# bindsym Mod4+s layout toggle split
# bindsym Mod4+space focus mode_toggle
# bindsym Mod4+t layout tabbed
# bindsym Mod4+underscore workspace 8
# bindsym Mod4+v splitv
# bindsym Mod4+w layout tabbed
# bindsym Mod4+x move container to scratchpad
# bindsym Print exec grim -g $(slurp) - | wl-copy -t image/png
# bindsym twosuperior scratchpad show

# input "type:keyboard" {
# xkb_layout fr
# xkb_options ctrl:nocaps
# }

# input "type:pointer" {
# accel_profile flat
# pointer_accel 1
# }

# input "type:touchpad" {
# dwt enabled
# middle_emulation enabled
# natural_scroll enabled
# tap enabled
# }

# output "*" {
# background #000000 solid_color
# scale 1
# }

# mode "resize" {
# bindsym Down resize grow height 10 px
# bindsym Escape mode default
# bindsym Left resize shrink width 10 px
# bindsym Return mode default
# bindsym Right resize grow width 10 px
# bindsym Up resize shrink height 10 px
# bindsym h resize shrink width 10 px
# bindsym j resize grow height 10 px
# bindsym k resize shrink height 10 px
# bindsym l resize grow width 10 px
# }

# for_window [window_role="pop-up"] floating enable
# for_window [title="Volume Control"] floating enable
# for_window [app_id="imv"] floating enable
# for_window [app_id="pavucontrol"] floating enable
# for_window [app_id="mpv"] floating enable
# for_window [title="Picture in picture"] floating enable
# for_window [title="LastPass: Free Password Manager"] floating enable
# for_window [app_id="scratchpad"] floating enable
# for_window [app_id="scratchpad"] move scratchpad
# for_window [app_id="scratchpad"] scratchpad show
# for_window [app_id="scratchpad"] resize set 2560 1600
# for_window [app_id="scratchpad"] move position 0.000000 0.000000
# for_window [app_id="mpv"] inhibit_idle visible
# for_window [title="Volume Control"] resize set 1000 1000

# exec "systemctl --user import-environment; systemctl --user start sway-session.target"

# titlebar_padding 20 8

{ lib, pkgs, ... }:

let theme = import (dirOf <nixos-config> + /modules/theme.nix);
in {
  home-manager.users.andrei = { config, ... }: {
    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;
      wrapperFeatures = {
        gtk = true;
        base = true;
      };

      config = let
        modifier = config.modifier;
        resize_increment = "40px";
        left = "h";
        down = "j";
        up = "k";
        right = "l";
      in {
        modifier = "Mod4";
        menu = "find ~/.nix-profile/share -name '*.desktop' | xargs basename -s .desktop | menu | xargs ${pkgs.gtk3-x11}/bin/gtk-launch";

        focus = {
          followMouse = "yes";
          wrapping = "no";
          newWindow = "smart";
          mouseWarping = "output";
        };

        workspaceLayout = "default";
        workspaceAutoBackAndForth = false;

        colors = {
          focused = {
            border = "#${theme.colors.normal.green}";
            background = "#${theme.dark.active.background}";
            text = "#${theme.dark.active.foreground}";
            indicator = "#${theme.dark.active.background}";
            childBorder = "#${theme.colors.normal.green}";
          };
          focusedInactive = {
            border = "#${theme.dark.active.background}";
            background = "#${theme.dark.active.background}";
            text = "#${theme.dark.active.foreground}";
            indicator = "#${theme.dark.active.background}";
            childBorder = "#${theme.dark.active.background}";
          };
          unfocused = {
            border = "#${theme.dark.inactive.background}";
            background = "#${theme.dark.inactive.background}";
            text = "#${theme.dark.inactive.foreground}";
            indicator = "#${theme.dark.inactive.background}";
            childBorder = "#${theme.dark.inactive.background}";
          };
          urgent = {
            border = "#${theme.dark.urgent.background}";
            background = "#${theme.dark.urgent.background}";
            text = "#${theme.dark.urgent.foreground}";
            indicator = "#${theme.dark.urgent.background}";
            childBorder = "#${theme.dark.urgent.background}";
          };
        };

        fonts = {
          names = [ "Ubuntu" ];
          size = 16.0;
        };

        input = {
          "type:keyboard" = {
            xkb_layout = "fr";
            xkb_options = "caps:swapescape";
          };
          "type:pointer" = {
            accel_profile = "adaptive";
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
          "*" = {
            scale = "1";
            background = "#000000 solid_color";
          };
        };

        gaps = {
          smartBorders = "on";
          smartGaps = true;
        };

        window = {
          border = 0;
          titlebar = false;
          hideEdgeBorders = "both";
          commands = let
            display = { width = 2560; height = 1600; };
            scratchpad = rec {
              width = display.width * 0.83;
              height = width / 1.5;
              pos_x = 0.0;
              pos_y = 0.0;
            };
          in [
            { criteria.app_id = "scratchpad"; command = "floating enable"; }
            { criteria.app_id = "scratchpad"; command = "move scratchpad"; }
            { criteria.app_id = "scratchpad"; command = "scratchpad show"; }
            { criteria.app_id = "scratchpad"; command = "resize set ${toString display.width} ${toString display.height}"; }
            { criteria.app_id = "scratchpad"; command = "move position ${toString scratchpad.pos_x} ${toString scratchpad.pos_y}"; }
          ]
          ++ [
            { criteria.app_id = "mpv"; command = "inhibit_idle visible"; }
          ]
          # ++ (
          #   let app_ids = [
          #     "firefox-nightly" "scratchpad" "tidal-hifi"
          #   ];
          #   in map (app_id: { criteria.app_id = app_id; command = "border none"; })
          # )
          ++ [
            { criteria.title = "Volume Control"; command = "resize set 1000 1000"; }
          ];
        };

        floating = {
          titlebar = true;
          border = 2;
          criteria = [
            { window_role = "pop-up"; }
            { title = "Volume Control"; }
            { app_id = "imv"; }
            { app_id = "pavucontrol"; }
            { app_id = "mpv"; }
            { title = "Picture in picture"; }
            { title = "LastPass: Free Password Manager"; }
          ];
        };

        modes = {
          resize = {
            Down = "resize grow height ${resize_increment}";
            Escape = "mode default";
            Left = "resize shrink width ${resize_increment}";
            Return = "mode default";
            Right = "resize grow width ${resize_increment}";
            Up = "resize shrink height ${resize_increment}";
            h = "resize shrink width ${resize_increment}";
            j = "resize grow height ${resize_increment}";
            k = "resize shrink height ${resize_increment}";
            l = "resize grow width ${resize_increment}";
          };
        };

        keybindings = lib.mkOptionDefault {
          "${modifier}+Return" = "exec ${pkgs.kitty}/bin/kitty";
          "${modifier}+Shift+c" = "kill";
          "twosuperior" = "scratchpad show";
          "${modifier}+x" = "move container to scratchpad";
          "Print" = "exec screenshot --notify copy area";
          "${modifier}+p" = "exec $menu";
          "${modifier}+q" = "reload";
          "${modifier}+i" = "exec colortemp up";
          "${modifier}+o" = "exec colortemp down";
          "${modifier}+Tab" = "focus right";
          "${modifier}+Shift+Tab" = "focus left";
          "${modifier}+t" = "layout tabbed";
          "${modifier}+s" = "layout toggle split";
          "${modifier}+b" = "splith";
          "${modifier}+v" = "splitv";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+a" = "focus parent";
          "${modifier}+space" = "focus mode_toggle";
          "${modifier}+Shift+space" = "floating toggle";
          "${modifier}+r" = "mode resize";

          # Media keys
          "F1" = "exec pamixer --toggle-mute && ( pamixer --get-mute && echo 0 > $XDG_RUNTIME_DIR/wob.sock ) || pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
          "F2" = "exec pamixer --decrease 2 && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
          "F3" = "exec pamixer --increase 2 --allow-boost && pamixer --get-volume > $XDG_RUNTIME_DIR/wob.sock";
          "F4" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "F5" = ''mode "default"'';
          "F12" = "exec randomtab";
          "Home" = "exec playerctl previous";
          "End" = "exec playerctl next";
          "Pause" = "exec playerctl play-pause";

          # Workspace navigation
          "${modifier}+Alt+Left" = "workspace prev";
          "${modifier}+Alt+Right" = "workspace next";

          # Workspace bindings (fr layout)
          "${modifier}+ampersand" = "workspace 1";
          "${modifier}+eacute" = "workspace 2";
          "${modifier}+quotedbl" = "workspace 3";
          "${modifier}+apostrophe" = "workspace 4";
          "${modifier}+parenleft" = "workspace 5";
          "${modifier}+minus" = "workspace 6";
          "${modifier}+egrave" = "workspace 7";
          "${modifier}+underscore" = "workspace 8";
          "${modifier}+ccedilla" = "workspace 9";
          "${modifier}+agrave" = "workspace 10";

          "${modifier}+Shift+ampersand" = "move container to workspace 1";
          "${modifier}+Shift+eacute" = "move container to workspace 2";
          "${modifier}+Shift+quotedbl" = "move container to workspace 3";
          "${modifier}+Shift+apostrophe" = "move container to workspace 4";
          "${modifier}+Shift+parenleft" = "move container to workspace 5";
          "${modifier}+Shift+minus" = "move container to workspace 6";
          "${modifier}+Shift+egrave" = "move container to workspace 7";
          "${modifier}+Shift+underscore" = "move container to workspace 8";
          "${modifier}+Shift+ccedilla" = "move container to workspace 9";
          "${modifier}+Shift+agrave" = "move container to workspace 10";

          # Navigation
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          "${modifier}+${left}" = "focus left";
          "${modifier}+${down}" = "focus down";
          "${modifier}+${up}" = "focus up";
          "${modifier}+${right}" = "focus right";

          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Down" = "move down";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Right" = "move right";
          "${modifier}+Shift+${left}" = "move left";
          "${modifier}+Shift+${down}" = "move down";
          "${modifier}+Shift+${up}" = "move up";
          "${modifier}+Shift+${right}" = "move right";

          # Resize bindings
          "${modifier}+Alt+${left}" = "resize shrink width ${resize_increment}";
          "${modifier}+Alt+${down}" = "resize grow height ${resize_increment}";
          "${modifier}+Alt+${up}" = "resize shrink height ${resize_increment}";
          "${modifier}+Alt+${right}" = "resize grow width ${resize_increment}";
        };

        bars = [];

        terminal = "${pkgs.kitty}/bin/kitty";

        startup = [
          { command = "${pkgs.autotiling}/bin/autotiling"; }
          { command = "${pkgs.kitty}/bin/kitty --class scratchpad"; }
        ];
      };

      extraConfig = let
        mouseButtonBindings = ''
          # Close window by middle clicking title bar:
          bindsym button2 kill
          # Toggle float by right clicking window title:
          bindsym button3 floating toggle
        '';

        windowRules = ''
          # Set the title bar for floating windows
          for_window [floating] title_format "%title"
        '';

        autohideCursor = ''
          seat * hide_cursor 5000
          seat * hide_cursor when-typing enable
        '';
      in ''
        default_border pixel 1
        default_floating_border normal 1
        hide_edge_borders none
        smart_borders on
        smart_gaps on
        titlebar_border_thickness 0
      '' + mouseButtonBindings + windowRules + autohideCursor;
    };

    home.packages = with pkgs; with sway-contrib; [
      bemenu
      gammastep
      grim
      grimshot
      inactive-windows-transparency
      slurp
      sway-audio-idle-inhibit
      swaybg
      swayidle
      swaylock
      swaywsr
      waybar
      wdisplays
      wev
      wf-recorder
      wl-clipboard
      wmfocus
      xwayland
    ];
  };
}

# {
#   home-manager.users.andrei = { pkgs, ... }: {
#     home.file.".zlogin".text = ''
#       # if not running interactively, don't do anything
#       [[ $- != *i* ]] && return
#
#       if [[ "$(tty)" == "/dev/tty1" ]]; then
#         ${pkgs.startsway}/bin/startsway;
#       fi
#     '';
#   };
# }
