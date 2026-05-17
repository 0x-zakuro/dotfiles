#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    
    // MEDICAL GRADE PROTECTION (2700K)
    pix.g *= 0.78;  // Lowered more to remove the "harsh" green-yellow
    pix.b *= 0.45;  // Dropped below 0.50 to effectively "kill" the high-energy blue
    
    fragColor = pix;
}