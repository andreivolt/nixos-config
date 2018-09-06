{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Local.Keys (myKeys, modifierKey) where

import           Local.ConditionalKeys
import           Local.DropdownTerminal              (toggleDropdownTerminal)
import           Local.Layouts                       (TABBED (..))

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
  [ "M-q"                    ~~ spawn "xmonad --recompile && xmonad --restart"

  , "<Print>"                ~~ spawn "gtk-launch flameshot.desktop"

  , "M-S-<Return>"           ~~ spawn $ XMonad.terminal conf

  , "M-p"                    ~~ spawn "notify-send -a whattimeisit \"$(whattimeisit)\""

  , "<XF86AudioRaiseVolume>" ~~ spawn "volume up"
  , "<XF86AudioLowerVolume>" ~~ spawn "volume down"
  , "<XF86AudioMute>"        ~~ spawn "volume mute-toggle"

  , "M-g"                    ~~ spawn "window-switcher"

  , "M-<Space>"              ~~ sendMessage NextLayout
  , "M-f"                    ~~ sendMessage (Toggle FULL)
  , "M-t"                    ~~ sendMessage (Toggle TABBED)

  , "M-:"                    ~~ Paste.pasteString "y" >> spawn "sleep 0.1; google-search $(xsel -b)"

  , "M-S-c"                  ~~ kill

  , "M-u"                    ~~ focusUrgent

  , "M-<Return>"             ~~ windows W.swapMaster

  , "M-s"                    ~~ withFocused $ windows . W.sink

  , "M-<Tab>"                ~~ windows W.focusDown
  , "M-S-<Tab>"              ~~ windows W.focusUp
  , "M-h"                    ~~ windows W.focusDown
  , "M-j"                    ~~ windowGo MD.D False
  , "M-k"                    ~~ windowGo MD.U False
  , "M-l"                    ~~ windows W.focusUp

  , "M-S-h"                  ~~ windows W.swapDown
  , "M-S-j"                  ~~ windows W.swapUp
  , "M-S-k"                  ~~ windows W.swapDown
  , "M-S-l"                  ~~ windows W.swapUp

  , "M-M1-h"                 ~~ sendMessage Shrink
  , "M-M1-l"                 ~~ sendMessage Expand
  ]
 where
  infixr 0 ~~
  (~~) :: a -> b -> (a, b)
  (~~) = (,)
