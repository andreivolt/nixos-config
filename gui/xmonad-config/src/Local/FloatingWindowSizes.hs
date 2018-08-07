module Local.FloatingWindowSizes () where

import qualified XMonad.StackSet as W

largeRect, smallRect, topRect, bottomRect, leftRect, rightRect :: W.RationalRect
largeRect  = W.RationalRect (1/20) (1/20) (18/20) (18/20)
smallRect  = W.RationalRect (1/6)  (1/6)  (4/6)   (4/6)
topRect    = W.RationalRect 0      0      1       (1/3)
bottomRect = W.RationalRect 0      (2/3)  1       (1/3)
leftRect   = W.RationalRect 0      0      (1/3)   1
rightRect  = W.RationalRect (2/3)  0      (1/3)   1
sidebar    = W.RationalRect 0      0      (1/10)  1
