precision mediump float;

uniform sampler2D u_tex;
varying vec2 v_texcoord;

float rerange(float val, float l1, float h1, float l2, float h2){
  return ((val - l1) / (h1 - l1)) * (h2 - l2) + l2;
}

float mapToDarkeningFactor(float x) {
  // Note: Ensure input is clamped to avoid division by zero or out-of-bounds math
  return rerange(clamp(x, 0.5, 1.0), 0.5, 1.0, 0.8, 0.15);
}

void main() {
  // 1. Fixed variable names: u_tex instead of Source, v_texcoord instead of vTexCoord
  vec3 color = texture2D(u_tex, v_texcoord).rgb;

  // 2. Fixed math: 3.0 is a float, but always use 1.0 instead of 1 for rerange constants
  float averageIntensity = (color.r + color.g + color.b) / 3.0;
    
  float darkeningFactor = mapToDarkeningFactor(averageIntensity);

  // 3. Fixed variable name: color instead of col, darkeningFactor instead of factor
  gl_FragColor = vec4(color * darkeningFactor, 1.0);
}