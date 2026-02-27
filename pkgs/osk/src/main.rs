use std::os::fd::AsFd;
use std::os::unix::io::AsRawFd;
use tiny_skia::{Color, FillRule, Paint, PathBuilder, Pixmap, PixmapMut, Rect, Transform};
use wayland_client::protocol::wl_buffer::WlBuffer;
use wayland_client::protocol::wl_compositor::WlCompositor;
use wayland_client::protocol::wl_output::WlOutput;
use wayland_client::protocol::wl_pointer::{self, WlPointer};
use wayland_client::protocol::wl_registry;
use wayland_client::protocol::wl_seat::WlSeat;
use wayland_client::protocol::wl_shm::WlShm;
use wayland_client::protocol::wl_shm_pool::WlShmPool;
use wayland_client::protocol::wl_surface::WlSurface;
use wayland_client::protocol::wl_touch::{self, WlTouch};
use wayland_client::{delegate_noop, Connection, Dispatch, QueueHandle, WEnum};
use wayland_protocols_misc::zwp_input_method_v2::client::zwp_input_method_manager_v2::ZwpInputMethodManagerV2;
use wayland_protocols_misc::zwp_input_method_v2::client::zwp_input_method_v2::{self, ZwpInputMethodV2};
use wayland_protocols_misc::zwp_virtual_keyboard_v1::client::zwp_virtual_keyboard_manager_v1::ZwpVirtualKeyboardManagerV1;
use wayland_protocols_misc::zwp_virtual_keyboard_v1::client::zwp_virtual_keyboard_v1::ZwpVirtualKeyboardV1;
use wayland_protocols_wlr::layer_shell::v1::client::zwlr_layer_shell_v1::{Layer, ZwlrLayerShellV1};
use wayland_protocols_wlr::layer_shell::v1::client::zwlr_layer_surface_v1::{
    self, Anchor, ZwlrLayerSurfaceV1,
};

// Layout definitions — 3 layers: main, shift, symbols
// Each key: (label, scancode, width_units)
// Scancodes from linux/input-event-codes.h — these are AZERTY physical positions
// The XKB keymap (fr/azerty) maps them to the correct output characters

const KEY_1: u32 = 2;
const KEY_2: u32 = 3;
const KEY_3: u32 = 4;
const KEY_4: u32 = 5;
const KEY_5: u32 = 6;
const KEY_6: u32 = 7;
const KEY_7: u32 = 8;
const KEY_8: u32 = 9;
const KEY_9: u32 = 10;
const KEY_0: u32 = 11;
const KEY_Q: u32 = 16;
const KEY_W: u32 = 17;
const KEY_E: u32 = 18;
const KEY_R: u32 = 19;
const KEY_T: u32 = 20;
const KEY_Y: u32 = 21;
const KEY_U: u32 = 22;
const KEY_I: u32 = 23;
const KEY_O: u32 = 24;
const KEY_P: u32 = 25;
const KEY_A: u32 = 30;
const KEY_S: u32 = 31;
const KEY_D: u32 = 32;
const KEY_F: u32 = 33;
const KEY_G: u32 = 34;
const KEY_H: u32 = 35;
const KEY_J: u32 = 36;
const KEY_K: u32 = 37;
const KEY_L: u32 = 38;
const KEY_SEMICOLON: u32 = 39;
const KEY_Z: u32 = 44;
const KEY_X: u32 = 45;
const KEY_C: u32 = 46;
const KEY_V: u32 = 47;
const KEY_B: u32 = 48;
const KEY_N: u32 = 49;
const KEY_LEFTSHIFT: u32 = 42;
const KEY_BACKSPACE: u32 = 14;
const KEY_SPACE: u32 = 57;
const KEY_ENTER: u32 = 28;
const KEY_COMMA: u32 = 51;
const KEY_DOT: u32 = 52;
const KEY_LEFTMETA: u32 = 125;
const KEY_MINUS: u32 = 12;
const KEY_EQUAL: u32 = 13;
const KEY_BACKSLASH: u32 = 43;
const KEY_SLASH: u32 = 53;

// Special action codes (not real scancodes)
const ACTION_SHIFT: u32 = 0xF001;
const ACTION_SYM: u32 = 0xF002;
const ACTION_ABC: u32 = 0xF003;

struct KeyDef {
    label: &'static str,
    code: u32,
    width: f32, // in units (1.0 = standard key)
}

impl KeyDef {
    const fn new(label: &'static str, code: u32, width: f32) -> Self {
        Self { label, code, width }
    }
}

type Row = &'static [KeyDef];
type LayoutLayer = &'static [Row];

