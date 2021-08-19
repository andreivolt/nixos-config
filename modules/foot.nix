{
  home-manager.users.avo.programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        # term = "xterm-256color";
        font = "JetBrainsMono Nerd Font Mono:size=10";
        # dpi-aware = "yes";
        letter-spacing = "-0.5";
      };

      colors = with (import ./theme.nix); {
        foreground = foreground;
        background = background;

        regular0 = black_bg;
        regular1 = red_fg;
        regular2 = green_fg;
        regular3 = yellow_fg;
        regular4 = blue_fg;
        regular5 = magenta_fg;
        regular6 = cyan_fg;
        regular7 = white_fg;

        bright0 = black_bg;
        bright1 = red_bg;
        bright2 = green_bg;
        bright3 = yellow_bg;
        bright4 = blue_bg;
        bright5 = magenta_bg;
        bright6 = cyan_bg;
        bright7 = white_bg;
      };

      mouse.hide-when-typing = "yes";

      key-bindings = {
        # show-urls-launch = "Alt+f";
      };
    };
  };
}
