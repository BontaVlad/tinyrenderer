iterator countup*(a: float, b: float, step = 1.0): float {.inline.} =
  var res:float = a
  while res <= b:
    yield res
    res += step
