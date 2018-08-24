module Local.ChallengerDeepTheme (
  background, foreground
, lightBlack, black
, lightRed, red
, lightGreen, green
, lightYellow, yellow
, lightBlue, blue
, lightMagenta, magenta
, lightCyan, cyan
, lightWhite, white
, lightestGray, lightGray
, gray, darkGray
, topBarTheme
, tabTheme, tabTopBarTheme
, xmonadColors
) where

import XMonad
import XMonad.Layout.Decoration

foreground   = "#cbe3e7"
background   = "#1b182c"
lightBlack   = "#565575"
black        = "#100e23"
lightRed     = "#ff8080"
red          = "#ff5458"
lightGreen   = "#95ffa4"
green        = "#62d196"
lightYellow  = "#ffe9aa"
yellow       = "#ffb378"
lightBlue    = "#91ddff"
blue         = "#65b2ff"
lightMagenta = "#c991e1"
magenta      = "#906cff"
lightCyan    = "#aaffe4"
cyan         = "#63f2f1"
lightWhite   = "#cbe3e7"
white        = "#a6b3cc"
lightestGray = "#cbe3e7"
lightGray    = "#a6b3cc"
gray         = "#565575"
darkGray     = "#2b2942"

lightGray2 = "#e8e8e8"

xmonadColors :: XConfig a -> XConfig a
xmonadColors x = x { normalBorderColor  = red
                   , focusedBorderColor = cyan
                   , borderWidth        = 0
                   }

topBarTheme = def { activeColor         = cyan
                  , activeBorderColor   = cyan
                  , activeTextColor     = cyan
                  , inactiveColor       = black
                  , inactiveBorderColor = black
                  , inactiveTextColor   = black
                  , urgentColor         = yellow
                  , urgentBorderColor   = yellow
                  , urgentTextColor     = yellow
                  , decoHeight          = 9
                  }

tabTheme = def { activeColor         = darkGray
               , activeBorderColor   = darkGray
               , activeTextColor     = lightWhite
               , inactiveColor       = lightGray
               , inactiveBorderColor = lightGray
               , inactiveTextColor   = black
               , urgentColor         = yellow
               , urgentBorderColor   = yellow
               , urgentTextColor     = black
               , decoHeight          = 45
               , fontName            = "xft:Lato:size=11"
               }

tabTopBarTheme = def { activeColor         = darkGray
                     , activeBorderColor   = darkGray
                     , activeTextColor     = darkGray
                     , inactiveColor       = lightGray
                     , inactiveBorderColor = lightGray
                     , inactiveTextColor   = lightGray
                     , urgentColor         = yellow
                     , urgentBorderColor   = yellow
                     , urgentTextColor     = yellow
                     , decoHeight          = 6
                     }
