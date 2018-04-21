{ theme }:
let
  inherit (theme) blue yellow red foreground background;
in
''
Config {
    font = "xft:Abel:size=11,xft:Iosevka Custom:size=10.5"
  , bgColor = "#000000"
  , fgColor = "#565575"
  , overrideRedirect = False
  , textOffset = 34
  , position = BottomSize L 100 40
  , commands = [
      Run DynNetwork
       [ "-L","50"
       , "-H","10000"
       , "--low","gray"
       , "--normal","#cbe3e7"
       , "--high","#ff5458"
       , "--template","<rx> : <tx>"]
        50
    , Run Com "/home/avo/.config/xmobar/bin/load-average" [] "load-average" 100
    , Run StdinReader
    , Run Com "/home/avo/.config/xmobar/bin/online-indicator" [] "is-online" 100
  ]
  , sepChar = "%"
  , alignSep = "}{"
  , template = "   %StdinReader% }{ %dynnetwork%  |  %load-average%  |  %is-online%   "
}
''
