// Mandelbrot zoom animation

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

fn mandelbrot(c: vec2<f32>, max_iter: i32) -> f32 {
    var z = vec2<f32>(0.0, 0.0);

    for (var i = 0; i < max_iter; i++) {
        if (dot(z, z) > 4.0) {
            // Smooth iteration count
            return f32(i) - log2(log2(dot(z, z))) + 4.0;
        }
        z = vec2<f32>(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
    }
    return f32(max_iter);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    let t = uniforms.time;

    // Zoom into an interesting point (Seahorse Valley)
    let zoom_point = vec2<f32>(-0.743643887037158704752191506114774, 0.131825904205311970493132056385139);

    // Exponential zoom (very slow)
    let zoom = exp(t * 0.05);
    let scale = 3.0 / zoom;

    // Map UV to complex plane
    let c = (uv - 0.5) * scale + zoom_point;

    // Dynamic iteration count based on zoom
    let max_iter = i32(min(100.0 + zoom * 2.0, 500.0));

    let iter = mandelbrot(c, max_iter);
    let n = iter / f32(max_iter);

    // OLED-optimized: fractal colors visible, black vignette at screen edges
    var col = vec3<f32>(0.0);  // True black

    if (n < 1.0) {
        // Smooth coloring based on escape time
        let hue = n * 6.0 + t * 0.02;
        col.r = sin(hue) * 0.12 + 0.1;
        col.g = sin(hue + 2.0) * 0.04 + 0.03;
        col.b = sin(hue + 4.0) * 0.06 + 0.05;
    }
    // Inside the set stays true black

    // Vignette: fade to black at screen edges (OLED friendly)
    let dist = length(uv - 0.5);
    let vig = 1.0 - smoothstep(0.3, 0.6, dist);
    col *= vig;

    return vec4<f32>(col, 1.0);
}
