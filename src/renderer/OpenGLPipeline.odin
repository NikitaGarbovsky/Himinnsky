package renderer

import "vendor:glfw" 
import "vendor:OpenGL"
import "ShaderLoader"

InitRenderer :: proc()
{
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
    window := glfw.CreateWindow(1920, 1080, "OpenGL Window", nil, nil)
    glfw.MakeContextCurrent(window)
    OpenGL.load_up_to(4,6,glfw.gl_set_proc_address) // This is a replacement for GLEW, odin has it built in.
    OpenGL.ClearColor(0,0,0,1) // Sets it to blackz
    OpenGL.Viewport(0,0, 1920, 1080) // Sets the viewport (#TODO these numbers need to be variables so they're changable in the future.)
    
    runRenderLoop(window)
}

runRenderLoop :: proc(_window: glfw.WindowHandle)
{
    program_fixedtri = ShaderLoader.CreateProgramFromShader("Resources/Shaders/FixedTriangle.vert", 
                                                            "Resources/Shaders/FixedColor.frag")


    // Generate the VAO for a Triangle
    OpenGL.GenVertexArrays(1, &vao)
    OpenGL.BindVertexArray(vao)

    // Generate the VBO for a Triangle
    OpenGL.GenBuffers(1, &vbo)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, vbo)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(vertices_tri), raw_data(&vertices_tri), OpenGL.STATIC_DRAW)

    // Set the Vertex Attribute information (how to interpret the vertex data)
    OpenGL.VertexAttribPointer(0,  3, OpenGL.FLOAT, false, 3 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(0)

    for !glfw.WindowShouldClose(_window)
    {
        update()
        render(_window, program_fixedtri)
    }
    glfw.DestroyWindow(_window)
    glfw.Terminate()
}

render :: proc(_window: glfw.WindowHandle, _program: u32)
{
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

    OpenGL.UseProgram(_program)
    OpenGL.BindVertexArray(vao)
    OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 3)
    OpenGL.BindVertexArray(0)
    OpenGL.UseProgram(0)

    glfw.SwapBuffers(_window)
}

update :: proc()
{
    glfw.PollEvents()
}