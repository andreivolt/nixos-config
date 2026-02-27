use std::os::fd::AsFd;
use std::os::unix::io::AsRawFd;
use tiny_skia::{Color, FillRule, Paint, PathBuilder, Pixmap, PixmapMut, Rect, Transform};
use wayland_client::protocol::wl_buffer::WlBuffer;
use wayland_client::protocol::wl_compositor::WlCompositor;
use wayland_client::protocol::wl_output::{self, WlOutput};
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

const KEY_LEFTBRACE: u32 = 26;  // dead circumflex ^ (dead key)
const KEY_RIGHTBRACE: u32 = 27; // $ on AZERTY
const KEY_APOSTROPHE: u32 = 40; // ù on AZERTY
const KEY_102ND: u32 = 86;      // < > on AZERTY

const KEY_LEFTCTRL: u32 = 29;
const KEY_LEFTALT: u32 = 56;
const KEY_TAB: u32 = 15;
const KEY_ESC: u32 = 1;
const KEY_UP: u32 = 103;
const KEY_DOWN: u32 = 108;
const KEY_LEFT: u32 = 105;
const KEY_RIGHT: u32 = 106;

// Special action codes (not real scancodes)
const ACTION_SHIFT: u32 = 0xF001;
const ACTION_SYM: u32 = 0xF002;
const ACTION_ABC: u32 = 0xF003;
const ACTION_CTRL: u32 = 0xF004;
const ACTION_ALT: u32 = 0xF005;
const ACTION_SUPER: u32 = 0xF006;

struct KeyDef {
    label: &'static str,
    code: u32,
    width: f32, // in units (1.0 = standard key)
    force_shift: bool, // send with Shift held regardless of current state
}

impl KeyDef {
    const fn new(label: &'static str, code: u32, width: f32) -> Self {
        Self { label, code, width, force_shift: false }
    }
    const fn shifted(label: &'static str, code: u32, width: f32) -> Self {
        Self { label, code, width, force_shift: true }
    }
}

type Row = &'static [KeyDef];
type LayoutLayer = &'static [Row];

// Number row — shared across all layers
// AZERTY: digits require Shift+number_key
static NUM_ROW: &[KeyDef] = &[
    KeyDef::shifted("1", KEY_1, 1.0),
    KeyDef::shifted("2", KEY_2, 1.0),
    KeyDef::shifted("3", KEY_3, 1.0),
    KeyDef::shifted("4", KEY_4, 1.0),
    KeyDef::shifted("5", KEY_5, 1.0),
    KeyDef::shifted("6", KEY_6, 1.0),
    KeyDef::shifted("7", KEY_7, 1.0),
    KeyDef::shifted("8", KEY_8, 1.0),
    KeyDef::shifted("9", KEY_9, 1.0),
    KeyDef::shifted("0", KEY_0, 1.0),
];

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
    KeyDef::new("?123", ACTION_SYM, 1.2),
    KeyDef::new("Ctrl", ACTION_CTRL, 1.0),
    KeyDef::new("Alt", ACTION_ALT, 1.0),
    KeyDef::new("Super", ACTION_SUPER, 1.0),
    KeyDef::new(",", KEY_COMMA, 0.8),
    KeyDef::new(" ", KEY_SPACE, 2.5),
    KeyDef::new(".", KEY_DOT, 0.8),
    KeyDef::new("←", KEY_LEFT, 0.8),
    KeyDef::new("→", KEY_RIGHT, 0.8),
    KeyDef::new("⏎", KEY_ENTER, 1.1),
];
static MAIN_LAYER: &[Row] = &[&*NUM_ROW, &*MAIN_R0, &*MAIN_R1, &*MAIN_R2, &*MAIN_R3];

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
    KeyDef::new("?123", ACTION_SYM, 1.2),
    KeyDef::new("Ctrl", ACTION_CTRL, 1.0),
    KeyDef::new("Alt", ACTION_ALT, 1.0),
    KeyDef::new("Super", ACTION_SUPER, 1.0),
    KeyDef::new(",", KEY_COMMA, 0.8),
    KeyDef::new(" ", KEY_SPACE, 2.5),
    KeyDef::new(".", KEY_DOT, 0.8),
    KeyDef::new("←", KEY_LEFT, 0.8),
    KeyDef::new("→", KEY_RIGHT, 0.8),
    KeyDef::new("⏎", KEY_ENTER, 1.1),
];
static SHIFT_LAYER: &[Row] = &[&*NUM_ROW, &*SHIFT_R0, &*SHIFT_R1, &*SHIFT_R2, &*SHIFT_R3];

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
    KeyDef::new("ABC", ACTION_ABC, 1.2),
    KeyDef::new("Ctrl", ACTION_CTRL, 1.0),
    KeyDef::new("Alt", ACTION_ALT, 1.0),
    KeyDef::new("Super", ACTION_SUPER, 1.0),
    KeyDef::new("Esc", KEY_ESC, 0.8),
    KeyDef::new(" ", KEY_SPACE, 2.5),
    KeyDef::new("Tab", KEY_TAB, 0.8),
    KeyDef::new("↑", KEY_UP, 0.8),
    KeyDef::new("↓", KEY_DOWN, 0.8),
    KeyDef::new("⏎", KEY_ENTER, 1.1),
];
static SYM_LAYER: &[Row] = &[&*NUM_ROW, &*SYM_R0, &*SYM_R1, &*SYM_R2, &*SYM_R3];

