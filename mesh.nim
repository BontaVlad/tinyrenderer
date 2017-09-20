import re
import streams
import strutils
import basic3d

import image


type
  ObjLoaderObj = object
  ObjLoader = ref ObjLoaderObj # Loads WafeFront OBJ format for 3D assets

  Face* = tuple[v: array[3, Vector3d], t: array[3, Vector3d], n: array[3, Vector3d]]
  Mesh* = ref object
    vertices*: seq[Vector3d]
    textures*: seq[Vector3d]
    normals*: seq[Vector3d]
    faces*: seq[Face]
    diffusemap*: Image


template loadMeshData*(loader: ObjLoader, s: Stream, addVertex: untyped, addTexture: untyped, addNormal: untyped, addFace: untyped) =
    ## Loads mesh data from stream defined in streams module of
    ## standard library.
    var
        line: string = ""
    while s.readLine(line):
        # Parse line
        # line = line.strip()
        let components = line.split(re"\s+")

        if components.len() == 0:
            continue
        elif components[0] == "#":  # Comment
            continue
        elif components[0] == "v":  # Vertex data
            addVertex(parseFloat(components[1]), parseFloat(components[2]), parseFloat(components[3]))
        elif components[0] == "vt": # Vertex Texture data
            addTexture(parseFloat(components[1]), parseFloat(components[2]), parseFloat(components[3]))
        elif components[0] == "vn": # Vertext Normals data
            addNormal(parseFloat(components[1]), parseFloat(components[2]), parseFloat(components[3]))
        elif components[0] == "f":
            let comnponentsCount = components[1].count("/") + 1
            if comnponentsCount == 1:  # Only vertices in face data
                addFace(parseInt(components[1]), parseInt(components[2]), parseInt(components[3]), 0, 0, 0, 0, 0, 0)
                continue
            elif comnponentsCount >= 2:  # Vertex, Normal and Texture data in face data
                let
                    block_1 = components[1].split("/")
                    block_2 = components[2].split("/")
                    block_3 = components[3].split("/")
                    vi_0 = parseInt(block_1[0])
                    vi_1 = parseInt(block_2[0])
                    vi_2 = parseInt(block_3[0])
                    ti_0 = parseInt(block_1[1])
                    ti_1 = parseInt(block_2[1])
                    ti_2 = parseInt(block_3[1])
                var
                    ni0 = 0
                    ni1 = 0
                    ni2 = 0

                if comnponentsCount >= 3:
                    ni0 = parseInt(block_1[2])
                    ni1 = parseInt(block_2[2])
                    ni2 = parseInt(block_3[2])
                addFace(vi_0, vi_1, vi_2, ti_0, ti_1, ti_2, ni0, ni1, ni2)


template loadMeshData*(loader: ObjLoader, s: Stream, addVertex: untyped, addTexture: untyped, addFace: untyped) =
    template addNormal(x, y, z: float32) = discard
    loadMeshData(loader, s, addVertex, addTexture, addNormal, addFace)


template loadMeshData*(loader: ObjLoader, data: pointer, addVertex: untyped, addTexture: untyped, addNormal: untyped, addFace: untyped) =
    ## Loads mesh data from given pointer as a source, and a size
    ## of data provided with pointer.
    loadMeshData(loader, newStringStream(`$`(cast[cstring](data))), addVertex, addTexture, addNormal, addFace)


when not defined(js):
    template loadMeshData*(loader: ObjLoader, f: File, addVertex: untyped, addTexture: untyped, addNormal: untyped, addFace: untyped) =
        ## Loads mesh data from file
        loadMeshData(loader, newFileStream(f), addVertex, addTexture, addNormal, addFace)


template loadMeshData*(loader: ObjLoader, data: string, addVertex: untyped, addTexture: untyped, addNormal: untyped, addFace: untyped) =
    ## Loads mesh data from string
    loadMeshData(loader, newStringStream(data), addVertex, addTexture, addNormal, addFace)


proc `$`*(self: Mesh): string =
  result = "verts: [$#], textures: [$#], normals: [$#], faces: [$#]" % [
    $(self.vertices.len - 1),
    $(self.textures.len - 1),
    $(self.normals.len - 1),
    $self.faces.len]


proc newMesh*(path: string): Mesh =
  let
    loader = new(ObjLoader)
    f = open(path)
    fs = newFileStream(f)

  var mesh = new(Mesh)
  let empty_vector = vector3d(0.0, 0.0, 0.0)

  mesh.vertices = @[empty_vector]
  mesh.textures = @[empty_vector]
  mesh.normals = @[empty_vector]
  mesh.faces = @[]

  proc get[T](s: seq[T], i: int): T =
    if i < 0:
      return s[^abs(i)]
    result = s[i]

  proc addVertex(x, y, z: float) =
    mesh.vertices.add(vector3d(x, y, z))

  proc addTexture(u, v, w: float) =
    mesh.textures.add(vector3d(u, v, w))

  proc addNormal(x, y, z: float) =
    mesh.normals.add(vector3d(x, y, z))

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
  new result
  result = newMesh(mesh_filepath)
  result.diffusemap = newImage(diffuse_filepath)


when isMainModule:
  import unittest

  suite "Test mesh loading":
    test "mesh.newMesh":
      var mesh = newMesh("objs/african_head.obj", "african_head_diffuse.tga")

      check(mesh.faces.len == 2492)
      check(mesh.diffusemap.width == 1024)
      check(mesh.diffusemap.height == 1024)
      check(mesh.diffusemap.channels == 4)
