module Main where

import Mouse
import Keyboard

import Data(..)
import Logic(..)
import Drawing(..)
import Config(..)

-- Inputs

inputs : Signal Inputs
inputs = let ticker = fps 30
         in sampleOn ticker <|
                     lift2 (\dt rt -> { dt = dt, rodTarget = rt })
                           ticker
                           (lift2 (,) Mouse.isDown (lift toFloatPoint Mouse.position))

score : Signal Game -> Signal Int
score g = foldp max 0 (lift (.me >> .y >> truncate) g)

sampleTime s = lift fst <| timestamp s

main : Signal Element
main = let game = foldp (<|) (initial canvasWidth canvasHeight) (lift runGame inputs)
       in draw <~ game ~ (score game) ~ (sampleTime game) ~ Mouse.position
