module Local.Theme (
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
) where

import XMonad
import XMonad.Layout.Decoration

foreground = "#cbe3e7"
background = "#1b182c"
lightBlack = "#333333"
black = "#111111"
lightRed = "#ff8080"
red = "#ff5458"
lightGreen = "#95ffa4"
green = "#62d196"
lightYellow = "#ffe9aa"
yellow = "#ffb378"
lightBlue = "#91ddff"
blue = "#2e8ae6"
lightMagenta = "#c991e1"
magenta = "#906cff"
lightCyan = "#aaffe4"
cyan = "#63f2f1"
lightWhite = "#cbe3e7"
white = "#ffffff"
lightestGray = "#cbe3e7"
lightGray = "#a6b3cc"
gray = "#565575"
darkGray = "#2b2942"

lightGray2 = "#e7eaed"

topBarTheme = def { activeColor = blue
                  , activeBorderColor = blue
                  , activeTextColor = blue
                  , inactiveColor = lightGray2
                  , inactiveBorderColor = lightGray2
                  , inactiveTextColor = lightGray2
                  , urgentColor = yellow
                  , urgentBorderColor = yellow
                  , urgentTextColor = yellow
                  , decoHeight = 10
                  }

tabTheme = def { activeColor = blue
               , activeBorderColor = blue
               , activeTextColor = white
               , inactiveColor = lightGray2
               , inactiveBorderColor = lightGray2
               , inactiveTextColor = lightBlack
               , urgentColor = yellow
               , urgentBorderColor = yellow
               , urgentTextColor = black
               , decoHeight = 48
               , fontName = "xft:Product Sans:size=10"
               }

tabTopBarTheme = def { activeColor = blue
                     , activeBorderColor = blue
                     , activeTextColor = blue
                     , inactiveColor = lightGray2
                     , inactiveBorderColor = lightGray2
                     , inactiveTextColor = lightGray2
                     , urgentColor = yellow
                     , urgentBorderColor = yellow
                     , urgentTextColor = yellow
                     , decoHeight = 1
                     }
