package renderer

import lm "core:math/linalg/glsl"
import "vendor:glfw"

// The main glfw window
window : glfw.WindowHandle

EditorMode :: enum {
	Edit,
	FreeCam
}

CurrentEditorMode : EditorMode = .FreeCam

transitioningToFreeCam : bool

windowWidth, WindowHeight : i32 = 1920, 1080

wireframe_enabled : bool 
