use bytemuck::{Pod, Zeroable};
use clap::Parser;
use std::sync::Arc;
use wgpu::util::DeviceExt;
use winit::{
    application::ApplicationHandler,
    event::{ElementState, KeyEvent, WindowEvent},
    event_loop::{ActiveEventLoop, ControlFlow, EventLoop},
    keyboard::PhysicalKey,
    window::{Fullscreen, Window, WindowId},
};

#[derive(Parser)]
#[command(name = "screensaver-wgpu")]
#[command(about = "Minimal Wayland GLSL screensaver")]
struct Args {
    /// Target FPS
    #[arg(short, long, default_value = "60")]
    fps: u32,

    /// Shader type: plasma, sierpinski, mandelbrot
    #[arg(short, long, default_value = "plasma")]
    shader: String,

    /// Don't exit on input (for testing)
    #[arg(long)]
    no_input_exit: bool,
}

#[repr(C)]
#[derive(Copy, Clone, Pod, Zeroable)]
struct Uniforms {
    time: f32,
    _pad: [f32; 3],
}

struct State<'a> {
    surface: wgpu::Surface<'a>,
    device: wgpu::Device,
    queue: wgpu::Queue,
    config: wgpu::SurfaceConfiguration,
    render_pipeline: wgpu::RenderPipeline,
    uniform_buffer: wgpu::Buffer,
    uniform_bind_group: wgpu::BindGroup,
    start_time: std::time::Instant,
}

impl<'a> State<'a> {
    async fn new(window: Arc<Window>, shader_type: &str) -> Self {
        let size = window.inner_size();

        // Prefer Vulkan (supports large textures), fall back to others
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::VULKAN | wgpu::Backends::METAL,
            ..Default::default()
        });

        let surface = instance.create_surface(window).unwrap();

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::LowPower,
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            })
            .await
            .unwrap();

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    label: None,
                    required_features: wgpu::Features::empty(),
                    required_limits: wgpu::Limits::downlevel_webgl2_defaults(),
                    memory_hints: Default::default(),
                },
                None,
            )
            .await
            .unwrap();

        let caps = surface.get_capabilities(&adapter);
        let format = caps.formats[0];

        // Get device limits for max texture size
        let limits = device.limits();
        let max_size = limits.max_texture_dimension_2d;

        // Clamp to max texture size while maintaining aspect ratio
        let (width, height) = if size.width > max_size || size.height > max_size {
            let scale = (max_size as f32) / (size.width.max(size.height) as f32);
            ((size.width as f32 * scale) as u32, (size.height as f32 * scale) as u32)
        } else {
            (size.width, size.height)
        };

        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format,
            width,
            height,
            present_mode: wgpu::PresentMode::Fifo,
            alpha_mode: caps.alpha_modes[0],
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };
        surface.configure(&device, &config);

        // Create uniform buffer
        let uniforms = Uniforms {
            time: 0.0,
            _pad: [0.0; 3],
        };
        let uniform_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Uniform Buffer"),
            contents: bytemuck::cast_slice(&[uniforms]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        let uniform_bind_group_layout =
            device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                entries: &[wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                }],
                label: Some("uniform_bind_group_layout"),
            });

        let uniform_bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &uniform_bind_group_layout,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniform_buffer.as_entire_binding(),
            }],
            label: Some("uniform_bind_group"),
        });

        // Select shader based on type
        let frag_shader = match shader_type {
            "sierpinski" => include_str!("shaders/sierpinski.wgsl"),
            "mandelbrot" => include_str!("shaders/mandelbrot.wgsl"),
            _ => include_str!("shaders/plasma.wgsl"),
        };

        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Shader"),
            source: wgpu::ShaderSource::Wgsl(frag_shader.into()),
        });

        let render_pipeline_layout =
            device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                label: Some("Render Pipeline Layout"),
                bind_group_layouts: &[&uniform_bind_group_layout],
                push_constant_ranges: &[],
            });

        let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Render Pipeline"),
            layout: Some(&render_pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(wgpu::ColorTargetState {
                    format: config.format,
                    blend: Some(wgpu::BlendState::REPLACE),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: Default::default(),
            }),
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleList,
                strip_index_format: None,
                front_face: wgpu::FrontFace::Ccw,
                cull_mode: None,
                polygon_mode: wgpu::PolygonMode::Fill,
                unclipped_depth: false,
                conservative: false,
            },
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        });

        Self {
            surface,
            device,
            queue,
            config,
            render_pipeline,
            uniform_buffer,
            uniform_bind_group,
            start_time: std::time::Instant::now(),
        }
    }

    fn resize(&mut self, new_size: winit::dpi::PhysicalSize<u32>) {
        if new_size.width > 0 && new_size.height > 0 {
            // Clamp to device's max texture size
            let max_size = self.device.limits().max_texture_dimension_2d;
            let (width, height) = if new_size.width > max_size || new_size.height > max_size {
                let scale = (max_size as f32) / (new_size.width.max(new_size.height) as f32);
                ((new_size.width as f32 * scale) as u32, (new_size.height as f32 * scale) as u32)
            } else {
                (new_size.width, new_size.height)
            };
            self.config.width = width;
            self.config.height = height;
            self.surface.configure(&self.device, &self.config);
        }
    }

    fn render(&mut self) -> Result<(), wgpu::SurfaceError> {
        let output = self.surface.get_current_texture()?;
        let view = output
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());

        // Update time uniform
        let time = self.start_time.elapsed().as_secs_f32();
        let uniforms = Uniforms {
            time,
            _pad: [0.0; 3],
        };
        self.queue
            .write_buffer(&self.uniform_buffer, 0, bytemuck::cast_slice(&[uniforms]));

        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("Render Encoder"),
            });

        {
            let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("Render Pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                ..Default::default()
            });

            render_pass.set_pipeline(&self.render_pipeline);
            render_pass.set_bind_group(0, &self.uniform_bind_group, &[]);
            render_pass.draw(0..3, 0..1);
        }

        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();

        Ok(())
    }
}

