// P3 saturation boost - compensates for sRGB on wide gamut display
#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);

    // Saturation boost (1.22 ≈ P3 compensation)
    float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(gray), color.rgb, 1.22);

    fragColor = vec4(saturated, color.a);
}
