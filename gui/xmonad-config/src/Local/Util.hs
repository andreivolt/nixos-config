module Local.Util where

import XMonad


notify :: String -> String -> X ()
notify title msg = spawn $ "notify-send " ++ show title ++ " " ++ show msg
