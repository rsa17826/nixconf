precision mediump float;

uniform sampler2D u_tex;
varying vec2 v_texcoord;

float rerange(float val, float l1, float h1, float l2, float h2){
    return ((val - l1) / (h1 - l1)) * (h2 - l2) + l2;
}

float mapToDarkeningFactor(float x) {
    // Note: Ensure input is clamped to avoid division by zero or out-of-bounds math
    return rerange(clamp(x, 0.5, 1.0), 0.5, 1.0, 0.8, 0.15);
}

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    
    // Perceptual brightness
    float luminance = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));

    // Map white (1.0) to transparent (0.0)
    // Map black (0.0) to opaque (1.0)
    float alpha = 1.0 - luminance;

    // Use smoothstep to sharpen the edges of the text
    alpha = smoothstep(0.05, 0.15, alpha);

    gl_FragColor = vec4(pixColor.rgb, alpha * pixColor.a);
}