precision mediump float;

uniform sampler2D u_tex;
varying vec2 v_texcoord;

float rerange(float val, float l1, float h1, float l2, float h2){
    return ((val - l1) / (h1 - l1)) * (h2 - l2) + l2;
}
float mapToDarkeningFactor(float x) {
  // return rerange(x, .4, 1, .8,.0);
  // return rerange(x, 0.5, 0.9, 0.3, 0.0)+.2;
  return rerange(x, 0.5, 1, 0.8, 0.15);
  // return rerange(x, 0.5, 0.9, 0.3, 0.0)+.3;
}
void main() {
  vec3 color = texture(Source, vTexCoord).rgb;

    float avg = (col.r + col.g + col.b) / 3.0;

  float averageIntensity = (color.r + color.g + color.b) / 3.0;
  float darkeningFactor = mapToDarkeningFactor(averageIntensity);

    gl_FragColor = vec4(col * factor, 1.0);
}
