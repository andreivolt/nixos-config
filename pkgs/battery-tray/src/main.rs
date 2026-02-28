use std::sync::{Arc, Mutex};
use tokio::time::{interval, Duration};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const ICON_SIZE: usize = 20;
const CENTER: f64 = ICON_SIZE as f64 / 2.0;
const RADIUS: f64 = ICON_SIZE as f64 * 0.4;
const RING_WIDTH: f64 = 3.0;

const COLOR_BG: (u8, u8, u8) = (0x3c, 0x3a, 0x36);
const COLOR_NORMAL: (u8, u8, u8) = (0x7a, 0x75, 0x6d);
const COLOR_LOW: (u8, u8, u8) = (0xd6, 0x50, 0x4e);
const COLOR_ICON: (u8, u8, u8) = (0xd4, 0xd0, 0xca);

fn arc_color(pct: u32) -> (u8, u8, u8) {
    if pct <= 20 {
        COLOR_LOW
    } else {
        COLOR_NORMAL
    }
}

const PCT_ICON_LOGICAL: i32 = 20;
const PCT_FONT_LOGICAL: f64 = 14.0;

fn render_icon(pct: u32, charging: bool) -> Vec<(i32, i32, Vec<u8>)> {
    let mut buf = vec![0u8; ICON_SIZE * ICON_SIZE * 4];

    let set_pixel = |buf: &mut Vec<u8>, x: usize, y: usize, a: u8, r: u8, g: u8, b: u8| {
        let off = (y * ICON_SIZE + x) * 4;
        buf[off] = a;
        buf[off + 1] = r;
        buf[off + 2] = g;
        buf[off + 3] = b;
    };

    let fill_color = arc_color(pct);
    let fill_angle = (pct as f64 / 100.0) * std::f64::consts::TAU;

    // Draw ring
    for y in 0..ICON_SIZE {
        for x in 0..ICON_SIZE {
            let dx = x as f64 + 0.5 - CENTER;
            let dy = y as f64 + 0.5 - CENTER;
            let dist = (dx * dx + dy * dy).sqrt();

            let inner = RADIUS - RING_WIDTH / 2.0;
            let outer = RADIUS + RING_WIDTH / 2.0;

            if dist >= inner && dist <= outer {
                // Angle from 12 o'clock, clockwise
                let angle = (dx.atan2(-dy) + std::f64::consts::TAU) % std::f64::consts::TAU;

                // Anti-aliasing at edges
                let edge_inner = (dist - inner).min(1.0).max(0.0);
                let edge_outer = (outer - dist).min(1.0).max(0.0);
                let alpha = (edge_inner * edge_outer * 255.0) as u8;

                if angle <= fill_angle {
                    set_pixel(&mut buf, x, y, alpha, fill_color.0, fill_color.1, fill_color.2);
                } else {
                    set_pixel(&mut buf, x, y, alpha, COLOR_BG.0, COLOR_BG.1, COLOR_BG.2);
                }
            }
        }
    }

    // Draw lightning bolt inside ring when charging
    if charging {
        let bolt: &[(usize, usize)] = &[
            (10, 6), (11, 6),
            (9, 7), (10, 7),
            (8, 8), (9, 8), (10, 8), (11, 8),
            (10, 9), (11, 9),
            (9, 10), (10, 10),
            (8, 11), (9, 11),
        ];
        for &(x, y) in bolt {
            set_pixel(&mut buf, x, y, 255, COLOR_ICON.0, COLOR_ICON.1, COLOR_ICON.2);
        }
    }

    vec![(ICON_SIZE as i32, ICON_SIZE as i32, buf)]
}