static LAYERS: &[LayoutLayer] = &[MAIN_LAYER, SHIFT_LAYER, SYM_LAYER];

const DEFAULT_KB_HEIGHT: u32 = 260;
const TARGET_KEY_HEIGHT_MM: f32 = 9.0;
const MIN_KEY_HEIGHT_MM: f32 = 7.0;
const MAX_KEY_HEIGHT_MM: f32 = 11.0;
const NUM_ROWS: u32 = 5;
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
            | ACTION_CTRL
            | ACTION_ALT
            | ACTION_SUPER
            | KEY_BACKSPACE
            | KEY_ENTER
            | KEY_LEFTMETA
            | KEY_LEFTSHIFT
            | KEY_UP
            | KEY_DOWN
            | KEY_LEFT
            | KEY_RIGHT
            | KEY_TAB
            | KEY_ESC
    )
}

#[derive(Clone, Copy, PartialEq)]
enum ModState {
    Off,
    OneShot,
    Locked,
}

// Long-press alternates
// Each step is (scancode, modifier_bitmask) — 1=Shift, 64=AltGr
// For dead key combos: send dead key, release, then send base key
struct Alternate {
    label: &'static str,
    steps: &'static [(u32, u32)],
}

// Dead circumflex: KEY_LEFTBRACE (no mod), then base key
// Dead diaeresis: Shift+KEY_LEFTBRACE, then base key
// AZERTY direct keys: à=KEY_0, é=KEY_2, è=KEY_7, ù=KEY_APOSTROPHE, ç=KEY_9
// AOSP/SwiftKey-style alternates for AZERTY French
// Accented chars first, then hint symbol (row 2/3 symbols, row 1 bracket/special)
// Modifier bitmasks: 1=Shift, 128=AltGr(Mod5)
// Dead circumflex: KEY_LEFTBRACE (no mod) then base
// Dead diaeresis: Shift+KEY_LEFTBRACE then base
fn get_alternates(label: &str) -> &'static [Alternate] {
    match label {
        // Row 1 — vowels with accents + symbol hints
        "a" | "A" => &[
            Alternate { label: "à", steps: &[(KEY_0, 0)] },
            Alternate { label: "â", steps: &[(KEY_LEFTBRACE, 0), (KEY_Q, 0)] },
            Alternate { label: "ä", steps: &[(KEY_LEFTBRACE, 1), (KEY_Q, 0)] },
            Alternate { label: "æ", steps: &[(KEY_Q, 128)] },
        ],
        "e" | "E" => &[
            Alternate { label: "é", steps: &[(KEY_2, 0)] },
            Alternate { label: "è", steps: &[(KEY_7, 0)] },
            Alternate { label: "ê", steps: &[(KEY_LEFTBRACE, 0), (KEY_E, 0)] },
            Alternate { label: "ë", steps: &[(KEY_LEFTBRACE, 1), (KEY_E, 0)] },
            Alternate { label: "€", steps: &[(KEY_E, 128)] },
        ],
        "i" | "I" => &[
            Alternate { label: "î", steps: &[(KEY_LEFTBRACE, 0), (KEY_I, 0)] },
            Alternate { label: "ï", steps: &[(KEY_LEFTBRACE, 1), (KEY_I, 0)] },
        ],
        "o" | "O" => &[
            Alternate { label: "ô", steps: &[(KEY_LEFTBRACE, 0), (KEY_O, 0)] },
            Alternate { label: "œ", steps: &[(KEY_O, 128)] },
            Alternate { label: "ö", steps: &[(KEY_LEFTBRACE, 1), (KEY_O, 0)] },
        ],
        "u" | "U" => &[
            Alternate { label: "ù", steps: &[(KEY_APOSTROPHE, 0)] },
            Alternate { label: "û", steps: &[(KEY_LEFTBRACE, 0), (KEY_U, 0)] },
            Alternate { label: "ü", steps: &[(KEY_LEFTBRACE, 1), (KEY_U, 0)] },
        ],
        "y" | "Y" => &[
            Alternate { label: "ÿ", steps: &[(KEY_LEFTBRACE, 1), (KEY_Y, 0)] },
        ],
        "r" | "R" => &[
            Alternate { label: "=", steps: &[(KEY_EQUAL, 0)] },
        ],
        "t" | "T" => &[
            Alternate { label: "[", steps: &[(KEY_5, 128)] },
        ],
        "p" | "P" => &[
            Alternate { label: "}", steps: &[(KEY_EQUAL, 128)] },
        ],
        "z" | "Z" => &[
            Alternate { label: "\\", steps: &[(KEY_8, 128)] },
        ],
        // Row 2 — hint symbols
        "q" | "Q" => &[
            Alternate { label: "@", steps: &[(KEY_0, 128)] },
        ],
        "s" | "S" => &[
            Alternate { label: "#", steps: &[(KEY_3, 128)] },
        ],
        "d" | "D" => &[
            Alternate { label: "$", steps: &[(KEY_RIGHTBRACE, 0)] },
        ],
        "f" | "F" => &[
            Alternate { label: "%", steps: &[(KEY_APOSTROPHE, 1)] },
        ],
        "g" | "G" => &[
            Alternate { label: "&", steps: &[(KEY_1, 0)] },
        ],
        "h" | "H" => &[
            Alternate { label: "-", steps: &[(KEY_6, 0)] },
        ],
        "j" | "J" => &[
            Alternate { label: "+", steps: &[(KEY_EQUAL, 1)] },
        ],
        "k" | "K" => &[
            Alternate { label: "(", steps: &[(KEY_5, 0)] },
        ],
        "l" | "L" => &[
            Alternate { label: ")", steps: &[(KEY_MINUS, 0)] },
        ],
        "m" | "M" => &[
            Alternate { label: "?", steps: &[(50, 1)] }, // Shift+KEY_M = ? on AZERTY
        ],
        // Row 3 — hint symbols
        "w" | "W" => &[
            Alternate { label: "*", steps: &[(KEY_BACKSLASH, 0)] },
        ],
        "x" | "X" => &[
            Alternate { label: "\"", steps: &[(KEY_3, 0)] },
        ],
        "c" | "C" => &[
            Alternate { label: "ç", steps: &[(KEY_9, 0)] },
            Alternate { label: "'", steps: &[(KEY_4, 0)] },
        ],
        "v" | "V" => &[
            Alternate { label: ":", steps: &[(KEY_DOT, 0)] },
        ],
        "b" | "B" => &[
            Alternate { label: ";", steps: &[(KEY_COMMA, 0)] },
        ],
        "n" | "N" => &[
            Alternate { label: "!", steps: &[(KEY_SLASH, 0)] },
        ],
        _ => &[],
    }
}

