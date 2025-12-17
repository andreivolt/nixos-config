{pkgs, ...}:
let
  colors = import ./colors.nix;
  aurora = colors.aurora;
  accent = colors.accent;
  ui = colors.ui;

  kittyScrollbackNvim = pkgs.fetchFromGitHub {
    owner = "mikesmithgh";
    repo = "kitty-scrollback.nvim";
    rev = "v6.2.2";
    hash = "sha256-0OPNHWR/qCbMKDQE6Pbt0Ew9QCm2ZSeZq4s9OL2rj04=";
  };

  nvimScrollbackConfig = ''
    vim.opt.rtp:prepend("${kittyScrollbackNvim}")
    vim.opt.signcolumn = "no"
    vim.opt.statuscolumn = ""
    vim.opt.clipboard = "unnamedplus"

    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        vim.highlight.on_yank({ timeout = 100 })
      end,
    })

    vim.api.nvim_create_autocmd("TermClose", {
      callback = function()
        vim.api.nvim_echo({}, false, {})
      end,
    })

    require("kitty-scrollback").setup({
      {
        paste_window = { yank_register_enabled = false },
        callbacks = {
          after_ready = function()
            vim.wo.wrap = true
          end,
        },
      },
    })
  '';
in {
  home-manager.sharedModules = [
    ({lib, ...}: {
      # nvim-scrollback profile for kitty-scrollback.nvim
      xdg.configFile."nvim-scrollback/init.lua".text = nvimScrollbackConfig;

      programs.kitty = {
        enable = true;

        font = {
          name = "Pragmasevka Nerd Font Light";
          size = 15;
        };

        extraConfig = ''
          modify_font cell_height 94%
          modify_font cell_width 88%

          # kitty-scrollback.nvim (uses separate nvim-scrollback profile)
          action_alias kitty_scrollback_nvim kitten ${kittyScrollbackNvim}/python/kitty_scrollback_nvim.py --env NVIM_APPNAME=nvim-scrollback
        '';

        settings = {
          bold_font = "Pragmasevka Nerd Font SemiBold";
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

          # Aurora terminal colors with Obsidian Aurora chrome
          background = aurora.background;
          foreground = aurora.foreground;
          selection_background = aurora.selection.background;
          selection_foreground = aurora.selection.foreground;
          url_color = aurora.normal.blue;
          cursor = aurora.cursor;
          cursor_text_color = aurora.cursorText;
          active_border_color = accent.primary;
          inactive_border_color = ui.border;
          active_tab_background = ui.bgAlt;
          active_tab_foreground = accent.primary;
          inactive_tab_background = aurora.background;
          inactive_tab_foreground = ui.fgDim;
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
          "kitty_mod+h" = "kitty_scrollback_nvim";
          "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
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
