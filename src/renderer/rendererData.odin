package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

triangle :: struct 
{
    vbo : u32,
    vao : u32,
    program_fixedtri : u32,
    vertices_tri : [dynamic]f32 
}

fillVertices :: proc(_triangle : ^triangle)
{
    append(&_triangle.vertices_tri, 
    
        // Position         // Color
        0.0, 0.0, 0.0,      1.0, 0.0, 0.0, // Top Right
        -0.5, 0.8, 0.0,     0.0, 1.0, 0.0, // Top Left
        0.5, 0.8, 0.0,      0.0, 0.0, 1.0  // Bottom Center
    )
}