fn get_scale_factor() -> f64 {
    std::process::Command::new("hyprctl")
        .args(["monitors", "-j"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .and_then(|s| {
            s.find("\"scale\":")
                .and_then(|i| s[i + 8..].trim_start().split(|c: char| !c.is_ascii_digit() && c != '.').next()
                    .and_then(|v| v.parse::<f64>().ok()))
        })
        .unwrap_or(1.0)
}

fn render_pct_icon(pct: u32, scale: f64) -> Vec<(i32, i32, Vec<u8>)> {
    let text = format!("{}", pct);
    let color = arc_color(pct);
    let icon_w = (f64::from(PCT_ICON_LOGICAL) * scale).round() as i32;
    let icon_h = icon_w;

    let mut surface =
        cairo::ImageSurface::create(cairo::Format::ARgb32, icon_w, icon_h).unwrap();
    let cr = cairo::Context::new(&surface).unwrap();

    let layout = pangocairo::functions::create_layout(&cr);
    let mut font_desc = pango::FontDescription::new();
    font_desc.set_family("Inter Tight");
    font_desc.set_weight(pango::Weight::Bold);
    let mut px = PCT_FONT_LOGICAL * scale;
    font_desc.set_absolute_size(px * f64::from(pango::SCALE));
    layout.set_font_description(Some(&font_desc));
    layout.set_text(&text);

    while layout.pixel_size().0 > icon_w && px > 8.0 {
        px -= 0.5;
        font_desc.set_absolute_size(px * f64::from(pango::SCALE));
        layout.set_font_description(Some(&font_desc));
    }

    let (text_w, text_h) = layout.pixel_size();
    cr.move_to(
        (f64::from(icon_w) - f64::from(text_w)) / 2.0,
        (f64::from(icon_h) - f64::from(text_h)) / 2.0,
    );
    cr.set_source_rgba(
        f64::from(color.0) / 255.0,
        f64::from(color.1) / 255.0,
        f64::from(color.2) / 255.0,
        1.0,
    );
    pangocairo::functions::show_layout(&cr, &layout);

    drop(cr);
    surface.flush();
    let stride = surface.stride() as usize;
    let data = surface.data().unwrap();

    let mut buf = vec![0u8; (icon_w * icon_h * 4) as usize];
    for y in 0..icon_h as usize {
        for x in 0..icon_w as usize {
            let src = y * stride + x * 4;
            let dst = (y * icon_w as usize + x) * 4;
            let a = data[src + 3];
            if a > 0 {
                buf[dst] = a;
                buf[dst + 1] = color.0;
                buf[dst + 2] = color.1;
                buf[dst + 3] = color.2;
            }
        }
    }

    vec![(icon_w, icon_h, buf)]
}

fn read_sysfs(path: &str) -> Option<String> {
    std::fs::read_to_string(path).ok().map(|s| s.trim().to_string())
}

struct BatteryReading {
    pct: u32,
    charging: bool,
    time_to_full: u32,
    time_to_empty: u32,
}

fn read_battery() -> BatteryReading {
    let pct = read_sysfs("/sys/class/power_supply/macsmc-battery/capacity")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let charging = read_sysfs("/sys/class/power_supply/macsmc-ac/online")
        .and_then(|s| s.parse::<u32>().ok())
        .map(|v| v == 1)
        .unwrap_or(false);
    let time_to_full = read_sysfs("/sys/class/power_supply/macsmc-battery/time_to_full_now")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    let time_to_empty = read_sysfs("/sys/class/power_supply/macsmc-battery/time_to_empty_now")
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);
    BatteryReading { pct, charging, time_to_full, time_to_empty }
}

fn format_duration(secs: u32) -> String {
    let h = secs / 3600;
    let m = (secs % 3600) / 60;
    if h > 0 {
        format!("{}h {:02}m", h, m)
    } else {
        format!("{}m", m)
    }
}

#[derive(Clone)]
struct BatteryState {
    inner: Arc<Mutex<BatteryReading>>,
    scale: f64,
}

impl BatteryState {
    fn new(scale: f64) -> Self {
        Self { inner: Arc::new(Mutex::new(read_battery())), scale }
    }

    fn update(&self) {
        *self.inner.lock().unwrap() = read_battery();
    }

    fn icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        let r = self.inner.lock().unwrap();
        render_icon(r.pct, r.charging)
    }

    fn pct_icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        let r = self.inner.lock().unwrap();
        render_pct_icon(r.pct, self.scale)
    }

    fn tooltip(&self) -> String {
        let r = self.inner.lock().unwrap();
        if r.charging {
            if r.time_to_full > 0 {
                format!("Battery: {}% — {} to full", r.pct, format_duration(r.time_to_full))
            } else {
                format!("Battery: {}% (charging)", r.pct)
            }
        } else if r.time_to_empty > 0 {
            format!("Battery: {}% — {} remaining", r.pct, format_duration(r.time_to_empty))
        } else {
            format!("Battery: {}%", r.pct)
        }
    }
}

