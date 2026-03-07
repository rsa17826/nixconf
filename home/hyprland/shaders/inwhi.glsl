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
  // 1. Get the full vec4 (RGBA) so we have the alpha channel available
  vec4 pix = texture2D(u_tex, v_texcoord);
  vec3 color = pix.rgb;

  float maxC = max(color.r, max(color.g, color.b));
  float minC = min(color.r, min(color.g, color.b));

  // 2. Logic: if the difference between max and min channel is < 5%
  if ((maxC - minC) < 0.02) {
    // Invert RGB but keep the original Alpha
vec3 inverted = 1.0 - color.rgb;
float brightness = (inverted.r + inverted.g + inverted.b) / 3.0;
        
  if (brightness >= 0.8) {
    // Apply your formula: 40% + (brightness - 80%)
    // This dims the harsh whites while keeping some detail
    float dimmedRatio = 0.4 + (brightness - 0.8);
    inverted = inverted * (dimmedRatio / brightness);
  }
        
  gl_FragColor = vec4(inverted, pix.a);
      } else {
  // Output original RGBA
  gl_FragColor = pix;
}
}
