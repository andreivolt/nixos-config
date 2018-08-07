{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE MultiParamTypeClasses     #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE TypeSynonymInstances      #-}


module Local.Layouts (
    tabs
  , webdev
  , masterTabbed
  , full
  , TABBED(TABBED)
) where

import           Local.ChallengerDeepTheme

import           XMonad                           (Full (Full), Mirror (Mirror),
                                                   Tall (Tall), Typeable,
                                                   Window)
import           XMonad.Layout.Accordion          (Accordion (..))
import           XMonad.Layout.ComboP             (Property (..), combineTwoP)
import           XMonad.Layout.Decoration         (shrinkText, ModifiedLayout(ModifiedLayout))
import qualified XMonad.Layout.Fullscreen         as Fullscreen
import           XMonad.Layout.Grid               (Grid (Grid))
import           XMonad.Layout.Master
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.NoFrillsDecoration (noFrillsDeco)
import           XMonad.Layout.Renamed            (Rename (Replace), renamed)
import           XMonad.Layout.Simplest           (Simplest (Simplest))
import           XMonad.Layout.Tabbed             (addTabs, tabbed)
import           XMonad.Layout.TwoPane            (TwoPane (..))
import           XMonad.Layout.Spacing            (smartSpacingWithEdge)


data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
  transform TABBED x k = k tabs (const x)


addTopBar = noFrillsDeco shrinkText topBarTheme

full =
  Fullscreen.fullscreenFull Full

tabs =
  addTabTopBar
  $ myAddTabs Simplest
 where
  addTabTopBar = noFrillsDeco shrinkText tabTopBarTheme
  myAddTabs = addTabs shrinkText tabTheme

webdev =
  addTopBar
  $ Tall 1 (1 / 100) (3 / 5)

masterTabbed =
  addTopBar
  $ mastered (1 / 100) (1 / 2) tabs
