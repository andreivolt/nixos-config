module Local.FloatHelpers
  ( markAsFloating
  ) where

import XMonad

markAsFloating :: Window -> X ()
markAsFloating w = withDisplay $ \dpy -> do
  a <- getAtom "XMONAD_FLOATING_WINDOW"
  c <- getAtom "CARDINAL"
  io $ changeProperty32 dpy w a c propModeReplace [1]
