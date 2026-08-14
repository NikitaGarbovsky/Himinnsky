package renderer

import "vendor:glfw"
import lm "core:math/linalg/glsl"

// The main glfw window
window : glfw.WindowHandle

TimeSinceAppStart : f32 = 0.0
lastFrameTime: f32 = 0.0
deltaTime : f32 = 0.0

EditorMode :: enum {
	Edit,
	FreeCam
}

CurrentEditorMode : EditorMode = .FreeCam

transitioningToFreeCam : bool

WindowWidth, WindowHeight : i32 = 1920, 1080

wireframe_enabled : bool 

// A dynamic array holding all currently rendered objects 
currentlyRenderedObjects : #soa[dynamic]renderObject

renderObject :: struct {
    vbo, vao, ebo : u32,
    objVertices : []f32,
    objIndices : []u32,
    textures: []u32, 

    localMat : lm.mat4, // from glTF, configured from model loading.

    objPosition : lm.vec3, 
    objRotation : lm.vec3,
    objScale : lm.vec3,

    modelMat : lm.mat4, // computed each fram
}
