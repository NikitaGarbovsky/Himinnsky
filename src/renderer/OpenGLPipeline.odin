package renderer

import "vendor:glfw" 
import gl "vendor:OpenGL"
import "ShaderLoader"
import "modelLoader"
import "core:fmt"
import lm "core:math/linalg/glsl"
import "core:mem"
import "core:slice"
import "core:math"
import "core:strings"
import imgui               "Dependencies:odin-imgui"
import imgui_impl_glfw     "Dependencies:odin-imgui/imgui_impl_glfw"
import imgui_impl_opengl3  "Dependencies:odin-imgui/imgui_impl_opengl3"

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

    // ------------ IMGUI INIT ------------
    imgui.CreateContext()
    io := imgui.GetIO()

    imgui_impl_glfw.InitForOpenGL(window, true)
    imgui_impl_opengl3.Init("#version 460") 

    imgui.StyleColorsDark()
    // ------------------------------------

    runRenderLoop()
}

runRenderLoop :: proc()
{
    gl.Enable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LESS)

    // This is here just so we can go straight into free cam mode upon starting.
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED) 

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

update :: proc()
{
    // Update time values that are used throughout the application
    TimeSinceAppStart = f32(glfw.GetTime())
    deltaTime = TimeSinceAppStart - lastFrameTime
    lastFrameTime = TimeSinceAppStart

    // Update each render objects model matrix
    for &renderedObject, i in currentlyRenderedObjects
    {
        renderedObject.modelMat = lm.mat4Translate(renderedObject.objPosition) * lm.mat4Scale({1, 1, 1})
    }

    glfw.PollEvents()

    updateCamera()
}

render :: proc()
{
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    gl.UseProgram(RenderObjProgram)
    
    viewMat := gl.GetUniformLocation(RenderObjProgram, "ViewMat")
    gl.UniformMatrix4fv(viewMat, 1, false, raw_data(&ViewMat))

    projectionMat := gl.GetUniformLocation(RenderObjProgram, "ProjectionMat")
    gl.UniformMatrix4fv(projectionMat, 1, false, raw_data(&ProjectionMat))

    // Renderes all render objects that are currently stored.
    for &renderedObject, i in currentlyRenderedObjects
    {
        // Set the model matrix uniform location and pass in this render ojects model matrix
        modelMatLoc := gl.GetUniformLocation(RenderObjProgram, "ModelMat")
        gl.UniformMatrix4fv(modelMatLoc, 1, false, &renderedObject.modelMat[0,0])

        gl.BindVertexArray(renderedObject.vao)

        // Bind texture (use first one, #TODO match by material index later)
        tex_id := len(renderedObject.textures) > i ? renderedObject.textures[i] : renderedObject.textures[0]
        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, tex_id)
        //gl.Uniform1i(gl.GetUniformLocation(RenderObjProgram, "Texture1"), 0)

        gl.DrawElements(gl.TRIANGLES, i32(len(renderedObject.objIndices)), gl.UNSIGNED_INT, nil)
    }
    
    gl.BindVertexArray(0)
    gl.UseProgram(0)

    //  RENDER IMGUI 
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()

    // Test window — delete later
    if imgui.Begin("Himinnsky Debug") {
        imgui.Text("FPS: %.1f", 1.0 / deltaTime)
        imgui.Separator()
        if imgui.Button("Toggle Wireframe") {
            wireframe_enabled = !wireframe_enabled
            gl.PolygonMode(gl.FRONT_AND_BACK, wireframe_enabled ? gl.LINE : gl.FILL)
        }
        if imgui.CollapsingHeader("Camera###Cam") {
            imgui.DragFloat("X###camX", &CameraPos[0])
            imgui.DragFloat("Y###camY", &CameraPos[1])
            imgui.DragFloat("Z###camZ", &CameraPos[2])

            yaw_rad := cameraYaw * (math.PI / 180.0)
            imgui.DragFloat("Yaw", &yaw_rad, -180, 180) // #TODO This is not working correctly
            imgui.SliderAngle("Pitch", &cameraPitch, -89, 89) // #TODO This is not working correctly
        }
        for &RO, i in currentlyRenderedObjects
        {   
            header := fmt.tprintf("RenderObject###%d", i) // Generate a unique id based off index
            if imgui.CollapsingHeader(strings.clone_to_cstring(header))
            { 
                // Generate widget GUI's with Unique ID's (using index for ID)
                x_label := fmt.tprintf("X###RenderObjectPositionX%d", i)
                y_label := fmt.tprintf("Y###RenderObjectPositionY%d", i)
                z_label := fmt.tprintf("Z###RenderObjectPositionZ%d", i)

                imgui.DragFloat(strings.clone_to_cstring(x_label), &RO.objPosition[0])  
                imgui.DragFloat(strings.clone_to_cstring(y_label), &RO.objPosition[1])
                imgui.DragFloat(strings.clone_to_cstring(z_label), &RO.objPosition[2])
            }
        }
    }
    imgui.End()

    // Show the official demo window 
    // show_demo := true
    // imgui.ShowDemoWindow(&show_demo)

    imgui.Render()
    imgui_impl_opengl3.RenderDrawData(imgui.GetDrawData())
    // 
    
    glfw.SwapBuffers(window)
}
