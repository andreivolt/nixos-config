module Local.ConditionalKeys (
                                 XCond(..),
                                 chooseAction,
                                 bindOn
                                ) where

import XMonad
import qualified XMonad.StackSet as W
import Data.List (find)


data XCond = WS | LD

chooseAction :: XCond -> (String->X()) -> X()
chooseAction WS f = withWindowSet (f . W.currentTag)
chooseAction LD f = withWindowSet (f . description . W.layout . W.workspace . W.current)


bindOn :: XCond -> [(String, X())] -> X()
bindOn xc bindings = chooseAction xc chooser where
    chooser xc = case find ((xc==).fst) bindings of
        Just (_, action) -> action
        Nothing -> case find ((""==).fst) bindings of
            Just (_, action) -> action
            Nothing -> return ()
