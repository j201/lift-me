module Drawing where

import Maybe
import Text

import Data(..)
import Config(..)

blend : Float -> Color -> Color -> Color
blend x c1 c2 = let rgb1 = toRgb c1
                    rgb2 = toRgb c2
                    inter x a b = truncate (x*(toFloat a) + (1-x)*(toFloat b))
                in rgb (inter x rgb1.red rgb2.red)
                       (inter x rgb1.green rgb2.green)
                       (inter x rgb1.blue rgb2.blue)

-- Drawing

filledBox : View -> Color -> Box a  -> Form
filledBox v c b = rect b.w b.h |>
                  filled c |>
                  move (b.x - v.x, b.y - v.y)

removeOffset : View -> Positioned a -> Positioned a
removeOffset v p = { p | y <- p.y - v.y, x <- p.x - v.x }

drawRod : View -> Me -> Rod -> Form
drawRod v me rod = let rodLine = solid rodColour
                   in traced { rodLine | width <- 2 } <|
                      segment (toPoint <| removeOffset v me) (toPoint <| removeOffset v rod)

drawRodTrace : Game -> (Int, Int) -> Form
drawRodTrace g (mx, my) = case cursorTrace g.me g.platforms <|
                               toGameCoords g.view <|
                               toFloatPoint (mx,my)
                          of Just (x,y) -> traced (solid cursorTraceDetectedColour)
                                                  (segment (toPoint <| removeOffset g.view g.me)
                                                           (x - g.view.x, y - g.view.y))
                             Nothing -> traced (solid cursorTraceColour)
                                               (segment (toPoint <| removeOffset g.view g.me)
                                                        (toFloat mx - g.view.w/2, g.view.h/2 - toFloat my))
barrier : Time -> Form
barrier t = rect barrierWidth canvasHeight |>
            filled (barrierFill t) |>
            -- gradient (barrierGrad t) |>
            moveX (-canvasWidth/2)

draw : Game -> Int -> Time -> (Int, Int) -> Element
draw g score t (mx, my) = collage (truncate g.view.w) (truncate g.view.h)

                                  ([filled bgColour (rect g.view.w g.view.h)] ++

                                   (if g.me.stunTime > 0 || g.me.rod /= Nothing
                                    then []
                                    else [drawRodTrace g (mx,my)]) ++

                                   map (filledBox g.view platformColour) g.platforms ++

                                   (case g.me.rod of 
                                      (Just rod) -> [drawRod g.view g.me rod]
                                      Nothing -> []) ++

                                   [filledBox g.view
                                              (if g.me.stunTime > 0 then blend (g.me.stunTime/barrierStunTime) meStunnedColour meColour else meColour)
                                              { x = g.me.x, y = g.me.y, w = meWidth, h = meWidth }] ++

                                   [barrier t] ++

                                   [filledBox g.view groundColour { x = g.view.x, y = -g.view.h/2 - meWidth/2, w = g.view.w, h = g.view.h }] ++

                                   [toText ("Height: " ++  (show <| truncate g.me.y)) |> Text.style scoreStyle |> centered |> toForm |> move (-400, 250),
                                    toText ("Score: " ++ (show score)) |> Text.style scoreStyle |> centered |> toForm |> move (-400, 270)])
