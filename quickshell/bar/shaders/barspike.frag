#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  vec2 resolution; // px
  float time;
  float speed;      // spikes per second travelling along the bar
  float amplitude;  // spike depth in px
  float spikeWidth; // px per spike
  float sharpness;  // 1 = triangles, 2-4 = thin thorns
  float edgeWidth;  // px from bottom where content gets distorted
};
layout(binding = 1) uniform sampler2D source;
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Height (0..~1.3) of the spike belonging to cell k, evaluated at x.
float spikeAt(float x, float k) {
  // jittered centre, separate left/right half-widths -> random angles, narrow
  // base
  float cx = k + 0.5 + (hash(vec2(k, 1.0)) - 0.5) * 0.5;
  float wl = mix(0.10, 0.28, hash(vec2(k, 2.0)));
  float wr = mix(0.10, 0.28, hash(vec2(k, 3.0)));
  float h = mix(0.4, 1.0, hash(vec2(k, 4.0)));

  // grow/shrink in all directions (width AND height), only in occasional
  // bursts: `gate` is ~0 most of the time, so s stays ~1 until a burst opens it
  float gate = smoothstep(0.55, 0.95,
                          sin(time * (0.3 + 0.4 * hash(vec2(k, 5.0))) +
                              6.2831 * hash(vec2(k, 6.0))) *
                                  0.5 +
                              0.5);
  float s = 1.0 + 0.45 * gate *
                      sin(time * (1.0 + hash(vec2(k, 7.0))) +
                          6.2831 * hash(vec2(k, 8.0)));

  // separate, faster pulse: height only, always running, small
  float pulse = 1.0 + 0.15 * sin(time * (3.0 + 2.0 * hash(vec2(k, 9.0))) +
                                 6.2831 * hash(vec2(k, 10.0)));

  float dx = x - cx;
  float w = (dx < 0.0 ? wl : wr) * s;
  float tip =
      max(0.0, 1.0 - abs(dx) / w); // straight sides, sharp tip, flat elsewhere
  return tip * h * s * pulse;
}

void main() {
  vec2 uv = qt_TexCoord0;
  vec2 p = uv * resolution;
  float m = resolution.y - p.y; // px from bottom edge

  float x = p.x / spikeWidth -
            time * speed; // position along the edge, in spike units

  // spikes can widen into neighbouring cells, so take the tallest of 3 cells
  float k = floor(x);
  float tip = max(spikeAt(x, k - 1.0), max(spikeAt(x, k), spikeAt(x, k + 1.0)));

  float d = amplitude * (1.0 - clamp(tip * 0.65, 0.0,
                                     1.0)); // how far the edge is eaten in here
  float mask = smoothstep(edgeWidth, 0.0, m);

  vec2 duv = uv + vec2(0.0, d * mask) / resolution;
  float cut = clamp(m - d + 0.5, 0.0, 1.0); // anti-aliased cutoff

  fragColor = texture(source, duv) * cut * qt_Opacity;
}
