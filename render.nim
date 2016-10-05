let doc = """
Usage:
  render [options] -f FILE -o FILE

Options:
  -h --help           Show this message
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
"""

import docopt


import graphics, colors, os,
       math, system, strutils

import mesh


let args = docopt(doc)
echo args

let
  input_file =  if args["-f"]: $args["FILE"][0] else: ""
  output_file =  if args["-o"]: $args["FILE"][1] else: ""
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])

var
  x0: int
  y0: int
  x1: int
  y1: int

proc line(l_x0, l_y0, l_x1, l_y1: int, sur: PSurface, col: colors.Color) =
  x0 = l_x0
  y0 = l_y0
  x1 = l_x1
  y1 = l_y1
  var steep = false

  if (abs(x0-x1) < abs(y0-y1)):
    swap(x0, y0)
    swap(x1, y1)
    steep = true

  if (x0 > x1):
    swap(x0, x1)
    swap(y0, y1)

  let dx = x1 - x0
  let dy = y1 - y0

  let derror2 = abs(dy * 2)
  var error2 = 0
  var y = y0

  y = y0
  for x in x0 .. x1:
    if steep:
      sur.setPixel(y, x, col)
    else:
      sur.setPixel(x, y, col)
    error2 += derror2
    if error2 > dx:
      y += (if y1 > y0: 1 else: -1)
      error2 -= dx * 2

proc render(surf: PSurface, mesh: Mesh) =
  for face in mesh.faces:
    for i,v in pairs(face.v):
      let v0 = face.v[i]
      let v1 = face.v[fmod(float(i+1), 3).int]
      let x0 = ((v0.x + 1) * width.float / 6f).int.abs
      let y0 = ((v0.y + 1) * height.float / 6f).int.abs
      let x1 = ((v1.x + 1) * width.float / 6f).int.abs
      let y1 = ((v1.y + 1) * height.float / 6f).int.abs

      echo "i:$# $# $# $# $#" % [$i, $x0, $y0, $x1, $y1]
      # echo "i:$# $# $#" % [$i, $v0, $v1]

      line(x0, y0, x1, y1, surf, colWhite)


let w_obj = Mesh.newMesh(input_file)
echo "Loaded mesh: " & $w_obj

var surf = newScreenSurface(width, height)
surf.fillSurface(colBlack)

render(surf, w_obj)

surf.writeToBMP(output_file)
