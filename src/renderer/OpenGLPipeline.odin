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
    window := glfw.CreateWindow(windowWidth, WindowHeight, "OpenGL Window", nil, nil)
    glfw.MakeContextCurrent(window)
    OpenGL.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    OpenGL.ClearColor(0,0,0,1) // Sets it to blackz
    OpenGL.Viewport(0,0, windowWidth, WindowHeight) // Sets the viewport
    
    runRenderLoop(window)
}

runRenderLoop :: proc(_window: glfw.WindowHandle)
{
    // Create the render object array
    renderObjs : [5]renderObject
    
    // Allocare the memory for all the vertices in the render object array
    for v, i in renderObjs
    {
        renderObjs[i].objVertices = make([dynamic]f32, 0, 18)
    }
    
    // Defer deallocation of the memory until the end of the scope.
    defer delete(renderObjs[0].objVertices)
    defer delete(renderObjs[1].objVertices)
    defer delete(renderObjs[2].objVertices)
    defer delete(renderObjs[3].objVertices)
    defer delete(renderObjs[4].objVertices)

    // Fill the vertices with the data
    for v, i in renderObjs
    {
        fillVertices(&renderObjs[i])
    }

    RenderObjProgram = ShaderLoader.CreateProgramFromShader("Resources/Shaders/ClipSpace.vert", 
                                                            "Resources/Shaders/Texture.frag")

    // Bind the vao, ebo & vbo's for all the render objs
    for RO, i in renderObjs
    {
        // Generate the VAO for a Rendered Obj
        OpenGL.GenVertexArrays(1, &renderObjs[i].vao)
        OpenGL.BindVertexArray(renderObjs[i].vao)

        // Generate the EBO for a Rendered Obj
        OpenGL.GenBuffers(1, &renderObjs[i].ebo)
        OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, renderObjs[i].ebo)
        OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, len(renderObjs[i].objIndices) * size_of(u32), raw_data(renderObjs[i].objIndices), OpenGL.STATIC_DRAW)

        // Generate the VBO for a Rendered Obj
        OpenGL.GenBuffers(1, &renderObjs[i].vbo)
        OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, renderObjs[i].vbo)
        OpenGL.BufferData(OpenGL.ARRAY_BUFFER, len(renderObjs[i].objVertices) * size_of(f32), raw_data(renderObjs[i].objVertices), OpenGL.STATIC_DRAW)
    
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
        OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, false, i32(5 * size_of(f32)), uintptr(0))
        OpenGL.EnableVertexAttribArray(0)
        OpenGL.VertexAttribPointer(1, 2, OpenGL.FLOAT, false, i32(5 * size_of(f32)), uintptr(3 * size_of(f32)))
        OpenGL.EnableVertexAttribArray(1)

        OpenGL.Enable(OpenGL.DEPTH_TEST)
        OpenGL.DepthFunc(OpenGL.LESS)
        OpenGL.Enable(OpenGL.CULL_FACE)
        OpenGL.CullFace(OpenGL.BACK)
        OpenGL.FrontFace(OpenGL.CCW)

        //OpenGL.PolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.LINE)
    }

    for !glfw.WindowShouldClose(_window)
    {
        update(&renderObjs)
        render(_window, &renderObjs)
    }

    glfw.DestroyWindow(_window)
    glfw.Terminate()
}

render :: proc(_window: glfw.WindowHandle, _renderObjs: ^[5]renderObject)
{
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    OpenGL.UseProgram(RenderObjProgram)

    modelMatLoc := OpenGL.GetUniformLocation(RenderObjProgram, "ModelMat")
    viewMat := OpenGL.GetUniformLocation(RenderObjProgram, "ViewMat")
    OpenGL.UniformMatrix4fv(viewMat, 1, false, raw_data(&ViewMat))

    projectionMat := OpenGL.GetUniformLocation(RenderObjProgram, "ProjectionMat")
    OpenGL.UniformMatrix4fv(projectionMat, 1, false, raw_data(&ProjectionMat))

    for RO, i in _renderObjs
    {
        OpenGL.BindVertexArray(_renderObjs[i].vao)
    
        //  --------------- Send variables to the shaders via Uniform ---------------
        // CurrentTimeLoc := OpenGL.GetUniformLocation(_renderObj.program, "CurrentTime")
        // OpenGL.Uniform1f(CurrentTimeLoc, CurrentTime)

        OpenGL.UniformMatrix4fv(modelMatLoc, 1, false, raw_data(&_renderObjs[i].modelMat))
                
        OpenGL.ActiveTexture(OpenGL.TEXTURE0)
        OpenGL.BindTexture(OpenGL.TEXTURE_2D, textureGlass)
        OpenGL.Uniform1i(OpenGL.GetUniformLocation(RenderObjProgram, "Texture0"), 0)
        //  --------------- Send variables to the shaders via Uniform ---------------

        OpenGL.DrawElements(OpenGL.TRIANGLES, i32(len(_renderObjs[i].objIndices)), OpenGL.UNSIGNED_INT, rawptr(uintptr(0)))
    }
    
    OpenGL.BindVertexArray(0)
    OpenGL.UseProgram(0)

    glfw.SwapBuffers(_window)
}

update :: proc(_renderObjs: ^[5]renderObject)
{
    glfw.PollEvents()

    CurrentTime = f32(glfw.GetTime())

    // TODO move this // Assigns the world positions of each rendered Object
    _renderObjs[0].objPosition = lm.vec3{250, 250, -1000.0}
    _renderObjs[1].objPosition = lm.vec3{-250, 250, -1000.0}
    _renderObjs[2].objPosition = lm.vec3{0, 0, -1000.0}
    _renderObjs[3].objPosition = lm.vec3{250, -250, -1000.0}
    _renderObjs[4].objPosition = lm.vec3{-250, -250, -1000.0}

    // Do all the matrix assignments for each render obj in the array.
    for v, i in _renderObjs
    {
        // Translation matrix assignments.
        _renderObjs[i].translationMat = lm.mat4(0)
        _renderObjs[i].translationMat = lm.mat4Translate(_renderObjs[i].objPosition)

        // Rotation matrix assignments.
        _renderObjs[i].vec3Rotation = {1.0, 1.0, 1.0}
        _renderObjs[i].rotationDegrees = 20 * CurrentTime
        _renderObjs[i].rotationMat = lm.mat4Rotate(_renderObjs[i].vec3Rotation, lm.radians(_renderObjs[i].rotationDegrees))
        
        // Scale matrix assignments.
        vec3Scale : lm.vec3 = { 250.0, 250.0, 250.0 }
        _renderObjs[i].scaleMat = lm.mat4Scale(vec3Scale)

        _renderObjs[i].modelMat = _renderObjs[i].translationMat * _renderObjs[i].rotationMat * _renderObjs[i].scaleMat
    }
}