// Main AZERTY layer
static MAIN_R0: &[KeyDef] = &[
    KeyDef::new("a", KEY_Q, 1.0),
    KeyDef::new("z", KEY_W, 1.0),
    KeyDef::new("e", KEY_E, 1.0),
    KeyDef::new("r", KEY_R, 1.0),
    KeyDef::new("t", KEY_T, 1.0),
    KeyDef::new("y", KEY_Y, 1.0),
    KeyDef::new("u", KEY_U, 1.0),
    KeyDef::new("i", KEY_I, 1.0),
    KeyDef::new("o", KEY_O, 1.0),
    KeyDef::new("p", KEY_P, 1.0),
];
static MAIN_R1: &[KeyDef] = &[
    KeyDef::new("q", KEY_A, 1.0),
    KeyDef::new("s", KEY_S, 1.0),
    KeyDef::new("d", KEY_D, 1.0),
    KeyDef::new("f", KEY_F, 1.0),
    KeyDef::new("g", KEY_G, 1.0),
    KeyDef::new("h", KEY_H, 1.0),
    KeyDef::new("j", KEY_J, 1.0),
    KeyDef::new("k", KEY_K, 1.0),
    KeyDef::new("l", KEY_L, 1.0),
    KeyDef::new("m", KEY_SEMICOLON, 1.0),
];
static MAIN_R2: &[KeyDef] = &[
    KeyDef::new("⇧", ACTION_SHIFT, 1.5),
    KeyDef::new("w", KEY_Z, 1.0),
    KeyDef::new("x", KEY_X, 1.0),
    KeyDef::new("c", KEY_C, 1.0),
    KeyDef::new("v", KEY_V, 1.0),
    KeyDef::new("b", KEY_B, 1.0),
    KeyDef::new("n", KEY_N, 1.0),
    KeyDef::new("⌫", KEY_BACKSPACE, 1.5),
];
static MAIN_R3: &[KeyDef] = &[
    KeyDef::new("?123", ACTION_SYM, 1.5),
    KeyDef::new("Super", KEY_LEFTMETA, 1.0),
    KeyDef::new(",", KEY_COMMA, 1.0),
    KeyDef::new(" ", KEY_SPACE, 3.0),
    KeyDef::new(".", KEY_DOT, 1.0),
    KeyDef::new("⏎", KEY_ENTER, 1.5),
];
static MAIN_LAYER: &[Row] = &[&*MAIN_R0, &*MAIN_R1, &*MAIN_R2, &*MAIN_R3];

// Shift layer
static SHIFT_R0: &[KeyDef] = &[
    KeyDef::new("A", KEY_Q, 1.0),
    KeyDef::new("Z", KEY_W, 1.0),
    KeyDef::new("E", KEY_E, 1.0),
    KeyDef::new("R", KEY_R, 1.0),
    KeyDef::new("T", KEY_T, 1.0),
    KeyDef::new("Y", KEY_Y, 1.0),
    KeyDef::new("U", KEY_U, 1.0),
    KeyDef::new("I", KEY_I, 1.0),
    KeyDef::new("O", KEY_O, 1.0),
    KeyDef::new("P", KEY_P, 1.0),
];
static SHIFT_R1: &[KeyDef] = &[
    KeyDef::new("Q", KEY_A, 1.0),
    KeyDef::new("S", KEY_S, 1.0),
    KeyDef::new("D", KEY_D, 1.0),
    KeyDef::new("F", KEY_F, 1.0),
    KeyDef::new("G", KEY_G, 1.0),
    KeyDef::new("H", KEY_H, 1.0),
    KeyDef::new("J", KEY_J, 1.0),
    KeyDef::new("K", KEY_K, 1.0),
    KeyDef::new("L", KEY_L, 1.0),
    KeyDef::new("M", KEY_SEMICOLON, 1.0),
];
static SHIFT_R2: &[KeyDef] = &[
    KeyDef::new("⇧", ACTION_SHIFT, 1.5),
    KeyDef::new("W", KEY_Z, 1.0),
    KeyDef::new("X", KEY_X, 1.0),
    KeyDef::new("C", KEY_C, 1.0),
    KeyDef::new("V", KEY_V, 1.0),
    KeyDef::new("B", KEY_B, 1.0),
    KeyDef::new("N", KEY_N, 1.0),
    KeyDef::new("⌫", KEY_BACKSPACE, 1.5),
];
static SHIFT_R3: &[KeyDef] = &[
    KeyDef::new("?123", ACTION_SYM, 1.5),
    KeyDef::new("Super", KEY_LEFTMETA, 1.0),
    KeyDef::new(",", KEY_COMMA, 1.0),
    KeyDef::new(" ", KEY_SPACE, 3.0),
    KeyDef::new(".", KEY_DOT, 1.0),
    KeyDef::new("⏎", KEY_ENTER, 1.5),
];
static SHIFT_LAYER: &[Row] = &[&*SHIFT_R0, &*SHIFT_R1, &*SHIFT_R2, &*SHIFT_R3];

