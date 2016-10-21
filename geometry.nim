import surface, colors, utils, math

type
  Vec2* = tuple[x, y: float]
  Vec3* = tuple[x, y, z: float]
  Triangle* = object
    v0*, v1*, v2*: Vec3
  BBox* = tuple[p0, p1, p2, p3: Vec2]

proc len*(v: Vec3): float=
  sqrt(v.x * v.x + v.y * v.y + v.z * v.z)

proc `+`*(u, v: Vec2): Vec2 =
  result = (x: u.x + v.x, y: u.y + v.y)

proc `+`*(u, v: Vec3): Vec3 =
  result = (x: u.x + v.x, y: u.y + v.y, z: u.z + v.z)

proc `-`*(u, v: Vec2): Vec2 =
  result = (x: u.x - v.x, y: u.y - v.y)

proc `-`*(u, v: Vec3): Vec3 =
  result = (x: u.x - v.x, y: u.y - v.y, z: u.z - v.z)

proc `*`*(u: Vec2, f: float): Vec2 =
  result = (x: u.x.float * f, y: u.y.float * f)

proc `*`*(v1, v2: Vec3): float =
  result = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

proc `^`*(v1, v2: Vec3): Vec3 =
  result.x = (v1.y * v2.z) - (v2.y * v1.z)
  result.y = (v1.z * v2.x) - (v2.z * v1.x)
  result.z = (v1.x * v2.y) - (v2.x * v1.y)

proc normalize*(v: Vec3): Vec3 =
  let mag=v.len

  if mag==0.0:
    raise newException(DivByZeroError, "Cannot normalize zero length vector")

  result.x = v.x / mag
  result.y = v.y / mag
  result.z = v.z / mag

proc newTriangle*(v0, v1, v2: Vec3): Triangle =
  result.v0 = v0
  result.v1 = v1
  result.v2 = v2

proc bounding_box*(t: Triangle): BBox=
  result.p0.x = min([t.v0.x, t.v1.x, t.v2.x])
  result.p0.y = min([t.v0.y, t.v1.y, t.v2.y])
  result.p3.x = max([t.v0.x, t.v1.x, t.v2.x])
  result.p3.y = max([t.v0.y, t.v1.y, t.v2.y])
  result.p1.x = result.p3.x
  result.p1.y = result.p0.y
  result.p2.x = result.p0.x
  result.p2.y = result.p3.y

iterator get_points_in_bbox*(bbox: BBox): Vec2 =
  for y in bbox.p0.y.int .. bbox.p3.y.int:
    for x in bbox.p0.x.int .. bbox.p3.x.int:
      yield (x.float, y.float)

proc barycentric*(t: Triangle, p: Vec2): array[3, float] =
  let lambda1 = ((t.v1.y - t.v2.y) * (p.x - t.v2.x) + (t.v2.x - t.v1.x) * (p.y - t.v2.y)) /
                ((t.v1.y - t.v2.y) * (t.v0.x - t.v2.x) + (t.v2.x - t.v1.x) * (t.v0.y - t.v2.y))
  let lambda2 = ((t.v2.y - t.v0.y) * (p.x - t.v2.x) + (t.v0.x - t.v2.x) * (p.y - t.v2.y)) /
                ((t.v1.y - t.v2.y) * (t.v0.x - t.v2.x) + (t.v2.x - t.v1.x) * (t.v0.y - t.v2.y))
  let lambda3 = 1.0 - lambda1 - lambda2
  return [lambda1, lambda2, lambda3]

template is_inside*(bc: array[3, float], v: Vec2): bool =
  # min(bc) >= 0.0
  # this is faster
  bc[0] >= 0.0 and bc[1] >= 0.0 and bc[2] >= 0
