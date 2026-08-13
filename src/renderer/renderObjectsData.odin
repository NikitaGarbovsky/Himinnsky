package renderer

// Imports glsl math types (vec3, mat4 etc)
import lm "core:math/linalg/glsl" // Only have to use lm to call math procedures from core library.

InfiniteGridProgram : u32 
RenderObjProgram : u32
SkyboxProgram : u32

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
