package renderer

import "vendor:glfw" 
import "vendor:OpenGL"
import "modelLoader"

// Imports glsl math types (vec3, mat4 etc)
import lm "core:math/linalg/glsl" // Only have to use lm to call math procedures from core library.

TimeSinceAppStart : f32 = 0.0
lastFrameTime: f32 = 0.0
deltaTime : f32 = 0.0

RenderObjProgram : u32

// A dynamic array holding all currently rendered objects 
currentlyRenderedObjects : [dynamic]renderObject

renderObject :: struct 
{
    vbo : u32,
    vao : u32,
    ebo : u32,
    objVertices : []f32,
    objIndices : []u32,
    textures: []u32, 
    objPosition : lm.vec3,
    translationMat : lm.mat4,
    objRotation : lm.vec3,
    rotationDegrees : f32,
    rotationMat : lm.mat4,
    scaleMat : lm.mat4,
    modelMat : lm.mat4,
}
