package renderer

import "vendor:glfw" 
import gl "vendor:OpenGL"
import "base:runtime"

// Binds input for GLFW, called when initializing the renderer
keyInput :: proc "c" (_window : glfw.WindowHandle, _key : i32, _scanCode : i32, _action : i32, _mods : i32)
{
    context = runtime.default_context() // "c" callback requires specific configuration of type of allocator context.

    if(_key == glfw.KEY_ESCAPE && _action == glfw.PRESS)
    {
        glfw.SetWindowShouldClose(_window, true)       
    }
    if(_key == glfw.KEY_1 && _action == glfw.PRESS)
    {
        setCameraProjection(cameraType.Free) 
    }
    if(_key == glfw.KEY_2 && _action == glfw.PRESS)
    {
        setCameraProjection(cameraType.Ortho) 
    }
}