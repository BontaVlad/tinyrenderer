let doc = """
Usage:
  main [options]

Options:
  -h --help           Show this message
  --verbose=<lvl>     Show debug messages based on level
  --width=<pixels>    Image width [default: 800]
  --height=<pixels>   Image height [default: 800]
"""

import strutils

import docopt

import world
import mesh
import render
import image


let args = docopt(doc)

let
  width = parse_int($args["--width"])
  height = parse_int($args["--height"])

template verbose(lvl: int, stm: untyped): untyped =
  if args["--verbose"]:
    if parseInt($args["--verbose"]) == lvl: stm

proc main =
  let world = newWorld(
    @[newMesh("objs/african_head.obj", "african_head_diffuse.tga")]
  )
  var image = newImage(width, height)
  render(world, image)
  image.write("output.png", width, height)

main()
