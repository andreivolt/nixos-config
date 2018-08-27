import           Local.DropdownTerminal              (manageDropdownTerminal)
import           Local.Keys                          as Local
import           Local.Layouts                       as Layouts
import           Local.NotifyUrgencyHook             (handleUrgencyHook)

import           Control.Monad
import qualified Data.Map                            as M
import           XMonad                              hiding ((|||))
import           XMonad.Actions.GroupNavigation
import           XMonad.Actions.Navigation2D
import           XMonad.Config.Azerty                (azertyConfig)
import           XMonad.Hooks.EwmhDesktops           (ewmh)
import           XMonad.Hooks.ManageHelpers
import qualified XMonad.Layout.Fullscreen            as Fullscreen
import           XMonad.Layout.LayoutCombinators     ((|||))
import           XMonad.Layout.MultiToggle           (mkToggle, single)
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (FULL))
import           XMonad.Layout.PerWorkspace          (onWorkspace)
import qualified XMonad.StackSet                     as W


main = xmonad
  ( ewmh
  . withNavigation2DConfig myNav2DConf
  . handleUrgencyHook
  $ myConfig)
  where
    myNav2DConf = def { defaultTiledNavigation = centerNavigation
                       , floatNavigation = centerNavigation
                       , screenNavigation = lineNavigation
                       , layoutNavigation =
                           [ ("Full", centerNavigation)
                           , ("Tabs", hybridNavigation)]
                       }

    myConfig = azertyConfig
                 { terminal = "alacritty"
                 , workspaces = ["1", "2", "3", "4"]
                 , manageHook = myManageHook <+> manageDropdownTerminal
                 , layoutHook = myLayoutHook
                 , clickJustFocuses = True
                 , focusFollowsMouse = False
                 , logHook = historyHook
                 , modMask = Local.modifierKey
                 , borderWidth = 0
                 -- , mouseBindings = Local.myMouseBindings
                 , handleEventHook = Fullscreen.fullscreenEventHook
                 , keys = Local.myKeys
                 }

    myManageHook = composeAll . concat $
       [ [isDialog --> doRectFloat (W.RationalRect (1/4) (1/4) (1/2) (1/2))]
       , [className =? c --> doRectFloat (W.RationalRect (1/4) (1/4) (1/2) (1/2)) | c <- myFloatWCs]
       , [role =? "pop-up" <&&> className =? "Google-chrome-unstable" --> doFloat]
       ] where
        role = stringProperty "WM_WINDOW_ROLE"
        myFloatWCs =
          [ "Sxiv"
          , "mpv"]

    myLayoutHook =
      mkToggle (single Layouts.TABBED)
      $ mkToggle (single FULL)
      $ (Layouts.full |||
         Layouts.masterTabbed |||
         Layouts.tabs |||
         Layouts.centeredMasterTabbed)
