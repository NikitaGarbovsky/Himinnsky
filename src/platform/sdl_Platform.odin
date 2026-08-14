package platform

import sdl "vendor:sdl3"
import "core:fmt"

Platform :: struct {
	window : ^sdl.Window,
	gpu : ^sdl.GPUDevice,
	running : bool,
	windowWidth, windowHeight : i32,
}

init :: proc(_platformO : ^Platform) {
	ok := sdl.Init({.VIDEO, .EVENTS}); assert(ok)

	flags := sdl.WindowFlags {
		.RESIZABLE,
	}

	_platformO.window = sdl.CreateWindow("2DOdinGameEngine", 1920, 1080, flags); assert(_platformO.window != nil)

	_platformO.gpu = sdl.CreateGPUDevice({.SPIRV}, true, nil); assert(_platformO.gpu != nil)
	ok = sdl.ClaimWindowForGPUDevice(_platformO.gpu, _platformO.window); assert(ok)

	_platformO.running = true
	_platformO.windowWidth = 1920
	_platformO.windowHeight = 1080 

	fmt.printfln("--- Platform & Window Initialized Successfully.")
}

shutdown :: proc(_platformO : ^Platform) {
	if _platformO.window != nil {
		sdl.DestroyWindow(_platformO.window)
		_platformO.window = nil
	}
	sdl.Quit()
}