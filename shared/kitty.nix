{pkgs, ...}:
let
  colors = import ./colors.nix;
  aurora = colors.aurora;
in {
  home-manager.sharedModules = [
    ({lib, ...}: {
      programs.kitty = {
        enable = true;

        font = {
          name = "IosevkaTerm Nerd Font Mono";
          size = 15.5;
        };

        extraConfig = ''
          font_family family='IosevkaTerm Nerd Font Mono' style=Light
          modify_font baseline 0
          modify_font cell_height -3px
          modify_font cell_width 84%
          modify_font underline_thickness 200%
        '';

        settings = {
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
          cursor_stop_blinking_after = 0;
          cursor_trail = 1;
          cursor_trail_decay = "0.02 0.08";
          cursor_beam_thickness = 1;
          cursor_blink_interval = -1;

          copy_on_select = "yes";
          mouse_hide_wait = -1;

          # Tab bar
          tab_bar_style = "powerline";

          remember_window_size = "no";
          confirm_os_window_close = 0;
          macos_traditional_fullscreen = "yes";
          macos_show_window_title_in = "window";
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";
          kitty_mod = if pkgs.stdenv.isDarwin then "cmd" else "ctrl+shift";
          paste_actions = "quote-urls-at-prompt,replace-dangerous-control-codes";
          notify_on_cmd_finish = "unfocused";
          enable_audio_bell = "no";
          visual_bell_duration = "0.1";
          visual_bell_color = "red";

          # Aurora theme
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
          color16 = aurora.extended.color16;
          color17 = aurora.extended.color17;
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
          "ctrl+minus" = "change_font_size all -0.5";
          "ctrl+0" = "change_font_size all 0";
          "cmd+minus" = "change_font_size all -0.5";
          "shift+cmd+minus" = "change_font_size all -0.5";
          "kitty_mod+a>m" = "set_background_opacity +0.1";
          "kitty_mod+a>l" = "set_background_opacity -0.1";
        };
      };

      xdg.configFile."kitty/macos-launch-services-cmdline" = lib.mkIf pkgs.stdenv.isDarwin {
        text = "--start-as=fullscreen";
      };
    })
  ];
}
