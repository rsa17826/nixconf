precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
  vec4 px = texture2D(tex, v_texcoord);
  vec3 c = px.rgb;

  // 1. Determine the "whiteness" (the common minimum of all channels)
  float whiteness = min(min(c.r, c.g), c.b);

  // 2. Subtract the whiteness to push it toward black
  // Using a power (like 2.0) makes the transition sharper
  c.r -= pow(whiteness * 0.9, 2.0);
  c.g -= pow(whiteness * 0.9, 2.0);
  c.b -= pow(whiteness * 0.9, 2.0);

  // 3. Ensure values don't go below zero
  c = max(c, 0.0);

  gl_FragColor = vec4(c, px.a);
}