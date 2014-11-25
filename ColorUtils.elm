module ColorUtils where

data HslUpdate = Hue | Saturation | Lightness | Alpha

modifyColour : (HslUpdate, Float) Color -> Color
modifyColour (param, val) c = let {hue, saturation, lightness, alpha} = toHsl c
                              in case param of
                                  Hue -> hsla val saturation lightness alpha
                                  Saturation -> hsla hue val lightness alpha
                                  Lightness -> hsla hue saturation val alpha
                                  Alpha -> hsla hue saturation lightness val
