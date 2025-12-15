package _modelLoader

import cgltf "vendor:cgltf"
import "core:os"
import "base:runtime"
import "core:strings"
import "core:fmt"
import "core:path/filepath"
import gl "vendor:OpenGL"
import "core:image"
import "core:image/png"

Model :: struct { 
	mesh: [dynamic]Mesh,
	textures: [dynamic]u32, // GL ID's, index matches mesh or material
	// TODO, materials : [dynamic]Material, nodes: [dynamic]Node
}

Mesh :: struct {
	vertices: [dynamic]f32, 
	indices: [dynamic]u32,
	vao, vbo, ebo: u32,
}

load_gltf :: proc(_path : string) -> (_model: Model, ok: bool)
{
	context.allocator = runtime.default_allocator() // For [dynamic]

	opts: cgltf.options = {} // default: no extras

	// Load the file, return result and data
	data, res := cgltf.parse_file(opts, strings.clone_to_cstring(_path, context.temp_allocator))

	// Check if loading failed
	if res != .success {fmt.eprintln("Parse fail:", res); return {}, false}

	defer cgltf.free(data)

	res = cgltf.validate(data)
	if res != .success {fmt.eprintln("Validation fail:", res); return {}, false}

	res = cgltf.load_buffers(opts, data, strings.clone_to_cstring(_path, context.temp_allocator))
	if res != .success {fmt.eprintln("Buffers fail:", res); return {}, false}


	_model.mesh = make([dynamic]Mesh, context.temp_allocator)
	_model.textures = make([dynamic]u32, context.temp_allocator)

    fmt.println("Number of meshes: ", len(data.meshes))
	// Extract meshes
    for m in 0..<len(data.meshes) {

        mesh := &data.meshes[m]

        for p in 0..<len(mesh.primitives) {
            prim := &mesh.primitives[p]
            submesh: Mesh

            // ============ Vertices ============

            // Get vertex count from position accessor (mandatory)
            pos_acc := get_attribute(prim, .position, 0)
            if pos_acc == nil { continue }  // Skip invalid

            vert_count := int(pos_acc.count)
            submesh.vertices = make([dynamic]f32, 0, vert_count * 8, context.temp_allocator)  // Reserve for interleaved
            uv_acc := get_attribute(prim, .texcoord, 0)
            norm_acc := get_attribute(prim, .normal, 0)

            // Positions (vec3 f32)
            for i in 0..<vert_count {
                pos: [3]f32
                if !cgltf.accessor_read_float(pos_acc, uint(i), &pos[0], 3) {
                    continue
                }
                uv: [2]f32 = {0,0}
                if uv_acc != nil && uv_acc.count == pos_acc.count {
                    _ = cgltf.accessor_read_float(uv_acc, uint(i), &uv[0], 2)
                }

                norm: [3]f32 = {0,0,0}
                if norm_acc != nil && norm_acc.count == pos_acc.count {
                    _ = cgltf.accessor_read_float(norm_acc, uint(i), &norm[0], 3)
                }

                runtime.append_elems(&submesh.vertices,
                    pos[0], pos[1], pos[2],
                    uv[0], uv[1],
                    norm[0], norm[1], norm[2],
                )
            }

            //
            // INDICES
            //

            if prim.indices != nil {
                count := int(prim.indices.count)
                submesh.indices = make([dynamic]u32, 0, count, context.temp_allocator)

                for i in 0..<count {
                    idx: u32
                    ok := cgltf.accessor_read_uint(prim.indices, uint(i), &idx, 1)
                    if ok {
                        runtime.append_elem(&submesh.indices, idx)
                    }
                }
            } else {
                submesh.indices = make([dynamic]u32, 0, vert_count, context.temp_allocator)
                for i in 0..<vert_count {
                    runtime.append_elem(&submesh.indices, u32(i))
                }
            }

            //
            // TEXTURE
            //

            if prim.material != nil && prim.material.has_pbr_metallic_roughness {
                t := prim.material.pbr_metallic_roughness.base_color_texture

                if t.texture != nil && t.texture.image_ != nil && t.texture.image_.uri != nil {
                    tex_uri := string(t.texture.image_.uri)
                    dir := filepath.dir(_path)
                    full_path := filepath.join({dir, tex_uri})
                    tex_id := load_texture(full_path)
                    runtime.append_elem(&_model.textures, tex_id)
                }
            }

            upload_mesh(&submesh)
            runtime.append_elem(&_model.mesh, submesh)
            fmt.println("mesh", m, "prim", p, "verts:", len(submesh.vertices)/8, "indices:", len(submesh.indices))

        }
    }
    return _model, true
}

