import strutils

import glm

import utils

type
  Triangle* = object
    v0*, v1*, v2*: Vec4[float]
  BBox* = tuple[p0, p1, p2, p3: Vec2[float]]

proc `$`*(t: Triangle): string =
  return "\nv0: $# \nv1: $# \nv2 $#" % [glm.`$`(t.v0), glm.`$`(t.v1), glm.`$`(t.v2)]

proc bounding_box*(t: Triangle): BBox=
  result.p0 = vec2(min([t.v0.x, t.v1.x, t.v2.x]),
                   min([t.v0.y, t.v1.y, t.v2.y]))
  result.p3 = vec2(max([t.v0.x, t.v1.x, t.v2.x]),
                   max([t.v0.y, t.v1.y, t.v2.y]))
  result.p1 = vec2(result.p3.x, result.p0.y)
  result.p2 = vec2(result.p0.x, result.p3.y)

iterator get_points_in_bbox*(bbox: BBox): Vec2[float] =
  for y in countup(bbox.p0.y, bbox.p3.y, 1.0):
    for x in countup(bbox.p0.x, bbox.p3.x, 1.0):
      yield vec2(x, y)

proc barycentric*(t: Triangle, p: Vec2[float]): array[3, float] =
  let lambda1 = ((t.v1.y - t.v2.y) * (p.x - t.v2.x) + (t.v2.x - t.v1.x) * (p.y - t.v2.y)) /
                ((t.v1.y - t.v2.y) * (t.v0.x - t.v2.x) + (t.v2.x - t.v1.x) * (t.v0.y - t.v2.y))
  let lambda2 = ((t.v2.y - t.v0.y) * (p.x - t.v2.x) + (t.v0.x - t.v2.x) * (p.y - t.v2.y)) /
                ((t.v1.y - t.v2.y) * (t.v0.x - t.v2.x) + (t.v2.x - t.v1.x) * (t.v0.y - t.v2.y))
  let lambda3 = 1.0 - lambda1 - lambda2
  return [lambda1, lambda2, lambda3]

template is_inside*(bc: array[3, float], v: Vec2[float]): bool =
  bc[0] >= 0.0 and bc[1] >= 0.0 and bc[2] >= 0
