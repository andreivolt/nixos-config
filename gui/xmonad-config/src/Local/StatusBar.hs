{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Local.StatusBar (withStatusBar) where

import qualified Local.ChallengerDeepTheme   as Theme

import           Control.Applicative         ((<$>))
import           XMonad                      (XConfig (XConfig), modMask, xK_b)
import           XMonad.Hooks.DynamicLog
import           XMonad.Util.NamedScratchpad (namedScratchpadFilterOutWorkspace)


withStatusBar = statusBar myBar myPP toggleStrutsKey
 where
  myBar = "~/.local/bin/xmobar"

  myPP = xmobarPP
    { ppTitle           = xmobarColor Theme.lightGray "" . wrap "  " "  "
    , ppHiddenNoWindows = const ""
    , ppUrgent          = const ""
    , ppHidden          = const ""
    , ppCurrent         = const ""
    , ppVisible         = const ""
    , ppLayout          = const ""
    , ppSep             = "  "
    , ppSort            = (. namedScratchpadFilterOutWorkspace) <$> ppSort def
    }

  toggleStrutsKey XConfig { modMask = modifierKey } = (modifierKey, xK_b)



-- -- {{{ EVENTS

-- -- Respawn Status Bars When Multi-Head Configuration Changes.
-- StatusBar.eventHook


-- -- | Render each Screen's Workspaces into their own xmobar, highlighting
-- -- the current Screen's window title.
-- --
-- -- TODO: Move to `StatusBar` module?
-- xmobarLogHook :: X ()
-- xmobarLogHook =
--     multiPPFormat
--         (onlyCurrentScreen >=> withCurrentIcon >=> dynamicLogString)
--         Theme.focusedScreenPP
--         Theme.unfocusedScreenPP
--     where
--         -- Only show workspaces on the bar's screen
--         onlyCurrentScreen :: PP -> X PP
--         onlyCurrentScreen pp =
--             hideOffScreen pp <$> gets (windowset .> W.current .> W.screen)
--         -- Hide any hidden workspaces on other screens
--         hideOffScreen :: PP -> ScreenId -> PP
--         hideOffScreen pp screenId =
--             pp { ppHidden = showIfPrefix screenId True
--                , ppHiddenNoWindows = showIfPrefix screenId False
--                }
--         -- Only show the workspace if it's prefix matches the current screen.
--         showIfPrefix :: ScreenId -> Bool -> WorkspaceId -> String
--         showIfPrefix screenId hasWindows workspaceId =
--             if screenId == unmarshallS workspaceId then
--                 unmarshallW workspaceId |> \n ->
--                     if hasWindows then
--                         Theme.icon Theme.HiddenWorkspaceHasWindows ++ n ++ " "
--                     else
--                         pad n
--             else
--                 ""
--         -- Add an icon to visible workspaces with windows
--         withCurrentIcon :: PP -> X PP
--         withCurrentIcon pp = do
--             hasWindows <- gets $
--                 windowset
--                     .> W.current
--                     .> W.workspace
--                     .> W.stack
--                     .> W.integrate'
--                     .> (not . null)
--             return $ pp { ppCurrent = renderCurrentWorkspace hasWindows }
--         -- Render the workspace name
--         renderCurrentWorkspace :: Bool -> String -> String
--         renderCurrentWorkspace hasWindows name =
--             unmarshallW name |> \n -> Theme.currentWorkspace $
--                 if hasWindows then
--                     Theme.icon Theme.CurrentWorkspaceHasWindows ++ n ++ " "
--                 else
--                     pad n
