import           Local.DropdownTerminal              (manageDropdownTerminal)
import           Local.FloatHelpers                  (markAsFloating)
import           Local.Keys                          as Local
import           Local.Layouts                       as Layouts
import           Local.NotifyUrgencyHook             (handleUrgencyHook)
import           Local.Scratchpads                   (manageMyScratchpads)
import           Local.StatusBar                     (withStatusBar)
import qualified Local.Workspaces                    as Local

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


main = xmonad
  =<< withStatusBar
  ( ewmh
  . withNavigation2DConfig myNav2DConf
  . handleUrgencyHook
  . docks
  $ myConfig)
   where
    myNav2DConf = def { defaultTiledNavigation = centerNavigation
                      , floatNavigation        = centerNavigation
                      , screenNavigation       = lineNavigation
                      , layoutNavigation       = [ ("Full", centerNavigation)
                                                 , ("Tabs", hybridNavigation)]
                      }

    myConfig = azertyConfig
                 { terminal          = "alacritty"
                 , workspaces        = Local.workspaceNames
                 , manageHook        = myManageHook
                                       <+> manageDocks
                                       <+> manageDropdownTerminal
                                       <+> manageMyScratchpads
                 , startupHook       = myStartupHook
                 , layoutHook        = myLayoutHook
                 , clickJustFocuses  = True
                 , focusFollowsMouse = False
                 , logHook           = historyHook
                                       <+> updatePointer (0.25, 0.25) (0.25, 0.25)
                 , modMask           = Local.modifierKey
                 , mouseBindings     = Local.myMouseBindings
                 , borderWidth       = 0
                 , handleEventHook   = Fullscreen.fullscreenEventHook
                                       <+> docksEventHook
                                       <+> handleTimerEvent
                 , keys              = Local.myKeys
                 }

   -- myDynHook = composeAll
   --   [ title =? "editor" --> doRectFloat (W.RationalRect (1/4) (1/4) (1/2) (1/2))]

    myStartupHook = do
      docksStartupHook

    myManageHook = composeAll . concat $
       [ [isDialog           --> (ask >>= \w -> liftX (markAsFloating w) >> doRectFloat (W.RationalRect (1/4) (1/4) (1/2) (1/2)))]
       -- , [isFullscreen       --> doFullFloat]
       , [className =? c     --> (ask >>= \w -> liftX (markAsFloating w) >> doCenterFloat) | c <- myFloatWCs]
       , [className =? "mpv" --> doShift "VID"]
       ] where
        myFloatWCs =
          [ "Sxiv"
          , "mpv"]

        shiftByClass s ws = className =? s --> doShift ws

    -- showWorkspaceNameOnChange = showWName' def { swn_font = "xft:Abel-24", swn_fade = 1 }

    myLayoutHook =
        avoidStruts
      -- $ showWorkspaceNameOnChange
      $ onWorkspace "MAIN" (Layouts.tabs ||| Layouts.masterTabbed ||| Layouts.full)
      $ onWorkspace "REF" (Layouts.tabs ||| Layouts.masterTabbed ||| Layouts.full)
      $ onWorkspace "VID" Layouts.full
      $ onWorkspace "WEBDEV" Layouts.webdev
      -- $ onWorkspace "VID" grid
      $ mkToggle (single Layouts.TABBED)
      $ mkToggle (single FULL)
      $ (Layouts.full |||
         Layouts.masterTabbed |||
         Layouts.tabs |||
         Layouts.webdev)



-- myKeyBindingsTable = concat $ table

