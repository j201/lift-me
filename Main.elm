module Main where

import ColorUtils(..)
import Mouse
import Debug

log x = Debug.log (show x) x

type Positioned a = { a | x: Float, y: Float }
type Moving a = { a | x: Float, y: Float, dx: Float, dy: Float } -- Velocities in px/s
type Box a = { a | x: Float, y: Float, w: Float, h: Float }
type MovingBox a = { a | x: Float, y: Float, dx: Float, dy: Float, w: Float, h: Float } -- TODO: find a clean way of doing this

updateMoving : Float -> Moving a -> Moving a
updateMoving dt p = { p | x <- p.x + dt * p.dx,
                          y <- p.y + dt * p.dy }

data RodState = Connecting | Connected | Disconnecting
type Rod = Positioned { lengthFrac: Float, state: RodState }

type Me = Moving { rods: [Rod] }

type Platform = MovingBox {}

type View = Box {}

type Game = { view: View, me: Me, platforms: [Platform], timeSinceAdded: Time }

type Inputs = { dt: Float, rodTarget: Maybe (Float, Float) }

overlap : Box a -> Box b -> Bool
overlap a b = let linearOverlap s1 e1 s2 e2 = (s1 <= s2 && e1 >= s2) || (s2 <= s1 && e2 >= s1) 
              in linearOverlap a.x (a.x + a.w) b.x (b.x + b.w) &&
                 linearOverlap a.y (a.y + a.h) b.y (b.y + b.h)

timeBetweenPlatforms = 6000
platformSpeed = 0.05

biggestHole : [Float] -> (Float, Float)
biggestHole = let size (x, y) = y - x
                  bhSorted xs = case xs of
                                  [x, y] -> (x, y)
                                  (x::y::xs) -> let candidate = bhSorted (y::xs)
                                                in if size candidate < (y - x)
                                                   then (x, y)
                                                   else candidate
              in bhSorted << sort 

canvasWidth = 600
canvasHeight = 400

defaultView = { x = 0, y = 0, w = canvasWidth, h = canvasHeight }

initial : Game
initial = { view = defaultView,
            me = { x = 0, y = 0, dx = 0, dy = 0, rods = [] },
            platforms = [{ x = 0, y = 100, dx = -platformSpeed, dy = 0, w = 100, h = 10 },
                         { x = 50, y = 150, dx = -platformSpeed, dy = 0, w = 300, h = 10 }],
            timeSinceAdded = timeBetweenPlatforms }

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

-- Updates

removeInvisible : View -> [Box a] -> [Box a]
removeInvisible v = filter (\b -> b.x + b.w/2 > v.x - v.w/2 &&
                                  b.x - b.w/2 < v.x + v.w/2 &&
                                  b.y + b.h/2 > v.y - v.h/2 &&
                                  b.y - b.h/2 < v.y + v.h/2)

-- Remove any invisible platforms, add new ones if there's space, move the rest
updatePlatforms : Float -> Game -> Game
updatePlatforms dt g = let shouldAddNew = g.timeSinceAdded >= timeBetweenPlatforms
                           addNew ps = if shouldAddNew
                                       then { x = g.view.w/2 + 75, y = 100, dx = -platformSpeed, dy = 0, w = 150, h = 10 } :: ps
                                       else ps
                       in { g | platforms <- addNew <| removeInvisible g.view <| map (updateMoving dt) g.platforms,
                                timeSinceAdded <- if shouldAddNew then 0 else g.timeSinceAdded + dt}

updateMe : Float -> Maybe (Float, Float) -> Game -> Game
updateMe dt rt g = let moved = updateMoving dt g.me
                   in case rt of
                       (Just (x,y)) -> { g | me <- { moved | rods <- [{ x = x, y = y, lengthFrac = 1, state = Connecting }] } }
                       Nothing -> { g | me <- moved }

runGame : Inputs -> Game -> Game
runGame {dt, rodTarget} g = updatePlatforms dt <|
                            updateMe dt rodTarget g

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

toFloatPoint : (Int, Int) -> Point
toFloatPoint (x,y) = (toFloat x, toFloat y)

toGameCoords : View -> Point -> Point
toGameCoords {x,y,w,h} (px,py) = (x + px - w/2, y - py + h/2)

drawRod : View -> Me -> Rod -> Form
drawRod me v rod = traced (solid rodColour) <|
                   segment (toPoint me) <|
                   lineFrac rod.lengthFrac (toPoint me) (toPoint rod)

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
cursorTrace src tgts (x,y) = let crossings = sortBy (\(Just (_,y)) -> y) <|
                                             filter ((/=) Nothing) <|
                                             map (findXCrossing src (x,y)) tgts
                             in if crossings == []
                                then Nothing
                                else head crossings

draw : Game -> (Int, Int) -> Element
draw g (mx, my) = collage (truncate g.view.w) (truncate g.view.h)
                          [filled bgColour (rect g.view.w g.view.h),
                           case cursorTrace g.me g.platforms <| toGameCoords g.view <| toFloatPoint (mx,my) of
                               Just (x,y) -> traced (solid lightRed) (segment (toPoint g.me) (x,y))
                               Nothing -> traced (solid <| modifyColour (Lightness, 0.8) lightRed) (segment (toPoint g.me) (toFloat mx - g.view.w/2, g.view.h/2 - toFloat my)),
                           filledBox g.view groundColour { x = 0, y = -g.view.h/2 - meWidth/2, w = g.view.w, h = g.view.h },
                           group <| map (filledBox g.view platformColour) g.platforms,
                           group <| map (drawRod g.view g.me) g.me.rods,
                           filledBox g.view meColour { x = g.me.x, y = g.me.y, w = meWidth, h = meWidth }]

-- Inputs
inputs : Signal Inputs
inputs = let ticker = fps 30
         in lift2 (\dt rt -> { dt = dt, rodTarget = rt })
                  ticker
                  (lift fst <|
                   foldp (\newPos (m, pos) -> if pos == newPos
                                              then (Nothing, pos)
                                              else (Just <| toGameCoords defaultView <| toFloatPoint newPos, newPos)) -- TODO: defaultView
                         (Nothing, (0, 0))
                         (sampleOn ticker <| sampleOn Mouse.clicks Mouse.position))

main : Signal Element
main = lift2 draw (foldp (<|) initial (lift runGame inputs)) Mouse.position
