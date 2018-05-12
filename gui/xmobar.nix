{ pkgs, ... }:

{
  environment.systemPackages = with pkgs.haskellPackages; [ xmobar ];

  home-manager.users.avo
    .xdg.configFile."xmobar/xmobarrc".text = let
      myFonts = {
        proportional = "Abel";
        monospace = "Source Code Pro";
        defaultSize = 10;
      };
      theme = import ../themes/challenger-deep.nix;
      online-indicator = pkgs.writeScript "xmobar-online-indicator" (with theme; ''
        color=$(is-online && echo '${green}' || echo '${red}')
        symbol=$(is-online && echo ﯱ || echo ﯱ)

        echo "<fc=$color>$symbol</fc>"
      '');
    in ''
      Config {
          font = "xft:${myFonts.proportional}:size=10.5,SauceCodePro Nerd Font:size:6"
        , bgColor = "${theme.background}"
        , fgColor = "${theme.gray}"
        , overrideRedirect = False
        , textOffset = 35
        , position = BottomSize L 100 50
        , commands = [
            Run DynNetwork
             [ "-L", "50"
             , "-H", "10000"
             , "--low", "${theme.white}"
             , "--normal", "${theme.white}"
             , "--high", "${theme.white}"
             , "--width", "8"
             , "--template", "<rx> ﯲ <tx> ﯴ"]
             50
          , Run Memory
             [ "-t", "<usedratio>%"
             , "--high", "${theme.white}"
             , "--normal", "${theme.white}"
             , "--low", "${theme.white}"]
             10
          , Run StdinReader
          , Run MultiCpu
             [ "-t", "<total>%"
             , "--high", "${theme.white}"
             , "--normal", "${theme.white}"
             , "--low", "${theme.white}"]
             10
          , Run Com "${online-indicator}" [] "is-online" 100
        ]
        , sepChar = "%"
        , alignSep = "}{"
        , template = "   %StdinReader% }{   %dynnetwork%          %memory% MiB          %multicpu%         %is-online%   "
      }
    '';
}
