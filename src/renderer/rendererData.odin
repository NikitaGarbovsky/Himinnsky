package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

import lm "core:math/linalg" // Only have to use lm to call math procedures from core library.

CurrentTime : f32

triangle :: struct 
{
    vbo : u32,
    vao : u32,
    ebo : u32,
    program_fixedtri : u32,
    vertices_quad : [dynamic]f32,
    indices_quad : [dynamic]u32,
}

fillVertices :: proc(_triangle : ^triangle)
{
    // Triangle 
    append(&_triangle.vertices_quad, 
        // Index        // Position          // Color
        /* 0 */         -0.5, 0.8, 0.0,      1.0, 0.0, 0.0,  // Top Left
        /* 1 */         -0.5, -0.8, 0.0,     0.0, 1.0, 0.0,  // Bottom Left
        /* 2 */         0.5, -0.8, 0.0,      1.0, 0.0, 1.0,  // Bottom Right
        /* 3 */         0.5, 0.8, 0.0,       0.0, 1.0, 0.0,  // Top Right
    )
    append(&_triangle.indices_quad,
        0, 1, 2, // First Triangle (TL -> BL -> BR)
        0, 2, 3  // Second Triangle (TL -> BR -> TR)
    )
}