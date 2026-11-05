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
  float edgeWidth;
};
layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Spike height of cell k at x. `seed` makes every edge different.
// depth = px from the edge of this pixel (0 at the tip, >= amplitude at the
// base)
float spikeAt(float x, float k, float seed, float depth) {
  float ks = k + seed * 37.0;

  // lean: random direction per spike, active only in occasional slow bursts
  float leanGate = smoothstep(0.5, 0.9,
                              sin(time * (0.15 + 0.25 * hash(vec2(ks, 11.0))) +
                                  6.2831 * hash(vec2(ks, 12.0))) *
                                      0.5 +
                                  0.5);
  float lean = (hash(vec2(ks, 13.0)) - 0.5) * 2.0 * 0.4 *
               leanGate; // spike units, max ~0.6
  float shear = 1.0 - clamp(depth / amplitude, 0.0, 1.0); // 1 at tip, 0 at base

  float cx = k + 0.5 + (hash(vec2(ks, 1.0)) - 0.5) * 0.5 + lean * shear;
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
  float pulse = 1.0 + .6 * sin(time * (1 + 8.0 * hash(vec2(ks, 9.0))) +
                               6.2831 * hash(vec2(ks, 10.0)));

  float dx = x - cx;
  float w = (dx < 0.0 ? wl : wr) * s;
  float tip = max(0.0, 1.0 - abs(dx) / w);
  return tip * h * s * pulse;
}
float spikeNeon(float along, float depth, float seed, float dir) {
  float x = along / spikeWidth - time * speed * dir + seed * 11.3;
  float k = floor(x);

  float tip =
      max(spikeAt(x, k - 1.0, seed, depth),
          max(spikeAt(x, k, seed, depth), spikeAt(x, k + 1.0, seed, depth)));

  // Only color the actual spike regions
  float spike = smoothstep(0.02, 0.12, tip);

  // Fade the neon toward the inner base of each spike
  float fade = 1.0 - smoothstep(0.65, 1.0, abs(depth) / amplitude);

  return spike * fade;
}
void edge(float along, float m, float seed, float dir, out float d,
          out float mask) {
  float x = along / spikeWidth - time * speed * dir + seed * 11.3;
  float k = floor(x);
  float tip = max(spikeAt(x, k - 1.0, seed, m),
                  max(spikeAt(x, k, seed, m), spikeAt(x, k + 1.0, seed, m)));
  d = amplitude * (1.0 - clamp(tip, 0.0, 1.0));
  mask = smoothstep(edgeWidth, 0.0, m);
}

void main() {
  vec2 uv = qt_TexCoord0;
  vec2 p = uv * resolution;

  float dB, mB, dT, mT, dL, mL, dR, mR;
  edge(p.x, resolution.y - p.y, 0.0, 1.0, dB, mB);
  edge(p.x, p.y, 1.0, -1.0, dT, mT);
  edge(p.y, p.x, 2.0, 1.0, dL, mL);
  edge(p.y, resolution.x - p.x, 3.0, -1.0, dR, mR);
  float nB = spikeNeon(p.x, resolution.y - p.y, 0.0, 1.0) * mB;
  float nT = spikeNeon(p.x, p.y, 1.0, -1.0) * mT;
  float nL = spikeNeon(p.y, p.x, 2.0, 1.0) * mL;
  float nR = spikeNeon(p.y, resolution.x - p.x, 3.0, -1.0) * mR;

  float neon = max(max(nB, nT), max(nL, nR));
  vec2 disp = vec2(dR * mR - dL * mL, dB * mB - dT * mT);

  vec2 duv = uv + disp / resolution;

  float cut = clamp((resolution.y - p.y) - dB + 0.5, 0.0, 1.0) *
              clamp(p.y - dT + 0.5, 0.0, 1.0) *
              clamp(p.x - dL + 0.5, 0.0, 1.0) *
              clamp((resolution.x - p.x) - dR + 0.5, 0.0, 1.0);

  vec4 color = texture(source, duv);
  //
  vec3 colA = vec3(0.65, 0.05, 1.0);
  vec3 colB = vec3(0.699, 0.0625, 0.0625);
  vec3 colC = vec3(0.1, 0.8, 0.4);

  // Position in animation cycle
  float phase = time + (p.x / 150.0);

  // Calculate weights evenly spaced by 120 degrees (2 * PI / 3)
  float wA = max(0.0, sin(phase));
  float wB = max(0.0, sin(phase + 2.094395));
  float wC = max(0.0, sin(phase + 4.188790));

  // Normalize weights so they always sum to 1.0
  vec3 finalColor = (colA * wA + colB * wB + colC * wC) / (wA + wB + wC);
  //
  color.rgb = mix(color.rgb, (finalColor), neon);
  // color.rgb = mix(color.rgb,
  //                 mix(vec3(0.65, 0.05, 1.0), vec3(0.69921875, 0.0625,
  //                 0.0625),
  //                     hash(vec2(p.x, 10))),
  //                 neon);

  fragColor = color * cut * qt_Opacity;
}
