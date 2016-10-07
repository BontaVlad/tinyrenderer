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
  Vec2i = tuple[x, y: int]

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

proc `+`(u, v: Vec2i): Vec2i =
  result = (x: u.x + v.x, y: u.y + v.y)

proc `-`(u, v: Vec2i): Vec2i =
  result = (x: u.x - v.x, y: u.y - v.y)

# proc `*`(u: Vec2i, f: float): Vec2i =
#   result = (x: u.x.float * f, y: u.y.float * f)

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc line(p0, p1: Vec2i, sur: PSurface, col: colors.Color) =
  x0 = p0.x
  y0 = p0.y
  x1 = p1.x
  y1 = p1.y
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
  if (v0.y > v1.y): swap(v0, v1)
  if (v0.y > v2.y): swap(v0, v2)
  if (v1.y > v2.y): swap(v1, v2)
  line(v0, v1, sur, colYellow)
  line(v1, v2, sur, colYellow)
  line(v2, v0, sur, colRed)
  let total_height = v2.y - v0.y
  for y in v0.y .. v1.y:
    let segment_height = v1.y - v0.y + 1
    let alpha = (y - v0.y) / total_height
    let beta = (y - v0.y) / segment_height
    let a = v0 + (v2 - v0)
    let b = v0 + (v1 - v0)
    # TODO: put pixels

  # for (int y=t0.y; y<=t1.y; y++) { 
  #   int segment_height = t1.y-t0.y+1; 
  #   float alpha = (float)(y-t0.y)/total_height; 
  #   float beta  = (float)(y-t0.y)/segment_height; // be careful with divisions by zero 
  #   Vec2i A = t0 + (t2-t0)*alpha; 
  #   Vec2i B = t0 + (t1-t0)*beta; 
  #   image.set(A.x, y, red); 
  #   image.set(B.x, y, green); 
                               # }

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
      p0.x = ((v0.x + offset.x) * scale).round.int
      p0.y = ((v0.y + offset.y) * scale).round.int
      p1.x = ((v1.x + offset.x) * scale).round.int
      p1.y = ((v1.y + offset.y) * scale).round.int
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
var t0: array[3, Vec2i] = [(10, 70), (50, 160), (70, 80)]
var t1: array[3, Vec2i] = [(180, 50), (150, 1), (70, 180)]
var t2: array[3, Vec2i] = [(180, 150), (120, 160), (130, 180)]
triangle(t0[0], t0[1], t0[2], surf, colRed)
triangle(t1[0], t1[1], t1[2], surf, colWhite)
triangle(t2[0], t2[1], t2[2], surf, colGreen)

flip_horizontally(surf)
surf.writeToBMP(output_file)
