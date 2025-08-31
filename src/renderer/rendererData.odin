package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

vbo : u32
vao : u32
program_fixedtri : u32 

vertices_tri : [9]f32 =
{
    0.0, 0.0, 0.0,
   -0.5, 0.8, 0.0,
    0.5, 0.8, 0.0,
}