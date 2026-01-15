{pkgs, ...}:
let
  colors = import ../colors.nix;
  colorSettings = import ./colors.nix { inherit colors; };
  keybindings = import ./keybindings.nix;

  kittyScrollbackNvim = pkgs.fetchFromGitHub {
    owner = "mikesmithgh";
    repo = "kitty-scrollback.nvim";
    rev = "v6.2.2";
    hash = "sha256-0OPNHWR/qCbMKDQE6Pbt0Ew9QCm2ZSeZq4s9OL2rj04=";
  };

  scrollbackConfig = ''
    vim.opt.rtp:prepend("${kittyScrollbackNvim}")
    dofile(vim.fn.expand("~/.config/nvim-pager.lua"))

    vim.api.nvim_create_autocmd("TermClose", {
      callback = function()
        vim.api.nvim_echo({}, false, {})
      end,
    })

    require("kitty-scrollback").setup({
      {
        paste_window = { yank_register_enabled = false },
      },
    })
  '';
in {
  home-manager.sharedModules = [
    ({lib, ...}: {
      xdg.configFile."nvim-scrollback/init.lua".text = scrollbackConfig;

      programs.kitty = {
        enable = true;

        font = {
          name = "Pragmasevka Nerd Font Light";
          size = 13;
        };

        extraConfig = ''
          modify_font cell_width 88%
          modify_font underline_position 3
          modify_font underline_thickness 150%

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
          window_padding_width = 5;
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

          # Scrollbar
          scrollbar_width = 1.25;
          scrollbar_hover_width = 2;
          visual_bell_duration = "0.1";
          visual_bell_color = "red";
        } // colorSettings;

        inherit keybindings;
      };

      xdg.configFile."kitty/macos-launch-services-cmdline" = lib.mkIf pkgs.stdenv.isDarwin {
        text = "--start-as=fullscreen";
      };
    })
  ];
}
