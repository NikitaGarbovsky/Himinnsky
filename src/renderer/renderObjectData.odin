package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

// Imports glsl math types (vec3, mat4 etc)
import lm "core:math/linalg/glsl" // Only have to use lm to call math procedures from core library.

CurrentTime : f32

renderObject :: struct 
{
    vbo : u32,
    vao : u32,
    ebo : u32,
    program : u32,
    vertices_quad : [dynamic]f32,
    indices_quad : [dynamic]u32,
    quadPosition : lm.vec3,
    translationMat : lm.mat4,
    vec3Rotation : lm.vec3,
    rotationDegrees : f32,
    rotationMat : lm.mat4,
    scaleMat : lm.mat4,
    modelMat : lm.mat4,
}

fillVertices :: proc(_quad : ^renderObject)
{
    // Quad
    append(&_quad.vertices_quad, 
        // Index        // Position          // Color        // Texture Coords 
        /* 0 */         -0.5, 0.5, 0.0,      1.0, 0.0, 0.0,  0.0, 1.0,      // Top Left
        /* 1 */         -0.5, -0.5, 0.0,     0.0, 1.0, 0.0,  0.0, 0.0,      // Bottom Left
        /* 2 */         0.5, -0.5, 0.0,      1.0, 0.0, 1.0,  1.0, 0.0,      // Bottom Right
        /* 3 */         0.5, 0.5, 0.0,       0.0, 0.0, 1.0,  1.0, 1.0       // Top Right
    )
    append(&_quad.indices_quad,
        0, 1, 2, // First Triangle (TL -> BL -> BR)
        0, 2, 3  // Second Triangle (TL -> BR -> TR)
    )
}