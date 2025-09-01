package renderer

import "vendor:stb/image"
import "core:fmt"

textureGlass : u32
imageData : [^]byte
imageHeight, imageWidth, imageComponents : i32  

loadImageTexture :: proc()
{
    filePath : cstring = "Resources/Textures/floor_tiles_texture.png"
    imageData = image.load(filePath, &imageWidth, &imageHeight, &imageComponents, 0)

    if imageData == nil // Image filled with no data
    {
        fmt.println("Texture failed to load at: %v", filePath)
    }
}

freeImageTextureData :: proc()
{
    image.image_free(imageData)
}

setImageFlip :: proc()
{
    image.set_flip_vertically_on_load(1)
}