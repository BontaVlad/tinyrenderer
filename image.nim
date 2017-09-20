import sequtils

import stb_image/read as stbi
import stb_image/write as stbiw


type
  Image* = object
    width*: int
    height*: int
    channels*: int
    pixels*: seq[uint8]


proc newImage*(w, h: int, channels = stbi.RGBA): Image =
  result.pixels = repeat(0.uint8, w * h * channels)
  result.channels = channels


proc newImage*(filename: string, channels = stbi.Default): Image =
  try:
    result.pixels = stbi.load(filename, result.width, result.height, result.channels, channels)
  except STBIException:
    quit("Image " & filename & " not found", QuitFailure)


proc setPixel*(image: var Image, x, y: int, r = 0.uint8, g = 0.uint8, b = 0.uint8, a = 255.uint8) =
  let index = x * image.width + y
  case image.channels:
  of stbi.Grey: image.pixels[index] = r
  of stbi.GreyAlpha:
    image.pixels[index] = r
    image.pixels[index + 1] = g
  of stbi.RGB:
    image.pixels[index] = r
    image.pixels[index + 1] = g
    image.pixels[index + 2] = b
  of stbi.RGBA:
    image.pixels[index] = r
    image.pixels[index + 1] = g
    image.pixels[index + 2] = b
    image.pixels[index + 3] = a
  else: discard


proc getPixel*(image: var Image, x, y: int): seq[uint8] =
  let index = x * image.width + y
  case image.channels:
    of stbi.Grey:
      result = @[image.pixels[index]]
    of stbi.GreyAlpha:
      result = @[
        image.pixels[index],
        image.pixels[index + 1],
      ]
    of stbi.RGB:
      result = @[
        image.pixels[index],
        image.pixels[index + 1],
        image.pixels[index + 2]
      ]
    of stbi.RGBA:
      result = @[
        image.pixels[index],
        image.pixels[index + 1],
        image.pixels[index + 2],
        image.pixels[index + 3]
      ]
    else: discard

proc write*(image: Image, filename: string, w, h: int): bool {.discardable.} =
  result = stbiw.writePNG(filename, w, h, stbi.RGBA, image.pixels)

