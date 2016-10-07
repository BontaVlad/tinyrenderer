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
  Offset = tuple[x: float, y: float, z: float]

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

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc line(l_x0, l_y0, l_x1, l_y1: int, sur: PSurface, col: colors.Color) =
  x0 = l_x0
  y0 = l_y0
  x1 = l_x1
  y1 = l_y1
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
  for face in mesh.faces:
    for i,v in pairs(face.v):
      let v0 = face.v[i]
      let v1 = face.v[fmod(float(i+1), 3).int]
      let x0 = ((v0.x + offset.x) * scale).round.int
      let y0 = ((v0.y + offset.y) * scale).round.int
      let x1 = ((v1.x + offset.x) * scale).round.int
      let y1 = ((v1.y + offset.y) * scale).round.int
      verbose(2, echo "i:$# $# $# $# $#" % [$i, $x0, $y0, $x1, $y1])
      # echo "i:$# $# $#" % [$i, $v0, $v1]
      line(x0, y0, x1, y1, surf, colWhite)


let w_obj = Mesh.newMesh(input_file)
verbose(2, echo args)
verbose(0, echo "Loaded mesh: " & $w_obj)

var surf = newScreenSurface(width, height)
surf.fillSurface(colBlack)
let offset = get_offset(w_obj)
let scale = scale_factor(w_obj, width, height)
verbose(1, echo "offset " & $offset)
verbose(1, echo "scale : $#" % $scale)

render(surf, w_obj, offset, scale)

flip_horizontally(surf)
surf.writeToBMP(output_file)
