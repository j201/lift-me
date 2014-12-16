module Config where

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
meColour = rgb 81 137 227
meStunnedColour = rgb 200 120 130
rodColour = rgb 18 102 236
bgColour = rgb 229 231 236
groundColour = rgb 106 115 128
cursorTraceColour = groundColour
platformColour = charcoal
barrierWidth = 20
barrierFlashPeriod = 1000
barrierGrad t = linear (0,0) (barrierWidth-10,0) [(0, rgba 255 0 0 (0.25 * sin (toFloat (truncate t % barrierFlashPeriod) * 2 * pi / barrierFlashPeriod) + 0.25)),
                                                  (1, rgba 255 00 0 0)]