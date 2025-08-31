package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

CurrentTime : f32

triangle :: struct 
{
    vbo : u32,
    vao : u32,
    program_fixedtri : u32,
    vertices_tri : [dynamic]f32,
}

fillVertices :: proc(_triangle : ^triangle)
{
    // Triangle 1 (bottom-left)
    append(&_triangle.vertices_tri, 
    
        // Position         // Color
        -0.5, 0.8, 0.0,      1.0, 0.0, 0.0, // Top Left
        -0.5, -0.8, 0.0,     0.0, 1.0, 0.0, // Bottom Left
        0.5, -0.8, 0.0,      0.0, 0.0, 1.0  // Bottom Right
    )
    // Triangle 2 (top-right)
    append(&_triangle.vertices_tri, 
    
        // Position         // Color
        0.5, -0.8, 0.0,      0.0, 0.0, 1.0, // Bottom Right
        0.5, 0.8, 0.0,       0.0, 1.0, 0.0, // Top Right
        -0.5, 0.8, 0.0,      1.0, 0.0, 0.0  // Top Left
    )
}