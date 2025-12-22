#version 450

layout(set = 0, binding = 0) uniform sampler2D Source;
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

float mapToDarkeningFactor(float intensity) {
  return mix(0.6, 1.0, intensity);
}

void main() {
  vec3 color = texture(Source, vTexCoord).rgb;

  float averageIntensity = (color.r + color.g + color.b) / 3.0;
  float darkeningFactor = mapToDarkeningFactor(averageIntensity);

  FragColor = vec4(color * darkeningFactor, 1.0);
}
