#version 450

layout(set = 0, binding = 0) uniform sampler2D Source;
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
// float mapToDarkeningFactor(float intensity) {
  // Darken more aggressively at low intensity
  // return mix(0.4, 1.0, pow(intensity, 0.8));
// }

// float mapToDarkeningFactor(float intensity) {
  // return mix(0.6, 1.0, intensity);
// }
float rerange(float val, float low1, float high1, float low2, float high2){
  return ((val - low1) / (high1 - low1)) * (high2 - low2) + low2;
}
float mapToDarkeningFactor(float x) {
  // return rerange(x, .4, 1, .8,.0);
  // return rerange(x, 0.5, 0.9, 0.3, 0.0)+.2;
  return rerange(x, 0.5, 1, 0.8, 0.15);
  // return rerange(x, 0.5, 0.9, 0.3, 0.0)+.3;
}
void main() {
  vec3 color = texture(Source, vTexCoord).rgb;

  float averageIntensity = (color.r + color.g + color.b) / 3.0;
  float darkeningFactor = mapToDarkeningFactor(averageIntensity);

  FragColor = vec4(color * darkeningFactor, 1.0);
}
