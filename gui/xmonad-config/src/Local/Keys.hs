{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Local.Keys (myKeys, myMouseBindings, modifierKey) where

import           Local.ConditionalKeys
import           Local.DropdownTerminal              (toggleDropdownTerminal)
import           Local.Layouts                       (TABBED (..))
import           Local.Scratchpads                   (toggleScratchpad)

import           XMonad
import           XMonad.Actions.CycleWS              (WSType (EmptyWS, WSIs, WSTagGroup),
                                                      moveTo, nextWS, prevWS,
                                                      shiftTo, shiftToNext,
                                                      shiftToPrev)
import           XMonad.Actions.GroupNavigation      (Direction (Backward, Forward),
                                                      nextMatch)
import           XMonad.Actions.Navigation2D         (screenGo, windowGo,
                                                      windowToScreen)
import           XMonad.Actions.UpdatePointer
import qualified XMonad.Hooks.ManageDocks            as MD
import           XMonad.Hooks.UrgencyHook            (focusUrgent)
import           XMonad.Layout                       (ChangeLayout (NextLayout),
                                                      Resize (Expand, Shrink))
import           XMonad.Layout.LayoutCombinators     (JumpToLayout (JumpToLayout))
import           XMonad.Layout.MultiToggle           (Toggle (Toggle))
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (FULL))
import           XMonad.Layout.WindowNavigation      (Direction2D (D, L, R, U))
import qualified XMonad.StackSet                     as W
import           XMonad.Util.EZConfig                (mkKeymap)
import           XMonad.Util.Paste                   (pasteSelection)

import qualified Data.Map                            as M
import           XMonad.Util.Paste                   as Paste
import           XMonad.Util.Run
import           XMonad.Util.XSelection
import qualified XMonad.Actions.FlexibleManipulate   as Flex


modifierKey = mod4Mask

myKeys conf =
  (myKeys' conf) `M.union` (M.fromList [((0, xK_twosuperior), toggleDropdownTerminal)])

myKeys' conf@XConfig {XMonad.modMask = modm} = mkKeymap conf
  [ "<Insert>"               ~~ runProcessWithInput "copy" [] "" >>= Paste.pasteString

  , "<Pause>"                ~~ spawn "suspend"
  , "M-q"                    ~~ spawn "xmonad=~/.local/share/xmonad/xmonad-x86_64-linux; $xmonad --recompile && $xmonad --restart"

  , "<Print>"                ~~ spawn "gtk-launch flameshot.desktop"
  , "M-S-<Return>"           ~~ spawn $ XMonad.terminal conf

  , "M-p"                    ~~ spawn "notify-send -a whattimeisit \"$(whattimeisit)\""

  , "<XF86AudioRaiseVolume>" ~~ spawn "volume up"
  , "<XF86AudioLowerVolume>" ~~ spawn "volume down"
  , "<XF86AudioStop>"        ~~ spawn "volume mute-toggle"

  , "<F7>"                   ~~ toggleScratchpad "music"

  , "M-<F1>"                 ~~ spawn "nightlight -b-"
  , "M-<F2>"                 ~~ spawn "nightlight -t-"
  , "M-<F3>"                 ~~ spawn "nightlight -t+"
  , "M-<F4>"                 ~~ spawn "nightlight -b+"

  , "M-s"                    ~~ withFocused $ windows . W.sink

  , "M-<Space>"              ~~ sendMessage NextLayout
  , "M-f"                    ~~ sendMessage (Toggle FULL)
  , "M-t"                    ~~ sendMessage (Toggle TABBED)
  , "M-:"                    ~~ Paste.pasteString "y" >> spawn "sleep 0.1; surfraw google $(xsel -b)"

  , "M-S-c"                  ~~ kill

  , "M-a n"                  ~~ spawn "notify-send foo"

  , "M-u"                    ~~ focusUrgent

  , "M-<Tab>"                ~~ windows W.focusDown
  , "M-S-<Tab>"              ~~ windows W.focusUp
  , "M-<Return>"             ~~ windows W.swapMaster

  , "M-i"                    ~~ nextMatch Backward (return True)
  , "M-o"                    ~~ nextMatch Forward (return True)

  , "M-h"                    ~~ bindOn LD [("Tabs", windows W.focusUp), ("", windowGo MD.L False)]
  , "M-j"                    ~~ windowGo MD.D False
  , "M-k"                    ~~ windowGo MD.U False
  , "M-l"                    ~~ bindOn LD [("Tabs", windows W.focusDown), ("", windowGo MD.R False)]

  , "M-S-h"                  ~~ windowToScreen MD.L False
  , "M-S-j"                  ~~ windowToScreen MD.D False
  , "M-S-k"                  ~~ windowToScreen MD.U False
  , "M-S-l"                  ~~ windowToScreen MD.R False

  , "M-M1-h"                 ~~ sendMessage Shrink
  , "M-M1-l"                 ~~ sendMessage Expand

  , "M-<Left>"               ~~ prevWS
  , "M-<Right>"              ~~ nextWS
  ]
 where
  infixr 0 ~~
  (~~) :: a -> b -> (a, b)
  (~~) = (,)


myMouseBindings XConfig {XMonad.modMask = modMask} = M.fromList
  [ ((modMask, button1), (\w -> focus w >> windows W.swapMaster))
  , ((modMask, button3), (\w -> focus w >> Flex.mouseWindow Flex.discrete w))
  ]
