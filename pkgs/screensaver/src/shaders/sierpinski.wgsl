// Sierpinski triangle with slow animation

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

fn sierpinski(p: vec2<f32>, iterations: i32) -> f32 {
    var uv = p;
    var scale = 1.0;

    for (var i = 0; i < iterations; i++) {
        // Fold space to create sierpinski pattern
        uv *= 2.0;
        scale *= 2.0;

        // Wrap coordinates
        uv = fract(uv);

        // Create triangle cutout
        if (uv.x + uv.y > 1.0) {
            return 0.0;
        }
    }
    return 1.0;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    let t = uniforms.time * 0.1;

    // Slow zoom animation
    let zoom = 1.0 + sin(t) * 0.3;
    let center = vec2<f32>(0.5, 0.5);
    var p = (uv - center) * zoom + center;

    // Slow rotation
    let angle = t * 0.2;
    let c = cos(angle);
    let s = sin(angle);
    let centered = p - center;
    p = vec2<f32>(
        centered.x * c - centered.y * s,
        centered.x * s + centered.y * c
    ) + center;

    // Calculate sierpinski at different scales for depth
    let s1 = sierpinski(p, 6);
    let s2 = sierpinski(p * 0.5 + 0.25, 5);

    // OLED-optimized: true black background, subtle triangle outlines
    var col = vec3<f32>(0.0);  // True black

    if (s1 > 0.5) {
        // Show only edges, not filled triangles (OLED friendly)
        let edge_dist = abs(s1 - 0.5);
        let edge = smoothstep(0.0, 0.02, edge_dist) * smoothstep(0.1, 0.02, edge_dist);
        col = vec3<f32>(0.08 * edge, 0.02 * edge, 0.03 * edge);
    }

    return vec4<f32>(col, 1.0);
}
