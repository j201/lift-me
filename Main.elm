module Main where

import ColorUtils(..)
import Mouse
import Debug

log x = Debug.log (show x) x

type Positioned a = { a | x: Float, y: Float }
type Moving a = Positioned { a | dx: Float, dy: Float } -- Velocities in px/s
type Box a = Positioned { a | w: Float, h: Float }

updateMoving : Float -> Moving a -> Moving a
updateMoving dt p = { p | x <- p.x + dt * p.dx,
                          y <- p.y + dt * p.dy }

data RodState = Connecting | Connected | Disconnecting
type Rod = Positioned { lengthFrac: Float, state: RodState }

type Me = Moving { rods: [Rod] }

type Platform = Moving (Box {})

type View = Box {}

type Game = { view: View, me: Me, platforms: [Platform], timeSinceAdded: Time }

type Inputs = { newRod: Maybe Rod }

overlap : Box a -> Box b -> Bool
overlap a b = let linearOverlap s1 e1 s2 e2 = (s1 <= s2 && e1 >= s2) || (s2 <= s1 && e2 >= s1) 
              in linearOverlap a.x (a.x + a.w) b.x (b.x + b.w) &&
                 linearOverlap a.y (a.y + a.h) b.y (b.y + b.h)

timeBetweenPlatforms = 1

biggestHole : [Float] -> (Float, Float)
biggestHole = let size (x, y) = y - x
                  bhSorted xs = case xs of
                                  [x, y] -> (x, y)
                                  (x::y::xs) -> let candidate = bhSorted (y::xs)
                                                in if size candidate < (y - x)
                                                   then (x, y)
                                                   else candidate
              in bhSorted << sort 

defaultView = { x = 0, y = 0, w = 600, h = 400 }

initial : Game
initial = { view = { x = 0, y = 0, w = 600, h = 400 },
            me = { x = 0, y = 0, dx = 0, dy = 0, rods = [] },
            platforms = [],
            timeSinceAdded = 0 }

game = constant initial

-- Physics

gravity = 0.3
meMass = 1

connectedAcceleration : Me -> Rod -> (Float, Float)
connectedAcceleration me rod = let theta = snd <| toPolar (rod.x - me.x, rod.y - me.y)
                                   cost = cos theta
                               in fromPolar (meMass * gravity * cost,
                                             if cost > 0 then theta - (pi/2) else theta + (pi/2))

updateVelocity : Float -> Me -> Me
updateVelocity dt me = let connectedRods = filter (.state >> ((==) Connected)) me.rods
                       in if | me.y == 0 -> { me | dx <- 0, dy <- 0 }
                             | connectedRods == [] -> { me | dy <- me.dy + gravity * dt }
                             | otherwise ->
                                 let rod = head connectedRods -- Only calculates from one rod
                                     (ax, ay) = connectedAcceleration me rod
                                 in { me | dx <- me.dx + ax * dt, dy <- me.dy + ay * dt }

-- -- Remove any invisible platforms, add new ones if there's space, move the rest
-- updatePlatforms : Float -> Game -> Game
-- updatePlatforms dt s = let shouldAddNew = s.timeSinceAdded >= timeBetweenPlatforms
--                            addNew ps = if shouldAddNew
--                                        then 
--                                        -- find the biggest space and stick it in, with a bit of fuzzing
--                                        else ps
--                        in { s | platforms <- addNew <| filter (overlap s.view) <| map (updateMoving dt) s.platforms,
--                                 timeSinceAdded <- if shouldAddNew then 0 else s.timeSinceAdded + dt}

-- Drawing

type Point = (Float, Float)

filledBox : View -> Color -> Box a  -> Form
filledBox v c b = rect b.w b.h |>
                  filled c |>
                  move (b.x - v.x, b.y - v.y)

meWidth = 30
meColour = lightOrange
rodColour = lightBlue
bgColour = lightGrey
groundColour = grey
platformColour = charcoal

lineFrac : Float -> Point -> Point -> Point
lineFrac frac (x1, y1) (x2, y2) = (x1 + (x2 - x1) * frac,
                                   y1 + (y2 - y1) * frac)

toPoint : Positioned a -> Point
toPoint p = (p.x, p.y)

drawRod : View -> Me -> Rod -> Form
drawRod me v rod = traced (solid rodColour) <|
                   segment (toPoint me) <|
                   lineFrac rod.lengthFrac (toPoint me) (toPoint rod)

-- infinity issues?
lineInverse : Point -> Point -> Float -> Float
lineInverse (x1,y1) (x2,y2) y = x1 + (y-y1)*(x2-x1)/(y2-y1)

findXCrossing : Positioned a -> (Int, Int) -> Box b -> Maybe Point
findXCrossing src (x,y) tgt = let xCrossing = lineInverse (src.x, src.y) (toFloat x, toFloat y) tgt.y
                              in if tgt.x <= xCrossing && tgt.x + tgt.w >= xCrossing
                                 then Just (xCrossing, tgt.y)
                                 else Nothing

cursorTrace : Positioned a -> [Box b] -> (Int, Int) -> Maybe Point
cursorTrace src tgts (x,y) = let crossings = sortBy (\(Just (_,y)) -> y) <|
                                             filter ((/=) Nothing) <|
                                             map (findXCrossing src (x,y)) tgts
                             in if crossings == []
                                then Nothing
                                else head crossings

draw : View -> Game -> (Int, Int) -> Element
draw v g (mx, my) = collage (truncate v.w) (truncate v.h)
                            [filled bgColour (rect v.w v.h),
                             case cursorTrace g.me g.platforms (mx,my) of
                                 Just (x,y) -> traced (solid lightRed) (segment (toPoint g.me) (x - v.w/2, v.h/2 - y))
                                 Nothing -> traced (solid <| modifyColour (Alpha, 0.5) lightRed) (segment (toPoint g.me) (toFloat mx - v.w/2, v.h/2 - toFloat my)),
                             filledBox v groundColour { x = 0, y = -v.h/2 - meWidth/2, w = v.w, h = v.h },
                             group <| map (filledBox v platformColour) g.platforms,
                             group <| map (drawRod v g.me) g.me.rods,
                             filledBox v meColour { x = g.me.x, y = g.me.y, w = meWidth, h = meWidth }]

main : Signal Element
main = lift2 (draw defaultView) game Mouse.position