struct SniIcon {
    state: BatteryState,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl SniIcon {
    #[zbus(property)]
    fn category(&self) -> &str {
        "SystemServices"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        "battery-tray"
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        "Battery"
    }
    #[zbus(property)]
    fn status(&self) -> &str {
        "Active"
    }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> {
        self.state.icon()
    }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        (String::new(), vec![], self.state.tooltip(), String::new())
    }

    fn activate(&self, _x: i32, _y: i32) {}
    fn secondary_activate(&self, _x: i32, _y: i32) {}
    fn context_menu(&self, _x: i32, _y: i32) {}
    fn scroll(&self, _delta: i32, _orientation: &str) {}

    #[zbus(signal, name = "NewIcon")]
    async fn new_icon(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;

    #[zbus(signal, name = "NewToolTip")]
    async fn new_tool_tip(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

struct SniPct {
    state: BatteryState,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl SniPct {
    #[zbus(property)]
    fn category(&self) -> &str {
        "SystemServices"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        "battery-pct"
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        "Battery"
    }
    #[zbus(property)]
    fn status(&self) -> &str {
        "Active"
    }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> {
        self.state.pct_icon()
    }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        (String::new(), vec![], self.state.tooltip(), String::new())
    }

    fn activate(&self, _x: i32, _y: i32) {}
    fn secondary_activate(&self, _x: i32, _y: i32) {}
    fn context_menu(&self, _x: i32, _y: i32) {}
    fn scroll(&self, _delta: i32, _orientation: &str) {}

    #[zbus(signal, name = "NewIcon")]
    async fn new_icon(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;

    #[zbus(signal, name = "NewToolTip")]
    async fn new_tool_tip(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

async fn register_sni(conn: &Connection, bus_name: &str) {
    let _ = conn
        .call_method(
            Some("org.kde.StatusNotifierWatcher"),
            "/StatusNotifierWatcher",
            Some("org.kde.StatusNotifierWatcher"),
            "RegisterStatusNotifierItem",
            &bus_name,
        )
        .await;
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let scale = get_scale_factor();
    let state = BatteryState::new(scale);

    let conn_icon = Connection::session().await?;
    let bus_name_icon = "org.kde.StatusNotifierItem-battery-tray";
    conn_icon.object_server().at(SNI_PATH, SniIcon { state: state.clone() }).await?;
    conn_icon.request_name(bus_name_icon).await?;
    register_sni(&conn_icon, bus_name_icon).await;

    let conn_pct = Connection::session().await?;
    let bus_name_pct = "org.kde.StatusNotifierItem-battery-pct";
    conn_pct.object_server().at(SNI_PATH, SniPct { state: state.clone() }).await?;
    conn_pct.request_name(bus_name_pct).await?;
    register_sni(&conn_pct, bus_name_pct).await;

    let rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .path("/org/freedesktop/DBus")?
        .build();
    let mut watcher_stream =
        zbus::MessageStream::for_match_rule(rule, &conn_icon, Some(16)).await?;

    let iface_icon = conn_icon
        .object_server()
        .interface::<_, SniIcon>(SNI_PATH)
        .await?;
    let iface_pct = conn_pct
        .object_server()
        .interface::<_, SniPct>(SNI_PATH)
        .await?;

    let mut tick = interval(Duration::from_secs(30));

    loop {
        tokio::select! {
            _ = tick.tick() => {
                state.update();
                let e = iface_icon.signal_emitter();
                let _ = SniIcon::new_icon(&e).await;
                let _ = SniIcon::new_tool_tip(&e).await;
                let e = iface_pct.signal_emitter();
                let _ = SniPct::new_icon(&e).await;
                let _ = SniPct::new_tool_tip(&e).await;
            }
            Some(Ok(msg)) = futures_util::StreamExt::next(&mut watcher_stream) => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        register_sni(&conn_icon, bus_name_icon).await;
                        register_sni(&conn_pct, bus_name_pct).await;
                    }
                }
            }
        }
    }
}