// Symbols layer — uses number row scancodes + shifted positions
static SYM_R0: &[KeyDef] = &[
    KeyDef::new("1", KEY_1, 1.0),
    KeyDef::new("2", KEY_2, 1.0),
    KeyDef::new("3", KEY_3, 1.0),
    KeyDef::new("4", KEY_4, 1.0),
    KeyDef::new("5", KEY_5, 1.0),
    KeyDef::new("6", KEY_6, 1.0),
    KeyDef::new("7", KEY_7, 1.0),
    KeyDef::new("8", KEY_8, 1.0),
    KeyDef::new("9", KEY_9, 1.0),
    KeyDef::new("0", KEY_0, 1.0),
];
static SYM_R1: &[KeyDef] = &[
    KeyDef::new("@", KEY_0, 1.0),   // AltGr+0 on AZERTY
    KeyDef::new("#", KEY_3, 1.0),   // AltGr+3
    KeyDef::new("€", KEY_E, 1.0),   // AltGr+E
    KeyDef::new("_", KEY_8, 1.0),   // 8 key unshifted = _
    KeyDef::new("&", KEY_1, 1.0),   // 1 key unshifted = &
    KeyDef::new("-", KEY_6, 1.0),   // 6 key unshifted = -
    KeyDef::new("+", KEY_EQUAL, 1.0),
    KeyDef::new("(", KEY_5, 1.0),   // 5 key unshifted = (
    KeyDef::new(")", KEY_MINUS, 1.0),
    KeyDef::new("/", KEY_SLASH, 1.0),
];
static SYM_R2: &[KeyDef] = &[
    KeyDef::new("?123", ACTION_SYM, 1.5),
    KeyDef::new("*", KEY_BACKSLASH, 1.0),
    KeyDef::new("\"", KEY_3, 1.0),
    KeyDef::new("'", KEY_4, 1.0),
    KeyDef::new(":", KEY_DOT, 1.0),
    KeyDef::new(";", KEY_COMMA, 1.0),
    KeyDef::new("!", KEY_SLASH, 1.0),
    KeyDef::new("⌫", KEY_BACKSPACE, 1.5),
];
static SYM_R3: &[KeyDef] = &[
    KeyDef::new("ABC", ACTION_ABC, 1.5),
    KeyDef::new("Super", KEY_LEFTMETA, 1.0),
    KeyDef::new(",", KEY_COMMA, 1.0),
    KeyDef::new(" ", KEY_SPACE, 3.0),
    KeyDef::new(".", KEY_DOT, 1.0),
    KeyDef::new("⏎", KEY_ENTER, 1.5),
];
static SYM_LAYER: &[Row] = &[&*SYM_R0, &*SYM_R1, &*SYM_R2, &*SYM_R3];

static LAYERS: &[LayoutLayer] = &[MAIN_LAYER, SHIFT_LAYER, SYM_LAYER];

const KB_HEIGHT: u32 = 260;
const KEY_MARGIN: f32 = 3.0;
const KEY_RADIUS: f32 = 6.0;

fn bg_color() -> Color { Color::from_rgba8(30, 30, 30, 230) }
fn key_color() -> Color { Color::from_rgba8(60, 60, 60, 255) }
fn key_pressed_color() -> Color { Color::from_rgba8(100, 100, 100, 255) }
fn special_key_color() -> Color { Color::from_rgba8(45, 45, 45, 255) }
fn text_color() -> Color { Color::from_rgba8(220, 220, 220, 255) }

fn is_special_key(code: u32) -> bool {
    matches!(
        code,
        ACTION_SHIFT
            | ACTION_SYM
            | ACTION_ABC
            | KEY_BACKSPACE
            | KEY_ENTER
            | KEY_LEFTMETA
            | KEY_LEFTSHIFT
    )
}

// Computed key rectangle for hit-testing
struct KeyRect {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    code: u32,
    row: usize,
    col: usize,
}

fn compute_key_rects(width: u32, layer_idx: usize) -> Vec<KeyRect> {
    let layer = LAYERS[layer_idx];
    let rows = layer.len();
    let row_height = KB_HEIGHT as f32 / rows as f32;
    let mut rects = Vec::new();

    for (ri, row) in layer.iter().enumerate() {
        let total_units: f32 = row.iter().map(|k| k.width).sum();
        let unit_width = width as f32 / total_units;
        let mut x = 0.0;
        let y = ri as f32 * row_height;

        for (ci, key) in row.iter().enumerate() {
            let w = key.width * unit_width;
            rects.push(KeyRect {
                x,
                y,
                w,
                h: row_height,
                code: key.code,
                row: ri,
                col: ci,
            });
            x += w;
        }
    }
    rects
}

fn hit_test(rects: &[KeyRect], px: f32, py: f32) -> Option<usize> {
    rects
        .iter()
        .position(|r| px >= r.x && px < r.x + r.w && py >= r.y && py < r.y + r.h)
}

// Font rendering
struct FontRenderer {
    font: fontdue::Font,
}

impl FontRenderer {
    fn new() -> Self {
        let font_path = std::env::var("OSK_FONT").unwrap_or_else(|_| {
            // Search common NixOS/Linux font locations
            for path in &[
                "/run/current-system/sw/share/X11/fonts/DejaVuSans.ttf",
                "/run/current-system/sw/share/fonts/truetype/DejaVuSans.ttf",
            ] {
                if std::path::Path::new(path).exists() {
                    return path.to_string();
                }
            }
            // Glob for any DejaVuSans in nix store
            for entry in std::fs::read_dir("/run/current-system/sw/share/X11/fonts/").into_iter().flatten() {
                if let Ok(e) = entry {
                    if e.file_name().to_str().map_or(false, |n| n == "DejaVuSans.ttf") {
                        return e.path().to_string_lossy().to_string();
                    }
                }
            }
            panic!("no font found — set OSK_FONT env var");
        });
        let font_data = std::fs::read(&font_path).expect(&format!("failed to read font: {}", font_path));
        let settings = fontdue::FontSettings::default();
        let font =
            fontdue::Font::from_bytes(font_data, settings).expect("failed to parse font");
        Self { font }
    }

