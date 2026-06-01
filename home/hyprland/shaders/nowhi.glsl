precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// Define v globally so the function can access it, or pass it in.
const float v = 0.80;
// A small offset value for looking at neighboring pixels (adjust as needed)
const float offset = 0.002;

// Fixed parameter order and added missing semicolon
bool w(vec3 p) { return p.r > v && p.g > v && p.b > v; }

void main() {
  // Sample the current pixel
  vec4 p = texture2D(tex, v_texcoord);

  // Sample neighboring pixels by modifying the texture coordinates
  vec4 top = texture2D(tex, v_texcoord + vec2(0.0, offset));
  vec4 bottom = texture2D(tex, v_texcoord + vec2(0.0, -offset));
  vec4 right = texture2D(tex, v_texcoord + vec2(offset, 0.0));
  vec4 left = texture2D(tex, v_texcoord + vec2(-offset, 0.0));
  vec4 ur = texture2D(tex, v_texcoord + vec2(-offset, -offset));
  vec4 ul = texture2D(tex, v_texcoord + vec2(-offset, offset));
  vec4 dr = texture2D(tex, v_texcoord + vec2(offset, -offset));
  vec4 dl = texture2D(tex, v_texcoord + vec2(offset, offset));

  float c = 1.0;
  if (w(p.rgb)) {
    if (w(top.rgb)) {
      c += 1.0;
    }
    if (w(bottom.rgb)) {
      c += 1.0;
    }
    if (w(left.rgb)) {
      c += 1.0;
    }
    if (w(right.rgb)) {
      c += 1.0;
    }
    if (w(ur.rgb)) {
      c += 1.0;
    }
    if (w(ul.rgb)) {
      c += 1.0;
    }
    if (w(dr.rgb)) {
      c += 1.0;
    }
    if (w(dl.rgb)) {
      c += 1.0;
    }
    p.rgb = mix(p.rgb, vec3(0.0), c / 18.0);
  }
  gl_FragColor = p;
}