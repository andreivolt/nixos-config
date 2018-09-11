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
import qualified XMonad.StackSet                     as W
import XMonad.Layout.Gaps
import           XMonad.Actions.GroupNavigation      (Direction (Backward, Forward))
import           XMonad.Actions.Navigation2D         (windowGo)
import qualified XMonad.Hooks.ManageDocks            as MD
import           XMonad.Hooks.UrgencyHook            (focusUrgent)
import           XMonad.Layout                       (ChangeLayout (NextLayout),
                                                      Resize (Expand, Shrink))
import           XMonad.Layout.LayoutCombinators     (JumpToLayout (JumpToLayout))
import           XMonad.Layout.WindowNavigation      (Direction2D (D, L, R, U))
import qualified XMonad.StackSet                     as W
import           XMonad.Util.EZConfig                (mkKeymap)
import           XMonad.Util.Paste                   (pasteSelection)
import qualified Data.Map                            as M
import           XMonad.Util.Paste                   as Paste
import           XMonad.Util.XSelection
import qualified XMonad.Actions.FlexibleManipulate   as Flex
import qualified XMonad.StackSet        as W
import           XMonad.Util.Scratchpad (scratchpadManageHook,
                                         scratchpadManageHookDefault,
                                         scratchpadSpawnActionCustom)
import           XMonad                           (Full (Full), Mirror (Mirror),
                                                   Tall (Tall), Typeable,
                                                   Window)
import           XMonad.Layout.ComboP             (Property (..), combineTwoP)
import qualified XMonad.Layout.Fullscreen         as Fullscreen
import           XMonad.Layout.Master
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.NoFrillsDecoration (noFrillsDeco)
import           XMonad.Layout.Simplest           (Simplest (Simplest))
import           XMonad.Layout.Tabbed             (addTabs)
import XMonad.ManageHook
import XMonad.Util.NamedScratchpad
import XMonad.Layout.Decoration
import XMonad.Hooks.DynamicProperty

import           XMonad.Hooks.UrgencyHook  (BorderUrgencyHook (BorderUrgencyHook),
                                            RemindWhen (Every),
                                            SuppressWhen (Focused), UrgencyHook,
                                            remindWhen, suppressWhen,
                                            urgencyBorderColor, urgencyConfig,
                                            urgencyHook, withUrgencyHook,
                                            withUrgencyHookC)
import qualified XMonad.StackSet           as W
import           XMonad.Util.NamedWindows  (getName)

import           Control.Applicative       ((<$>))


