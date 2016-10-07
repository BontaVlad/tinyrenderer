let doc = """
Usage:
  render [options] -f FILE -o FILE

Options:
  -h --help           Show this message
  --verbose=<lvl>     Show debug messages based on level
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
"""

import docopt


import graphics, colors, os,
       math, system, strutils

import mesh


let args = docopt(doc)

type
  Offset = tuple[x, y, z: float]
  Vec2i = tuple[x, y: float]

let
  input_file =  if args["-f"]: $args["FILE"][0] else: ""
  output_file =  if args["-o"]: $args["FILE"][1] else: ""
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])

var
  x0: int
  y0: int
  x1: int
  y1: int

iterator countup*(a: float, b: float, step = 1.0): float {.inline.} =
  var res:float = a
  while res <= b:
    yield res
    res += step

proc `+`(u, v: Vec2i): Vec2i =
  result = (x: u.x + v.x, y: u.y + v.y)

proc `-`(u, v: Vec2i): Vec2i =
  result = (x: u.x - v.x, y: u.y - v.y)

proc `*`(u: Vec2i, f: float): Vec2i =
  result = (x: u.x.float * f, y: u.y.float * f)

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc line(p0, p1: Vec2i, sur: PSurface, col: colors.Color) =
  x0 = p0.x.int
  y0 = p0.y.int
  x1 = p1.x.int
  y1 = p1.y.int
  var steep = false

  if (abs(x0-x1) < abs(y0-y1)):
    swap(x0, y0)
    swap(x1, y1)
    steep = true

  if (x0 > x1):
    swap(x0, x1)
    swap(y0, y1)

  let dx = x1 - x0
  let dy = y1 - y0

  let derror2 = abs(dy * 2)
  var error2 = 0
  var y = y0

  y = y0
  for x in x0 .. x1:
    if steep:
      sur.setPixel(y, x, col)
    else:
      sur.setPixel(x, y, col)
    error2 += derror2
    if error2 > dx:
      y += (if y1 > y0: 1 else: -1)
      error2 -= dx * 2

template triangle(v0, v1, v2: var Vec2i, sur: PSurface, col: colors.Color) =
  # if v0.y == v1.y and v0.y == v1.y: discard
  if (v0.y > v1.y): swap(v0, v1)
  if (v0.y > v2.y): swap(v0, v2)
  if (v1.y > v2.y): swap(v1, v2)

  let total_height = v2.y - v0.y

  var
    second_half: bool
    segment_height: float
    a, b: Vec2i
    alpha, beta: float

  for i in countUp(0, total_height):
    second_half = i > v1.y - v0.y or v1.y == v0.y
    segment_height = if second_half: v2.y - v1.y else: v1.y - v0.y
    alpha = i / total_height
    beta = (i - (if second_half: v1.y - v0.y else: 0)) / segment_height
    a = v0 + (v2 - v0) * alpha
    b = if second_half: v1 + (v2 - v1) * beta else: v0 + (v1 - v0) * beta
    if a.x > b.x: swap(a, b)
    for j in countUp(a.x, b.x):
      surf.setPixel(j.int, int(v0.y + i), col)

proc scale_factor(mesh: Mesh, width, height: int): float =
  verbose(1, echo "max" & $max([mesh.width, mesh.height]))
  return min([width, height]).float / max([mesh.width, mesh.height]) / 2

proc get_offset(mesh: Mesh): Offset =
  let x = mesh.min("x")
  let y = mesh.min("y")
  let z = mesh.min("z")
  result = (
    x: if x < 0: x.abs else: 0,
    y: if y < 0: y.abs else: 0,
    z: if z < 0: z.abs else: 0
  )

proc flip_horizontally(surf: PSurface) =
  var p1, p2: Color
  let mid = height div 2
  var mirror: int
  for x in 1..width:
    for y in 1..mid - 1:
      mirror = height - y
      p1 = surf.getPixel(x, y)
      p2 = surf.getPixel(x, mirror)
      surf.setPixel(x, y, p2)
      surf.setPixel(x, mirror, p1)

proc render(surf: PSurface, mesh: Mesh, offset: Offset, scale: float) =
  var p0, p1: Vec2i
  for face in mesh.faces:
    for i,v in pairs(face.v):
      let v0 = face.v[i]
      let v1 = face.v[fmod(float(i+1), 3).int]
      p0.x = ((v0.x + offset.x) * scale)
      p0.y = ((v0.y + offset.y) * scale)
      p1.x = ((v1.x + offset.x) * scale)
      p1.y = ((v1.y + offset.y) * scale)
      verbose(2, echo "i:$# $# $# $# $#" % [$i, $x0, $y0, $x1, $y1])
      # echo "i:$# $# $#" % [$i, $v0, $v1]
      line(p0, p1, surf, colWhite)


let w_obj = Mesh.newMesh(input_file)
verbose(2, echo args)
verbose(0, echo "Loaded mesh: " & $w_obj)

var surf = newScreenSurface(width, height)
surf.fillSurface(colBlack)
let offset = get_offset(w_obj)
let scale = scale_factor(w_obj, width, height)
verbose(1, echo "offset " & $offset)
verbose(1, echo "scale : $#" % $scale)

# render(surf, w_obj, offset, scale)
var t0: array[3, Vec2i] = [(10.0, 70.0), (50.0, 160.0), (70.0, 80.0)]
var t1: array[3, Vec2i] = [(180.0, 50.0), (150.0, 1.0), (70.0, 180.0)]
var t2: array[3, Vec2i] = [(180.0, 150.0), (120.0, 160.0), (130.0, 180.0)]
triangle(t0[0], t0[1], t0[2], surf, colRed)
triangle(t1[0], t1[1], t1[2], surf, colWhite)
triangle(t2[0], t2[1], t2[2], surf, colGreen)

flip_horizontally(surf)
surf.writeToBMP(output_file)
