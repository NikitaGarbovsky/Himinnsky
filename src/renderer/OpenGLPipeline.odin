package renderer

import "vendor:glfw" 
import gl "vendor:OpenGL"
import "ShaderLoader"
import "modelLoader"
import "core:fmt"
import lm "core:math/linalg/glsl"
import "core:mem"
import "core:slice"

initRenderer :: proc()
{
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    // Create window and assign to global
    window = glfw.CreateWindow(windowWidth, WindowHeight, "Himinnsky Renderer", nil, nil)
    glfw.MakeContextCurrent(window)
    gl.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    gl.ClearColor(0,0,0,1) // Sets it to blackz
    gl.Viewport(0,0, windowWidth, WindowHeight) // Sets the viewport
    
    glfw.SetKeyCallback(window, keyInput)
    setCameraProjection(cameraType.Free)

    // TEMP: glTF loader test -------------------------------
    test_path := "Resources/Models/Long_Ax_1.gltf"

    model, ok := modelLoader.load_gltf(test_path)
    if !ok {
    fmt.println("glTF load FAILED:", test_path)
    } else {
        fmt.println("glTF load SUCCESS:", test_path)
    }

    axe := renderObject{
        vbo = model.mesh[0].vbo, 
        vao = model.mesh[0].vao, 
        ebo = model.mesh[0].ebo,
        objVertices = slice.clone(model.mesh[0].vertices[:]), // Deep copy
        objIndices = slice.clone(model.mesh[0].indices[:]), // Deep copy
        textures = slice.clone(model.textures[:]), // Deep copy
    }

    append(&currentlyRenderedObjects, axe)

    free_all(context.temp_allocator)
    runRenderLoop()
}

runRenderLoop :: proc()
{
    gl.Enable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LESS)

    if len(currentlyRenderedObjects) <= 0 {
        fmt.eprintln("No models loaded!")
        return
    }

    RenderObjProgram = ShaderLoader.CreateProgramFromShader(
        "Resources/Shaders/ClipSpace.vert",
        "Resources/Shaders/Texture.frag",
    )

    for !glfw.WindowShouldClose(window)
    {
        update()
        render()
    }

    glfw.DestroyWindow(window)
    glfw.Terminate()
}

render :: proc()
{
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.UseProgram(RenderObjProgram)

    
    viewMat := gl.GetUniformLocation(RenderObjProgram, "ViewMat")
    gl.UniformMatrix4fv(viewMat, 1, false, raw_data(&ViewMat))

    projectionMat := gl.GetUniformLocation(RenderObjProgram, "ProjectionMat")
    gl.UniformMatrix4fv(projectionMat, 1, false, raw_data(&ProjectionMat))

    // Simple rotating model matrix 
    angle := f32(glfw.GetTime()) * 30.0
    modelMat := lm.mat4Rotate({0,1,0}, lm.radians(angle)) *
                lm.mat4Scale({10, 10, 10}) 

    modelMatLoc := gl.GetUniformLocation(RenderObjProgram, "ModelMat")
    gl.UniformMatrix4fv(modelMatLoc, 1, false, &modelMat[0][0])

    for &renderedObject, i in currentlyRenderedObjects
    {
        gl.BindVertexArray(renderedObject.vao)

        // Bind texture (use first one, #TODO match by material index later)
        tex_id := len(renderedObject.textures) > i ? renderedObject.textures[i] : renderedObject.textures[0]
        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, tex_id)
        gl.Uniform1i(gl.GetUniformLocation(RenderObjProgram, "Texture0"), 0)

        gl.DrawElements(gl.TRIANGLES, i32(len(renderedObject.objIndices)), gl.UNSIGNED_INT, nil)
    }
    
    gl.BindVertexArray(0)
    gl.UseProgram(0)

    glfw.SwapBuffers(window)
}

update :: proc()
{
    // Update time values that are used throughout the application
    TimeSinceAppStart = f32(glfw.GetTime())
    deltaTime = TimeSinceAppStart - lastFrameTime
    lastFrameTime = TimeSinceAppStart

    glfw.PollEvents()

    updateCamera()
}