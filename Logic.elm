module Logic where

import Maybe
import Generator
import Generator.Standard(..)

import Data(..)
import Config(..)

updateMoving : Float -> Moving a -> Moving a
updateMoving dt p = { p | x <- p.x + dt * p.dx,
                          y <- p.y + dt * p.dy }

initial : Int -> Int -> Game
initial w h = { view = { x = 0, y = 0, w = toFloat w, h = toFloat h },
                me = { x = 0, y = 0, dx = 0, dy = 0, rod = Nothing, stunTime = 0, lastMouseDown = False },
                platforms = [],
                timeSinceAdded = timeBetweenPlatforms 0,
                randGen = generator 0}

-- Physics

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
updatePlatforms dt g = let shouldAddNew = g.timeSinceAdded >= timeBetweenPlatforms g.me.y
                           newTime = if shouldAddNew then 0 else g.timeSinceAdded + dt
                       in if shouldAddNew
                          then let (randVal, gen') = Generator.float g.randGen
                                   addNew ps = { x = g.view.w/2 + platformWidth/2 + g.view.x, y = 50 + randVal * 200 + g.view.y, dx = -(platformSpeed g.me.y), dy = 0, w = platformWidth, h = 10 } :: ps
                               in { g | platforms <- addNew <| removeInvisible g.view <| map (updateMoving dt) g.platforms,
                                        timeSinceAdded <- newTime,
                                        randGen <- gen'}
                          else { g | platforms <- removeInvisible g.view <| map (updateMoving dt) g.platforms,
                                     timeSinceAdded <- newTime } 

updateRod : Float -> Me -> Me
updateRod dt me = case me.rod of
                    Nothing -> me
                    (Just rod) -> let newRod = { rod | x <- rod.x - (platformSpeed me.y) * dt }
                                  in { me | rod <- Just newRod }

updateStun : Float -> Me -> Me
updateStun dt me = { me | stunTime <- max 0 (me.stunTime - dt) }

addRod : Float -> (Bool, Point) -> Game -> Me -> Me
addRod dt (rb, rp) g moved = if | rb == g.me.lastMouseDown -> moved
                                | rb == False -> { moved | rod <- Nothing, lastMouseDown <- False }
                                | otherwise -> case cursorTrace g.me g.platforms rp of
                                    (Just (rx, ry)) -> { moved | rod <- if g.me.stunTime > 0
                                                                        then Nothing
                                                                        else Just { x = rx, y = ry },
                                                                 lastMouseDown <- True }
                                    Nothing -> { moved | rod <- Nothing,
                                                         lastMouseDown <- True }

updateMe : Float -> (Bool, Point) -> Game -> Game
updateMe dt (rb, rp) g = { g | me <- g.me |>
                                     updateStun dt |>
                                     applyDamping dt |>
                                     applyRodForce dt |>
                                     applyGravity dt |>
                                     updateMoving dt |>
                                     groundCollide |>
                                     viewCollide dt g.view |>
                                     addRod dt (rb, rp) g |>
                                     updateRod dt }

updateView : Game -> Game
updateView g = let view = g.view
                   newView = { view | x <- max (g.me.x - 100) g.view.x,
                                      y <- g.me.y }
               in { g | view <- newView }

runGame : Inputs -> Game -> Game
runGame {dt, rodTarget} g = updateView <|
                            updatePlatforms dt <|
                            updateMe dt ((\(b, r) -> (b, toGameCoords g.view r)) rodTarget) g