-- --    key             M-                     M-S-                    M-C-                    M-S-C-
-- table =
--   [ k "<Return>"     launchTerminal          __                      __                      __
--   , k "a"            __                      __                      __                      __
--   , k "b"            __                      __                      __                      __
--   , k "c"            goUp                    swapUp                  expandVertical          moveUp
--   , k "d"            __                      __                      __                      __
--   , k "e"            __                      __                      __                      __
--   , k "f"            __                      tileFloating            __                      resizeFloatingWindow
--   , k "g"            __                      __                      __                      __
--   , k "h"            goLeft                  swapLeft                shrinkHorizontal        moveLeft
--   , k "i"            __                      __                      __                      __
--   , k "j"            __                      __                      __                      __
--   , k "k"            __                      __                      __                      __
--   , k "l"            __                      __                      __                      __
--   , k "m"            gotoMaster              swapMaster              __                      toggleMagnifier
--   , k "n"            goRight                 swapRight               expandHorizontal        moveRight
--   , k "o"            __                      __                      __                      __
--   , k "p"            __                      __                      __                      __
--   , k "q"            closeWindow             deleteWorkspace         __                      __
--   , k "r"            __                      __                      __                      __
--   , k "s"            jumpToNextScreen        jumpToPrevScreen        __                      __
--   , k "t"            goDown                  swapDown                shrinkVertical          moveDown
--   , k "u"            __                      __                      __                      __
--   , k "v"            __                      __                      __                      __
--   , k "w"            gotoWorkspace           shiftToWorkspace        createWorkspace         shiftAndGoToWorkspace
--   , k "x"            __                      __                      renameWorkspace'        deleteWorkspace
--   , k "y"            __                      __                      __                      __
--   , k "z"            promptZealSearch        __                      __                      __
--   , k "<Backspace>"  closeWindow             __                      __                      deleteWorkspace
--   , k "<Space>"      launchKupfer            nextKeyboardLayout      __                      __
--   , k "<Tab>"        nextLayout              resetLayout             __                      __
--   , k "`"            scratchTerminal         __                      __                      __
--   , k "'"            gridSelect              __                      __                      __
--   , k "/"            promptWebSearch         selectWebSearch         __                      __
--   , k "0"            gotoPrevWorkspace       __                      __                      __
--   , k "<F5>"         __                      restartXMonad           __                      __
--   , k "<F10>"        __                      logout                  __                      __
--   , k "<F11>"        __                      reboot                  __                      __
--   , k "<F12>"        __                      powerOff                __                      __
--   , [bind "M1-" "<Tab>" gotoNextWindow]
--   -- Multimedia keys
--   , [bind "" "<XF86AudioMute>"         audioMute]
--   , [bind "" "<XF86AudioLowerVolume>"  audioLowerVolume]
--   , [bind "" "<XF86AudioRaiseVolume>"  audioRaiseVolume]
--   , [bind "" "<XF86AudioPlay>"         audioPlay]
--   , [bind "" "<XF86AudioStop>"         audioStop]
--   , [bind "" "<XF86MonBrightnessDown>" brightnessDown]
--   , [bind "" "<XF86MonBrightnessUp>"   brightnessUp]
--   , [bind "" "<XF86Favorites>"         sendKiss]
--   ]
--   where
--     k key m ms mc msc =
--       [ bind "M-"      key m
--       , bind "M-S-"    key ms
--       , bind "M-C-"    key mc
--       , bind "M-S-C-"  key msc
--       ]
--     bind modifiers key (Unbound comment action) = (modifiers ++ key, action)
--     bind modifiers key (Bound comment action) = (modifiers ++ key, action $ modifiers ++ key)
--     __ = Bound "Available for use"
--          (\key -> spawn $ "xmessage '" ++ key ++ " is not bound.'")

