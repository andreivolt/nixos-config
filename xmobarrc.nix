{ theme, font }:

''
Config {
    font = "xft:${font}:size=10.5,SauceCodePro Nerd Font:size:6"
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
    , Run Com "/home/avo/.config/xmobar/bin/online-indicator" [] "is-online" 100
  ]
  , sepChar = "%"
  , alignSep = "}{theme."
  , template = "   %StdinReader% }{theme.   %dynnetwork%          %memory% MiB          %multicpu%         %is-online%   "
}
''