    fn render_centered(&self, pixmap: &mut Pixmap, text: &str, cx: f32, cy: f32, size: f32) {
        // Measure total width
        let mut total_w = 0.0f32;
        let metrics: Vec<_> = text
            .chars()
            .map(|ch| {
                let (m, _) = self.font.rasterize(ch, size);
                total_w += m.advance_width;
                m
            })
            .collect();

        let bitmaps: Vec<_> = text
            .chars()
            .map(|ch| {
                let (_, bmp) = self.font.rasterize(ch, size);
                bmp
            })
            .collect();

        let start_x = cx - total_w / 2.0;
        // Use first char metrics for baseline estimate
        let ascent = size * 0.75;
        let baseline_y = cy + ascent / 2.0;

        let mut pen_x = start_x;
        for (i, (m, bmp)) in metrics.iter().zip(bitmaps.iter()).enumerate() {
            let _ = i;
            let gx = pen_x + m.xmin as f32;
            let gy = baseline_y - m.height as f32 - m.ymin as f32;

            for row in 0..m.height {
                for col in 0..m.width {
                    let alpha = bmp[row * m.width + col];
                    if alpha == 0 {
                        continue;
                    }
                    let px = (gx + col as f32) as i32;
                    let py = (gy + row as f32) as i32;
                    if px < 0
                        || py < 0
                        || px >= pixmap.width() as i32
                        || py >= pixmap.height() as i32
                    {
                        continue;
                    }
                    let idx = (py as u32 * pixmap.width() + px as u32) as usize * 4;
                    let data = pixmap.data_mut();
                    // Alpha blend
                    let a = alpha as f32 / 255.0;
                    let tc = text_color();
                    let sr = tc.red() * 255.0;
                    let sg = tc.green() * 255.0;
                    let sb = tc.blue() * 255.0;
                    data[idx] = (data[idx] as f32 * (1.0 - a) + sb * a) as u8; // B
                    data[idx + 1] = (data[idx + 1] as f32 * (1.0 - a) + sg * a) as u8; // G
                    data[idx + 2] = (data[idx + 2] as f32 * (1.0 - a) + sr * a) as u8; // R
                    data[idx + 3] = 255; // A
                }
            }
            pen_x += m.advance_width;
        }
    }
}

fn draw_rounded_rect(pixmap: &mut Pixmap, x: f32, y: f32, w: f32, h: f32, r: f32, color: Color) {
    let rect = Rect::from_xywh(x, y, w, h);
    if rect.is_none() {
        return;
    }

    let mut pb = PathBuilder::new();
    let x1 = x;
    let y1 = y;
    let x2 = x + w;
    let y2 = y + h;
    let r = r.min(w / 2.0).min(h / 2.0);

    pb.move_to(x1 + r, y1);
    pb.line_to(x2 - r, y1);
    pb.quad_to(x2, y1, x2, y1 + r);
    pb.line_to(x2, y2 - r);
    pb.quad_to(x2, y2, x2 - r, y2);
    pb.line_to(x1 + r, y2);
    pb.quad_to(x1, y2, x1, y2 - r);
    pb.line_to(x1, y1 + r);
    pb.quad_to(x1, y1, x1 + r, y1);
    pb.close();

    let path = pb.finish().unwrap();
    let mut paint = Paint::default();
    paint.set_color(color);
    paint.anti_alias = true;
    pixmap.fill_path(&path, &paint, FillRule::Winding, Transform::identity(), None);
}

fn render_keyboard(
    pixmap: &mut Pixmap,
    rects: &[KeyRect],
    layer_idx: usize,
    pressed_key: Option<usize>,
    font: &FontRenderer,
) {
    // Fill background
    pixmap.fill(bg_color());

    let layer = LAYERS[layer_idx];

    for (i, kr) in rects.iter().enumerate() {
        let key_def = &layer[kr.row][kr.col];
        let color = if Some(i) == pressed_key {
            key_pressed_color()
        } else if is_special_key(kr.code) {
            special_key_color()
        } else {
            key_color()
        };

        draw_rounded_rect(
            pixmap,
            kr.x + KEY_MARGIN,
            kr.y + KEY_MARGIN,
            kr.w - KEY_MARGIN * 2.0,
            kr.h - KEY_MARGIN * 2.0,
            KEY_RADIUS,
            color,
        );

        let font_size = if key_def.label.len() > 3 { 14.0 } else { 20.0 };
        font.render_centered(
            pixmap,
            key_def.label,
            kr.x + kr.w / 2.0,
            kr.y + kr.h / 2.0,
            font_size,
        );
    }
}

// Wayland state
struct OskState {
    compositor: Option<WlCompositor>,
    shm: Option<WlShm>,
    layer_shell: Option<ZwlrLayerShellV1>,
    seat: Option<WlSeat>,
    vk_mgr: Option<ZwpVirtualKeyboardManagerV1>,
    im_mgr: Option<ZwpInputMethodManagerV2>,
    output: Option<WlOutput>,

    surface: Option<WlSurface>,
    layer_surface: Option<ZwlrLayerSurfaceV1>,
    vk: Option<ZwpVirtualKeyboardV1>,
    im: Option<ZwpInputMethodV2>,
    pointer: Option<WlPointer>,
    touch: Option<WlTouch>,
    configured: bool,
    width: u32,
    height: u32,

    visible: bool,
    auto_show_enabled: bool,
    current_layer: usize,
    shift_active: bool,
    pressed_key: Option<usize>,
    key_rects: Vec<KeyRect>,

    shm_pool: Option<WlShmPool>,
    shm_fd: Option<std::os::unix::io::RawFd>,
    buffer: Option<WlBuffer>,
    pool_size: usize,

