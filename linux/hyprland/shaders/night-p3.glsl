// P3 saturation boost + blue light filter for night use
#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Adjustable settings
const float saturation = 1.22;    // P3 compensation (1.0 = no boost)
const float blueReduce = 0.7;     // Blue reduction (1.0 = none, 0.5 = strong)
const float temperature = 0.92;   // Color temp (1.0 = neutral, lower = warmer)

void main() {
    vec4 color = texture(tex, v_texcoord);

    // P3 saturation boost
    float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 saturated = mix(vec3(gray), color.rgb, saturation);

    // Blue light filter (warm shift)
    saturated.b *= blueReduce;
    saturated.g *= temperature;

    fragColor = vec4(saturated, color.a);
}
