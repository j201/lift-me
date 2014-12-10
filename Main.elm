module Main where

import ColorUtils(..)
import Mouse
import Debug
import Maybe
import Generator
import Generator.Standard(..)
import Keyboard

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

type Me = Moving { rod: Maybe Rod, stunTime: Time, lastRod: Time, lastCancel: Time }

type Platform = MovingBox {}

type View = Box {}

type Game = { view: View, me: Me, platforms: [Platform], timeSinceAdded: Time, randGen: Generator.Generator Standard }

type Inputs = { dt: Float, rodTarget: (Time, Point), cancelRod: Time }

overlap : Box a -> Box b -> Bool
overlap a b = let linearOverlap s1 e1 s2 e2 = (s1 <= s2 && e1 >= s2) || (s2 <= s1 && e2 >= s1) 
              in linearOverlap a.x (a.x + a.w) b.x (b.x + b.w) &&
                 linearOverlap a.y (a.y + a.h) b.y (b.y + b.h)

platformSpeed = 0.2
timeBetweenPlatforms = 35/platformSpeed
platformWidth = 100
maxRodLength = 1000

biggestHole : [Float] -> (Float, Float)
biggestHole = let size (x, y) = y - x
                  bhSorted xs = case xs of
                                  [x, y] -> (x, y)
                                  (x::y::xs) -> let candidate = bhSorted (y::xs)
                                                in if size candidate < (y - x)
                                                   then (x, y)
                                                   else candidate
              in bhSorted << sort 

canvasWidth = 1000
canvasHeight = 600

defaultView = { x = 0, y = 0, w = canvasWidth, h = canvasHeight }

initial : Game
initial = { view = defaultView,
            me = { x = 0, y = 0, dx = 0, dy = 0, rod = Nothing, stunTime = 0, lastRod = 0, lastCancel = 0 },
            platforms = [],
            timeSinceAdded = timeBetweenPlatforms,
            randGen = generator 0}

-- Physics

gravity = 0.0004
meMass = 200
rodRestLength = 60
rodElasticity = 0.001 -- not sure why it has to be so low
damping = 0.1
barrierStunTime = 3000

connectedAcceleration : Me -> Rod -> (Float, Float)
connectedAcceleration me rod = let theta = snd <| toPolar (rod.x - me.x, rod.y - me.y)
                                   cost = cos theta
                               in fromPolar (meMass * gravity * cost,
                                             if cost > 0 then theta - (pi/2) else theta + (pi/2))

applyGravity : Float -> Me -> Me
applyGravity dt me = { me | dy <- me.dy - gravity * dt }

applyDamping : Float -> Me -> Me
applyDamping dt me = let velFactor = (-damping) / meMass * dt
                     in { me | dx <- me.dx + velFactor * me.dx, dy <- me.dy + velFactor * me.dy }

posDistance : Positioned a -> Positioned b -> Float
posDistance p1 p2 = sqrt ((p1.x-p2.x) ^ 2 + (p1.y-p2.y) ^ 2)

unitVector : Positioned a -> Positioned b -> Point
unitVector from to = let dist = posDistance from to
                     in ((to.x-from.x) / dist, (to.y-from.y) / dist)

applyRodForce : Float -> Me -> Me
applyRodForce dt me = case me.rod of
                        Nothing -> me
                        (Just rod) -> let len = posDistance me rod
                                      in if len <= rodRestLength
                                         then me
                                         else let acc = len * rodElasticity / meMass
                                                  (ux, uy) = unitVector me rod
                                              in { me | dx <- me.dx + acc * ux * dt, dy <- me.dy + acc * uy * dt }

groundCollide : Me -> Me
groundCollide me = if me.y <= 0
                      then { me | y <- 0, dy <- 0, dx <- 0 }
                      else me

viewCollide: Float -> View -> Me -> Me
viewCollide dt v me = if me.x <= v.x - v.w/2 + meWidth/2 && me.dx <= 0
                      then { me | x <- v.x - v.w/2 + meWidth/2, dx <- 0,
                                  rod <- Nothing,
                                  stunTime <- if me.dx < 0 then barrierStunTime else me.stunTime }
                      else me

-- Updates

removeInvisible : View -> [Box a] -> [Box a]
removeInvisible v = filter (\b -> b.x + b.w/2 > v.x - v.w/2 &&
                                  b.x - b.w/2 < v.x + v.w/2)

