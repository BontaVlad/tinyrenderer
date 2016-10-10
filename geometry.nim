import surface, colors

type
  Vec2i* = tuple[x, y: float]
  Triangle* = tuple[v0, v1, v2: Vec2i]

proc `+`*(u, v: Vec2i): Vec2i =
  result = (x: u.x + v.x, y: u.y + v.y)

proc `-`*(u, v: Vec2i): Vec2i =
  result = (x: u.x - v.x, y: u.y - v.y)

proc `*`*(u: Vec2i, f: float): Vec2i =
  result = (x: u.x.float * f, y: u.y.float * f)

proc newTriangle*(v0, v1, v2: Vec2i): Triangle =
  result.v0 = v0
  result.v1 = v1
  result.v2 = v2
