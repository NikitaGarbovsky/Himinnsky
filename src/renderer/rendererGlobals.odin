package renderer

import "vendor:glfw"

// The main glfw window
window : glfw.WindowHandle

TimeSinceAppStart : f32 = 0.0
lastFrameTime: f32 = 0.0
deltaTime : f32 = 0.0

EditorMode :: enum {
	Edit,
	FreeCam
}

CurrentEditorMode : EditorMode = .FreeCam

transitioningToFreeCam : bool

WindowWidth, WindowHeight : i32 = 1920, 1080

wireframe_enabled : bool 