struct App {
    state: Option<State<'static>>,
    window: Option<Arc<Window>>,
    fps: u32,
    shader: String,
    last_frame: std::time::Instant,
    no_input_exit: bool,
}

impl App {
    fn new(fps: u32, shader: String, no_input_exit: bool) -> Self {
        Self {
            state: None,
            window: None,
            fps,
            shader,
            last_frame: std::time::Instant::now(),
            no_input_exit,
        }
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        let window_attrs = Window::default_attributes()
            .with_title("Screensaver")
            .with_fullscreen(Some(Fullscreen::Borderless(None)))
            .with_decorations(false);

        let window = Arc::new(event_loop.create_window(window_attrs).unwrap());
        window.set_cursor_visible(false);

        let state = pollster::block_on(State::new(window.clone(), &self.shader));
        self.window = Some(window);
        self.state = Some(state);
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _: WindowId, event: WindowEvent) {
        match event {
            // Exit on any key press (unless --no-input-exit)
            WindowEvent::KeyboardInput {
                event:
                    KeyEvent {
                        physical_key: PhysicalKey::Code(_),
                        state: ElementState::Pressed,
                        ..
                    },
                ..
            } => {
                if !self.no_input_exit {
                    event_loop.exit();
                }
            }
            // Exit on mouse click (unless --no-input-exit)
            WindowEvent::MouseInput {
                state: ElementState::Pressed,
                ..
            } => {
                if !self.no_input_exit {
                    event_loop.exit();
                }
            }
            // Exit on mouse movement (screensaver behavior, unless --no-input-exit)
            WindowEvent::CursorMoved { .. } => {
                if !self.no_input_exit {
                    event_loop.exit();
                }
            }
            WindowEvent::Resized(physical_size) => {
                if let Some(state) = &mut self.state {
                    state.resize(physical_size);
                }
            }
            WindowEvent::CloseRequested => {
                event_loop.exit();
            }
            WindowEvent::RedrawRequested => {
                // Frame rate limiting
                let frame_time = std::time::Duration::from_secs_f64(1.0 / self.fps as f64);
                let elapsed = self.last_frame.elapsed();
                if elapsed < frame_time {
                    std::thread::sleep(frame_time - elapsed);
                }
                self.last_frame = std::time::Instant::now();

                if let Some(state) = &mut self.state {
                    match state.render() {
                        Ok(_) => {}
                        Err(wgpu::SurfaceError::Lost) => {
                            let size = winit::dpi::PhysicalSize::new(state.config.width, state.config.height);
                            state.resize(size);
                        }
                        Err(wgpu::SurfaceError::OutOfMemory) => event_loop.exit(),
                        Err(e) => eprintln!("{:?}", e),
                    }
                }
                if let Some(window) = &self.window {
                    window.request_redraw();
                }
            }
            _ => {}
        }
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        if let Some(window) = &self.window {
            window.request_redraw();
        }
    }
}

fn main() {
    let args = Args::parse();

    let event_loop = EventLoop::new().unwrap();
    event_loop.set_control_flow(ControlFlow::Poll);

    let mut app = App::new(args.fps, args.shader, args.no_input_exit);
    event_loop.run_app(&mut app).unwrap();
}
