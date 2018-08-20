module Local.DropdownTerminal (
    toggleDropdownTerminal
  , manageDropdownTerminal
) where

import           Local.Scratchpads      (hideAllScratchpads)
import qualified XMonad.StackSet        as W
import           XMonad.Util.Scratchpad (scratchpadManageHook,
                                         scratchpadSpawnActionCustom)

toggleDropdownTerminal = do
  hideAllScratchpads

  scratchpadSpawnActionCustom "alacritty --class scratchpad -e terminal-scratchpad"

manageDropdownTerminal = scratchpadManageHook myTopFloatRect
  where
    myTopFloatRect = W.RationalRect l t w h
      where
        h = 0.62
        w = 1 - 2 * l
        t = 0
        l = 0.01
