module Local.Theme (
  tabTheme
, tabTopBarTheme
, topBarTheme
, yellow
) where

import XMonad
import XMonad.Layout.Decoration

black = "#333333"
blue = "#217dd9"
gray = "#d8dbde"
white = "#ffffff"
yellow = "#ffb378"

topBarTheme = def { activeColor = blue
                  , activeBorderColor = blue
                  , activeTextColor = blue
                  , inactiveColor = gray
                  , inactiveBorderColor = gray
                  , inactiveTextColor = gray
                  , urgentColor = yellow
                  , urgentBorderColor = yellow
                  , urgentTextColor = yellow
                  , decoHeight = 10
                  }

tabTheme = def { activeColor = blue
               , activeBorderColor = blue
               , activeTextColor = white
               , inactiveColor = gray
               , inactiveBorderColor = gray
               , inactiveTextColor = black
               , urgentColor = yellow
               , urgentBorderColor = yellow
               , urgentTextColor = black
               , decoHeight = 44
               , fontName = "xft:Product Sans:size=10"
               }

tabTopBarTheme = def { activeColor = blue
                     , activeBorderColor = blue
                     , activeTextColor = blue
                     , inactiveColor = gray
                     , inactiveBorderColor = gray
                     , inactiveTextColor = gray
                     , urgentColor = yellow
                     , urgentBorderColor = yellow
                     , urgentTextColor = yellow
                     , decoHeight = 2
                     }
