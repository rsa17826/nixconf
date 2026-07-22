precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform int output;

// The script targets these three lines specifically:
int MON = -1;

vec2 offset = vec2(0.0, 0.0);
vec2 size = vec2(1.0, 1.0);
vec2 dispSize = vec2(1.0, 1.0);

void main() {
  if (output == MON) {
    // Centered display rectangle with black borders
    vec2 dispStart = (vec2(1.0) - dispSize) * 0.5;
    vec2 dispEnd = dispStart + dispSize;

    // Anything outside the display rect → black
    if (v_texcoord.x < dispStart.x || v_texcoord.x > dispEnd.x ||
        v_texcoord.y < dispStart.y || v_texcoord.y > dispEnd.y) {
      gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
      // Map the display viewport position (0-1) into the source region
      vec2 relPos = (v_texcoord - dispStart) / dispSize;
      vec2 sourceCoord = offset + (relPos * size);

      sourceCoord = clamp(sourceCoord, 0.0, 1.0);
      gl_FragColor = texture2D(tex, sourceCoord);
    }
  }
}
