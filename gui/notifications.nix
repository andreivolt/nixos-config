{ pkgs, ... }:

let
  myFonts = {
    proportional = if builtins.getEnv("PROPORTIONAL_FONT_FAMILY") != "" then builtins.getEnv("PROPORTIONAL_FONT_FAMILY") else "Lato";
    monospace = if builtins.getEnv("MONOSPACE_FONT_FAMILY") != "" then builtins.getEnv("MONOSPACE_FONT_FAMILY") else "Source Code Pro";
  };
  theme = import ../theme.nix;

in {
  environment.systemPackages = with pkgs; let
    toggle-notifications = pkgs.stdenv.mkDerivation rec {
      name = "toggle-notifications";

      src = [(pkgs.writeScript name ''
        #!/usr/bin/env bash

        pkill -USR1 ${dunst}/bin/dunst
        pkill -USR2 ${dunst}/bin/dunst
      '')];

      unpackPhase = "true";

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/${name}
      '';
    };
  in [
    libnotify
    toggle-notifications
  ];

  home-manager.users.avo
    .services.dunst = {
      enable = true;
      settings = let font = myFonts.proportional; in {
        global = {
          alignment = "left";
          bounce_freq = "0";
          browser = "${pkgs.google-chrome-dev}/bin/google-chrome-unstable";
          follow = "keyboard";
          font = "${font} 16";
          format = "<b>%s</b>: %b";
          frame_color = "${theme.black}";
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
          separator_color = "${theme.white}";
          separator_height = "1";
          show_age_threshold = "60";
          sort = "yes";
          startup_notification = "false";
          sticky_history = "yes";
          transparency = "10";
          word_wrap = "yes";
        };

        shortcuts = {
          close_all = "ctrl+shift+space";
          history = "ctrl+space";
          context = "ctrl+e";
        };

        urgency_low = {
          background = "${theme.black}";
          foreground = "${theme.white}";
          timeout = 3;
        };

        urgency_normal = {
          background = "${theme.black}";
          foreground = "${theme.white}";
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
          format = "%b";
          history_length = "1";
          timeout = "1";
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
