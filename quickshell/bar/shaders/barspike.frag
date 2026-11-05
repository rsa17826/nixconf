#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  vec2 resolution; // px
  float time;
  float speed;
  float amplitude;
  float spikeWidth;
  float sharpness; // unused, can be removed from both files
  float edgeWidth;
};
layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Spike height of cell k at x. `seed` makes every edge different.
float spikeAt(float x, float k, float seed) {
  float ks = k + seed * 37.0;
  float cx = k + 0.5 + (hash(vec2(ks, 1.0)) - 0.5) * 0.5;
  float wl = mix(0.10, 0.28, hash(vec2(ks, 2.0)));
  float wr = mix(0.10, 0.28, hash(vec2(ks, 3.0)));
  float h = mix(0.4, 1.0, hash(vec2(ks, 4.0)));

  float gate = smoothstep(0.55, 0.95,
                          sin(time * (0.3 + 0.4 * hash(vec2(ks, 5.0))) +
                              6.2831 * hash(vec2(ks, 6.0))) *
                                  0.5 +
                              0.5);
  float s = 1.0 + 0.45 * gate *
                      sin(time * (1.0 + hash(vec2(ks, 7.0))) +
                          6.2831 * hash(vec2(ks, 8.0)));
  float pulse = 1.0 + 0.15 * sin(time * (3.0 + 2.0 * hash(vec2(ks, 9.0))) +
                                 6.2831 * hash(vec2(ks, 10.0)));

  float dx = x - cx;
  float w = (dx < 0.0 ? wl : wr) * s;
  float tip = max(0.0, 1.0 - abs(dx) / w);
  return tip * h * s * pulse;
}

// along = px along the edge, m = px from the edge, dir = scroll direction
void edge(float along, float m, float seed, float dir, out float d,
          out float mask) {
  float x = along / spikeWidth - time * speed * dir + seed * 11.3;
  float k = floor(x);
  float tip = max(spikeAt(x, k - 1.0, seed),
                  max(spikeAt(x, k, seed), spikeAt(x, k + 1.0, seed)));
  d = amplitude * (1.0 - clamp(tip * 1, 0.0, 1.0));
  mask = smoothstep(edgeWidth, 0.0, m);
}

void main() {
  vec2 uv = qt_TexCoord0;
  vec2 p = uv * resolution;

  float dB, mB, dT, mT, dL, mL, dR, mR;
  edge(p.x, resolution.y - p.y, 0.0, 1.0, dB, mB);  // bottom
  edge(p.x, p.y, 1.0, -1.0, dT, mT);                // top
  edge(p.y, p.x, 2.0, 1.0, dL, mL);                 // left
  edge(p.y, resolution.x - p.x, 3.0, -1.0, dR, mR); // right

  // sample from toward each edge so content gets pushed inward
  vec2 disp = vec2(dR * mR - dL * mL, dB * mB - dT * mT);
  vec2 duv = uv + disp / resolution;

  float cut = clamp((resolution.y - p.y) - dB + 0.5, 0.0, 1.0) *
              clamp(p.y - dT + 0.5, 0.0, 1.0) *
              clamp(p.x - dL + 0.5, 0.0, 1.0) *
              clamp((resolution.x - p.x) - dR + 0.5, 0.0, 1.0);

  fragColor = texture(source, duv) * cut * qt_Opacity;
}