    font: FontRenderer,
    needs_redraw: bool,
    pending_show: bool,

    // Track pointer position for click handling
    pointer_x: f32,
    pointer_y: f32,

    // Track active touch points for multi-touch
    touch_points: std::collections::HashMap<i32, (f64, f64)>,
}

impl OskState {
    fn new() -> Self {
        Self {
            compositor: None,
            shm: None,
            layer_shell: None,
            seat: None,
            vk_mgr: None,
            im_mgr: None,
            output: None,
            surface: None,
            layer_surface: None,
            vk: None,
            im: None,
            pointer: None,
            touch: None,
            configured: false,
            width: 0,
            height: KB_HEIGHT,
            visible: false,
            auto_show_enabled: true,
            current_layer: 0,
            shift_active: false,
            pressed_key: None,
            key_rects: Vec::new(),
            shm_pool: None,
            shm_fd: None,
            buffer: None,
            pool_size: 0,
            font: FontRenderer::new(),
            needs_redraw: false,
            pending_show: false,
            pointer_x: 0.0,
            pointer_y: 0.0,
            touch_points: std::collections::HashMap::new(),
        }
    }

    fn setup_surface(&mut self, qh: &QueueHandle<Self>) {
        let compositor = self.compositor.as_ref().unwrap();
        let layer_shell = self.layer_shell.as_ref().unwrap();

        let surface = compositor.create_surface(qh, ());
        let layer_surface = layer_shell.get_layer_surface(
            &surface,
            self.output.as_ref(),
            Layer::Overlay,
            "osk".to_string(),
            qh,
            (),
        );

        layer_surface.set_anchor(Anchor::Bottom | Anchor::Left | Anchor::Right);
        layer_surface.set_size(0, self.height);
        layer_surface.set_exclusive_zone(self.height as i32);
        layer_surface.set_keyboard_interactivity(
            zwlr_layer_surface_v1::KeyboardInteractivity::None,
        );

        surface.commit();

        self.surface = Some(surface);
        self.layer_surface = Some(layer_surface);
    }

    fn setup_virtual_keyboard(&mut self, qh: &QueueHandle<Self>) {
        let vk_mgr = match self.vk_mgr.as_ref() {
            Some(m) => m,
            None => {
                eprintln!("osk: virtual keyboard manager not available");
                return;
            }
        };
        let seat = self.seat.as_ref().unwrap();
        let vk = vk_mgr.create_virtual_keyboard(seat, qh, ());

        // Compile and upload fr(azerty) keymap
        let keymap_str = std::ffi::CString::new(
            "xkb_keymap {\n\
             \txkb_keycodes { include \"evdev+aliases(azerty)\" };\n\
             \txkb_types { include \"complete\" };\n\
             \txkb_compat { include \"complete\" };\n\
             \txkb_symbols { include \"pc+fr(azerty)+inet(evdev)\" };\n\
             \txkb_geometry { include \"pc(pc105)\" };\n\
             };\n",
        )
        .unwrap();

        let ctx = xkbcommon::xkb::Context::new(xkbcommon::xkb::CONTEXT_NO_FLAGS);
        let keymap = xkbcommon::xkb::Keymap::new_from_string(
            &ctx,
            keymap_str.to_str().unwrap().to_string(),
            xkbcommon::xkb::KEYMAP_FORMAT_TEXT_V1,
            xkbcommon::xkb::KEYMAP_COMPILE_NO_FLAGS,
        )
        .expect("failed to compile AZERTY keymap");

        let keymap_text = keymap
            .get_as_string(xkbcommon::xkb::KEYMAP_FORMAT_TEXT_V1);
        let keymap_bytes = keymap_text.as_bytes();
        let keymap_size = keymap_bytes.len() + 1; // null terminated

        // Create memfd for keymap
        let name = std::ffi::CString::new("osk-keymap").unwrap();
        let fd = unsafe { libc::memfd_create(name.as_ptr(), libc::MFD_CLOEXEC) };
        assert!(fd >= 0, "memfd_create failed");
        unsafe {
            libc::ftruncate(fd, keymap_size as libc::off_t);
            let ptr = libc::mmap(
                std::ptr::null_mut(),
                keymap_size,
                libc::PROT_WRITE,
                libc::MAP_SHARED,
                fd,
                0,
            );
            std::ptr::copy_nonoverlapping(keymap_bytes.as_ptr(), ptr as *mut u8, keymap_bytes.len());
            // null terminator
            *(ptr as *mut u8).add(keymap_bytes.len()) = 0;
            libc::munmap(ptr, keymap_size);
        }

        vk.keymap(1, unsafe { std::os::fd::BorrowedFd::borrow_raw(fd) }, keymap_size as u32); // 1 = XKB_V1

        self.vk = Some(vk);
    }

    fn setup_input_method(&mut self, qh: &QueueHandle<Self>) {
        if let Some(im_mgr) = self.im_mgr.as_ref() {
            let seat = self.seat.as_ref().unwrap();
            let im = im_mgr.get_input_method(seat, qh, ());
            self.im = Some(im);
        }
    }

    fn show(&mut self, qh: &QueueHandle<Self>) {
        if self.visible {
            return;
        }
        self.visible = true;
        if self.surface.is_none() {
            self.setup_surface(qh);
        }
    }

