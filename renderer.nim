import graphics, colors, math, system

iterator range[T](a: T, b: T, step: T): T =
  var res: T = T(a)
  while res <= b:
    yield res
    res = round(res + step, 2)

proc line(x0, y0, x1, y1: int, sur: PSurface, col: colors.Color) =
  var x0: float = float(x0)
  var y0: float = float(y0)
  var x1: float = float(x1)
  var y1: float = float(y1)

  var x: float
  var y: float
  var steep = false

  if (abs(x0-x1) < abs(y0-y1)):
    swap(x0, y0)
    swap(x1, y1)

  if (x0 > x1):
    swap(x0, x1)
    swap(y0, y1)

  for t in range(0.0, 1.0, 0.01):
    echo t
    x = x0 * (1-t) + x1 * t
    y = y0 * (1-t) + y1 * t
    if steep:
      sur.drawLine((int(y), int(y)), (int(x), int(x)), col)
    else:
      sur.drawLine((int(x), int(x)), (int(y), int(y)), col)


var surf = newScreenSurface(1000, 1000)
surf.fillSurface(colBlack)

line(13, 20, 80, 40, surf, colWhite)
line(20, 13, 40, 80, surf, colRed)
line(20, 100, 40, 100, surf, colBlue)

surf.writeToBMP("test.bmp")
