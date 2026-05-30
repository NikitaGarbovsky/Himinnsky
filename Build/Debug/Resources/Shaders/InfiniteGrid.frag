#version 460 core

layout(location = 0) in vec2 inCoords;
layout(location = 0) out vec4 outColor;

uniform float grid_size;

float cell_size = 1000.0f; 
float half_cell_size = cell_size * 0.5f;

float subcell_size = 100.0f;
float half_subcell_size = subcell_size * 0.5f;

void main()
{
	// ---- Step 1: Displace coords so origin sits at cell corner ----
    vec2 cell_coords    = mod(inCoords + half_cell_size,    cell_size);
    vec2 subcell_coords = mod(inCoords + half_subcell_size, subcell_size);

    // ---- Step 2: Normalize inside each cell ----
    vec2 cell_uv    = cell_coords    / cell_size;     // 0..1 inside 1m cell
    vec2 subcell_uv = subcell_coords / subcell_size;  // 0..1 inside 0.1m subcell


    // For debugging: see both cell types at the same time
    outColor = vec4(subcell_uv, 0.0, 1.0);
}