    fn hide(&mut self) {
        if !self.visible {
            return;
        }
        self.visible = false;
        if let Some(ls) = self.layer_surface.take() {
            ls.destroy();
        }
        if let Some(s) = self.surface.take() {
            s.destroy();
        }
        if let Some(b) = self.buffer.take() {
            b.destroy();
        }
        if let Some(p) = self.shm_pool.take() {
            p.destroy();
        }
        self.shm_pool = None;
        self.shm_fd = None;
        self.buffer = None;
        self.pool_size = 0;
        self.configured = false;
    }

    fn draw(&mut self, qh: &QueueHandle<Self>) {
        if !self.visible || !self.configured || self.width == 0 {
            return;
        }

        let stride = self.width * 4;
        let size = (stride * self.height) as usize;

        // Recreate pool if size changed
        if self.pool_size != size {
            if let Some(b) = self.buffer.take() {
                b.destroy();
            }
            if let Some(p) = self.shm_pool.take() {
                p.destroy();
            }

            let name = std::ffi::CString::new("osk-shm").unwrap();
            let fd = unsafe { libc::memfd_create(name.as_ptr(), libc::MFD_CLOEXEC) };
            assert!(fd >= 0);
            unsafe {
                libc::ftruncate(fd, size as libc::off_t);
            }

            let shm = self.shm.as_ref().unwrap();
            let pool =
                shm.create_pool(unsafe { std::os::fd::BorrowedFd::borrow_raw(fd) }, size as i32, qh, ());

            let buffer = pool.create_buffer(
                0,
                self.width as i32,
                self.height as i32,
                stride as i32,
                wayland_client::protocol::wl_shm::Format::Argb8888,
                qh,
                (),
            );

            self.shm_pool = Some(pool);
            self.shm_fd = Some(fd);
            self.buffer = Some(buffer);
            self.pool_size = size;
        }

        // Map and render
        let fd = self.shm_fd.unwrap();
        let size = self.pool_size;
        let ptr = unsafe {
            libc::mmap(
                std::ptr::null_mut(),
                size,
                libc::PROT_READ | libc::PROT_WRITE,
                libc::MAP_SHARED,
                fd,
                0,
            )
        };
        assert_ne!(ptr, libc::MAP_FAILED);

        let data = unsafe { std::slice::from_raw_parts_mut(ptr as *mut u8, size) };

        // Render to pixmap
        self.key_rects = compute_key_rects(self.width, self.current_layer);
        let pixmap = PixmapMut::from_bytes(data, self.width, self.height).unwrap();
        let mut owned_pixmap = pixmap.to_owned();
        render_keyboard(
            &mut owned_pixmap,
            &self.key_rects,
            self.current_layer,
            self.pressed_key,
            &self.font,
        );
        data.copy_from_slice(owned_pixmap.data());

        unsafe {
            libc::munmap(ptr, size);
        }

        let surface = self.surface.as_ref().unwrap();
        let buffer = self.buffer.as_ref().unwrap();
        surface.attach(Some(buffer), 0, 0);
        surface.damage_buffer(0, 0, self.width as i32, self.height as i32);
        surface.commit();

        self.needs_redraw = false;
    }

    fn send_key(&self, scancode: u32, pressed: bool) {
        if let Some(vk) = self.vk.as_ref() {
            let time = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as u32;
            let state = if pressed { 1 } else { 0 };
            vk.key(time, scancode, state);
        }
    }

    fn send_modifier(&self, mods_depressed: u32) {
        if let Some(vk) = self.vk.as_ref() {
            vk.modifiers(mods_depressed, 0, 0, 0);
        }
    }

    fn handle_key_press(&mut self, key_idx: usize, _qh: &QueueHandle<Self>) {
        let kr = &self.key_rects[key_idx];
        let code = kr.code;

        match code {
            ACTION_SHIFT => {
                self.shift_active = !self.shift_active;
                self.current_layer = if self.shift_active { 1 } else { 0 };
                // Send shift modifier state
                let mods = if self.shift_active { 1 } else { 0 }; // MOD_SHIFT = 1
                self.send_modifier(mods);
                self.needs_redraw = true;
            }
            ACTION_SYM => {
                self.current_layer = 2;
                self.shift_active = false;
                self.send_modifier(0);
                self.needs_redraw = true;
            }
            ACTION_ABC => {
                self.current_layer = 0;
                self.shift_active = false;
                self.send_modifier(0);
                self.needs_redraw = true;
            }
            _ => {
                self.pressed_key = Some(key_idx);
                self.needs_redraw = true;
                // Send shift state before key if shift is active
                if self.shift_active {
                    self.send_modifier(1);
                }
                self.send_key(code, true);
            }
        }
    }

    fn handle_key_release(&mut self, _qh: &QueueHandle<Self>) {
        if let Some(idx) = self.pressed_key.take() {
            let code = self.key_rects[idx].code;
            if !matches!(code, ACTION_SHIFT | ACTION_SYM | ACTION_ABC) {
                self.send_key(code, false);
                // Return to main layer after typing with shift (one-shot)
                if self.shift_active && code != KEY_BACKSPACE && code != KEY_SPACE && code != KEY_ENTER {
                    self.shift_active = false;
                    self.current_layer = 0;
                    self.send_modifier(0);
                }
            }
            self.needs_redraw = true;
        }
    }
}

// Wayland dispatch implementations

