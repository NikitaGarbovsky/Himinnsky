package renderer

import "vendor:glfw" 
import "vendor:OpenGL"

// Imports glsl math types (vec3, mat4 etc)
import lm "core:math/linalg/glsl" // Only have to use lm to call math procedures from core library.

CurrentTime : f32
RenderObjProgram : u32

renderObject :: struct 
{
    vbo : u32,
    vao : u32,
    ebo : u32,
    objVertices : [dynamic]f32,
    objIndices : [dynamic]u32,
    objPosition : lm.vec3,
    translationMat : lm.mat4,
    vec3Rotation : lm.vec3,
    rotationDegrees : f32,
    rotationMat : lm.mat4,
    scaleMat : lm.mat4,
    modelMat : lm.mat4,
}

fillVertices :: proc(_ro : ^renderObject)
{
    // Quad
    append(&_ro.objVertices, 
        // Index        // Position          // Texture Coords  // Position Index 
                        // Front Quad
        /* 00 */         -0.5, 0.5, 0.5,      0.0, 1.0,         /* 00 */ 
        /* 01 */         -0.5, -0.5, 0.5,     0.0, 0.0,         /* 01 */ 
        /* 02 */         0.5, -0.5, 0.5,      1.0, 0.0,         /* 02 */ 
        /* 03 */         0.5, 0.5, 0.5,       1.0, 1.0,         /* 03 */ 
                        // Back Quad
        /* 04 */         0.5, 0.5, -0.5,      0.0, 1.0,         /* 04 */ 
        /* 05 */         0.5, -0.5, -0.5,     0.0, 0.0,         /* 05 */ 
        /* 06 */         -0.5, -0.5, -0.5,      1.0, 0.0,         /* 06 */ 
        /* 07 */         -0.5, 0.5, -0.5,       1.0, 1.0,         /* 07 */ 
                        // Right
        /* 08 */         0.5, 0.5, 0.5,      0.0, 1.0,         /* 03 */ 
        /* 09 */         0.5, -0.5, 0.5,     0.0, 0.0,         /* 02 */ 
        /* 10 */         0.5, -0.5, -0.5,      1.0, 0.0,         /* 05 */ 
        /* 11 */         0.5, 0.5, -0.5,       1.0, 1.0,         /* 04 */ 
                        // Left
        /* 12 */         -0.5, 0.5, -0.5,      0.0, 1.0,         /* 07 */ 
        /* 13 */         -0.5, -0.5, -0.5,     0.0, 0.0,         /* 06 */ 
        /* 14 */         -0.5, -0.5, 0.5,      1.0, 0.0,         /* 01 */ 
        /* 15 */         -0.5, 0.5, 0.5,       1.0, 1.0,         /* 00 */ 
                        // Top
        /* 16 */         -0.5, 0.5, -0.5,      0.0, 1.0,         /* 07 */ 
        /* 17 */         -0.5, 0.5, 0.5,     0.0, 0.0,         /* 00 */ 
        /* 18 */         0.5, 0.5, 0.5,      1.0, 0.0,         /* 01 */ 
        /* 19 */         0.5, 0.5, -0.5,       1.0, 1.0,         /* 00 */ 
                        // Bottom
        /* 20 */         -0.5, -0.5, 0.5,      0.0, 1.0,         /* 01 */ 
        /* 21 */         -0.5, -0.5, -0.5,     0.0, 0.0,         /* 06 */ 
        /* 22 */         0.5, -0.5, -0.5,      1.0, 0.0,         /* 05 */ 
        /* 23 */         0.5, -0.5, 0.5,       1.0, 1.0,         /* 02 */ 
    )
    append(&_ro.objIndices,
        0, 1, 2, // First Triangle 1
        0, 2, 3,  // Second Triangle 2
        4, 5, 6, // Back Tri 1
        4, 6, 7, // Back Tri 2
        8, 9, 10, // Right Tri 1
        8, 10, 11, // Right Tri 2
        12, 13, 14, // Left Tri 1
        12, 14, 15, // Left Tri 2
        16, 17, 18, // Top Tri 1
        16, 18, 19, // Top Tri 2
        20, 21, 22, // Bottom Tri 1
        20, 22, 23, // Bottom Tri 2
    )
}