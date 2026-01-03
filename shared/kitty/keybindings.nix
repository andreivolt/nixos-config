{
  "kitty_mod+h" = "kitty_scrollback_nvim";
  "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
  "shift+enter" = "send_text all \\n";
  "cmd+left" = "send_text all \\x1b[1;5D";
  "cmd+right" = "send_text all \\x1b[1;5C";
  # Font size (override defaults to use consistent 0.25 increments)
  "kitty_mod+equal" = "change_font_size all +0.25";
  "kitty_mod+minus" = "change_font_size all -0.25";
  "kitty_mod+backspace" = "change_font_size all 0";
  "ctrl+plus" = "change_font_size all +0.25";
  "ctrl+minus" = "change_font_size all -0.25";
  "ctrl+0" = "change_font_size all 0";
  # Numpad
  "kitty_mod+kp_add" = "change_font_size all +0.25";
  "kitty_mod+kp_subtract" = "change_font_size all -0.25";
  # macOS
  "cmd+plus" = "change_font_size all +0.25";
  "cmd+minus" = "change_font_size all -0.25";
  "kitty_mod+a>m" = "set_background_opacity +0.1";
  "kitty_mod+a>l" = "set_background_opacity -0.1";
}