main = xmonad
  ( ewmh
  . withNavigation2DConfig myNav2DConf
  -- . handleUrgencyHook
  $ myConfig)
  where
    myNav2DConf = def {
      defaultTiledNavigation = centerNavigation
    , floatNavigation = centerNavigation
    , screenNavigation = lineNavigation
    , layoutNavigation =
        [ ("Full", centerNavigation)
        , ("Tabs", hybridNavigation)
        ]
    }

    myConfig = azertyConfig {
      manageHook =
        myManageHook
        <+> scratchpadManageHook (W.RationalRect 0.2 0.2 0.6 0.6)
        <+> namedScratchpadManageHook scratchpads
     , layoutHook = myLayoutHook
     , logHook = historyHook
     , focusFollowsMouse = False
     , borderWidth = 0
     , modMask = mod4Mask, keys = myKeys, mouseBindings = myMouseBindings
     , handleEventHook = Fullscreen.fullscreenEventHook
                         <+> dynamicTitle myManageHook
     }
     where
       myLayoutHook =
         (mkToggle (single FULL)
         $ gaps [(U, 30), (D, 30), (L, 800), (R, 800)]
         $ (Fullscreen.fullscreenFull Full |||
            masterTabbed |||
            tabs))
         where
           tabs =
             addTabTopBar
             $ myAddTabs Simplest
             where
               addTabTopBar = noFrillsDeco shrinkText tabTopBarTheme
                 where tabTopBarTheme = def {
                     activeColor = blue
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
               myAddTabs = addTabs shrinkText tabTheme
                 where tabTheme = def {
                    activeColor = blue
                  , activeBorderColor = blue
                  , activeTextColor = white
                  , inactiveColor = gray
                  , inactiveBorderColor = gray
                  , inactiveTextColor = black
                  , urgentColor = yellow
                  , urgentBorderColor = yellow
                  , urgentTextColor = black
                  , decoHeight = 44
                  , fontName = "xft:Proxima Nova Condensed Semibold:size=10"
                  }

           masterTabbed =
             addTopBar $ mastered (1 / 100) (1 / 2) tabs
             where
               addTopBar = noFrillsDeco shrinkText topBarTheme
                 where topBarTheme = def {
                     activeColor = blue
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

       myManageHook = composeAll . concat $
          [ [className =? c --> doFloat | c <- myFloatWCs]
          , [role =? "pop-up" --> doFloat]
          , [title =? "XXX" --> doFloat]
          , [className =? "webapp" --> doSink]
          , [isDialog --> doFloat]
          ] where
           myDoFloat = doRectFloat $ W.RationalRect 0.2 0.2 0.6 0.6

           doSink = ask >>= \w -> doF (W.sink w)

           role = stringProperty "WM_WINDOW_ROLE"

           myFloatWCs =
             [ "Sxiv"
             , "Gcolor3"
             , "mpv"
             ]

       myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
           -- mod-button1, Set the window to floating mode and move by dragging
           [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))
           -- mod-button2, Raise the window to the top of the stack
           , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
           -- mod-button3, Set the window to floating mode and resize by dragging
           , ((modm, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))
           ]

       myKeys conf =
         (myKeys' conf) `M.union` (M.fromList [((0, xK_twosuperior), toggleDropdownTerminal)])
         where toggleDropdownTerminal = scratchpadSpawnActionCustom "terminal --class scratchpad --title scratchpad"

       myKeys' conf@XConfig {XMonad.modMask = modm} = mkKeymap conf
         [ ("M-q"                    , spawn "xmonad --recompile && xmonad --restart")

         , ("<Print>"                , spawn "flameshot")
         , ("M-S-<Return>"           , spawn "terminal")
         , ("M-p"                    , spawn "whattimeisit")
         , ("<XF86AudioRaiseVolume>" , spawn "volumectl up")
         , ("<XF86AudioLowerVolume>" , spawn "volumectl down")
         , ("<XF86AudioMute>"        , spawn "volumectl mute-toggle")
         , ("M-b"                    , spawn "browser")

         , ("<F1>"                   , namedScratchpadAction scratchpads "todos")
         , ("<F2>"                   , namedScratchpadAction scratchpads "todos-lib")
         , ("<F3>"                   , namedScratchpadAction scratchpads "Pushbullet")
         , ("<F4>"                   , spawn "set-scratchpad")

         , ("M-g"                    , sendMessage $ ToggleGaps)
         , ("M-<Left>"               , sequence_ [ sendMessage (IncGap 20 L), sendMessage (IncGap 20 R) ])
         , ("M-<Right>"              , sequence_ [ sendMessage (DecGap 20 L), sendMessage (DecGap 20 R) ])

         , ("M-<Space>"              , sendMessage NextLayout)
         , ("M-f"                    , sendMessage (Toggle FULL))
         , ("M-<Return>"             , windows W.swapMaster)
         , ("M-s"                    , withFocused $ windows . W.sink)

         , ("M-:"                    , Paste.pasteString "y" >> spawn "sleep 0.1; google-search $(xsel -b)")
         , ("M-S-c"                  , kill)
         , ("M-u"                    , focusUrgent)

         , ("M-<Tab>"                , windows W.focusDown)
         , ("M-S-<Tab>"              , windows W.focusUp)

         , ("M-h"                    , windows W.focusUp)
         , ("M-l"                    , windows W.focusDown)
         , ("M-j"                    , windowGo MD.D False)
         , ("M-k"                    , windowGo MD.U False)

         , ("M-S-h"                  , windows W.swapDown)
         , ("M-S-j"                  , windows W.swapUp)
         , ("M-S-k"                  , windows W.swapDown)
         , ("M-S-l"                  , windows W.swapUp)

         , ("M-M1-h"                 , sendMessage Shrink)
         , ("M-M1-l"                 , sendMessage Expand)
         ]

    scratchpads =
      [ NS "todos" "todos" (title =? "todos") (customFloating $ W.RationalRect (1/10) (1/10) (4/5) (4/5))
      , NS "Pushbullet" "pushbullet" (title =? "Pushbullet") (customFloating $ W.RationalRect (1/10) (1/10) (4/5) (4/5))
      , NS "todos-lib" "todos-lib" (title =? "todos-lib") (customFloating $ W.RationalRect (1/10) (1/10) (4/5) (4/5))
      ]

    black = "#333333"
    blue = "#217dd9"
    gray = "#d8dbde"
    white = "#ffffff"
    yellow = "#ffb378"


-- data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

-- instance UrgencyHook LibNotifyUrgencyHook

-- handleUrgencyHook =
--   withUrgencyHook LibNotifyUrgencyHook .
--   withUrgencyHookC BorderUrgencyHook { urgencyBorderColor = yellow }
--                      urgencyConfig { suppressWhen = Focused, remindWhen = Every 60 }