--     -- Actions
--     -- Launch program
--     launchBrowser           = Unbound "Launch browser"                      (spawn appBrowser)
--     launchTerminal          = Unbound "Launch terminal"                     (spawn appTerminal)
--     launchKupfer            = Unbound "Launch kupfer"                       (spawn "kupfer")
--     -- Window navigation
--     gotoNextWindow          = Unbound "Switch to next window"               (windows W.focusDown)
--     gotoMaster              = Unbound "Move focus to the master window"     (windows W.focusMaster)
--     goUp                    = Unbound "Switch to window above"              (sendMessage $ Go U)
--     goDown                  = Unbound "Switch to window below"              (sendMessage $ Go D)
--     goLeft                  = Unbound "Switch to window to the left"        (sendMessage $ Go L)
--     goRight                 = Unbound "Switch to window to the right"       (sendMessage $ Go R)
--     swapMaster              = Unbound "Swap with the master window"         (windows W.swapMaster)
--     swapUp                  = Unbound "Swap with window above"              (sendMessage $ Swap U)
--     swapDown                = Unbound "Swap with window below"              (sendMessage $ Swap D)
--     swapLeft                = Unbound "Swap with window to the left"        (sendMessage $ Swap L)
--     swapRight               = Unbound "Swap with window to the right"       (sendMessage $ Swap R)
--     -- Floating window manipulation
--     moveUp                  = Unbound "Move floating window up"             (withFocused (keysMoveWindow (0, -10)))
--     moveDown                = Unbound "Move floating window down"           (withFocused (keysMoveWindow (0, 10)))
--     moveLeft                = Unbound "Move floating window left"           (withFocused (keysMoveWindow (-10, 0)))
--     moveRight               = Unbound "Move floating window right"          (withFocused (keysMoveWindow (10, 0)))
--     expandVertical          = Unbound "Expand floating window vertically"   (withFocused (keysResizeWindow (0, 10) (0, 1%2)))
--     expandHorizontal        = Unbound "Expand floating window horizontally" (withFocused (keysResizeWindow (10, 0) (1%2, 0)))
--     shrinkVertical          = Unbound "Shrink floating window vertically"   (withFocused (keysResizeWindow (0, -10) (0, 1%2)))
--     shrinkHorizontal        = Unbound "Shrink floating window horizontally" (withFocused (keysResizeWindow (-10, 0) (1%2, 0)))
--     -- Layout management
--     shrinkMaster            = Unbound "Shrink master window"                (sendMessage Shrink)
--     expandMaster            = Unbound "Expand master window"                (sendMessage Expand)
--     nextLayout              = Unbound "Switch to next layout"               (sendMessage NextLayout)
--     resetLayout             = Unbound "Switch to default layout"            (sendMessage FirstLayout)
--     tileFloating            = Unbound "Push into tile"                      (withFocused $ windows . W.sink)
--     resizeFloatingWindow    = Unbound "Resize focused floating window"      (withFocused $ FR.mouseResizeWindow)
--     toggleMagnifier         = Unbound "Toggle magnifier"                    (sendMessage Mag.Toggle)
--     -- Workspace navigation
--     gotoPrevWorkspace       = Unbound "Switch to previous workspace"        (toggleWS' ["NSP"])
--     gotoWorkspace           = Unbound "Go to named workspace"               (removeIfEmpty (withWorkspace myXPConfigAutoComplete goto))
--     shiftToWorkspace        = Unbound "Shift to named workspace"            (removeIfEmpty (withWorkspace myXPConfigAutoComplete sendX))
--     shiftAndGoToWorkspace   = Unbound "Shift and go to named workspace"     (removeIfEmpty (withWorkspace myXPConfigAutoComplete takeX))
--     nextWorkspace           = Unbound "Go to next workspace"                (removeIfEmpty (DO.moveTo Next HiddenNonEmptyWS))
--     prevWorkspace           = Unbound "Go to previous workspace"            (removeIfEmpty (DO.moveTo Prev HiddenNonEmptyWS))
--     createWorkspace         = Unbound "Create named workspace"              (selectWorkspace myXPConfig)
--     renameWorkspace'        = Unbound "Rename workspace"                    (renameWorkspace myXPConfig)
--     deleteWorkspace         = Unbound "Remove workspace"                    (removeWorkspace)
--     -- Misc
--     scratchTerminal         = Unbound "Open scratch terminal"               (namedScratchpadAction myScratchPads "terminal")
--     restartXMonad           = Unbound "Restart XMonad"                      (spawn "killall xmobar" <+> unspawn "gmaild" <+> restart "xmonad" True)
--     jumpToNextScreen        = Unbound "Jump to next physical screen"        (onNextNeighbour W.view)
--     jumpToPrevScreen        = Unbound "Jump to previous physical screen"    (onPrevNeighbour W.view)
--     powerOff                = Unbound "Power off the system"                (spawn "gnome-session-quit --power-off")
--     reboot                  = Unbound "Reboot the system"                   (spawn "gnome-session-quit --reboot")
--     logout                  = Unbound "Logout"                              (spawn "session-logout")
--     promptZealSearch        = Unbound "Prompt Zeal search"                  (myPromptZealSearch)
--     promptWebSearch         = Unbound "Prompt web search"                   (submap . mySearchMap $ myPromptWebSearch)
--     selectWebSearch         = Unbound "X selection web search"              (submap . mySearchMap $ mySelectWebSearch)
--     closeWindow             = Unbound "Close the focused window"            (kill)
--     gridSelect              = Unbound "Open GridSelect"                     (goToSelected gridSelectConfig)
--     sendKiss                = Unbound "Send kiss to Anja"                   (spawn "kiss")
--     -- Keyboard control
--     nextKeyboardLayout      = Unbound "Next keyboard layout"                (spawn "keyboard -n")
--     -- Audio control
--     audioMute               = Unbound "Mute audio"                          (spawn "amixer -D pulse set Master toggle")
--     audioLowerVolume        = Unbound "Lower audio volume"                  (spawn "amixer -D pulse set Master 5%-")
--     audioRaiseVolume        = Unbound "Raise audio volume"                  (spawn "amixer -D pulse set Master 5%+")
--     audioPlay               = Unbound "Play/pause audio playback"           (spawn "mpc toggle")
--     audioStop               = Unbound "Stop audio playback"                 (spawn "mpc stop")
--     audioRate rating        = Unbound "Rate current song"                   (spawn ("mpdrate " ++ show rating))
--     -- Brightness control
--     brightnessDown          = Unbound "Brightness down"                     (spawn "xbacklight -dec 1")
--     brightnessUp            = Unbound "Brightness up"                       (spawn "xbacklight -inc 1")

--     {-gotoRecentWS     = Unbound "Switch to the most recently visited invisible workspace" (windows gotoRecent)-}
--     {-sendRecentWS     = Unbound   "Send to the most recently visited invisible workspace" (windows sendRecent)-}
--     {-takeRecentWS     = Unbound   "Take to the most recently visited invisible workspace" (windows takeRecent)-}

-- -- Two varieties of Action: B(ound) is aware of the key that was used to
-- -- invoke it, U(nbound) is not aware of the key.
-- data Action = Unbound String (          X ()) |
--               Bound   String (String -> X ())
