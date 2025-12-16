// Plasma shader - dark warm palette, OLED optimized, fast dynamic motion

struct Uniforms {
    time: f32,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    var out: VertexOutput;
    out.position = vec4<f32>(positions[vertex_index], 0.0, 1.0);
    out.uv = (positions[vertex_index] + 1.0) * 0.5;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    let p = uv * 2.0 - 1.0;
    let t = uniforms.time * 0.3;  // Smooth motion

    // Multi-layered plasma with varied speeds
    var v: f32 = 0.0;
    v += sin(p.x * 3.0 + t * 1.3);
    v += sin((p.y * 3.0 + t * 0.9) * 0.6);
    v += sin((p.x * 3.0 + p.y * 3.0 + t * 1.1) * 0.5);
    v += sin(length(p * 4.0) + t * 1.5);
    v += sin(p.x * 5.0 - p.y * 2.0 + t * 0.7) * 0.5;  // Extra layer for dynamism
    v *= 0.4;

    // OLED-optimized: mostly black with subtle color wisps
    var col = vec3<f32>(0.0);  // True black base

    // Only show color in "hot" areas (v > threshold)
    let intensity = smoothstep(0.25, 0.75, abs(v)) * 0.18;
    col.r = intensity * (sin(v * 3.14159) * 0.5 + 0.5);
    col.g = intensity * (sin(v * 3.14159 + 2.0) * 0.3 + 0.2);
    col.b = intensity * (sin(v * 3.14159 + 4.0) * 0.4 + 0.3);

    // Strong vignette to black at edges
    let vig = 1.0 - length(uv - 0.5) * 1.5;
    col *= max(vig, 0.0);

    return vec4<f32>(col, 1.0);
}
