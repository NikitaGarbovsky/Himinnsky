package renderer

import lm "core:math/linalg/glsl"
import "core:slice"
import gl "vendor:OpenGL"
import "core:strings"
import stb_image "vendor:stb/image"
import "core:fmt"

@private
cubemapPositions := [8]lm.vec3{
	{-1.0,-1.0, -1.0}, // 0
	{ 1.0, -1.0, -1.0}, // 1
	{ 1.0, 1.0, -1.0},
	{-1.0, 1.0, -1.0},
	{-1.0, -1.0, 1.0},
	{ 1.0, -1.0, 1.0},
	{ 1.0, 1.0, 1.0},
	{-1.0, 1.0, 1.0},
}

@private
cubemapIndices := []u32{
	// Front face 
	0,1,2, 2,3,0,
	// Back face
	4,6,5, 6,4,7,
	// Left face
	4,0,3, 3,7,4,
	// Right face
	1,5,6, 6,2,1,
	// Bottom face
	4,5,1, 1,0,4,
	// Top face
	3,2,6, 6,7,3,
}

// The render object that is the skybox
skyboxRenderObject : renderObject

TextureID_Skybox : u32 

skyboxProgram : u32

initSkybox :: proc()
{
	// Create a array which will hold the converted cubemap position data.
	vertices := make([]f32, 8*3, context.temp_allocator)
		
	index := 0
	for &pos in cubemapPositions
	{
		vertices[index] = pos.x
		vertices[index + 1] = pos.y
		vertices[index + 2] = pos.z
		index += 3
	}

	skyboxRenderObject.objVertices = slice.clone(vertices)
	skyboxRenderObject.objIndices = slice.clone(cubemapIndices)
	skyboxRenderObject.objPosition = lm.vec3{0,0,0}
	skyboxRenderObject.translationMat = lm.mat4Translate(lm.vec3{0,0,0})
	skyboxRenderObject.scaleMat = lm.mat4Scale(lm.vec3{1,1,1})
	skyboxRenderObject.rotationMat    = lm.mat4(1.0)
	skyboxRenderObject.modelMat = lm.mat4(1.0)

	gl.GenVertexArrays(1, &skyboxRenderObject.vao)
	gl.BindVertexArray(skyboxRenderObject.vao)

	gl.GenBuffers(1, &skyboxRenderObject.vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, skyboxRenderObject.vbo)
	gl.BufferData(gl.ARRAY_BUFFER, int(len(vertices)) * size_of(f32), raw_data(vertices), gl.STATIC_DRAW)
	gl.GenBuffers(1, &skyboxRenderObject.ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, skyboxRenderObject.ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, int(len(skyboxRenderObject.objIndices)) * size_of(u32), raw_data(skyboxRenderObject.objIndices), gl.STATIC_DRAW)

	// Position attribute (location 0)
	gl.VertexAttribPointer( 0,                      // Location
							3, 						// size (vec3) 
							gl.FLOAT, 				// type
							gl.FALSE, 				// normalized
							size_of(lm.vec3), 	// stride:tightly packed (no gaps)
							uintptr(0))				// offset
	gl.EnableVertexAttribArray(0)

	filepath := "Resources/Textures/Skybox/"

	front := strings.concatenate({filepath, "Front.png"})
	back := strings.concatenate({filepath, "Back.png"})
	up := strings.concatenate({filepath, "Top.png"})
	down := strings.concatenate({filepath, "Bottom.png"})
	right := strings.concatenate({filepath, "Right.png"})
	left := strings.concatenate({filepath, "Left.png"})

	defer delete(front)
	defer delete(back)
	defer delete(up)
	defer delete(down)
	defer delete(right)
	defer delete(left)

	textureStrings : [6]string = {
		right,
		left,
		up,
		down,
		front,
		back,
	}

	createTextureCubeMap(textureStrings)
}
 
createTextureCubeMap :: proc(_filepath : [6]string) 
{
	textureId : u32
	gl.Enable(gl.TEXTURE_CUBE_MAP_SEAMLESS)
	gl.GenTextures(1, &textureId)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, textureId) // Bind 
	
	ImageWidth, ImageHeight, ImageComponents : i32

	for i: u32=0; i < 6; i+=1
	{
		data := stb_image.load(strings.clone_to_cstring(_filepath[i]), &ImageWidth, &ImageHeight, &ImageComponents,0 )
		if data == nil {
	    	fmt.eprintf("Failed to load %s: %s\n", _filepath[i], stb_image.failure_reason())
		}

		LoadedComponents : u32= (ImageComponents == 4) ? gl.RGBA : gl.RGB

		gl.TexImage2D(u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X) + i,0, i32(LoadedComponents), 
			ImageWidth, ImageHeight, 0,LoadedComponents, gl.UNSIGNED_BYTE, data)

		stb_image.image_free(data)
	}

	gl.TextureParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TextureParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TextureParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE)
	gl.TextureParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TextureParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0) // Unbind

	TextureID_Skybox = textureId
}

renderSkybox :: proc()
{
	gl.UseProgram(skyboxProgram)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, TextureID_Skybox)
	gl.Uniform1i(gl.GetUniformLocation(skyboxProgram, "Texture_Skybox"), 0)

	// Setup the camera matrices
	CamMatView := ViewMat
	rotation := lm.mat3(ViewMat)
	view_rot_only := lm.mat4(rotation)
	vp := ProjectionMat * view_rot_only 
	gl.UniformMatrix4fv(gl.GetUniformLocation(skyboxProgram, "VP"), 1, gl.FALSE, ([^]f32)(&vp[0][0]))

	gl.BindVertexArray(skyboxRenderObject.vao)
	gl.DepthFunc(gl.LEQUAL)
	gl.DepthMask(gl.FALSE)
	gl.DrawElements(gl.TRIANGLES, 36, gl.UNSIGNED_INT, rawptr(uintptr(0)))
	gl.DepthFunc(gl.LESS)
	gl.DepthMask(gl.TRUE)

	gl.BindVertexArray(0)
	gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)
	gl.UseProgram(0)
}
check_gl_error :: proc(loc: string) {
    err := gl.GetError()
    if err != gl.NO_ERROR {
        fmt.eprintf("GL Error at %s: %v\n", loc, err)
    }
}