impl Dispatch<wl_registry::WlRegistry, ()> for OskState {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        if let wl_registry::Event::Global {
            name,
            interface,
            version,
        } = event
        {
            match interface.as_str() {
                "wl_compositor" => {
                    state.compositor =
                        Some(registry.bind::<WlCompositor, _, _>(name, version.min(6), qh, ()));
                }
                "wl_shm" => {
                    state.shm =
                        Some(registry.bind::<WlShm, _, _>(name, version.min(1), qh, ()));
                }
                "zwlr_layer_shell_v1" => {
                    state.layer_shell = Some(
                        registry.bind::<ZwlrLayerShellV1, _, _>(name, version.min(4), qh, ()),
                    );
                }
                "wl_seat" => {
                    state.seat =
                        Some(registry.bind::<WlSeat, _, _>(name, version.min(9), qh, ()));
                }
                "zwp_virtual_keyboard_manager_v1" => {
                    state.vk_mgr = Some(
                        registry.bind::<ZwpVirtualKeyboardManagerV1, _, _>(
                            name,
                            version.min(1),
                            qh,
                            (),
                        ),
                    );
                }
                "zwp_input_method_manager_v2" => {
                    state.im_mgr = Some(
                        registry.bind::<ZwpInputMethodManagerV2, _, _>(
                            name,
                            version.min(1),
                            qh,
                            (),
                        ),
                    );
                }
                "wl_output" => {
                    if state.output.is_none() {
                        state.output = Some(
                            registry.bind::<WlOutput, _, _>(name, version.min(4), qh, ()),
                        );
                    }
                }
                _ => {}
            }
        }
    }
}

impl Dispatch<ZwlrLayerSurfaceV1, ()> for OskState {
    fn event(
        state: &mut Self,
        surface: &ZwlrLayerSurfaceV1,
        event: zwlr_layer_surface_v1::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            zwlr_layer_surface_v1::Event::Configure {
                serial,
                width,
                height,
            } => {
                surface.ack_configure(serial);
                state.width = width;
                state.height = if height > 0 { height } else { KB_HEIGHT };
                state.configured = true;
                state.needs_redraw = true;
                state.draw(qh);
            }
            zwlr_layer_surface_v1::Event::Closed => {
                state.hide();
            }
            _ => {}
        }
    }
}

impl Dispatch<WlSeat, ()> for OskState {
    fn event(
        state: &mut Self,
        seat: &WlSeat,
        event: wayland_client::protocol::wl_seat::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        if let wayland_client::protocol::wl_seat::Event::Capabilities {
            capabilities: WEnum::Value(caps),
        } = event
        {
            if caps.contains(wayland_client::protocol::wl_seat::Capability::Pointer)
                && state.pointer.is_none()
            {
                state.pointer = Some(seat.get_pointer(qh, ()));
            }
            if caps.contains(wayland_client::protocol::wl_seat::Capability::Touch)
                && state.touch.is_none()
            {
                state.touch = Some(seat.get_touch(qh, ()));
            }
        }
    }
}

impl Dispatch<WlPointer, ()> for OskState {
    fn event(
        state: &mut Self,
        _: &WlPointer,
        event: wl_pointer::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            wl_pointer::Event::Button {
                button,
                state: WEnum::Value(button_state),
                ..
            } => {
                if button == 0x110 {
                    match button_state {
                        wl_pointer::ButtonState::Pressed => {
                            if let Some(idx) = hit_test(&state.key_rects, state.pointer_x, state.pointer_y) {
                                state.handle_key_press(idx, qh);
                                if state.needs_redraw {
                                    state.key_rects = compute_key_rects(state.width, state.current_layer);
                                    state.draw(qh);
                                }
                            }
                        }
                        wl_pointer::ButtonState::Released => {
                            state.handle_key_release(qh);
                            if state.needs_redraw {
                                state.draw(qh);
                            }
                        }
                        _ => {}
                    }
                }
            }
            wl_pointer::Event::Motion {
                surface_x,
                surface_y,
                ..
            } => {
                state.pointer_x = surface_x as f32;
                state.pointer_y = surface_y as f32;
            }
            _ => {}
        }
    }
}

impl Dispatch<WlTouch, ()> for OskState {
    fn event(
        state: &mut Self,
        _: &WlTouch,
        event: wl_touch::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            wl_touch::Event::Down { id, x, y, .. } => {
                state.touch_points.insert(id, (x, y));
                if let Some(idx) = hit_test(&state.key_rects, x as f32, y as f32) {
                    state.handle_key_press(idx, qh);
                    if state.needs_redraw {
                        state.key_rects = compute_key_rects(state.width, state.current_layer);
                        state.draw(qh);
                    }
                }
            }
            wl_touch::Event::Up { id, .. } => {
                state.touch_points.remove(&id);
                state.handle_key_release(qh);
                if state.needs_redraw {
                    state.draw(qh);
                }
            }
            wl_touch::Event::Motion { id, x, y, .. } => {
                state.touch_points.insert(id, (x, y));
            }
            _ => {}
        }
    }
}

impl Dispatch<ZwpInputMethodV2, ()> for OskState {
    fn event(
        state: &mut Self,
        _: &ZwpInputMethodV2,
        event: zwp_input_method_v2::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            zwp_input_method_v2::Event::Activate => {
                if state.auto_show_enabled {
                    state.show(qh);
                }
            }
            zwp_input_method_v2::Event::Deactivate => {
                if state.auto_show_enabled {
                    state.hide();
                }
            }
            _ => {}
        }
    }
}

