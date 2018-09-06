{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE MultiParamTypeClasses     #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE TypeSynonymInstances      #-}


module Local.Layouts (
    tabs
  , masterTabbed
  , centeredMasterTabbed
  , full
  , TABBED(TABBED)
) where

import           Local.Theme

import           XMonad                           (Full (Full), Mirror (Mirror),
                                                   Tall (Tall), Typeable,
                                                   Window)
import           XMonad.Layout.ComboP             (Property (..), combineTwoP)
import           XMonad.Layout.Decoration         (shrinkText, ModifiedLayout(ModifiedLayout))
import qualified XMonad.Layout.Fullscreen         as Fullscreen
import           XMonad.Layout.Grid               (Grid (Grid))
import           XMonad.Layout.Master
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.NoFrillsDecoration (noFrillsDeco)
import           XMonad.Layout.Renamed            (Rename (Replace), renamed)
import           XMonad.Layout.Simplest           (Simplest (Simplest))
import           XMonad.Layout.Tabbed             (addTabs)
import XMonad.Layout.Reflect
import XMonad.Layout.CenteredMaster


data TABBED = TABBED deriving (Read, Show, Eq, Typeable)
instance Transformer TABBED Window where
  transform TABBED x k = k tabs (const x)


addTopBar = noFrillsDeco shrinkText topBarTheme

full =
  Fullscreen.fullscreenFull Full

tabs =
  named "Tabs"
  $ addTabTopBar
  $ myAddTabs Simplest
 where
  addTabTopBar = noFrillsDeco shrinkText tabTopBarTheme
  myAddTabs = addTabs shrinkText tabTheme

masterTabbed =
  addTopBar
  $ reflectHoriz
  $ mastered (1 / 100) (1 / 2) tabs

centeredMasterTabbed =
  centerMaster $ Simplest

named n = renamed [(XMonad.Layout.Renamed.Replace n)]
