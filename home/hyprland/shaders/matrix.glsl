precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
  vec4 px = texture2D(tex, v_texcoord);
  vec3 c = px.rgb;

  // Target color #84708F converted to normalized RGB (0.0 to 1.0)
  // #84 -> 132/255 ≈ 0.5176
  // #70 -> 112/255 ≈ 0.4392
  // #8F -> 143/255 ≈ 0.5608
  vec3 targetColor = vec3(132.0 / 255.0, 112.0 / 255.0, 143.0 / 255.0);

  // Replacement color #00ff00 converted to normalized RGB
  // #00 -> 0/255 = 0.0
  // #aa -> 170/255 ≈ 0.6667
  // #00 -> 0/255 = 0.0
  vec3 replacementColor = vec3(0.0, 170.0 / 255.0, 0.0);

  // Calculate the distance (difference) between the current pixel and the
  // target color
  float dist = distance(c, targetColor);

  // Define a threshold for how close the color needs to be (adjust this to
  // broaden or narrow the effect)
  float threshold = 0.35;

  if (dist < threshold) {
    // Smoothly blend based on how close it is (closer = more replacement color)
    float factor = 1.0 - (dist / threshold);
    c = mix(c, replacementColor, factor);
  } else {
    float factor = 1.0 - (dist / threshold);
    c = mix(replacementColor, c, factor);
  }

  gl_FragColor = vec4(c, px.a);
}
