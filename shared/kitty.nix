{
  home-manager.sharedModules = [
    {
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
          kitty_mod = "cmd";
          paste_actions = "quote-urls-at-prompt,replace-dangerous-control-codes";
          notify_on_cmd_finish = "unfocused";
          enable_audio_bell = "no";
          visual_bell_duration = "0.1";
          visual_bell_color = "red";

          # Aurora theme
          background = "#000000";
          foreground = "#ffffff";
          selection_background = "#3f4060";
          selection_foreground = "#e7d3fb";
          url_color = "#be9af7";
          cursor = "#ddd0f4";
          cursor_text_color = "#211c2f";
          active_border_color = "#3f4060";
          inactive_border_color = "#211c2f";
          active_tab_background = "#211c2f";
          active_tab_foreground = "#e7d3fb";
          inactive_tab_background = "#000000";
          inactive_tab_foreground = "#a0a0a0";
          tab_bar_background = "#000000";

          color0 = "#070510";
          color1 = "#ff5874";
          color2 = "#addb67";
          color3 = "#ffcb65";
          color4 = "#be9af7";
          color5 = "#FD9720";
          color6 = "#A1EFE4";
          color7 = "#645775";
          color8 = "#443d60";
          color9 = "#ec5f67";
          color10 = "#d7ffaf";
          color11 = "#fbec9f";
          color12 = "#6690c4";
          color13 = "#ffbe00";
          color14 = "#54CED6";
          color15 = "#e7d3fb";
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
    }
  ];
}
