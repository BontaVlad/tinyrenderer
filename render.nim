let doc = """
Usage:
  render [options] -f FILE -o FILE [--diffuse FILE]

Options:
  -h --help           Show this message
  --verbose=<lvl>     Show debug messages based on level
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
  --wireframe=<over | only>
"""

import colors
import math
import strutils

import glm
import docopt

import mesh
import geometry
import surface
import utils

let args = docopt(doc)

type
  Zbuffer = seq[float]

let
  input_file =  if args["-f"]: $args["FILE"][0] else: ""
  output_file =  if args["-o"]: $args["FILE"][1] else: ""
  diffuse_file =  if args["--diffuse"]: $args["FILE"][2] else: ""
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])
  depth = 300
  wireframe = $args["--wireframe"]

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc `[]=`(z: var Zbuffer, x, y: int | float, value: float) =
  try:
    let idx = x.int + y.int * width
    z[idx] = value
  except IndexError:
    discard
    echo "x: $# y: $#" % [$x, $y]

proc `[]`(z: Zbuffer, x, y: int | float): float =
  try:
    let idx = x.int + y.int * width
    result = z[idx]
  except IndexError:
    discard
    echo "x: $# y: $#" % [$x, $y]

proc ZbufferNew(): Zbuffer =
  result = @[]
  for i in 0 .. height * width:
    result.add(NegInf)

proc line(v0_in, v1_in: Vec3[float], sur: var Surface, col: Color) =
  var
    v0, v1: Vec3[float]
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
  try:
    for x in countUp(v0.x, v1.x, 1.0):
      if steep:
        sur.setPixel(y, x, col)
      else:
        sur.setPixel(x, y, col)
      error2 += derror2
      if error2 > dx:
        y += (if v1.y > v0.y: 1 else: -1)
        error2 -= dx * 2
  except IndexError:
    discard

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

proc render(surface: var Surface, mesh: Mesh) =

  proc homogen[T](v:Vec4[T]): Vec4[T] {.inline.} = Vec4[T](arr: [v.x/v.w, v.y/v.w, v.z/v.w, v.w])
  proc vec3[T](v:Vec4[T]): Vec3[T] {.inline.} = Vec3[T](arr: [v.x, v.y, v.z])

  proc make_viewport[T](x, y, w, h: int): Mat4x4[T] =
    result = mat4[T](1.0)

    result[0][3] = x.float + width.float / 2.0
    result[1][3] = y.float + height.float / 2.0
    result[2][3] = depth.float / 2.0

    result[0][0] = width.float / 2.0
    result[1][1] = height.float / 2.0
    result[2][2] = depth.float / 2.0

  let
    eye = vec3(2.0, 1.0, 2.0)
    center = vec3(0.0)
    up = vec3(0.0, 1.0, 0.0)
    model  = translate(mat4(1.0), vec3(0.6, 1.0, -1.3))
    view = lookAt(eye, center, up)
    viewport = make_viewport[float](0, 0, width, height)
    projection = perspective(math.PI/4, width/height, 0.01, 100.0)
    # projection = ortho(-1.0, 1.0, -1.0, 1.0, 0.01, 100)
    screen = projection * view * model
    light_dir = vec3(2.0, 1.0, 2.0)

  var
    zBuffer = ZbufferNew()
    tv: Triangle
    tuv: Triangle
    point = vec3(0.0)
    surf_cord: Vec4[float]

  for face in mesh.faces:
    tv = Triangle(
      v0: screen * vec4(face.v[0], 1.0),
      v1: screen * vec4(face.v[1], 1.0),
      v2: screen * vec4(face.v[2], 1.0))
    tuv = Triangle(v0: vec4(face.t[0], 1.0), v1: vec4(face.t[1], 1.0), v2: vec4(face.t[2], 1.0))
    for pixel in get_points_in_bbox(tv.bounding_box):
      let bc = tv.barycentric(pixel)
      if is_inside(bc, pixel):
        var
          i = 0
          v = cross(vec3((tv.v1 - tv.v0)), vec3((tv.v2 - tv.v0)))
          v_n = v.normalize
          intensity = dot(v_n, light_dir)

        echo "vn: " & glm.`$`(v_n)
        echo "intensity: " & $intensity
        point.z = 0
        for v in tv.fields:
          point.z += v.z * bc[i]
          inc(i)

        if zBuffer[pixel.x, pixel.y] < point.z:
          var
            uv = vec2(0.0, 0.0)
            j = 0

          for u in tuv.fields:
            # uv.x += (u.x * bc[j]) * mesh.diffusemap.width
            # uv.y += (u.y * bc[j]) * mesh.diffusemap.heigh
            uv.x += (u.x * bc[j]) * 1024
            uv.y += (u.y * bc[j]) * 1024
            inc(j)
          let
            dif_col = mesh.diffuseGetColor(uv)
            # dif_col = colRed
            tmp = dif_col.extractRGB
            r = (tmp.r.float * intensity).round.int
            g = (tmp.g.float * intensity).round.int
            b = (tmp.b.float * intensity).round.int
            col = if intensity > 0.0: rgb(r, g, b) else: dif_col
          # let col = rgb(r, g, b)
          # echo "r: $# g: $# b: $#" % [$r, $g, $b]
          surf_cord = vec4(1.0)
          zBuffer[surf_cord.x, surf_cord.y] = point.z
          surface.setPixel(surf_cord.x, surf_cord.y, col)
    # line(tv.v0, tv.v1, surface, colYellow)
    # line(tv.v1, tv.v2, surface, colYellow)
    # line(tv.v2, tv.v0, surface, colYellow)

var obj: Mesh
if diffuse_file.isNilOrEmpty:
  obj = newMesh(input_file)
else:
  obj = newMesh(input_file, diffuse_file)
verbose(2, echo args)
verbose(0, echo "Loaded mesh: " & $obj)

var s = newSurface(width, height)
s.flip_vertically()

render(s, obj)

s.dump_to_file(output_file)
