{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}

module Local.NotifyUrgencyHook (handleUrgencyHook) where

import           XMonad                    hiding ((|||))
import           XMonad.Hooks.UrgencyHook  (BorderUrgencyHook (BorderUrgencyHook),
                                            RemindWhen (Every),
                                            SuppressWhen (Focused), UrgencyHook,
                                            remindWhen, suppressWhen,
                                            urgencyBorderColor, urgencyConfig,
                                            urgencyHook, withUrgencyHook,
                                            withUrgencyHookC)
import qualified XMonad.StackSet           as W
import           XMonad.Util.NamedWindows  (getName)
import           XMonad.Util.Run           (safeSpawn)

import           Control.Applicative       ((<$>))
import qualified Local.Theme as Theme


data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
    urgencyHook LibNotifyUrgencyHook w = do
        name     <- getName w
        Just idx <- (W.findTag w) <$> gets windowset

        notify ("workspace " ++ idx ++ ": ") (show name)
        where
          notify :: String -> String -> X ()
          notify title msg = spawn $ "notify-send " ++ show title ++ " " ++ show msg


handleUrgencyHook =
  withUrgencyHook LibNotifyUrgencyHook .
  withUrgencyHookC BorderUrgencyHook { urgencyBorderColor = Theme.yellow }
                     urgencyConfig { suppressWhen = Focused, remindWhen = Every 60 }
