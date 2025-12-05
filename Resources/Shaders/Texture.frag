#version 460 core

in vec2 FragTexCoords;

out vec4 FragColor;

uniform sampler2D Texture0;

void main()
{
    vec4 texColor = texture(Texture0, FragTexCoords);

    if (texColor.a < 0.5) discard;

    FragColor = vec4(texColor.rgb, texColor.a);
}