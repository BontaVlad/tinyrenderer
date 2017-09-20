# import math
# import basic2d
# import basic3d

# import geometry

# type
#   Matrix3d* = object
#     m11*, m12*, m13*: float
#     m21*, m22*, m23*: float
#     m31*, m32*, m33*: float
#   Matrix4d* = object
#     m11*, m12*, m13*, m14*: float
#     m21*, m22*, m23*, m24*: float
#     m31*, m32*, m33*, m34*: float
#     m41*, m42*, m43*, m44*: float

# proc newMatrix3d*(m11, m12, m13, m21, m22, m23, m31, m32, m33: float): Matrix3d {.noInit.}
# proc newMatrix4d*(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44: float): Matrix4d {.noInit.}

# let
#   idMatrix3*: Matrix3d = newMatrix3d(
#     1.0f, 0.0f, 0.0f,
#     0.0f, 1.0f, 0.0f,
#     0.0f, 0.0f, 1.0f)
#   idMatrix4*: Matrix4d = newMatrix4d(
#     1.0f, 0.0f, 0.0f, 0.0f,
#     0.0f, 1.0f, 0.0f, 0.0f,
#     0.0f, 0.0f, 1.0f, 0.0f,
#     0.0f, 0.0f, 0.0f, 1.0f)
#   origo*: Vector3d = vector3d(0.0,0.0,0.0)
#   xAxis*: Vector3d = vector3d(1.0,0.0,0.0)
#   yAxis*: Vector3d = vector3d(0.0,1.0,0.0)
#   zAxis*: Vector3d = vector3d(0.0,0.0,1.0)

# proc setElements*(t: var Matrix3d, m11, m12, m13, m21, m22, m23, m31, m32, m33: float) {.inline.}=
#   t.m11 = m11
#   t.m12 = m12
#   t.m13 = m13

#   t.m21 = m21
#   t.m22 = m22
#   t.m23 = m23

#   t.m31 = m31
#   t.m32 = m32
#   t.m33 = m33

# proc setElements*(t: var Matrix4d, m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44: float) {.inline.}=
#   t.m11 = m11
#   t.m12 = m12
#   t.m13 = m13
#   t.m14 = m14

#   t.m21 = m21
#   t.m22 = m22
#   t.m23 = m23
#   t.m24 = m24

#   t.m31 = m31
#   t.m32 = m32
#   t.m33 = m33
#   t.m34 = m34

#   t.m41 = m41
#   t.m42 = m42
#   t.m43 = m43
#   t.m44 = m44

# proc newMatrix3d*(m11, m12, m13, m21, m22, m23, m31, m32, m33: float): Matrix3d =
#   result.setElements(m11, m12, m13, m21, m22, m23, m31, m32, m33)

# proc newMatrix4d*(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44: float): Matrix4d =
#   result.setElements(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44)


# proc `&`*(m1, m2: Matrix4d): Matrix4d {.noInit.}=
#   result.setElements(
#     m1.m11 * m2.m11 + m1.m21 * m2.m12 + m1.m31 * m2.m13 + m1.m41 * m2.m14,
#     m1.m11 * m2.m21 + m1.m21 * m2.m22 + m1.m31 * m2.m23 + m1.m41 * m2.m24,
#     m1.m11 * m2.m31 + m1.m21 * m2.m32 + m1.m31 * m2.m33 + m1.m41 * m2.m34,
#     m1.m11 * m2.m41 + m1.m21 * m2.m42 + m1.m31 * m2.m43 + m1.m41 * m2.m44,

#     m1.m12 * m2.m11 + m1.m22 * m2.m12 + m1.m32 * m2.m13 + m1.m42 * m2.m14,
#     m1.m12 * m2.m21 + m1.m22 * m2.m22 + m1.m32 * m2.m23 + m1.m42 * m2.m24,
#     m1.m12 * m2.m31 + m1.m22 * m2.m32 + m1.m32 * m2.m33 + m1.m42 * m2.m34,
#     m1.m12 * m2.m41 + m1.m22 * m2.m42 + m1.m32 * m2.m43 + m1.m42 * m2.m44,

#     m1.m13 * m2.m11 + m1.m23 * m2.m12 + m1.m33 * m2.m13 + m1.m43 * m2.m14,
#     m1.m13 * m2.m21 + m1.m23 * m2.m22 + m1.m33 * m2.m23 + m1.m43 * m2.m24,
#     m1.m13 * m2.m31 + m1.m23 * m2.m32 + m1.m33 * m2.m33 + m1.m43 * m2.m34,
#     m1.m13 * m2.m41 + m1.m23 * m2.m42 + m1.m33 * m2.m43 + m1.m43 * m2.m44,

#     m1.m14 * m2.m11 + m1.m24 * m2.m12 + m1.m34 * m2.m13 + m1.m44 * m2.m14,
#     m1.m14 * m2.m21 + m1.m24 * m2.m22 + m1.m34 * m2.m23 + m1.m44 * m2.m24,
#     m1.m14 * m2.m31 + m1.m24 * m2.m32 + m1.m34 * m2.m33 + m1.m44 * m2.m34,
#     m1.m14 * m2.m41 + m1.m24 * m2.m42 + m1.m34 * m2.m43 + m1.m44 * m2.m44,
#   )



