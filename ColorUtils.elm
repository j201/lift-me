module ColorUtils where

data HslUpdate = Hue | Saturation | Lightness | Alpha

modifyColour : (HslUpdate, Float) -> Color -> Color
modifyColour (param, val) c = let {hue, saturation, lightness, alpha} = toHsl c
                              in case param of
                                  Hue -> hsla val saturation lightness alpha
                                  Saturation -> hsla hue val lightness alpha
                                  Lightness -> hsla hue saturation val alpha
                                  Alpha -> hsla hue saturation lightness val

blend : Float -> Color -> Color -> Color
blend x c1 c2 = let rgb1 = toRgb c1
                    rgb2 = toRgb c2
                    inter x a b = truncate (x*(toFloat a) + (1-x)*(toFloat b))
                in rgb (inter x rgb1.red rgb2.red)
                       (inter x rgb1.green rgb2.green)
                       (inter x rgb1.blue rgb2.blue)
