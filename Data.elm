module Data where

import Maybe
import Generator
import Generator.Standard(..)

import Config(..)

type Positioned a = { a | x: Float, y: Float }
type Moving a = { a | x: Float, y: Float, dx: Float, dy: Float } -- Velocities in px/s
type Box a = { a | x: Float, y: Float, w: Float, h: Float }
type MovingBox a = { a | x: Float, y: Float, dx: Float, dy: Float, w: Float, h: Float } -- TODO: find a clean way of doing this

type Rod = Positioned {}

type Me = Moving { rod: Maybe Rod, stunTime: Time, lastMouseDown: Bool }

type Platform = MovingBox {}

type View = Box {}

type Game = { view: View, me: Me, platforms: [Platform], timeSinceAdded: Time, randGen: Generator.Generator Standard }

type Inputs = { dt: Float, rodTarget: (Bool, Point) }

type Point = (Float, Float)

toPoint : Positioned a -> Point
toPoint p = (p.x, p.y)

toFloatPoint : (Int, Int) -> Point
toFloatPoint (x,y) = (toFloat x, toFloat y)

toGameCoords : View -> Point -> Point
toGameCoords {x,y,w,h} (px,py) = (x + px - w/2, y - py + h/2)

-- infinity issues?
lineInverse : Point -> Point -> Float -> Float
lineInverse (x1,y1) (x2,y2) y = x1 + (y-y1)*(x2-x1)/(y2-y1)

findXCrossing : Positioned a -> Point -> Box b -> Maybe Point
findXCrossing src (x,y) tgt = let xCrossing = lineInverse (src.x, src.y) (x,y) tgt.y
                              in if tgt.x - tgt.w/2 <= xCrossing &&
                                    tgt.x + tgt.w/2 >= xCrossing &&
                                    (y > src.y) == (tgt.y > src.y)
                                 then Just (xCrossing, tgt.y)
                                 else Nothing

cursorTrace : Positioned a -> [Box b] -> Point -> Maybe Point
cursorTrace src tgts (x,y) = let inRange (x,y) = sqrt ((src.x - x) ^ 2 + (src.y - y) ^ 2) < maxRodLength
                                 crossings = sortBy (\(Just (_,y)) -> y) <|
                                             filter (\(Just p) -> inRange p) <|
                                             filter ((/=) Nothing) <|
                                             map (findXCrossing src (x,y)) tgts
                             in if crossings == []
                                then Nothing
                                else head crossings
