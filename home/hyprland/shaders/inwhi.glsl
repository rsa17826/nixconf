precision mediump float;

uniform sampler2D u_tex;
varying vec2 v_texcoord;

float rerange(float val, float l1, float h1, float l2, float h2){
    return ((val - l1) / (h1 - l1)) * (h2 - l2) + l2;
}

void main() {
    // No flipping of Y-axis
    vec3 col = texture2D(u_tex, v_texcoord).rgb;

    float avg = (col.r + col.g + col.b) / 3.0;

    float factor = rerange(clamp(avg, 0.5, 1.0), 0.5, 1.0, 0.8, 0.15);
    if(avg < 0.5)
        factor = 0.8;

    gl_FragColor = vec4(col * factor, 1.0);
}