package renderer

import "vendor:glfw" 
import gl "vendor:OpenGL"
import "core:fmt"
import lm "core:math/linalg/glsl"
import "core:slice"
import "core:math"
import "core:strings"
import "core:os"
import "base:runtime"

// Project dependencies (imported librarys)
import imgui               "Dependencies:odin-imgui"
import imgui_impl_glfw     "Dependencies:odin-imgui/imgui_impl_glfw"
import imgui_impl_opengl3  "Dependencies:odin-imgui/imgui_impl_opengl3"

// Codebase package imports
import "ShaderLoader"
import "modelLoader"

initRenderer :: proc()
{
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    // Create window and assign to global
    window = glfw.CreateWindow(WindowWidth, WindowHeight, "Himinnsky Renderer", nil, nil)
    glfw.MakeContextCurrent(window)
    gl.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    gl.ClearColor(0.2,0.3,0.3,1) // Sets it to blackz
    gl.Viewport(0,0, WindowWidth, WindowHeight) // Sets the viewport
    
    glfw.SetKeyCallback(window, keyInput)
    setCameraProjection(cameraType.Free)

    // ------------ IMGUI INIT ------------
    imgui.CreateContext()
    io := imgui.GetIO()

    imgui_impl_glfw.InitForOpenGL(window, true)
    imgui_impl_opengl3.Init("#version 460") 

    imgui.StyleColorsDark()
    // ------------------------------------

    runRenderLoop()
}

// GLDebugCallback :: proc "cdecl" (
//     source:   u32,
//     type:     u32,
//     id:       u32,
//     severity: u32,
//     length:   i32,
//     message:  cstring,
//     user_ptr: rawptr,
// ) {
//     context = runtime.default_context()
//     // Print the debug message
//      fmt.printf("[GL DEBUG] severity=%v type=%v: %s\n", severity, type, message)
// }

