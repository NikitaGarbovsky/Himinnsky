#version 460 core

// This shader draws a fixed place, in-world grid that fades in the horizon 
// to eleviate artifacting when the thin grid lines reduces to a size below a 
// single pixel.

// Postion on the plane in world units. 
layout(location = 0) in vec2 inCoords;

uniform float grid_size;

float cell_size = 1000.0f; // in cm, so 10 Meters World Units
float subcell_size = 100.0f; // in cm, so 1 Meter World Units
const float outlineSize = 0.01f; // in Meters, so 1cm World Units

layout(location = 0) out vec4 outColor;

void main()
{
	// Compute the position within the total grid
    vec2 cell_coords    = mod(inCoords, cell_size);
    vec2 subcell_coords = mod(inCoords, subcell_size);

    // Get the Uv's inside the cells
    vec2 cell_uv    = cell_coords    / cell_size;     // 0..1 inside 10m cell
    vec2 subcell_uv = subcell_coords / subcell_size;  // 0..1 inside 1m subcell

    // What is the difference in world position in subcell units, between this 
    // pixel and it's adjacents.
    vec2 dx = dFdx(inCoords) / subcell_size; // Convert from world units to cell fractions
    vec2 dy = dFdy(inCoords) / subcell_size;

    // How much of a subcell does this pixel span.
    vec2 subcellsPerPx = vec2(length(vec2(dx.x, dy.x)),
                        length(vec2(dx.y, dy.y)));

    // Find the distance to the closest subcell uv
    vec2 dist_subcellsUV = min(subcell_uv, 1.0 - subcell_uv);
    vec2 distpx = dist_subcellsUV / subcellsPerPx; // Distance from the subcell line

    vec2 halfWidthPx = vec2(outlineSize) / subcellsPerPx;
    vec2 targetPx = max(halfWidthPx, vec2(0.5));
    vec2 dimming  = min(halfWidthPx / 0.5, vec2(0.3));

    vec2 cov = 1.0 - smoothstep(targetPx - 0.5, targetPx + 0.5, distpx);

    cov *= dimming;
    vec2 fade = 1.0 - smoothstep(vec2(0.25), vec2(0.8), subcellsPerPx);
    //cov *= fade;

    vec2 gridCov = cov;

    // Axis lines same width and AA as grid lines
    vec2 axisPx  = abs(inCoords) / (subcellsPerPx * subcell_size);
    vec2 axisCov = (1.0 - smoothstep(targetPx - 0.5, targetPx + 0.5, axisPx)) * dimming * 4; 
   
    float zAxis = axisCov.x;   // line where x == 0, runs along Z
    float xAxis = axisCov.y;   // line where z == 0, runs along X

    float alpha = max(max(gridCov.x, gridCov.y), max(xAxis, zAxis));

    vec3 col = vec3(0.502, 0.502, 0.502); // Default Grey color grid lines
    col = mix(col, vec3(0.2, 0.4, 0.9), zAxis);
    col = mix(col, vec3(0.9, 0.2, 0.2), xAxis);

    outColor = vec4(col, alpha);
}