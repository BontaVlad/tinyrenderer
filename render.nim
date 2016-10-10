let doc = """
Usage:
  render [options] -f FILE -o FILE

Options:
  -h --help           Show this message
  --verbose=<lvl>     Show debug messages based on level
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
"""

import colors, os, math, system, strutils

import docopt

import mesh, geometry, surface

let args = docopt(doc)

type
  Offset = tuple[x, y, z: float]

let
  input_file =  if args["-f"]: $args["FILE"][0] else: ""
  output_file =  if args["-o"]: $args["FILE"][1] else: ""
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])

iterator countup*(a: float, b: float, step = 1.0): float {.inline.} =
  var res:float = a
  while res <= b:
    yield res
    res += step

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc triangle*(t: Triangle, surf: var Surface, col: colors.Color) =
  var
    v0 = t.v0
    v1 = t.v1
    v2 = t.v2

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

proc line(v0_in, v1_in: Vec2i, sur: var Surface, col: colors.Color) =
  var
    v0, v1: Vec2i
    steep = false
  v0 = v0_in
  v1 = v1_in

  if (abs(v0.x-v1.x) < abs(v0.y-v1.y)):
    swap(v0.x, v0.y)
    swap(v1.x, v1.y)
    steep = true

  if (v0.x > v1.x):
    swap(v0.x, v1.x)
    swap(v0.y, v1.y)

  let dx = v1.x - v0.x
  let dy = v1.y - v0.y

  let derror2 = abs(dy * 2)
  var error2 = 0.0
  var y = v0.y

  y = v0.y
  for x in countUp(v0.x, v1.x):
    if steep:
      sur.setPixel(y, x, col)
    else:
      sur.setPixel(x, y, col)
    error2 += derror2
    if error2 > dx:
      y += (if v1.y > v0.y: 1 else: -1)
      error2 -= dx * 2


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

proc render(surf: var Surface, mesh: Mesh, offset: Offset, scale: float) =
  var
    p0, p1: Vec2i
    v0, v1: Vertex
  for face in mesh.faces:
    for i,v in pairs(face.v):
      v0 = face.v[i]
      v1 = face.v[fmod(float(i+1), 3).int]
      p0.x = ((v0.x + offset.x) * scale)
      p0.y = ((v0.y + offset.y) * scale)
      p1.x = ((v1.x + offset.x) * scale)
      p1.y = ((v1.y + offset.y) * scale)
      verbose(2, echo "i:$# $# $# $# $#" % [$i, $p0.x, $p0.y, $p1.x, $p1.y])
      line(p0, p1, surf, colWhite)


let w_obj = Mesh.newMesh(input_file)
verbose(2, echo args)
verbose(0, echo "Loaded mesh: " & $w_obj)

var s = newSurface(width, height)
s.flip_both()

let offset = get_offset(w_obj)
let scale = scale_factor(w_obj, width, height)

verbose(1, echo "offset " & $offset)
verbose(1, echo "scale : $#" % $scale)

render(s, w_obj, offset, scale)
# let t0 = newTriangle((10.0, 70.0), (50.0, 160.0), (70.0, 80.0))
# let t1 = newTriangle((180.0, 50.0), (150.0, 1.0), (70.0, 180.0))
# let t2 = newTriangle((180.0, 150.0), (120.0, 160.0), (130.0, 180.0))
# triangle(t0, s, colRed)
# triangle(t1, s, colWhite)
# triangle(t2, s, colGreen)

s.dump_to_file(output_file)
