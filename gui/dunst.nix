{ pkgs, ... }:

let
  myFonts = {
    proportional = builtins.getEnv "PROPORTIONAL_FONT_FAMILY";
    monospace = builtins.getEnv "MONOSPACE_FONT_FAMILY";
  };
  theme = import ../themes/challenger-deep.nix;

in {
  home-manager.users.avo
    .services.dunst = {
      enable = true;
      settings = let font = myFonts.proportional; in {
        global = {
          alignment = "left";
          bounce_freq = "0";
          browser = "${pkgs.qutebrowser}/bin/qutebrower-open-in-instance";
          dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
          follow = "keyboard";
          font = "${font} 16";
          format = "<b>%s</b>: %b";
          frame_color = "${theme.background}";
          frame_width = "1";
          geometry = "600x15+150-350";
          horizontal_padding = "16";
          idle_threshold = "120";
          ignore_newline = "yes";
          indicate_hidden = "yes";
          line_height = "0";
          markup = "yes";
          monitor = "0";
          padding = "12";
          separator_color = "auto";
          separator_height = "1";
          show_age_threshold = "60";
          sort = "yes";
          startup_notification = "false";
          sticky_history = "yes";
          transparency = "5";
          word_wrap = "yes";
        };

        shortcuts = {
          close_all = "ctrl+shift+space";
          history = "ctrl+space";
          context = "ctrl+e";
        };

        urgency_low = {
          background = "${theme.background}";
          foreground = "${theme.foreground}";
          timeout = 3;
        };

        urgency_normal = {
          background = "${theme.background}";
          foreground = "${theme.foreground}";
          timeout = 3;
        };

        urgency_critical = {
          background = "${theme.red}";
          foreground = "${theme.white}";
          timeout = 3;
        };

        irc = {
          appname = "irc";
          summary = "*ndrei*";
          format = "%b";
          script = "tts";
        };

        volume = {
          appname = "volume";
          urgency = "low";
          stack_duplicates = false;
          format = "%b";
          hide_duplicates_count = true;
          history_length = "1";
          timeout = "1";
        };

        ignore-dropbox = {
          appname = "Dropbox";
          summary = "*";
          format = "";
        };

        sticky = {
          appname = "sticky";
          format = "%s %b";
          timeout = 0;
        };

        whattimeisit = {
          appname = "whattimeisit";
          format = "%s";
          timeout = "1";
        };

        todo = {
          appname = "todo";
          format = "TODO %b";
          timeout = 0;
        };
      };
    };
}
