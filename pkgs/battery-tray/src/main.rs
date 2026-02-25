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
const COLOR_CHARGING: (u8, u8, u8) = (0x8a, 0xaa, 0x8a);
const COLOR_NORMAL: (u8, u8, u8) = (0x7a, 0x75, 0x6d);
const COLOR_LOW: (u8, u8, u8) = (0xd6, 0x50, 0x4e);
fn arc_color(pct: u32, charging: bool) -> (u8, u8, u8) {
    if charging {
        COLOR_CHARGING
    } else if pct <= 20 {
        COLOR_LOW
    } else {
        COLOR_NORMAL
    }
}

fn render_icon(pct: u32, charging: bool) -> Vec<(i32, i32, Vec<u8>)> {
    let mut buf = vec![0u8; ICON_SIZE * ICON_SIZE * 4];

    let set_pixel = |buf: &mut Vec<u8>, x: usize, y: usize, a: u8, r: u8, g: u8, b: u8| {
        let off = (y * ICON_SIZE + x) * 4;
        buf[off] = a;
        buf[off + 1] = r;
        buf[off + 2] = g;
        buf[off + 3] = b;
    };

    let fill_color = arc_color(pct, charging);
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

    vec![(ICON_SIZE as i32, ICON_SIZE as i32, buf)]
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
}

impl BatteryState {
    fn new() -> Self {
        Self { inner: Arc::new(Mutex::new(read_battery())) }
    }

    fn update(&self) {
        *self.inner.lock().unwrap() = read_battery();
    }

    fn icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        let r = self.inner.lock().unwrap();
        render_icon(r.pct, r.charging)
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

struct StatusNotifierItem {
    state: BatteryState,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
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
    let conn = Connection::session().await?;
    let state = BatteryState::new();

    let bus_name = "org.kde.StatusNotifierItem-battery-tray";

    let sni = StatusNotifierItem {
        state: state.clone(),
    };

    conn.object_server().at(SNI_PATH, sni).await?;
    conn.request_name(bus_name).await?;
    register_sni(&conn, bus_name).await;

    let conn2 = conn.clone();
    let rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .path("/org/freedesktop/DBus")?
        .build();
    let mut watcher_stream =
        zbus::MessageStream::for_match_rule(rule, &conn, Some(16)).await?;

    let iface_ref = conn
        .object_server()
        .interface::<_, StatusNotifierItem>(SNI_PATH)
        .await?;

    let mut tick = interval(Duration::from_secs(30));

    loop {
        tokio::select! {
            _ = tick.tick() => {
                state.update();
                let emitter = iface_ref.signal_emitter();
                let _ = StatusNotifierItem::new_icon(&emitter).await;
                let _ = StatusNotifierItem::new_tool_tip(&emitter).await;
            }
            Some(Ok(msg)) = futures_util::StreamExt::next(&mut watcher_stream) => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        register_sni(&conn2, bus_name).await;
                    }
                }
            }
        }
    }
}
