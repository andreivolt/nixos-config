import           Local.DropdownTerminal              (manageDropdownTerminal)
import           Local.FloatHelpers                  (markAsFloating)
import           Local.Keys                          as Local
import           Local.Layouts                       as Layouts
import           Local.NotifyUrgencyHook             (handleUrgencyHook)
import           Local.Scratchpads                   (manageMyScratchpads)
import           Local.StatusBar                     (withStatusBar)

import           Control.Monad
import qualified Data.Map                            as M
import           XMonad                              hiding ((|||))
import           XMonad.Actions.GroupNavigation
import           XMonad.Actions.Navigation2D
import           XMonad.Actions.UpdatePointer
import           XMonad.Config.Azerty                (azertyConfig)
import           XMonad.Hooks.EwmhDesktops           (ewmh)
import           XMonad.Hooks.ManageDocks            (avoidStruts, docks,
                                                      docksEventHook,
                                                      docksStartupHook,
                                                      manageDocks)
import           XMonad.Hooks.ManageHelpers
import qualified XMonad.Layout.Fullscreen            as Fullscreen
import           XMonad.Layout.LayoutCombinators     ((|||))
import           XMonad.Layout.MultiToggle           (mkToggle, single)
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (FULL))
import           XMonad.Layout.PerWorkspace          (onWorkspace)
import qualified XMonad.StackSet                     as W
import           XMonad.Layout.ShowWName

import XMonad.Actions.ShowText


main = xmonad myConfig
  where
    myConfig = azertyConfig
                 { terminal          = "alacritty"
                 , workspaces        = ["1", "2", "3", "4"]
                 , manageHook        = myManageHook
                                       <+> manageDocks
                                       <+> manageDropdownTerminal
                                       <+> manageMyScratchpads
                 , layoutHook        = myLayoutHook
                 , clickJustFocuses  = True
                 , focusFollowsMouse = False
                 , logHook           = historyHook
                 , modMask           = Local.modifierKey
                 , borderWidth       = 0
                 , handleEventHook   = Fullscreen.fullscreenEventHook
                                       <+> docksEventHook
                                       <+> handleTimerEvent
                 , keys              = Local.myKeys
                 }

    myManageHook = composeAll . concat $
       [ [isDialog           --> (ask >>= \w -> liftX (markAsFloating w) >> doRectFloat (W.RationalRect (1/4) (1/4) (1/2) (1/2)))]
       -- , [isFullscreen       --> doFullFloat]
       , [className =? c     --> (ask >>= \w -> liftX (markAsFloating w) >> doCenterFloat) | c <- myFloatWCs]
       ] where
        myFloatWCs =
          [ "Sxiv"
          , "mpv"]

        shiftByClass s ws = className =? s --> doShift ws

    -- showWorkspaceNameOnChange = showWName' def { swn_font = "xft:Abel-24", swn_fade = 1 }

    myLayoutHook =
      mkToggle (single Layouts.TABBED)
      $ mkToggle (single FULL)
      $ (Layouts.full |||
         Layouts.masterTabbed |||
         Layouts.tabs |||
         Layouts.webdev)
