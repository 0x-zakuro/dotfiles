#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    
    // MILD PROTECTION (~4000K)
    pix.g *= 0.90;  // Very slight reduction in green
    pix.b *= 0.75;  // Takes the edge off the blue without turning the screen orange
    
    fragColor = pix;
}