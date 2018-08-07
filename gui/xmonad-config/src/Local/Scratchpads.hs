module Local.Scratchpads (
    toggleScratchpad
  , hideAllScratchpads
  , manageMyScratchpads
  , manageScratchPad
) where

import           Local.FloatHelpers          (markAsFloating)

import           Control.Monad               (filterM, forM, forM_)
import           XMonad
import qualified XMonad.StackSet             as W
import           XMonad.Util.NamedScratchpad (NamedScratchpad (NS),
                                              customFloating,
                                              name, query,
                                              namedScratchpadAction,
                                              namedScratchpadManageHook)
import           XMonad.Util.Scratchpad      (scratchpadManageHook)


manageMyScratchpads = namedScratchpadManageHook myScratchpads
manageScratchPad = scratchpadManageHook myTopFloatRect

toggleScratchpad strachpadName = do
  withWindowSet $ \s ->
    forM_ (filter ((strachpadName/=) . name) myScratchpads) $ \conf -> do
    filterCurrent <- filterM (runQuery (query conf))
                             ((maybe [] W.integrate . W.stack . W.workspace . W.current) s)
    filterAll <- filterM (runQuery (query conf)) (W.allWindows s)
    mapM (windows . W.shiftWin "NSP") filterAll

  namedScratchpadAction myScratchpads strachpadName

hideAllScratchpads =
  withWindowSet $ \s ->
    forM_ myScratchpads $ \conf -> do
  filterCurrent <- filterM (runQuery (query conf))
                           ((maybe [] W.integrate . W.stack . W.workspace . W.current) s)
  filterAll <- filterM (runQuery (query conf)) (W.allWindows s)
  mapM (windows . W.shiftWin "NSP") filterAll

myScratchpads =
  [ NS "music"  "google-play-music-desktop-player" (className =? "Google Play Music Desktop Player") $ x (customFloating myCenterFloatRect)
  , NS "irc"    "irc"                              (title =? "irc") $ x (customFloating myTopFloatRect)
  , NS "mail"   "email"                            (title =? "mail") $ x (customFloating myTopFloatRect)
  , NS "system" "alacritty --title system -e htop" (title =? "system") $ x (customFloating myTopFloatRect)
  , NS "editor" "editor-scratchpad"                (title =? "editor") $ x (customFloating myTopFloatRect)
  ]
  where
    x y = ask >>= \w -> liftX (markAsFloating w) >> y

    myCenterFloatRect = W.RationalRect (1 / 5) (2 / 7) (3 / 5) (4 / 7)

myTopFloatRect = W.RationalRect l t w h
 where
  h = 0.7
  w = 1 - 2 * l
  t = 0
  l = 0.01