impl Dispatch<ZwpVirtualKeyboardV1, ()> for OskState {
    fn event(_: &mut Self, _: &ZwpVirtualKeyboardV1, _: <ZwpVirtualKeyboardV1 as wayland_client::Proxy>::Event, _: &(), _: &Connection, _: &QueueHandle<Self>) {}
}

// Noop dispatches for protocols that don't need event handling
delegate_noop!(OskState: ignore WlCompositor);
delegate_noop!(OskState: ignore WlShm);
delegate_noop!(OskState: ignore WlShmPool);
delegate_noop!(OskState: ignore WlBuffer);
delegate_noop!(OskState: ignore WlSurface);
delegate_noop!(OskState: ignore WlOutput);
delegate_noop!(OskState: ignore ZwlrLayerShellV1);
delegate_noop!(OskState: ignore ZwpVirtualKeyboardManagerV1);
delegate_noop!(OskState: ignore ZwpInputMethodManagerV2);

fn main() {
    let start_hidden = std::env::args().any(|a| a == "--hidden");

    let conn = Connection::connect_to_env().expect("failed to connect to Wayland");
    let display = conn.display();

    let mut event_queue = conn.new_event_queue::<OskState>();
    let qh = event_queue.handle();

    let mut state = OskState::new();

    display.get_registry(&qh, ());
    event_queue.roundtrip(&mut state).unwrap();

    // Setup virtual keyboard + input method
    state.setup_virtual_keyboard(&qh);
    state.setup_input_method(&qh);

    if !start_hidden {
        state.show(&qh);
    }

    event_queue.roundtrip(&mut state).unwrap();

    // Setup signal pipe for SIGUSR1/SIGUSR2
    let (sig_read, sig_write) = nix::unistd::pipe().expect("pipe failed");
    // Make write end non-blocking
    nix::fcntl::fcntl(sig_write.as_raw_fd(), nix::fcntl::FcntlArg::F_SETFL(nix::fcntl::OFlag::O_NONBLOCK)).ok();

    static SIG_WRITE_FD: std::sync::atomic::AtomicI32 = std::sync::atomic::AtomicI32::new(-1);
    SIG_WRITE_FD.store(sig_write.as_raw_fd(), std::sync::atomic::Ordering::Relaxed);

    extern "C" fn sig_handler(sig: libc::c_int) {
        let fd = SIG_WRITE_FD.load(std::sync::atomic::Ordering::Relaxed);
        if fd >= 0 {
            let byte = sig as u8;
            unsafe { libc::write(fd, &byte as *const u8 as *const libc::c_void, 1) };
        }
    }

    unsafe {
        libc::signal(libc::SIGUSR1, sig_handler as libc::sighandler_t);
        libc::signal(libc::SIGUSR2, sig_handler as libc::sighandler_t);
    }

    // Main event loop using poll
    let wl_fd = conn.as_fd().as_raw_fd();
    let sig_fd = sig_read.as_raw_fd();

    loop {
        // Flush outgoing wayland requests
        if let Err(e) = conn.flush() {
            eprintln!("osk: wayland flush error: {}", e);
            // Continue on WouldBlock, break on real errors
        }

        // Poll both wayland fd and signal pipe
        let mut fds = [
            libc::pollfd { fd: wl_fd, events: libc::POLLIN, revents: 0 },
            libc::pollfd { fd: sig_fd, events: libc::POLLIN, revents: 0 },
        ];

        let ret = unsafe { libc::poll(fds.as_mut_ptr(), 2, -1) };
        if ret < 0 {
            let err = std::io::Error::last_os_error();
            if err.kind() == std::io::ErrorKind::Interrupted {
                continue;
            }
            eprintln!("osk: poll error: {}", err);
            break;
        }

        // Handle signals
        if fds[1].revents & libc::POLLIN != 0 {
            let mut buf = [0u8; 16];
            let n = unsafe { libc::read(sig_read.as_raw_fd(), buf.as_mut_ptr() as *mut libc::c_void, buf.len()) };
            let n = if n > 0 { n as usize } else { 0 };
            for &byte in &buf[..n] {
                match byte as i32 {
                    libc::SIGUSR1 => {
                        state.auto_show_enabled = false;
                        state.hide();
                    }
                    libc::SIGUSR2 => {
                        state.auto_show_enabled = true;
                        state.pending_show = true;
                    }
                    _ => {}
                }
            }
        }

        // Handle pending show (needs qh)
        if state.pending_show {
            state.pending_show = false;
            state.show(&qh);
        }

        // Dispatch wayland events
        if fds[0].revents & libc::POLLIN != 0 {
            if let Err(e) = event_queue.dispatch_pending(&mut state) {
                eprintln!("osk: wayland dispatch error: {}", e);
                break;
            }
            conn.prepare_read().unwrap().read().ok();
            event_queue.dispatch_pending(&mut state).ok();
        }

        // Handle pending show triggered by wayland events (input-method activate)
        if state.pending_show {
            state.pending_show = false;
            state.show(&qh);
        }

        // Redraw if needed
        if state.needs_redraw && state.visible && state.configured {
            state.draw(&qh);
        }
    }
}
