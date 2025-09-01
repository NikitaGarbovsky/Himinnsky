#version 460 core

// Inputs
in vec3 FragColor;
in vec2 FragTexCoords;

// Uniform Inputs
uniform sampler2D Texture0;

// Ouput
out vec4 FinalColor;

void main()
{
    FinalColor = texture(Texture0, FragTexCoords);
}