# proc translate*(tx, ty, tz: float): Matrix4d =
#   result = newMatrix4d(
#     1.0f, 0.0f, 0.0f, tx,
#     0.0f, 1.0f, 0.0f, ty,
#     0.0f, 0.0f, 0.0f, tz,
#     0.0f, 0.0f, 0.0f, 1,
#   )

# proc scale*(sx, sy, sz: float): Matrix4d =
#   result = newMatrix4d(
#     sx,   0.0f, 0.0f, 0.0f,
#     0.0f, sy,   0.0f, 0.0f,
#     0.0f, 0.0f, sz,   0.0f,
#     0.0f, 0.0f, 0.0f, 1.07,
#   )

# proc rotateX*(angle: float): Matrix4d =
#   let
#     c = cos(angle)
#     s = sin(angle)
#   result.setElements(
#     1, 0,  0, 0,
#     0, c,  s, 0,
#     0, -s, c, 0,
#     0, 0,  0, 1,
#   )

# proc rotateY*(angle: float): Matrix4d =
#   let
#     c = cos(angle)
#     s = sin(angle)
#   result.setElements(
#     c, 0, -s, 0,
#     0, 1,  0, 0,
#     s, 0,  c, 0,
#     0, 0,  0, 1,
#   )

# proc rotateZ*(angle: float): Matrix4d =
#   let
#     c = cos(angle)
#     s = sin(angle)
#   result.setElements(
#      c, s,  0, 0,
#     -s, c,  0, 0,
#      0, 0,  1, 0,
#      0, 0,  0, 1,
#   )

# proc rotate*(theta: float, a: Vector3d): Matrix4d =
#   var
#     alpha = 0.0f
#     beta = 0.0f
#     theta = 0.0f
#   if a.y == 0.0f and a.z == 0.0f:
#     if a.x == 0.0f:
#       alpha = 0.0f
#       beta = 0.0f
#       theta = 0.0f
#     elif a.x > 0.0f:
#       beta = PI / 2
#     else:
#       beta = -PI / 2

#   alpha = arctan2(a.x, a.y)
#   beta = arctan2(a.y, a.z)
#   result = idMatrix4 & rotateZ(-alpha) & rotateX(-beta) & rotateZ(theta) & rotateX(beta) & rotateZ(alpha)



# proc makeFrustum*(minX, maxX, minY, maxY, minZ, maxZ: float): Matrix4d =
#   discard

# proc makePerspective*(fieldOfView, aspec, minZ, maxZ: float): Matrix4d =
#   discard

# proc makeViewport*(x, y, width, height: float): Matrix4d =
#   result = idMatrix4 &
#            translate(x, y, 0.0f) &
#            scale(width / 2, height / 2, 1.0f) &
#            translate(1.0f, 1.0f, 1.0f)


import basic2d
import basic3d


# proc `*`*(m1, m2: Matrix3d): Matrix3d {.noInit.}=
#   result = matrix3d(
#     m1.ax * m2.ax + m1.bx * m2.ay + m1.cx * m2.az,
#     m1.ax * m2.bx + m1.bx * m2.by + m1.cx * m2.bz,
#     m1.ax * m2.cx + m1.bx * m2.cy + m1.cx * m2.cz,
#     0.0,

#     m1.ay * m2.ax + m1.by * m2.ay + m1.cy * m2.az,
#     m1.ay * m2.bx + m1.by * m2.by + m1.cy * m2.bz,
#     m1.ay * m2.cx + m1.by * m2.cy + m1.cy * m2.cz,
#     0.0,

#     m1.az * m2.ax + m1.bz * m2.ay + m1.cz * m2.az,
#     m1.az * m2.bx + m1.bz * m2.by + m1.cz * m2.bz,
#     m1.az * m2.cx + m1.bz * m2.cy + m1.cz * m2.cz,
#     0.0,
#     0.0, 0.0, 0.0, 1.0
#   )


proc `*`*(m: Matrix3d, v: Vector3d, w = 1.0f): Vector3d =
  result.x = m.ax * v.x + m.bx * v.y + m.cx * w
  result.y = m.ay * v.x + m.by * v.y + m.cy * w


proc `*`*(v: Vector3d, m: Matrix3d, w = 1.0f): Vector3d =
  result = m * v

proc ortho*(minX, maxX, minY, maxY, minZ, maxZ: float): Matrix3d =
  result = stretch(2.0f / (maxX - minX),
                 2.0f / (maxY - minY),
                 2.0f / (maxZ - minZ)) &
           move((maxX - minX) / 2.0f,
                     -minY, -minZ) &
           move(-minX, -minY, -minZ)

proc lookAt*(eye, targe, up: Vector3d): Matrix3d =
  var zaxis = eye - targe
  zaxis.normalize()
  var xaxis = cross(up, zaxis)
  xaxis.normalize()
  var yaxis = cross(zaxis, xaxis)

  let orientation = matrix3d(
    xaxis.y, yaxis.x, zaxis.x, 0,
    xaxis.y, yaxis.y, zaxis.y, 0,
    xaxis.z, yaxis.z, zaxis.z, 0,
        0,      0,       0,    1
  )

  let translation = matrix3d(
    1,      0,      0,   0,
    0,      1,      0,   0,
    0,      0,      1,   0,
  -eye.x, -eye.y, -eye.z, 1)

  result = orientation & translation