-- Remove any invisible platforms, add new ones if there's space, move the rest
updatePlatforms : Float -> Game -> Game
updatePlatforms dt g = let shouldAddNew = g.timeSinceAdded >= timeBetweenPlatforms
                           newTime = if shouldAddNew then 0 else g.timeSinceAdded + dt
                       in if shouldAddNew
                          then let (randVal, gen') = Generator.float g.randGen
                                   addNew ps = { x = g.view.w/2 + platformWidth/2 + g.view.x, y = 50 + randVal * 200 + g.view.y, dx = -platformSpeed, dy = 0, w = platformWidth, h = 10 } :: ps
                               in { g | platforms <- addNew <| removeInvisible g.view <| map (updateMoving dt) g.platforms,
                                        timeSinceAdded <- newTime,
                                        randGen <- gen'}
                          else { g | platforms <- removeInvisible g.view <| map (updateMoving dt) g.platforms,
                                     timeSinceAdded <- newTime } 

updateRod : Float -> Me -> Me
updateRod dt me = case me.rod of
                    Nothing -> me
                    (Just rod) -> let newRod = { rod | x <- rod.x - platformSpeed * dt }
                                  in { me | rod <- Just newRod }

updateStun : Float -> Me -> Me
updateStun dt me = { me | stunTime <- max 0 (me.stunTime - dt) }

updateMe : Float -> (Time, Point) -> Time -> Game -> Game
updateMe dt (rt, rp) ct g = let moved = g.me |>
                                     updateStun dt |>
                                     updateRod dt |>
                                     applyDamping dt |>
                                     applyRodForce dt |>
                                     applyGravity dt |>
                                     updateMoving dt |>
                                     groundCollide |>
                                     viewCollide dt g.view
                                rodHandled = if rt == moved.lastRod -- TODO: move into function
                                             then moved
                                             else case cursorTrace g.me g.platforms rp of
                                                    (Just (rx, ry)) -> { moved | rod <- if g.me.stunTime > 0
                                                                                        then Nothing
                                                                                        else Just { x = rx, y = ry, lengthFrac = 1, state = Connecting },
                                                                                 lastRod <- rt }
                                                    Nothing -> { moved | rod <- Nothing,
                                                                         lastRod <- rt }
                                cancelHandled = if ct == rodHandled.lastCancel
                                                then rodHandled
                                                else { rodHandled | rod <- Nothing, lastCancel <- ct }
                            in { g | me <- cancelHandled }

updateView : Game -> Game
updateView g = let view = g.view
                   newView = { view | x <- max (g.me.x - 100) g.view.x,
                                      y <- g.me.y }
               in { g | view <- newView }

runGame : Inputs -> Game -> Game
runGame {dt, rodTarget, cancelRod } g = updateView <|
                                        updatePlatforms dt <|
                                        updateMe dt ((\(t, r) -> (t, toGameCoords g.view r)) rodTarget) cancelRod g

-- Drawing

type Point = (Float, Float)

filledBox : View -> Color -> Box a  -> Form
filledBox v c b = rect b.w b.h |>
                  filled c |>
                  move (b.x - v.x, b.y - v.y)

meWidth = 30
meColour = rgb 120 130 200
meStunnedColour = rgb 200 120 130
rodColour = lightBlue
bgColour = rgb 235 235 240
groundColour = rgb 100 100 110
cursorTraceColour = groundColour
platformColour = charcoal
barrierWidth = 20
barrierFlashPeriod = 1000
barrierGrad t = linear (0,0) (barrierWidth-10,0) [(0, rgba 255 0 0 (0.25 * sin (toFloat (truncate t % barrierFlashPeriod) * 2 * pi / barrierFlashPeriod) + 0.25)),
                                                  (1, rgba 255 00 0 0)]

lineFrac : Float -> Point -> Point -> Point
lineFrac frac (x1, y1) (x2, y2) = (x1 + (x2 - x1) * frac,
                                   y1 + (y2 - y1) * frac)

toPoint : Positioned a -> Point
toPoint p = (p.x, p.y)

toFloatPoint : (Int, Int) -> Point
toFloatPoint (x,y) = (toFloat x, toFloat y)

toGameCoords : View -> Point -> Point
toGameCoords {x,y,w,h} (px,py) = (x + px - w/2, y - py + h/2)

removeOffset : View -> Positioned a -> Positioned a
removeOffset v p = { p | y <- p.y - v.y, x <- p.x - v.x }

drawRod : View -> Me -> Rod -> Form
drawRod v me rod = traced (solid rodColour) <|
                   segment (toPoint <| removeOffset v me) (toPoint <| removeOffset v rod)

barrier : Time -> Form
barrier t = rect barrierWidth canvasHeight |>
            gradient (barrierGrad t) |>
            moveX (-canvasWidth/2)

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

-- TODO: clean this up
draw : Game -> Int -> Time -> (Int, Int) -> Element
draw g score t (mx, my) = collage (truncate g.view.w) (truncate g.view.h)
                                  ([filled bgColour (rect g.view.w g.view.h)] ++
                                   (if g.me.stunTime > 0
                                    then []
                                    else [case cursorTrace g.me g.platforms <| toGameCoords g.view <| toFloatPoint (mx,my) of
                                            Just (x,y) -> traced (solid lightRed) (segment (toPoint <| removeOffset g.view g.me) (x - g.view.x, y - g.view.y))
                                            Nothing -> traced (solid cursorTraceColour) (segment (toPoint <| removeOffset g.view g.me) (toFloat mx - g.view.w/2, g.view.h/2 - toFloat my))]) ++
                                   [filledBox g.view groundColour { x = g.view.x, y = -g.view.h/2 - meWidth/2, w = g.view.w, h = g.view.h }] ++
                                    map (filledBox g.view platformColour) g.platforms ++
                                    (case g.me.rod of 
                                       (Just rod) -> [drawRod g.view g.me rod]
                                       Nothing -> []) ++
                                    [filledBox g.view
                                               (if g.me.stunTime > 0 then blend (g.me.stunTime/barrierStunTime) meStunnedColour meColour else meColour)
                                               { x = g.me.x, y = g.me.y, w = meWidth, h = meWidth }] ++
                                    [barrier t] ++
                                    [plainText (show <| truncate g.me.y) |> toForm |> move (-400, 250),
                                     plainText (show score) |> toForm |> move (-400, 270)])

-- Inputs

toTimeSignal : Signal a -> Signal Time
toTimeSignal = lift fst << timestamp

inputs : Signal Inputs
inputs = let ticker = fps 30
         in lift3 (\dt rt cr -> { dt = dt, rodTarget = rt, cancelRod = cr })
                  ticker
                  (timestamp <| lift toFloatPoint <| sampleOn Mouse.clicks Mouse.position)
                  (toTimeSignal Keyboard.space)

score : Signal Game -> Signal Int
score g = foldp max 0 (lift (.me >> .y >> truncate) g)

sampleTime s = lift fst <| timestamp s

main : Signal Element
main = let game = foldp (<|) initial (lift runGame inputs)
       in draw <~ game ~ (score game) ~ (sampleTime game) ~ Mouse.position
