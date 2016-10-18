let doc = """
Usage:
  render [options] -f FILE -o FILE

Options:
  -h --help           Show this message
  --verbose=<lvl>     Show debug messages based on level
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
  --wireframe=<over | only>
"""

import colors, os, math, strutils, random, basic3d

import docopt

import mesh, geometry, surface, utils

let args = docopt(doc)

type
  Offset = tuple[x, y, z: float]
  Zbuffer = seq[float]

let
  input_file =  if args["-f"]: $args["FILE"][0] else: ""
  output_file =  if args["-o"]: $args["FILE"][1] else: ""
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])
  wireframe = $args["--wireframe"]

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc `[]=`(z: var Zbuffer, x, y: int | float, value: float) =
  let idx = x.int + y.int * width
  z[idx] = value

proc `[]`(z: Zbuffer, x, y: int | float): float =
  let idx = x.int + y.int * width
  result = z[idx]

proc ZbufferNew(): Zbuffer =
  result = @[]
  for i in 0 .. height * width:
    result.add(NegInf)

proc line(v0_in, v1_in: Vec3, sur: var Surface, col: colors.Color) =
  var
    v0, v1: Vec3
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

proc triangle*(t: Triangle, surf: var Surface, zBuffer: var Zbuffer, col: colors.Color, wireframe="") =
  if not wireframe.isNilOrEmpty:
    if not (wireframe in ["over", "only"]):
      raise newException(ValueError, "invalid wireframe mode")

  if wireframe != "only":
    var point: Vec3
    for pixel in get_points_in_bbox(t.bounding_box):
      point.z = 0
      let bc = t.barycentric(pixel)
      if is_inside(bc, pixel):
        var i = 0
        for v in t.fields:
          point.z += v.z * bc[i]
          inc(i)
        if zBuffer[pixel.x, pixel.y] < point.z:
          zBuffer[pixel.x, pixel.y] = point.z
          surf.setPixel(pixel.x, pixel.y, col)

  if not wireframe.isNilOrEmpty:
    line(t.v0, t.v1, surf, colYellow)
    line(t.v1, t.v2, surf, colYellow)
    line(t.v2, t.v0, surf, colYellow)

# debug helpers
# proc draw_boundingbox(s: var Surface, t: Triangle) =
#   let bbox = t.bounding_box
#   line(bbox.p0, bbox.p1, s, colYellow)
#   line(bbox.p1, bbox.p3, s, colYellow)
#   line(bbox.p3, bbox.p2, s, colYellow)
#   line(bbox.p2, bbox.p0, s, colYellow)

# debug helpers
# proc fill_bbox(s: var Surface, t: Triangle, c: Color) =
#   for v in get_points_in_bbox(t.bounding_box):
#     s.setPixel(v.x, v.y, c)

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
  let light_dir: Vec3 = (0.0, 0.0, 0.8)
  var zBuffer = ZbufferNew()
  var
    screen_coordinates: array[3, Vec3]
  for face in mesh.faces:
    for i,v in pairs(face.v):
      screen_coordinates[i] = ((v.x + offset.x) * scale, (v.y + offset.y) * scale, v.z)
    let v = (face.v[1] - face.v[0]) ^ (face.v[2] - face.v[0])
    let v_n = v.normalize()
    let intensity = v_n * light_dir
    if intensity >= 0.0:
      let color = rgb((intensity * 255).int, (intensity * 255).int, (intensity * 255).int)
      triangle(newTriangle(screen_coordinates[0], screen_coordinates[1], screen_coordinates[2]), surf, zBuffer, color, wireframe)

let w_obj = newMesh(input_file)
verbose(2, echo args)
verbose(0, echo "Loaded mesh: " & $w_obj)

var s = newSurface(width, height)
s.flip_vertically()

let offset = get_offset(w_obj)
let scale = scale_factor(w_obj, width, height)

verbose(1, echo "offset " & $offset)
verbose(1, echo "scale : $#" % $scale)

render(s, w_obj, offset, scale)

s.dump_to_file(output_file)
