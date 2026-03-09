precision mediump float;

uniform sampler2D tex; // Hyprland usually expects 'tex'
varying vec2 v_texcoord;

void main() {
  // 1. Get the full vec4 (RGBA) so we have the alpha channel available
  vec4 pix = texture2D(tex, v_texcoord);
  vec3 color = pix.rgb;

  float maxC = max(color.r, max(color.g, color.b));
  float minC = min(color.r, min(color.g, color.b));

  // 2. Logic: if the difference between max and min channel is < 5%
  if ((maxC - minC) < 0.05) {
    // Invert RGB but keep the original Alpha
    gl_FragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, pix.a);
  } else {
    // Output original RGBA
    gl_FragColor = pix;
  }
}