runRenderLoop :: proc()
{
    gl.Enable(gl.DEPTH_TEST)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    gl.Enable(gl.DEPTH_TEST)
    gl.DepthFunc(gl.LEQUAL)
    gl.Disable(gl.CULL_FACE)

    // gl.Enable(gl.DEBUG_OUTPUT);
    // gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);

    // gl.DebugMessageControl(
    //     gl.DONT_CARE,
    //     gl.DONT_CARE,
    //     gl.DONT_CARE,
    //     0, nil,
    //     gl.TRUE,
    // )
    //gl.DebugMessageCallback(GLDebugCallback, nil);

    // This is here just so we can go straight into free cam mode upon starting.
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED) 

    RenderObjProgram = ShaderLoader.CreateProgramFromShader(
        "Resources/Shaders/ClipSpace.vert",
        "Resources/Shaders/Texture.frag",
    )

    InfiniteGrid = ShaderLoader.CreateProgramFromShader(
        "Resources/Shaders/InfiniteGrid.vert",
        "Resources/Shaders/InfiniteGrid.frag",
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
    
    viewMatLoc := gl.GetUniformLocation(RenderObjProgram, "ViewMat")
    gl.UniformMatrix4fv(viewMatLoc, 1, false, raw_data(&ViewMat))

    projectionMat := gl.GetUniformLocation(RenderObjProgram, "ProjectionMat")
    gl.UniformMatrix4fv(projectionMat, 1, false, raw_data(&ProjectionMat))

    // Renderes all render objects that are currently stored.
    for &renderedObject, i in currentlyRenderedObjects
    {
        // Set the model matrix uniform location and pass in this render ojects model matrix
        modelMatLoc := gl.GetUniformLocation(RenderObjProgram, "ModelMat")
        gl.UniformMatrix4fv(modelMatLoc, 1, false, &renderedObject.modelMat[0,0])

        // Pass in camera position for specular lighting calculations. 
        cameraPosLoc := gl.GetUniformLocation(RenderObjProgram, "CameraPos")
        gl.Uniform3fv(cameraPosLoc,1, &CameraPos[0])

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

    view_proj := ProjectionMat * ViewMat 
    view_proj_loc := gl.GetUniformLocation(InfiniteGrid, "view_proj")
    grid_size_loc := gl.GetUniformLocation(InfiniteGrid, "grid_size")

    vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.BindVertexArray(vao)  
    gl.BindVertexArray(0)

    gl.UseProgram(InfiniteGrid)
    
    // Upload uniforms
    gl.UniformMatrix4fv(view_proj_loc, 1, false, &view_proj[0][0])
    gl.Uniform1f(grid_size_loc, 10000.0) // Size of grid.

    gl.BindVertexArray(vao)
    gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
    gl.BindVertexArray(0)
    
    gl.UseProgram(0)

    //  RENDER IMGUI 
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
    if imgui.GetDragDropPayload() != nil {

        io := imgui.GetIO()
        imgui.SetNextWindowPos({0,0})
        imgui.SetNextWindowSize(io.DisplaySize)
        imgui.SetNextWindowBgAlpha(0.0)

        flags: imgui.WindowFlags = {.NoTitleBar, .NoResize, .NoMove, 
            .NoScrollbar, .NoScrollWithMouse, .NoCollapse, .NoBackground, 
            .NoSavedSettings, .NoFocusOnAppearing}

        if imgui.Begin("viewport_drop_target", nil, flags) {
            imgui.InvisibleButton("##drop_area", imgui.GetContentRegionAvail())

            if imgui.BeginDragDropTarget() {
                dropped_payload := imgui.AcceptDragDropPayload("MODEL_PATH")

                if dropped_payload != nil {
                    if dropped_payload.Data == nil {
                        fmt.println("Error: Null payload data")
                    } else {
                        dropped_cstr := (cstring)(dropped_payload.Data)
                        dropped_path := strings.clone_from_cstring(dropped_cstr)
                        fmt.println("Drop detected - Path:", dropped_path)
                        
                        spawn_model(dropped_path)
                    }
                    
                }
                imgui.EndDragDropTarget()
            }
        }
        imgui.End()
    }
    

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

    if imgui.Begin("Asset Browser") {
    path := "Resources/Models"
    dir, open_err := os.open(path, os.O_RDONLY)
    entries, err := os.read_dir(dir, 0)
    defer os.file_info_slice_delete(entries)

        for &entry in entries {
            if entry.is_dir { continue }  // skip folders for now

            name := entry.name
            full_path := fmt.tprintf("%s/%s", path, name)

            // Make the whole line clickable + draggable
            imgui.Selectable(strings.clone_to_cstring(name), false, {.AllowOverlap})

            // This makes the file draggable
            if imgui.BeginDragDropSource({}) {
                fmt.println("Drag started for:", full_path)
                // Payload = full path as cstring
                payload := strings.clone_to_cstring(full_path, context.allocator)
                imgui.SetDragDropPayload("MODEL_PATH", rawptr(payload), uint(len(full_path) + 1))
                imgui.Text("%s", name)
                imgui.EndDragDropSource()
                delete(payload)
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

spawn_model :: proc(_path: string) {
    start := glfw.GetTime()

    model, ok := modelLoader.load_gltf(_path)

    end := glfw.GetTime()
    load_time_ms := (end - start) * 1000.0

    if !ok {
        fmt.printf("glTF load FAILED: %s (%.2f ms)\n", _path, load_time_ms)
        return
    }

    fmt.printf("glTF load SUCCESS: %s (%.2f ms)\n", _path, load_time_ms)

    spawn_pos := CameraPos + CameraLookDir * 375.0   // Spawn slightly infront of the camera

    new_obj := renderObject{
        vbo = model.mesh[0].vbo,
        vao = model.mesh[0].vao,
        ebo = model.mesh[0].ebo,
        objVertices = slice.clone(model.mesh[0].vertices[:]),
        objIndices = slice.clone(model.mesh[0].indices[:]),
        textures = slice.clone(model.textures[:]),
        objPosition = spawn_pos,
    }

    append(&currentlyRenderedObjects, new_obj)
    free_all(context.temp_allocator)
}   
