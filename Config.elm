module Config where

import Text(defaultStyle)

hsv h s v = hsl (degrees h) (s/100) (v/100)

canvasWidth = 1000
canvasHeight = 600

platformSpeedIncreaseFactor = 0.02
platformSpeed h = 0.2 * (h * platformSpeedIncreaseFactor  + 100) / 100
timeBetweenPlatforms h = 45/(platformSpeed h)
platformWidth = 100
maxRodLength = 1000

gravity = 0.0004
meMass = 200
rodRestLength = 60
rodElasticity = 0.001
damping = 0.1
barrierStunTime = 4000

meWidth = 30
meColour = hsv 30 90 50
meStunnedColour = hsv 0 100 50
rodColour = hsv 30 90 40
bgColour = hsv 200 90 90
groundColour = hsv 200 70 20
cursorTraceColour = groundColour
cursorTraceDetectedColour = hsv 0 100 50
platformColour = hsv 200 90 20
barrierWidth = 10
barrierFlashPeriod = 1000
barrierFill t = rgba 255 0 0 (0.25 * sin (toFloat (truncate t % barrierFlashPeriod) * 2 * pi / barrierFlashPeriod) + 0.25)
barrierGrad t = linear (0,0) (barrierWidth-10,0) [(0, rgba 255 0 0 (0.25 * sin (toFloat (truncate t % barrierFlashPeriod) * 2 * pi / barrierFlashPeriod) + 0.25)),
                                                  (1, rgba 255 0 0 1)]
scoreStyle = { defaultStyle | height <- Just 18 }
