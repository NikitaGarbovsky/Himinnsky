#version 460 core

layout(location = 0) in vec2 inCoords;
layout(location = 0) out vec4 outColor;

uniform float grid_size;

float cell_size = 1000.0f; 
float half_cell_size = cell_size * 0.5f;

float subcell_size = 100.0f;
float half_subcell_size = subcell_size * 0.5f;

const float outlineSize = 0.02f;

void main()
{
	// ---- Step 1: Displace coords so origin sits at cell corner ----
    vec2 cell_coords    = mod(inCoords + half_cell_size,    cell_size);
    vec2 subcell_coords = mod(inCoords + half_subcell_size, subcell_size);

    // ---- Step 2: Normalize inside each cell ----
    vec2 cell_uv    = cell_coords    / cell_size;     // 0..1 inside 1m cell
    vec2 subcell_uv = subcell_coords / subcell_size;  // 0..1 inside 0.1m subcell

   vec4 newUV = vec4(1,1,1,0);
   float belowX = 1.0 - step(outlineSize, subcell_uv.x); // 1 greater, 0 less
   float greaterX = step(1.0 - outlineSize, subcell_uv.x); 
   
   float belowY = 1.0 - step(outlineSize, subcell_uv.y);
   float greaterY = step(1.0 - outlineSize, subcell_uv.y);

   float x = belowX + greaterX;
   float y = belowY + greaterY;

   vec2 distUV = min(subcell_uv, 1.0 - subcell_uv);
   vec2 uvDeriv = fwidth(inCoords / subcell_size);

   vec2 distpx = distUV / uvDeriv;
   vec2 halfWidthPx = vec2(outlineSize) / uvDeriv;

   vec2 targetPx = max(halfWidthPx, vec2(0.5));
   vec2 dimming  = min(halfWidthPx / 0.5, vec2(1.0));

   vec2 cov = 1.0 - smoothstep(targetPx - 0.5, targetPx + 0.5, distpx);

   cov *= dimming;
   vec2 fade = 1.0 - smoothstep(vec2(0.25), vec2(0.8), uvDeriv);
   cov *= fade;
   float alpha = max(cov.x, cov.y);

   if (alpha < 0.001) discard;

   outColor = vec4(1,1,1, alpha);
}