get_attribute :: proc(prim: ^cgltf.primitive, kind: cgltf.attribute_type, attr_index: int) -> ^cgltf.accessor {
    for ai in 0..<len(prim.attributes) {
        attr := prim.attributes[ai];
        if attr.type == kind && attr.index == i32(attr_index) {
            return attr.data;
        }
    }
    return nil;
}

load_texture :: proc(path: string) -> u32 {
    if !os.exists(path) {
        fmt.eprintf("Texture not found: %s\n", path)
        return create_white_texture()
    }

    // Load using core:image (auto-detects format: PNG, JPG, etc.)
    img, load_err := image.load_from_file(path, allocator = context.allocator)
    if load_err != nil {
        fmt.eprintf("Failed to load texture %s: %v\n", path, load_err)
        return create_white_texture()
    }
    defer image.destroy(img)  // Clean up the loaded image data

    // Default to RGBA if not specified (most textures are)
    channels := img.channels
    if channels == 0 { channels = 4 }  // Fallback

    id: u32
    gl.GenTextures(1, &id)
    gl.BindTexture(gl.TEXTURE_2D, id)

    // Choose format based on channels (sRGB for better colors)
    format := channels == 4 ? gl.RGBA : gl.RGB
    internal_format := channels == 4 ? gl.SRGB_ALPHA : gl.SRGB

	pixels := img.pixels.buf
    gl.TexImage2D(gl.TEXTURE_2D, 0, i32(internal_format),
                  i32(img.width), i32(img.height), 0,
                  u32(format), gl.UNSIGNED_BYTE, raw_data(pixels))  // Get pixel data

    gl.GenerateMipmap(gl.TEXTURE_2D)

    // Standard texture params
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

    gl.BindTexture(gl.TEXTURE_2D, 0)  // Unbind
    return id
}

create_white_texture :: proc() -> u32
{
    white_pixel := [4]u8{255,255,255,255}
    id: u32
    gl.GenTextures(1, &id)
    gl.BindTexture(gl.TEXTURE_2D, id)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, &white_pixel[0])
    return id
}

upload_mesh :: proc(m: ^Mesh)
{
    gl.GenVertexArrays(1, &m.vao)
    gl.GenBuffers(1, &m.vbo)
    gl.GenBuffers(1, &m.ebo)

    gl.BindVertexArray(m.vao)

    // VBO
    gl.BindBuffer(gl.ARRAY_BUFFER, m.vbo)
    gl.BufferData(gl.ARRAY_BUFFER,
        len(m.vertices) * size_of(f32),
        raw_data(m.vertices),
        gl.STATIC_DRAW)

    // EBO
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER,
        len(m.indices) * size_of(u32),
        raw_data(m.indices),
        gl.STATIC_DRAW)

    // Vertex attributes: pos (3), uv (2), normal (3) -> 8 floats total
    stride := 8 * size_of(f32)

    // Position attribute (location 0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, i32(stride), uintptr(0))
    gl.EnableVertexAttribArray(0)

    // UV attribute (location 1)
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, i32(stride), uintptr(3 * size_of(f32)))
    gl.EnableVertexAttribArray(1)

    // Normal attribute (location 2)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, false, i32(stride), uintptr(5 * size_of(f32)))
    gl.EnableVertexAttribArray(2)

    gl.BindVertexArray(0)
}