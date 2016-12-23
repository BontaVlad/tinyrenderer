import colors, strutils, sequtils, streams, graphics

import nimtga

type
  Point* = tuple[x, y: int]
  Surface* = object
    w*, h*: int
    flip_v, flip_h: bool
    pixels*: seq[seq[Color]]


proc newSurface*(w, h: int, fill_color = colBlack): Surface =
  result.w = w
  result.h = h
  result.pixels = @[]
  for y in 0 .. h:
    var row = newSeq[Color]()
    for x in 0 .. w:
      row.add(fill_color)
    result.pixels.add(row)

proc flip_horizontally*(s: var Surface) =
  s.flip_h = not s.flip_h

proc flip_vertically*(s: var Surface) =
  s.flip_v = not s.flip_v

proc flip_both*(s: var Surface) =
  s.flip_v = not s.flip_v
  s.flip_h = not s.flip_h

proc getPixel*(s: Surface, x, y: int): Color =
  assert x <= s.w
  assert y <= s.h
  result = s.pixels[y][x]

proc getPixel*(s: Surface, x, y: float): Color =
  let x = x.int
  let y = y.int
  return getPixel(s, x, y)

proc setPixel*(s: var Surface, x, y: int, value: Color) =
  # assert x <= s.w
  # assert y <= s.h
  var
    x_o = x
    y_o = y
  # echo "x:[$#] y[$#] value: [$#]" % [$x, $y, $value]
  if s.flip_h:
    x_o = s.w - x
  if s.flip_v:
    y_o = s.h - y
  try:
    s.pixels[y_o][x_o] = value
  except IndexError:
    discard
    # echo "index error" & $x & " " $y

proc setPixel*(s: var Surface, x, y: float, value: Color) =
  let x = x.int
  let y = y.int
  setPixel(s, x, y, value)

proc dump_to_ppm(s: Surface, path: string) =
  var fs = newFileStream(path, fmWrite)
  defer: fs.close()
  if isNil(fs):
    raise newException(IOError, "could not create file")
  fs.writeLine("P3")
  fs.writeLine(" ")
  fs.writeLine("$# $#" % [$(s.w + 1), $(s.h + 1)])
  fs.writeLine(" ")
  fs.writeLine("255")
  fs.writeLine(" ")
  for y, row in pairs(s.pixels):
    for x, p in pairs(row):
      let rgb = extractRGB(p)
      fs.write(" $# $# $#" % [$rgb[0], $rgb[1], $rgb[2]])
    fs.writeLine()

proc dump_to_bmp(s: Surface, path: string) =
  var surf = newScreenSurface(s.w, s.h)
  surf.fillSurface(colBlack)
  for y, row in pairs(s.pixels):
    for x, p in pairs(row):
      surf.setPixel(x, y, p)
  surf.writeToBMP(path)

proc dump_to_tga(s: Surface, path: string) =
  # TODO: fix off by one bug
  var pixel_data: seq[seq[Pixel]]
  pixel_data = @[]

  for y, row in pairs(s.pixels):
    try:
      pixel_data[y].add(@[])
    except IndexError:
      pixel_data.add(@[])
    for p in row:
      let
        rgb = extractRGB(p)
        pixel = newPixel(rgb)
      pixel_data[y].add(pixel)
  var image = newImage(data=pixel_data)
  image.save(path)

proc dump_to_file*(s: Surface, path: string) =
  let components = path.split(".")
  let ext = components[1]
  case ext
  of "ppm": dump_to_ppm(s, path)
  of "bmp": dump_to_bmp(s, path)
  of "tga": dump_to_tga(s, path)
  else: raise newException(ValueError, "given extension is not supported")