// Computed rectangle for a long-press alternate popup item
struct AlternateRect {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    alt_idx: usize,
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

fn compute_key_rects(width: u32, kb_height: u32, layer_idx: usize) -> Vec<KeyRect> {
    let layer = LAYERS[layer_idx];
    let rows = layer.len();
    let row_height = kb_height as f32 / rows as f32;
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

fn shift_locked_color() -> Color { Color::from_rgba8(90, 90, 90, 255) }
fn dot_color() -> Color { Color::from_rgba8(180, 180, 180, 255) }
fn popup_bg_color() -> Color { Color::from_rgba8(80, 80, 80, 255) }
fn popup_selected_color() -> Color { Color::from_rgba8(120, 120, 120, 255) }

struct ModStates {
    shift: ModState,
    ctrl: ModState,
    alt: ModState,
    super_: ModState,
}

fn mod_state_for_key(code: u32, mods: &ModStates) -> ModState {
    match code {
        ACTION_SHIFT => mods.shift,
        ACTION_CTRL => mods.ctrl,
        ACTION_ALT => mods.alt,
        ACTION_SUPER => mods.super_,
        _ => ModState::Off,
    }
}

fn render_keyboard(
    pixmap: &mut Pixmap,
    rects: &[KeyRect],
    layer_idx: usize,
    pressed_key: Option<usize>,
    mod_states: &ModStates,
    long_press_active: bool,
    long_press_key_idx: Option<usize>,
    long_press_alternates: &[AlternateRect],
    long_press_selected: Option<usize>,
    font: &FontRenderer,
) {
    // Fill background
    pixmap.fill(bg_color());

    let layer = LAYERS[layer_idx];

    for (i, kr) in rects.iter().enumerate() {
        let key_def = &layer[kr.row][kr.col];
        let mod_st = mod_state_for_key(kr.code, mod_states);
        let is_sticky = matches!(kr.code, ACTION_SHIFT | ACTION_CTRL | ACTION_ALT | ACTION_SUPER);
        let color = if Some(i) == pressed_key {
            key_pressed_color()
        } else if is_sticky && mod_st == ModState::Locked {
            shift_locked_color()
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

        // Draw dot indicator for OneShot sticky modifiers
        if is_sticky && mod_st == ModState::OneShot {
            let dot_cx = kr.x + kr.w / 2.0;
            let dot_cy = kr.y + kr.h * 0.82;
            let dot_r = 3.0;
            let mut pb = PathBuilder::new();
            pb.push_circle(dot_cx, dot_cy, dot_r);
            if let Some(path) = pb.finish() {
                let mut paint = Paint::default();
                paint.set_color(dot_color());
                paint.anti_alias = true;
                pixmap.fill_path(&path, &paint, FillRule::Winding, Transform::identity(), None);
            }
        }
    }

    // Draw long-press popup
    if long_press_active {
        if let Some(key_idx) = long_press_key_idx {
            let key_def = &layer[rects[key_idx].row][rects[key_idx].col];
            let alts = get_alternates(key_def.label);

            for ar in long_press_alternates {
                let color = if long_press_selected == Some(ar.alt_idx) {
                    popup_selected_color()
                } else {
                    popup_bg_color()
                };
                draw_rounded_rect(
                    pixmap,
                    ar.x + KEY_MARGIN / 2.0,
                    ar.y + KEY_MARGIN / 2.0,
                    ar.w - KEY_MARGIN,
                    ar.h - KEY_MARGIN,
                    KEY_RADIUS,
                    color,
                );
                if ar.alt_idx < alts.len() {
                    font.render_centered(
                        pixmap,
                        alts[ar.alt_idx].label,
                        ar.x + ar.w / 2.0,
                        ar.y + ar.h / 2.0,
                        20.0,
                    );
                }
            }
        }
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
    shift_state: ModState,
    ctrl_state: ModState,
    alt_state: ModState,
    super_state: ModState,
    last_shift_tap: Option<std::time::Instant>,
    last_ctrl_tap: Option<std::time::Instant>,
    last_alt_tap: Option<std::time::Instant>,
    last_super_tap: Option<std::time::Instant>,
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

    // Display physical dimensions for DPI-aware sizing
    output_physical_width_mm: i32,
    output_pixel_width: i32,
    output_pixel_height: i32,
    kb_height: u32,

    // Long-press alternates
    touch_down_time: Option<std::time::Instant>,
    long_press_active: bool,
    long_press_key_idx: Option<usize>,
    long_press_alternates: Vec<AlternateRect>,
    long_press_selected: Option<usize>,
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
            height: DEFAULT_KB_HEIGHT,
            visible: false,
            auto_show_enabled: true,
            current_layer: 0,
            shift_state: ModState::Off,
            ctrl_state: ModState::Off,
            alt_state: ModState::Off,
            super_state: ModState::Off,
            last_shift_tap: None,
            last_ctrl_tap: None,
            last_alt_tap: None,
            last_super_tap: None,
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
            output_physical_width_mm: 0,
            output_pixel_width: 0,
            output_pixel_height: 0,
            kb_height: DEFAULT_KB_HEIGHT,
            touch_down_time: None,
            long_press_active: false,
            long_press_key_idx: None,
            long_press_alternates: Vec::new(),
            long_press_selected: None,
        }
    }

    fn compute_kb_height(&mut self) {
        if self.output_physical_width_mm > 0 && self.output_pixel_width > 0 {
            // Compute pixels-per-mm from the display
            let px_per_mm = self.output_pixel_width as f32 / self.output_physical_width_mm as f32;
            // Target key height: 9mm, but clamp to ergonomic range 7-11mm
            let key_mm = TARGET_KEY_HEIGHT_MM.clamp(MIN_KEY_HEIGHT_MM, MAX_KEY_HEIGHT_MM);
            let key_px = key_mm * px_per_mm;
            let mut h = (key_px * NUM_ROWS as f32) as u32;
            // Also cap total height to a physical max (55mm ≈ 5 rows × 11mm)
            let max_kb_mm = MAX_KEY_HEIGHT_MM * NUM_ROWS as f32;
            let max_kb_px = (max_kb_mm * px_per_mm) as u32;
            h = h.min(max_kb_px).max(150);
            self.kb_height = h;
        } else {
            self.kb_height = DEFAULT_KB_HEIGHT;
        }
        self.height = self.kb_height;
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
        self.key_rects = compute_key_rects(self.width, self.kb_height, self.current_layer);
        let pixmap = PixmapMut::from_bytes(data, self.width, self.height).unwrap();
        let mut owned_pixmap = pixmap.to_owned();
        let mod_states = ModStates {
            shift: self.shift_state,
            ctrl: self.ctrl_state,
            alt: self.alt_state,
            super_: self.super_state,
        };
        render_keyboard(
            &mut owned_pixmap,
            &self.key_rects,
            self.current_layer,
            self.pressed_key,
            &mod_states,
            self.long_press_active,
            self.long_press_key_idx,
            &self.long_press_alternates,
            self.long_press_selected,
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

    // XKB modifier bitmask: Shift=1, Lock=2, Control=4, Mod1(Alt)=8, Mod4(Super)=64
    fn active_mods(&self) -> u32 {
        let mut m = 0u32;
        if self.shift_state != ModState::Off { m |= 1; }
        if self.ctrl_state != ModState::Off { m |= 4; }
        if self.alt_state != ModState::Off { m |= 8; }
        if self.super_state != ModState::Off { m |= 64; }
        m
    }

    fn toggle_sticky(state: &mut ModState, last_tap: &mut Option<std::time::Instant>) {
        let now = std::time::Instant::now();
        *state = match *state {
            ModState::Off => {
                *last_tap = Some(now);
                ModState::OneShot
            }
            ModState::OneShot => {
                if last_tap.map_or(false, |t| now.duration_since(t).as_millis() < 400) {
                    ModState::Locked
                } else {
                    *last_tap = Some(now);
                    ModState::Off
                }
            }
            ModState::Locked => ModState::Off,
        };
    }

    fn clear_oneshot_mods(&mut self) {
        if self.shift_state == ModState::OneShot { self.shift_state = ModState::Off; }
        if self.ctrl_state == ModState::OneShot { self.ctrl_state = ModState::Off; }
        if self.alt_state == ModState::OneShot { self.alt_state = ModState::Off; }
        if self.super_state == ModState::OneShot { self.super_state = ModState::Off; }
        // Update layer based on shift
        self.current_layer = if self.shift_state != ModState::Off { 1 } else if self.current_layer == 1 { 0 } else { self.current_layer };
    }

    fn handle_key_press(&mut self, key_idx: usize, _qh: &QueueHandle<Self>) {
        let kr = &self.key_rects[key_idx];
        let code = kr.code;

        match code {
            ACTION_SHIFT => {
                Self::toggle_sticky(&mut self.shift_state, &mut self.last_shift_tap);
                let shift_on = self.shift_state != ModState::Off;
                self.current_layer = if shift_on { 1 } else { 0 };
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            ACTION_CTRL => {
                Self::toggle_sticky(&mut self.ctrl_state, &mut self.last_ctrl_tap);
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            ACTION_ALT => {
                Self::toggle_sticky(&mut self.alt_state, &mut self.last_alt_tap);
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            ACTION_SUPER => {
                Self::toggle_sticky(&mut self.super_state, &mut self.last_super_tap);
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            ACTION_SYM => {
                self.current_layer = 2;
                self.shift_state = ModState::Off;
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            ACTION_ABC => {
                self.current_layer = 0;
                self.shift_state = ModState::Off;
                self.send_modifier(self.active_mods());
                self.needs_redraw = true;
            }
            _ => {
                self.pressed_key = Some(key_idx);
                self.needs_redraw = true;
                // Record for long-press detection
                let key_def = &LAYERS[self.current_layer][kr.row][kr.col];
                let has_alternates = !get_alternates(key_def.label).is_empty();
                if has_alternates {
                    self.touch_down_time = Some(std::time::Instant::now());
                    self.long_press_key_idx = Some(key_idx);
                }
                if key_def.force_shift {
                    // Number row: temporarily engage Shift for digit output
                    self.send_modifier(self.active_mods() | 1);
                    self.send_key(code, true);
                } else {
                    self.send_modifier(self.active_mods());
                    self.send_key(code, true);
                }
            }
        }
    }

    fn handle_key_release(&mut self, _qh: &QueueHandle<Self>) {
        if self.long_press_active {
            // Long-press popup is showing — send selected alternate or cancel
            if let (Some(sel), Some(key_idx)) = (self.long_press_selected, self.long_press_key_idx) {
                let kr = &self.key_rects[key_idx];
                let key_def = &LAYERS[self.current_layer][kr.row][kr.col];
                let alts = get_alternates(key_def.label);
                if sel < alts.len() {
                    // Release the original key first
                    self.send_key(kr.code, false);
                    self.send_modifier(0);
                    // Send the alternate sequence
                    self.send_alternate_sequence(alts[sel].steps);
                }
            } else if let Some(idx) = self.pressed_key {
                // No alternate selected, just release the original key
                self.send_key(self.key_rects[idx].code, false);
            }
            self.pressed_key = None;
            self.cancel_long_press();
            self.needs_redraw = true;
            return;
        }

        if let Some(idx) = self.pressed_key.take() {
            let kr = &self.key_rects[idx];
            let code = kr.code;
            if !matches!(code, ACTION_SHIFT | ACTION_SYM | ACTION_ABC | ACTION_CTRL | ACTION_ALT | ACTION_SUPER) {
                let key_def = &LAYERS[self.current_layer][kr.row][kr.col];
                self.send_key(code, false);
                if key_def.force_shift {
                    // Restore modifier state after force_shift key
                    self.send_modifier(self.active_mods());
                } else if code != KEY_BACKSPACE && code != KEY_SPACE && code != KEY_ENTER {
                    // Clear one-shot modifiers after typing a character
                    self.clear_oneshot_mods();
                    self.send_modifier(self.active_mods());
                }
            }
            self.cancel_long_press();
            self.needs_redraw = true;
        }
    }
    fn compute_long_press_popup(&mut self) {
        let idx = match self.long_press_key_idx {
            Some(i) => i,
            None => return,
        };
        let kr = &self.key_rects[idx];
        let key_def = &LAYERS[self.current_layer][kr.row][kr.col];
        let alts = get_alternates(key_def.label);
        if alts.is_empty() {
            self.long_press_active = false;
            return;
        }

        let alt_w = kr.w * 1.2;
        let alt_h = kr.h;
        let total_w = alt_w * alts.len() as f32;
        // Center popup above the pressed key
        let start_x = (kr.x + kr.w / 2.0 - total_w / 2.0).max(0.0);
        let start_x = start_x.min((self.width as f32 - total_w).max(0.0));
        let popup_y = (kr.y - alt_h - KEY_MARGIN).max(0.0);

        self.long_press_alternates.clear();
        for (i, _alt) in alts.iter().enumerate() {
            self.long_press_alternates.push(AlternateRect {
                x: start_x + i as f32 * alt_w,
                y: popup_y,
                w: alt_w,
                h: alt_h,
                alt_idx: i,
            });
        }
        self.long_press_active = true;
        // Pre-select first alternate so releasing without drag inserts it
        self.long_press_selected = Some(0);
    }

    fn send_alternate_sequence(&self, steps: &[(u32, u32)]) {
        // Clear any current modifiers first
        self.send_modifier(0);
        for &(scancode, mods) in steps {
            if mods != 0 {
                self.send_modifier(mods);
            }
            self.send_key(scancode, true);
            self.send_key(scancode, false);
            if mods != 0 {
                self.send_modifier(0);
            }
        }
        // Restore active modifier state
        self.send_modifier(self.active_mods());
    }

    fn cancel_long_press(&mut self) {
        self.touch_down_time = None;
        self.long_press_active = false;
        self.long_press_key_idx = None;
        self.long_press_alternates.clear();
        self.long_press_selected = None;
    }

    fn long_press_hit_test(&self, x: f32, _y: f32) -> Option<usize> {
        for ar in &self.long_press_alternates {
            if x >= ar.x && x < ar.x + ar.w {
                return Some(ar.alt_idx);
            }
        }
        None
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
                state.height = if height > 0 { height } else { state.kb_height };
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
                                    state.key_rects = compute_key_rects(state.width, state.kb_height, state.current_layer);
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
                if state.long_press_active {
                    let prev = state.long_press_selected;
                    state.long_press_selected = state.long_press_hit_test(surface_x as f32, surface_y as f32);
                    if state.long_press_selected != prev {
                        state.needs_redraw = true;
                        state.draw(qh);
                    }
                }
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
                        state.key_rects = compute_key_rects(state.width, state.kb_height, state.current_layer);
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
                if state.long_press_active {
                    let prev = state.long_press_selected;
                    state.long_press_selected = state.long_press_hit_test(x as f32, y as f32);
                    if state.long_press_selected != prev {
                        state.needs_redraw = true;
                        state.draw(qh);
                    }
                }
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
impl Dispatch<WlOutput, ()> for OskState {
    fn event(
        state: &mut Self,
        _: &WlOutput,
        event: wl_output::Event,
        _: &(),
        _: &Connection,
        _qh: &QueueHandle<Self>,
    ) {
        match event {
            wl_output::Event::Geometry { physical_width, .. } => {
                state.output_physical_width_mm = physical_width;
            }
            wl_output::Event::Mode { width, height, .. } => {
                state.output_pixel_width = width;
                state.output_pixel_height = height;
            }
            wl_output::Event::Done => {
                state.compute_kb_height();
            }
            _ => {}
        }
    }
}
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

        // Compute poll timeout for long-press timer
        let poll_timeout = if let Some(down_time) = state.touch_down_time {
            if !state.long_press_active {
                let elapsed = std::time::Instant::now().duration_since(down_time).as_millis() as i32;
                (400 - elapsed).max(0)
            } else {
                -1
            }
        } else {
            -1
        };

        // Poll both wayland fd and signal pipe
        let mut fds = [
            libc::pollfd { fd: wl_fd, events: libc::POLLIN, revents: 0 },
            libc::pollfd { fd: sig_fd, events: libc::POLLIN, revents: 0 },
        ];

        let ret = unsafe { libc::poll(fds.as_mut_ptr(), 2, poll_timeout) };
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

        // Handle long-press timeout
        if let Some(down_time) = state.touch_down_time {
            if !state.long_press_active {
                let elapsed = std::time::Instant::now().duration_since(down_time).as_millis();
                if elapsed >= 400 && state.pressed_key.is_some() {
                    // Release the original key press first
                    if let Some(idx) = state.pressed_key {
                        let code = state.key_rects[idx].code;
                        state.send_key(code, false);
                        state.send_modifier(0);
                    }
                    state.compute_long_press_popup();
                    if state.long_press_active {
                        state.needs_redraw = true;
                    } else {
                        // No alternates for this key, cancel
                        state.touch_down_time = None;
                    }
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
