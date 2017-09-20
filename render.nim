import math
import strutils
import sequtils
import basic3d

import utils
import world
import geometry
import matrix
import image

type
  Zbuffer = ref object
    width: int
    data: seq[float]

  Renderer* = ref object
    data: seq[uint8]
    depth: int


proc `[]=`(z: var Zbuffer, x, y: int | float, value: float) =
  try:
    let idx = x.int + y.int * z.width
    z.data[idx] = value
  except IndexError:
    echo "x: $# y: $#" % [$x, $y]


proc `[]`(z: Zbuffer, x, y: int | float): float =
  try:
    let idx = x.int + y.int * z.width
    result = z.data[idx]
  except IndexError:
    echo "x: $# y: $#" % [$x, $y]


proc newZbuffer(width, height: int): Zbuffer =
  new result
  result.data = repeat(NegInf, width * height)


proc make_viewport(x, y, width, height, depth: int): Matrix3d =

  let
    aw = x.float + width.float / 2.0
    bw = y.float + height.float / 2.0
    cw = depth.float / 2.0

    ax = width.float / 2.0
    bx = height.float / 2.0
    cx = depth.float / 2.0

    ay = 1.0
    by = 1.0
    cy = 1.0
    az = 1.0
    bz = 1.0
    cz = 1.0

    tx = 1.0
    ty = 1.0
    tz = 1.0
    tw = 1.0

  result = matrix3d(ax, ay, az, aw,
                    bx, by, bz, bw,
                    cx, cy, cz, cw,
                    tx, ty, tz, tw)


proc line(v0_in, v1_in: Vector3d, image: var Image) =
  var
    v0, v1: Vector3d
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

  try:
    for x in countUp(v0.x, v1.x, 1.0):
      if steep:
        image.setPixel(y.int, x.int, 0.uint8, 0.uint8, 0.uint8)
      else:
        image.setPixel(x.int, y.int, 0.uint8, 0.uint8, 0.uint8)
      error2 += derror2
      if error2 > dx:
        y += (if v1.y > v0.y: 1 else: -1)
        error2 -= dx * 2
  except IndexError:
    echo "Index error"


proc render*(world: World, image: var Image, depth = 300) =
  var
    zbuffer = newZbuffer(image.width, image.height)
    tv: Triangle
    tuv: Triangle
    point = vector3d(0.0, 0.0, 0.0)
    surf_cord: Vector3d
    eye = vector3d(2.0, 1.0, 2.0)
    center = vector3d(0.0, 0.0, 0.0)
    up = vector3d(0.0, 1.0, 0.0)
    model  = move(0.6, 1.0, -1.3)
    view = lookAt(eye, center, up)
    # viewport = make_viewport(0, 0, world.w, world.h, r.depth)
    # projection = perspective(math.PI/4, world.w/world.h, 0.01, 100.0)
    projection = ortho(-1.0, 1.0, -1.0, 1.0, 0.01, 100)
    screen = projection & view & model
    # screen = projection * view
    light_dir = vector3d(2.0, 1.0, 2.0)

  for mesh in world.objects:
    for face in mesh.faces:
      tv = Triangle(
        v0: screen * vector3d(1.0, 1.0, 1.0) * face.v[0],
        v1: screen * vector3d(1.0, 1.0, 1.0) * face.v[1],
        v2: screen * vector3d(1.0, 1.0, 1.0) * face.v[2])
      tuv = Triangle(v0: screen * face.t[0], v1: screen * face.t[1], v2: screen * face.t[2])
      for point in get_points_in_bbox(tv.bounding_box):
        let bc = tv.barycentric(point)
        if is_inside(bc, point):
          var
            i = 0
            v = cross(tv.v1 - tv.v0, tv.v2 - tv.v0)
            z = 0.0
          v.normalize
          let intensity = dot(v, light_dir)
          echo "intensity: " & $intensity
          for v in tv.fields:
            z += v.z * bc[i]
            inc(i)

          if zBuffer[point.x, point.y] < z:
            var
              uv = vector3d(0.0, 0.0, 0.0)
              j = 0

            for u in tuv.fields:
              uv.x += (u.x * bc[j]) * mesh.diffusemap.width.float
              uv.y += (u.y * bc[j]) * mesh.diffusemap.height.float
              inc(j)
            let
              diffuse = mesh.diffusemap.getPixel(uv.x.int, uv.y.int)
              r = (diffuse[0].float * intensity).round.uint8
              g = (diffuse[1].float * intensity).round.uint8
              b = (diffuse[2].float * intensity).round.uint8
            # zBuffer[surf_cord.x, surf_cord.y] = z
            image.setPixel(point.x.int, point.y.int, r, g, b)
