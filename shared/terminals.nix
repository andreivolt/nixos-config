{
  pkgs,
  lib,
  ...
}: let
  # Aurora color scheme shared across terminals
  aurora = {
    background = "#000000";
    foreground = "#ffffff";
    cursor = "#ddd0f4";
    cursorText = "#211c2f";
    selection = {
      background = "#3f4060";
      foreground = "#e7d3fb";
    };
    normal = {
      black = "#070510";
      red = "#ff5874";
      green = "#addb67";
      yellow = "#ffcb65";
      blue = "#be9af7";
      magenta = "#FD9720";
      cyan = "#A1EFE4";
      white = "#645775";
    };
    bright = {
      black = "#443d60";
      red = "#ec5f67";
      green = "#d7ffaf";
      yellow = "#fbec9f";
      blue = "#6690c4";
      magenta = "#ffbe00";
      cyan = "#54CED6";
      white = "#e7d3fb";
    };
  };
in {
  home-manager.sharedModules = [
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;

        settings = {
          font-family = "IosevkaTerm NFM Light";
          font-family-italic = "IosevkaTerm NFM Light Italic";
          font-family-bold = "IosevkaTerm NFM";
          font-family-bold-italic = "IosevkaTerm NFM Italic";
          font-thicken = true;
          font-size = 16;

          adjust-cell-height = -8;
          adjust-font-baseline = 0;
          adjust-cell-width = "-12%";

          foreground = aurora.foreground;
          background = aurora.background;
          cursor-color = aurora.cursor;
          cursor-text = aurora.cursorText;
          selection-background = aurora.selection.background;
          selection-foreground = aurora.selection.foreground;

          palette = [
            "0=${aurora.normal.black}"
            "1=${aurora.normal.red}"
            "2=${aurora.normal.green}"
            "3=${aurora.normal.yellow}"
            "4=${aurora.normal.blue}"
            "5=${aurora.normal.magenta}"
            "6=${aurora.normal.cyan}"
            "7=${aurora.normal.white}"
            "8=${aurora.bright.black}"
            "9=${aurora.bright.red}"
            "10=${aurora.bright.green}"
            "11=${aurora.bright.yellow}"
            "12=${aurora.bright.blue}"
            "13=${aurora.bright.magenta}"
            "14=${aurora.bright.cyan}"
            "15=${aurora.bright.white}"
            "16=#8a6e2b"
            "17=#a8834a"
          ];

          minimum-contrast = 1;
          window-padding-x = 8;
          window-padding-y = 8;
          background-opacity = 0.75;
          background-blur-radius = 15;
          window-save-state = "always";
          window-vsync = false;
          macos-non-native-fullscreen = true;
          macos-window-shadow = false;
          window-decoration = false;
          cursor-style = "bar";
          mouse-hide-while-typing = true;
          confirm-close-surface = false;
          alpha-blending = "linear-corrected";
          window-colorspace = "display-p3";
          auto-update = "off";
          cursor-click-to-move = true;
          gtk-single-instance = true;

          keybind = [
            "shift+enter=text:\n"
          ];
        };
      };

      programs.kitty = {
        enable = true;

        font = {
          name = "IosevkaTerm Nerd Font Mono";
          size = 15.5;
        };

        settings = {
          # Font adjustments
          modify_font = "cell_height -3px";
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";

          # Performance
          input_delay = 0;
          repaint_delay = 2;
          sync_to_monitor = "no";
          wayland_enable_ime = "no";

          dynamic_background_opacity = "yes";
          scrollback_fill_enlarged_window = "yes";
          window_padding_width = 8;
          background_opacity = "0.65";
          background_blur = 25;

          # Cursor
          cursor = "none";
          cursor_stop_blinking_after = 0;
          cursor_trail = 1;
          cursor_trail_decay = "0.02 0.08";
          cursor_beam_thickness = 1;
          cursor_blink_interval = -1;

          copy_on_select = "yes";
          mouse_hide_wait = -1;

          # Tab bar
          tab_bar_style = "powerline";
          active_tab_background = "#ff00ff";
          active_tab_foreground = "#000000";
          inactive_tab_background = "#1c1c1c";
          inactive_tab_foreground = "#d3d3d3";
          tab_bar_background = "#000000";

          remember_window_size = "no";
          confirm_os_window_close = 0;
          macos_traditional_fullscreen = "yes";
          macos_show_window_title_in = "window";
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";
          kitty_mod = "cmd";
          paste_actions = "quote-urls-at-prompt,replace-dangerous-control-codes";
          notify_on_cmd_finish = "unfocused";
          enable_audio_bell = "no";
          visual_bell_duration = "0.1";
          visual_bell_color = "red";

          # Aurora theme colors
          background = aurora.background;
          foreground = aurora.foreground;
          selection_background = aurora.selection.background;
          selection_foreground = aurora.selection.foreground;
          url_color = aurora.normal.blue;
          cursor = aurora.cursor;
          cursor_text_color = aurora.cursorText;
          active_border_color = aurora.selection.background;
          inactive_border_color = aurora.cursorText;
          active_tab_background = aurora.cursorText;
          active_tab_foreground = aurora.selection.foreground;
          inactive_tab_background = aurora.background;
          inactive_tab_foreground = "#a0a0a0";
          tab_bar_background = aurora.background;

          color0 = aurora.normal.black;
          color1 = aurora.normal.red;
          color2 = aurora.normal.green;
          color3 = aurora.normal.yellow;
          color4 = aurora.normal.blue;
          color5 = aurora.normal.magenta;
          color6 = aurora.normal.cyan;
          color7 = aurora.normal.white;
          color8 = aurora.bright.black;
          color9 = aurora.bright.red;
          color10 = aurora.bright.green;
          color11 = aurora.bright.yellow;
          color12 = aurora.bright.blue;
          color13 = aurora.bright.magenta;
          color14 = aurora.bright.cyan;
          color15 = aurora.bright.white;
          color16 = "#8a6e2b";
          color17 = "#a8834a";
        };

        keybindings = {
          "shift+enter" = "send_text all \\n";
          "cmd+left" = "send_text all \\x1b[1;5D";
          "cmd+right" = "send_text all \\x1b[1;5C";
          "kitty_mod+equal" = "change_font_size all +0.5";
          "kitty_mod+plus" = "change_font_size all +0.5";
          "kitty_mod+kp_add" = "change_font_size all +0.5";
          "cmd+plus" = "change_font_size all +0.5";
          "cmd+equal" = "change_font_size all +0.5";
          "shift+cmd+equal" = "change_font_size all +0.5";
          "kitty_mod+minus" = "change_font_size all -0.5";
          "kitty_mod+kp_subtract" = "change_font_size all -0.5";
          "cmd+minus" = "change_font_size all -0.5";
          "shift+cmd+minus" = "change_font_size all -0.5";
          "kitty_mod+a>m" = "set_background_opacity +0.1";
          "kitty_mod+a>l" = "set_background_opacity -0.1";
        };
      };

      programs.alacritty = {
        enable = true;

        settings = {
          window = {
            opacity = 0.65;
            blur = true;
            padding = {
              x = 0;
              y = 0;
            };
            decorations = "None";
            startup_mode = "SimpleFullscreen";
          };

          font = {
            normal = {
              family = "IosevkaTerm Nerd Font Mono";
              style = "Light";
            };
            italic = {
              family = "IosevkaTerm Nerd Font Mono";
              style = "Light Italic";
            };
            size = 18;
            offset = {
              x = -3;
              y = -4;
            };
          };

          colors = {
            primary = {
              foreground = aurora.foreground;
              background = aurora.background;
            };
            cursor = {
              text = aurora.cursorText;
              cursor = aurora.cursor;
            };
            vi_mode_cursor = {
              text = aurora.cursorText;
              cursor = aurora.cursor;
            };
            selection = {
              text = aurora.selection.foreground;
              background = aurora.selection.background;
            };
            normal = {
              black = aurora.normal.black;
              red = aurora.normal.red;
              green = aurora.normal.green;
              yellow = aurora.normal.yellow;
              blue = aurora.normal.blue;
              magenta = aurora.normal.magenta;
              cyan = aurora.normal.cyan;
              white = aurora.normal.white;
            };
            bright = {
              black = aurora.bright.black;
              red = aurora.bright.red;
              green = aurora.bright.green;
              yellow = aurora.bright.yellow;
              blue = aurora.bright.blue;
              magenta = aurora.bright.magenta;
              cyan = aurora.bright.cyan;
              white = aurora.bright.white;
            };
          };

          cursor = {
            style = {
              shape = "Beam";
              blinking = "On";
            };
            blink_timeout = 0;
          };

          mouse = {
            hide_when_typing = true;
          };

          keyboard = {
            bindings = [
              {
                key = "Return";
                mods = "Shift";
                chars = "\n";
              }
              {
                key = "Left";
                mods = "Command";
                chars = "\\x1b[1;5D";
              }
              {
                key = "Right";
                mods = "Command";
                chars = "\\x1b[1;5C";
              }
              {
                key = "Equals";
                mods = "Command";
                action = "IncreaseFontSize";
              }
              {
                key = "Plus";
                mods = "Command";
                action = "IncreaseFontSize";
              }
              {
                key = "Minus";
                mods = "Command";
                action = "DecreaseFontSize";
              }
            ];
          };

          bell = {
            duration = 0;
          };
        };
      };
    }
  ];
}
