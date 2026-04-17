precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// The script targets these two lines specifically:
vec2 offset = vec2(0.0, 0.0);
vec2 size = vec2(1.0, 1.0);

void main() {
  // Map full screen (0-1) to the selected sub-region
  vec2 sub_region_coord = offset + (v_texcoord * size);

  // Safety check: ensure we don't sample outside 0-1 (optional)
  sub_region_coord = clamp(sub_region_coord, 0.0, 1.0);

  gl_FragColor = texture2D(tex, sub_region_coord);
}