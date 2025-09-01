package renderer

import "vendor:glfw" 
import "vendor:OpenGL"
import "ShaderLoader"
import "core:fmt"
import lm "core:math/linalg/glsl"

InitRenderer :: proc()
{
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    window := glfw.CreateWindow(1000, 1000, "OpenGL Window", nil, nil)
    glfw.MakeContextCurrent(window)
    OpenGL.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    OpenGL.ClearColor(0,0,0,1) // Sets it to blackz
    OpenGL.Viewport(0,0, 1000, 1000) // Sets the viewport (#TODO these numbers need to be variables so they're changable in the future.)
    
    runRenderLoop(window)
}

runRenderLoop :: proc(_window: glfw.WindowHandle)
{
    // Create the render struct object
    renderObj : renderObject

    renderObj.vertices_quad = make([dynamic]f32, 0, 18)

    defer delete(renderObj.vertices_quad)

    fillVertices(&renderObj)

    renderObj.program = ShaderLoader.CreateProgramFromShader("Resources/Shaders/Texture.vert", 
                                                            "Resources/Shaders/Texture.frag")

    // Generate the VAO for a Triangle
    OpenGL.GenVertexArrays(1, &renderObj.vao)
    OpenGL.BindVertexArray(renderObj.vao)

     // Generate the EBO for a Quad
    OpenGL.GenBuffers(1, &renderObj.ebo)
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, renderObj.ebo)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, len(renderObj.indices_quad) * size_of(u32), raw_data(renderObj.indices_quad), OpenGL.STATIC_DRAW)

    // Generate the VBO for a Triangle
    OpenGL.GenBuffers(1, &renderObj.vbo)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, renderObj.vbo)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, len(renderObj.vertices_quad) * size_of(f32), raw_data(renderObj.vertices_quad), OpenGL.STATIC_DRAW)
   
    // Create and bind a new texture variable
    setImageFlip()
    loadImageTexture() // <-- Loads image data
    OpenGL.GenTextures(1, &textureGlass)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, textureGlass)

    // Check how many components the loaded image has (RGBA or RGB?)
    loadedComponents : i32 
    if imageComponents == 4 {loadedComponents = OpenGL.RGBA} else {loadedComponents = OpenGL.RGB}

    // Populate the texture with the image data
    OpenGL.TexImage2D(OpenGL.TEXTURE_2D, 0, loadedComponents, imageWidth, imageHeight, 0, 
        u32(loadedComponents), OpenGL.UNSIGNED_BYTE, imageData)

    // Setting the filtering and mipmap parameters for this texture 
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MIN_FILTER, OpenGL.LINEAR_MIPMAP_LINEAR)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MAG_FILTER, OpenGL.LINEAR)

    // Generate the mipmaps, free the memory and unbind the texture
    OpenGL.GenerateMipmap(OpenGL.TEXTURE_2D)
    freeImageTextureData()
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, 0)

    // Set the Vertex Attribute information (how to interpret the vertex data)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, false, i32(8 * size_of(f32)), uintptr(0))
    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(1, 3, OpenGL.FLOAT, false, i32(8 * size_of(f32)), uintptr(3 * size_of(f32)))
    OpenGL.EnableVertexAttribArray(1)
    OpenGL.VertexAttribPointer(2, 2, OpenGL.FLOAT, false, i32(8 * size_of(f32)), uintptr(6 * size_of(f32)))
    OpenGL.EnableVertexAttribArray(2)

    for !glfw.WindowShouldClose(_window)
    {
        update(&renderObj)
        render(_window, &renderObj)
    }
    glfw.DestroyWindow(_window)
    glfw.Terminate()
}

render :: proc(_window: glfw.WindowHandle, _renderObj: ^renderObject)
{
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

    OpenGL.UseProgram(_renderObj.program)
    OpenGL.BindVertexArray(_renderObj.vao)

    //  --------------- Send variables to the shaders via Uniform ---------------
    // CurrentTimeLoc := OpenGL.GetUniformLocation(_renderObj.program, "CurrentTime")
    // OpenGL.Uniform1f(CurrentTimeLoc, CurrentTime)

    modelMatLoc := OpenGL.GetUniformLocation(_renderObj.program, "ModelMat")
    OpenGL.UniformMatrix4fv(modelMatLoc, 1, false, raw_data(&_renderObj.modelMat))

    OpenGL.ActiveTexture(OpenGL.TEXTURE0)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, textureGlass)
    OpenGL.Uniform1i(OpenGL.GetUniformLocation(_renderObj.program, "Texture0"), 0)
    //  --------------- Send variables to the shaders via Uniform ---------------

    OpenGL.DrawElements(OpenGL.TRIANGLES, 6, OpenGL.UNSIGNED_INT, rawptr(uintptr(0)))
    OpenGL.BindVertexArray(0)
    OpenGL.UseProgram(0)

    glfw.SwapBuffers(_window)
}

update :: proc(_renderObj: ^renderObject)
{
    glfw.PollEvents()

    CurrentTime = f32(glfw.GetTime())

    // Translation matrix assignments.
    _renderObj.quadPosition = lm.vec3{-0.5, -0.5, 0.0}
    _renderObj.translationMat = lm.mat4(0)
    _renderObj.translationMat = lm.mat4Translate(_renderObj.quadPosition)

    // Rotation matrix assignments.
    _renderObj.vec3Rotation = {0.0, 0.0, 1.0}
    _renderObj.rotationDegrees = 20 * CurrentTime
    _renderObj.rotationMat = lm.mat4Rotate(_renderObj.vec3Rotation, lm.radians(_renderObj.rotationDegrees))
    
    // Scale matrix assignments.
    vec3Scale : lm.vec3 = {0.5, 0.5, 1.0}
    _renderObj.scaleMat = lm.mat4Scale(vec3Scale)

    _renderObj.modelMat = _renderObj.translationMat * _renderObj.rotationMat * _renderObj.scaleMat
}