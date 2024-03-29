{
  home-manager.users.andrei = { pkgs, ... }: {
    programs.foot =
      let
        font = {
          # family = "PragmataPro for Powerline";
          family = "Ubuntu Mono";
          size = "24";
        };
      in
      {
        enable = true;
        package = pkgs.nixpkgsUnstable.foot;
        settings = {
          main = {
            font = "${font.family}:size=${font.size}";
            letter-spacing = "-0.5";
          };

          colors = with (import ./theme.nix); {
            foreground = foreground;
            background = background;
          } // (with colors.normal; {
            regular0 = black;
            regular1 = red;
            regular2 = green;
            regular3 = yellow;
            regular4 = blue;
            regular5 = magenta;
            regular6 = cyan;
            regular7 = white;
          }) // (with colors.bright; {
            bright0 = black;
            bright1 = red;
            bright2 = green;
            bright3 = yellow;
            bright4 = blue;
            bright5 = magenta;
            bright6 = cyan;
            bright7 = white;
          });

          mouse.hide-when-typing = "yes";
          cursor.blink = "yes";

          key-bindings = {
            # show-urls-launch = "Alt+f";
          };
        };
      };
  };
}
