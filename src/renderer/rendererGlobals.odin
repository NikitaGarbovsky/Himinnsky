package renderer

import lm "core:math/linalg/glsl"

windowWidth, WindowHeight : i32 = 1000, 1000

CameraPos := lm.vec3{0.0, 0.0, 3.0} // Starts 3 in Z (into the screen)
CameraUpDir := lm.vec3{0.0, 1.0, 0.0} // Up on Y axis.

// One or the other will be used.
CameraLookDir := lm.vec3{0.0, 0.0, -1.0}
CameraTargetPos := lm.vec3{0.0, 0.0, 0.0}

ViewMat := lm.mat4LookAt(CameraPos, CameraTargetPos, CameraUpDir)

// Projection Orthographic matrix calculated anchor point of (0,0) at the center (half window dimension)
// ProjectionMat := lm.mat4Ortho3d(-(f32(windowWidth) * 0.5), 
// (f32(windowWidth) * 0.5), -(f32(WindowHeight) * 0.5), (f32(WindowHeight) * 0.5), 0.1, 100)

// Projection perspective matrix
ProjectionMat := lm.mat4Perspective(lm.radians_f32(45), f32(windowWidth) / f32(WindowHeight), 0.1, 100)