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
    vec4 texColor = texture2D(u_tex, v_texcoord);
    
    // Calculate brightness (luminance)
    // We use weighted values because the eye sees Green as brightest
    float brightness = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));

    // INVERT logic: 
    // If brightness is 1.0 (white), alpha becomes 0.0 (transparent)
    // If brightness is 0.0 (black), alpha becomes 1.0 (opaque)
    float alpha = 1.0 - brightness;

    // Optional: Add a "threshold" to make sure near-whites are fully gone
    alpha = smoothstep(0.0, 0.1, alpha); 

    gl_FragColor = vec4(texColor.rgb, alpha);
}