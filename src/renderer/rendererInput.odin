package renderer

import "vendor:glfw" 
import "base:runtime"
import "core:fmt"

// Binds input for GLFW, called when initializing the renderer
keyInput :: proc "c" (_window : glfw.WindowHandle, _key : i32, _scanCode : i32, _action : i32, _mods : i32)
{
    context = runtime.default_context() // "c" callback requires specific configuration of type of allocator context.

    if _key == glfw.KEY_ESCAPE && _action == glfw.PRESS
    {
        glfw.SetWindowShouldClose(_window, true)       
    }
    if _key == glfw.KEY_1 && _action == glfw.PRESS
    {
        setCameraProjection(cameraType.Free) 
        fmt.println("Input: Perspective Camera Enabled")
    }
    if _key == glfw.KEY_2 && _action == glfw.PRESS
    {
        setCameraProjection(cameraType.Ortho) 
        fmt.println("Input: Orthographic Camera Enabled")
    }
    if _key == glfw.KEY_TAB && _action == glfw.PRESS // Swap between (FreeCam) & (Edit) Mode
    {
        if CurrentEditorMode == .Edit
        {      // Return to free cam mode
            transitioningToFreeCam = true
            if glfw.RawMouseMotionSupported() {
                glfw.SetInputMode(window, glfw.RAW_MOUSE_MOTION, 1)
            }

            glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
            offsetX += priorOffsetX
            offsetY += priorOffsetY
            CurrentEditorMode = .FreeCam
        }
        else // Swap to Edit Mode
        {
            // Record the offset so we can set it back to this when returning to (free cam) Mode
            // (this stops the camera from snapping to the mouse new position on the first update tick after we return into free cam mode)
            priorOffsetX = offsetX
            priorOffsetY = offsetY

            glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_NORMAL)
            glfw.SetInputMode(window, glfw.RAW_MOUSE_MOTION, 0)

            width, height := glfw.GetFramebufferSize(window)

            glfw.SetCursorPos(window, f64(width /2), f64(height / 2))
            CurrentEditorMode = .Edit
        }

        fmt.println("Input: UI & Mouse =",CurrentEditorMode)
    }
}