#version 460 core

layout(location = 0) out vec2 outCoords;

uniform mat4 view_proj;
uniform float grid_size;

const vec4 positions[4] = vec4[](
	vec4(-0.5, 0.0, 0.5, 1.0),
	vec4(0.5, 0.0, 0.5, 1.0),
	vec4(-0.5, 0.0, -0.5, 1.0),
	vec4(0.5, 0.0, -0.5, 1.0)
);

void main()
{
	vec4 world_pos = positions[gl_VertexID];
	world_pos.xyz *= grid_size * 100;

	gl_Position = view_proj * world_pos;
	outCoords = world_pos.xz;
}