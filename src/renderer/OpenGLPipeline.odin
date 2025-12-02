package renderer

import "vendor:glfw" 
import gl "vendor:OpenGL"
import "ShaderLoader"
import "core:fmt"
import lm "core:math/linalg/glsl"

InitRenderer :: proc()
{
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    window := glfw.CreateWindow(windowWidth, WindowHeight, "Himinnsky Renderer", nil, nil)
    glfw.MakeContextCurrent(window)
    gl.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    gl.ClearColor(0,0,0,1) // Sets it to blackz
    gl.Viewport(0,0, windowWidth, WindowHeight) // Sets the viewport
    
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
        gl.GenVertexArrays(1, &renderObjs[i].vao)
        gl.BindVertexArray(renderObjs[i].vao)

        // Generate the EBO for a Rendered Obj
        gl.GenBuffers(1, &renderObjs[i].ebo)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, renderObjs[i].ebo)
        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(renderObjs[i].objIndices) * size_of(u32), raw_data(renderObjs[i].objIndices), gl.STATIC_DRAW)

        // Generate the VBO for a Rendered Obj
        gl.GenBuffers(1, &renderObjs[i].vbo)
        gl.BindBuffer(gl.ARRAY_BUFFER, renderObjs[i].vbo)
        gl.BufferData(gl.ARRAY_BUFFER, len(renderObjs[i].objVertices) * size_of(f32), raw_data(renderObjs[i].objVertices), gl.STATIC_DRAW)
    
        // Create and bind a new texture variable
        setImageFlip()
        loadImageTexture() // <-- Loads image data
        gl.GenTextures(1, &textureGlass)
        gl.BindTexture(gl.TEXTURE_2D, textureGlass)

        // Check how many components the loaded image has (RGBA or RGB?)
        loadedComponents : i32 
        if imageComponents == 4 {loadedComponents = gl.RGBA} else {loadedComponents = gl.RGB}

        // Populate the texture with the image data
        gl.TexImage2D(gl.TEXTURE_2D, 0, loadedComponents, imageWidth, imageHeight, 0, 
            u32(loadedComponents), gl.UNSIGNED_BYTE, imageData)

        // Setting the filtering and mipmap parameters for this texture 
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

        // Generate the mipmaps, free the memory and unbind the texture
        gl.GenerateMipmap(gl.TEXTURE_2D)
        freeImageTextureData()
        gl.BindTexture(gl.TEXTURE_2D, 0)

        // Set the Vertex Attribute information (how to interpret the vertex data)
        gl.VertexAttribPointer(0, 3, gl.FLOAT, false, i32(5 * size_of(f32)), uintptr(0))
        gl.EnableVertexAttribArray(0)
        gl.VertexAttribPointer(1, 2, gl.FLOAT, false, i32(5 * size_of(f32)), uintptr(3 * size_of(f32)))
        gl.EnableVertexAttribArray(1)

        gl.Enable(gl.DEPTH_TEST)
        gl.DepthFunc(gl.LESS)
        gl.Enable(gl.CULL_FACE)
        gl.CullFace(gl.BACK)
        gl.FrontFace(gl.CCW)

        //gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
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
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.UseProgram(RenderObjProgram)

    modelMatLoc := gl.GetUniformLocation(RenderObjProgram, "ModelMat")
    viewMat := gl.GetUniformLocation(RenderObjProgram, "ViewMat")
    gl.UniformMatrix4fv(viewMat, 1, false, raw_data(&ViewMat))

    projectionMat := gl.GetUniformLocation(RenderObjProgram, "ProjectionMat")
    gl.UniformMatrix4fv(projectionMat, 1, false, raw_data(&ProjectionMat))

    for RO, i in _renderObjs
    {
        gl.BindVertexArray(_renderObjs[i].vao)
    
        //  --------------- Send variables to the shaders via Uniform ---------------
        // CurrentTimeLoc := gl.GetUniformLocation(_renderObj.program, "CurrentTime")
        // gl.Uniform1f(CurrentTimeLoc, CurrentTime)

        gl.UniformMatrix4fv(modelMatLoc, 1, false, raw_data(&_renderObjs[i].modelMat))
                
        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, textureGlass)
        gl.Uniform1i(gl.GetUniformLocation(RenderObjProgram, "Texture0"), 0)
        //  --------------- Send variables to the shaders via Uniform ---------------

        gl.DrawElements(gl.TRIANGLES, i32(len(_renderObjs[i].objIndices)), gl.UNSIGNED_INT, rawptr(uintptr(0)))
    }
    
    gl.BindVertexArray(0)
    gl.UseProgram(0)

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