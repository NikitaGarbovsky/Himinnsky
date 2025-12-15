#version 460 core

in vec2 FragTexCoords;
in vec3 FragNormal;
in vec3 FragPos;

uniform sampler2D Texture0;
uniform float AmbientStrength = 0.55f;
uniform vec3 AmbientColor = vec3(1.0f, 1.0f, 1.0f);
uniform vec3 LightColor = vec3(0.5f, 0.1f, 0.8f);
uniform vec3 LightPos = vec3(-300.0f, 000.0f, 100.0f);
uniform vec3 CameraPos;
uniform float LightSpecularStrength = 10.0f;
uniform float ObjectShinyness = 32.0f;

out vec4 FragColor;

void main()
{
    vec3 Ambient = AmbientStrength * AmbientColor;  

    // Light Direction
    vec3 Normal = normalize(FragNormal);
    vec3 LightDir = normalize(FragPos - LightPos);

    // Diffuse
    float DiffuseStrength = max(dot(Normal,-LightDir), 0.0f);
    vec3 Diffuse = DiffuseStrength * LightColor;
    
    // Specular calculations
    vec3 ReverseViewDir = normalize(CameraPos - FragPos);
    vec3 HalfwayVector = normalize(-LightDir + ReverseViewDir);
    float SpecularReflectivity = pow(max(dot(Normal, HalfwayVector), 0.0f), ObjectShinyness);
    vec3 Specular = LightSpecularStrength * SpecularReflectivity * LightColor;

    vec4 Light = vec4(Ambient + Diffuse + Specular, 1.0f); // Bling Phong lighting

    FragColor = Light * texture(Texture0, FragTexCoords);
}