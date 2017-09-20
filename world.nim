import mesh

type
  World* = ref object
    objects*: seq[Mesh]
    w*, h*: int


proc newWorld*(objects: openarray[Mesh] = @[]): World =
    new result
    result.objects = @[]

    for mesh in objects:
      result.objects.add(mesh)

