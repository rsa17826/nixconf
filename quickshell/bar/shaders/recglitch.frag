#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    float glitchAmount;   // 0.0 - 0.05ish: how far slices shove sideways
    float aberration;     // 0.0 - 0.01ish: per-channel sample offset
};

layout(binding = 1) uniform sampler2D source;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;

    // ── Slice displacement glitch ──
    // Chop the vertical axis into bands; each band gets a per-frame random
    // seed. Only bands whose noise crosses a threshold actually shove
    // sideways, so most frames sit still and occasional bands "tear".
    float sliceH = 0.14;
    float sliceIndex = floor(uv.y / sliceH);
    float sliceSeed = sliceIndex + floor(iTime * 6.0);
    float sliceNoise = rand(vec2(sliceSeed, 1.0));
    float sliceActive = step(0.86, sliceNoise);
    float displace = (rand(vec2(sliceSeed, 2.0)) - 0.5) * glitchAmount * sliceActive;
    uv.x += displace;

    // ── Chromatic aberration ──
    // Sample R/G/B from slightly different UVs. Widen it on slices that
    // are currently displacing, so the glitch and the color-split read as
    // one event instead of two independent effects.
    float ab = aberration * (1.0 + sliceActive * 5.0);
    vec2 offR = vec2(ab, 0.0);
    vec2 offB = vec2(-ab, 0.0);

    float r = texture(source, uv + offR).r;
    float g = texture(source, uv).g;
    float b = texture(source, uv + offB).b;
    float a = max(texture(source, uv).a, max(texture(source, uv + offR).a, texture(source, uv + offB).a));

    vec3 col = vec3(r, g, b);

    // ── Cheap radial bloom ──
    // Ring-sample around the pixel and add it back additively. Not a true
    // gaussian blur, but at 8 taps it's cheap and reads as a soft glow
    // around anything bright (the dot, the text edges).
    vec3 glow = vec3(0.0);
    const int TAPS = 8;
    const float radius = 0.010;
    for (int i = 0; i < TAPS; i++) {
        float angle = (float(i) / float(TAPS)) * 6.28318530718;
        vec2 o = vec2(cos(angle), sin(angle)) * radius;
        glow += texture(source, uv + o).rgb;
    }
    glow /= float(TAPS);

    col += glow * 0.85;

    fragColor = vec4(col, a) * qt_Opacity;
}
