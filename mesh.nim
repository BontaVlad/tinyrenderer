import streams, strutils, future, sequtils, system, colors

import nimasset.obj, nimtga

import geometry

type
  Face* = tuple[v: array[3, Vec3], t: array[3, Vec3], n: array[3, Vec3]]
  Mesh* = ref object
    vertices*: seq[Vec3]
    textures*: seq[Vec3]
    normals*: seq[Vec3]
    faces*: seq[Face]
    diffusemap*: Image

# proc all[T](args: varargs[T]): bool =
#   return 0 in args

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

proc newMesh*(path: string): Mesh =
  let
    loader = new(ObjLoader)
    f = open(path)
    fs = newFileStream(f)

  var mesh = new(Mesh)
  let empty_vector: Vec3 = (0.0, 0.0, 0.0)

  mesh.vertices = @[empty_vector]
  mesh.textures = @[empty_vector]
  mesh.normals = @[empty_vector]
  mesh.faces = @[]

  proc get[T](s: seq[T], i: int): T =
    if i < 0:
      return s[^abs(i)]
    result = s[i]

  proc addVertex(x, y, z: float) =
    mesh.vertices.add((x, y, z))

  proc addTexture(u, v, w: float) =
    mesh.textures.add((u, v, w))

  proc addNormal(x, y, z: float) =
    mesh.normals.add((x, y, z))

  proc addFace(vi0, vi1, vi2, ti0, ti1, ti2, ni0, ni1, ni2: int) =
    try:
      let face: Face = (
        v: [mesh.vertices.get(vi0), mesh.vertices.get(vi1), mesh.vertices.get(vi2)],
        t: [mesh.textures.get(ti0), mesh.textures.get(ti1), mesh.textures.get(ti2)],
        n: [mesh.normals.get(ni0), mesh.normals.get(ni1), mesh.normals.get(ni2)],
      )
      mesh.faces.add(face)
    except IndexError:
      echo "error $# $# $# $# $# $# $# $# $#" % [$vi0, $vi1, $vi2, $ti0, $ti1, $ti2, $ni0, $ni1, $ni2]
      echo "v_high $# t_high $# n_high $#" % [$mesh.vertices.high, $mesh.textures.high, $mesh.normals.high]

  loadMeshData(loader, fs, addVertex, addTexture, addNormal, addFace)
  return mesh

proc newMesh*(mesh_filepath, diffuse_filepath: string): Mesh =
  echo "loading diffuse: " & diffuse_filepath
  new(result)
  result = newMesh(mesh_filepath)
  result.diffusemap = newImage(diffuse_filepath)

proc diffuseGetColor*(self: Mesh, uv: Vec2): Color =
  discard
  # result = self.diffusemap.getPixel(uv.x.int, uv.y.int).toColor
