import streams, strutils, future, sequtils, system

import nimasset.obj


type
  Vertex* = tuple[x, y, z: float]
  Texture* = tuple[u, v, w: float]
  Normal* = tuple[x, y, z: float]
  Face* = tuple[v: array[3, Vertex], t: array[3, Texture], n: array[3, Normal]]
  Mesh* = ref object
    vertices*: seq[Vertex]
    textures*: seq[Texture]
    normals*: seq[Normal]
    faces*: seq[Face]

proc all[T](args: varargs[T]): bool =
  return 0 in args

proc `$`*(self: Mesh): string =
  result = "verts: [$#], textures: [$#], normals: [$#], faces: [$#]" % [
    $(self.vertices.len - 1),
    $(self.textures.len - 1),
    $(self.normals.len - 1),
    $self.faces.len]

proc min*(self: Mesh, field: string): float =
  case field
  of "x": result = min(self.vertices.mapIt(float, it.x))
  of "y": result = min(self.vertices.mapIt(float, it.y))
  of "z": result = min(self.vertices.mapIt(float, it.z))
  else: discard

proc width*(self: Mesh): float =
  result = max(self.vertices.mapIt(float, it.x))

proc height*(self: Mesh): float =
  result = max(self.vertices.mapIt(float, it.y))

proc depth*(self: Mesh): float =
  result = max(self.vertices.mapIt(float, it.z))

proc newMesh*(Model: typedesc, path: string): Model =
  let
    loader = new(ObjLoader)
    f = open(path)
    fs = newFileStream(f)

  var mesh = new(Model)
  let empty_vertex: Vertex = (x: float(0), y: float(0), z: float(0))
  let empty_texture: Texture = (u: float(0), v: float(0), w: float(0))
  let empty_normal: Normal = (x: float(0), y: float(0), z: float(0))

  mesh.vertices = @[empty_vertex]
  mesh.textures = @[empty_texture]
  mesh.normals = @[empty_normal]
  mesh.faces = @[]

  proc get[T](s: seq[T], i: int): T =
    if i < 0:
      return s[^abs(i)]
    result = s[i]

  proc addVertex(x, y, z: float) =
    # echo "Vertex: $# $# $#" % [$x, $y, $z]
    let vert: Vertex = (x: x, y: y, z: z)
    mesh.vertices.add(vert)

  proc addTexture(u, v, w: float) =
    # if not all(u, v, w):
    #   return

    let tex: Texture = (u: u, v: v, w: w)
    mesh.textures.add(tex)
    # echo "Texture: $# $# $#" % [$u, $v, $w]

  proc addNormal(x, y, z: float) =
    # if not all(x, y, z):
    #   return

    let norm: Normal = (x: x, y: y, z: z)
    mesh.normals.add(norm)
    # echo "Texture: $# $# $#" % [$u, $v, $w]

  proc addFace(vi0, vi1, vi2, ti0, ti1, ti2, ni0, ni1, ni2: int) =
    try:
      let face: Face = (
        v: [mesh.vertices.get(vi0), mesh.vertices.get(vi1), mesh.vertices.get(vi2)],
        t: [mesh.textures.get(ti0), mesh.textures.get(ti1), mesh.textures.get(ti2)],
        n: [mesh.normals.get(ni0), mesh.normals.get(ni1), mesh.normals.get(ni2)],
      )
      mesh.faces.add(face)
    except IndexError:
      # let
      #   e = getCurrentException()
      #   msg = getCurrentExceptionMsg()
      # echo "Got exception ", repr(e), " with message ", msg
      echo "error $# $# $# $# $# $# $# $# $#" % [$vi0, $vi1, $vi2, $ti0, $ti1, $ti2, $ni0, $ni1, $ni2]
      echo "v_high $# t_high $# n_high $#" % [$mesh.vertices.high, $mesh.textures.high, $mesh.normals.high]

  loadMeshData(loader, fs, addVertex, addTexture, addNormal, addFace)
  return mesh
