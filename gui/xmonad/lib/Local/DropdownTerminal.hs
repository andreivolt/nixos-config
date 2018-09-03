module Local.DropdownTerminal (
    toggleDropdownTerminal
  , manageDropdownTerminal
) where

import qualified XMonad.StackSet        as W
import           XMonad.Util.Scratchpad (scratchpadManageHook,
                                         scratchpadSpawnActionCustom)

toggleDropdownTerminal =
  scratchpadSpawnActionCustom "alacritty --config-file ~/.config/alacritty/config_scratchpad.yml --class scratchpad --title scratchpad"

manageDropdownTerminal = scratchpadManageHook myTopFloatRect
  where
    myTopFloatRect = W.RationalRect l t w h
      where
        h = 0.7
        w = 1 - 2 * l
        t = 0
        l = 0.1
