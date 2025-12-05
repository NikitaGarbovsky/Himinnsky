#version 460 core

layout (location = 0) in vec3 aPosition;   
layout (location = 1) in vec2 aTexCoord;   

uniform mat4 ProjectionMat;
uniform mat4 ViewMat;
uniform mat4 ModelMat;

out vec2 FragTexCoords;

void main()
{
    vec4 worldPos = ModelMat * vec4(aPosition, 1.0);
    gl_Position = ProjectionMat * ViewMat * worldPos;

    FragTexCoords = aTexCoord;
}