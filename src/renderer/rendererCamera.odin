package renderer

import lm "core:math/linalg/glsl"
import "vendor:glfw"
import "core:math"

cameraType :: enum{Free, Ortho} // The Enum Type
CurrentCameraType := cameraType.Free // The current camera type set.

CameraPos := lm.vec3{0.0, 0.0, 3.0} // Starts 3 in Z (into the screen)
CameraUpDir := lm.vec3{0.0, 1.0, 0.0} // Up on Y axis.

// One or the other will be used.
CameraLookDir := lm.vec3{0.0, 0.0, -1.0}
CameraTargetPos := lm.vec3{0.0, 0.0, 0.0}

ViewMat := lm.mat4LookAt(CameraPos, CameraTargetPos, CameraUpDir)

// The main projection matrix for the camera, swapped in setCameraProjection
ProjectionMat := lm.mat4{}

// Free movement properties
FreeMoveSpeed : f32 = 1000
fastMovementModifier : f32 = 5
rightDirection := lm.vec3{0,0,0}
cameraYaw : f32
cameraPitch : f32
offsetX : f32
offsetY : f32
mousePosX : f32
mousePosY : f32

updateCamera :: proc()
{
	switch CurrentCameraType {
	case .Free:
		{
			updateFreeMovement()
			ViewMat = lm.mat4LookAt(CameraPos,  CameraPos + CameraLookDir, CameraUpDir)
			glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
			if glfw.RawMouseMotionSupported()
			{
				glfw.SetInputMode(window, glfw.RAW_MOUSE_MOTION, 1) // raw is better for first person cam
			}
		}
	case .Ortho:
		{
			glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_NORMAL)
		}
	}
}

setCameraProjection :: proc(_cameraType : cameraType)
{
	CurrentCameraType = _cameraType
	switch _cameraType {
	case .Free:
		{
			ProjectionMat = lm.mat4Perspective(lm.radians_f32(45), f32(windowWidth) / f32(WindowHeight), 0.1, 10000)
		}
	case .Ortho:
		{
			ProjectionMat = lm.mat4Ortho3d(-(f32(windowWidth) * 0.5), 
			(f32(windowWidth) * 0.5), -(f32(WindowHeight) * 0.5), (f32(WindowHeight) * 0.5), 0.1, 10000)
		}
	}
}

updateFreeMovement :: proc()
{
	updateMouseData()

	// Apply sensitivity to mouse movement
	mouseSensitivity := 30.0 * deltaTime
	offsetX *= mouseSensitivity
	offsetY *= mouseSensitivity

	// Apply offset to yaw and pitch
	cameraYaw += offsetX
	cameraPitch += offsetY

	// Prevent gimbal lock 
	cameraPitch = lm.clamp_f32(cameraPitch, -85, 85)

	look := lm.vec3{}
	look.x = math.cos(lm.radians(cameraYaw)) * math.cos(lm.radians(cameraPitch))
	look.y = math.sin(lm.radians(cameraPitch))
	look.z = math.sin(lm.radians(cameraYaw)) * math.cos(lm.radians(cameraPitch))
	CameraLookDir = lm.normalize(look)
	rightDirection = lm.normalize(lm.cross(CameraLookDir, CameraUpDir))

	moveInput := lm.vec3{}
	if(glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) // Move forward
	{
		moveInput += CameraLookDir
	}
	if(glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) // Move backward
	{
		moveInput -= CameraLookDir
	}
	if(glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) // Move Left
	{
		moveInput -= rightDirection
	}
	if(glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) // Move Right
	{
		moveInput += rightDirection
	}
	if(glfw.GetKey(window, glfw.KEY_E) == glfw.PRESS) // Move Up
	{
		moveInput += CameraUpDir
	}
	if(glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS) // Move Down
	{
		moveInput -= CameraUpDir
	}

	// Enable fast movement?
	fastMovement := false
	if(glfw.GetKey(window,glfw.KEY_LEFT_SHIFT) == glfw.PRESS)
	{
		fastMovement = true
	}

	if moveInput != {}
	{
		speed := FreeMoveSpeed * deltaTime
		CameraPos += lm.normalize(moveInput) * (fastMovement ? speed * fastMovementModifier : speed)
	}
}

updateMouseData :: proc()
{
	if CurrentCameraType == .Free
	{
		mouseX, mouseY := glfw.GetCursorPos(window)

		offsetX = cast(f32)mouseX - mousePosX
		offsetY = mousePosY - cast(f32)mouseY 

		mousePosX = cast(f32)mouseX
		mousePosY = cast(f32)mouseY
	}
}