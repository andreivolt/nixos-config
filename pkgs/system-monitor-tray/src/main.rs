use std::sync::{Arc, Mutex};
use tokio::time::{interval, Duration};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const BUS_NAME: &str = "org.kde.StatusNotifierItem-system-monitor";
const SNI_PATH: &str = "/StatusNotifierItem";
const ICON_SIZE: i32 = 20;
const UPDATE_SECS: u64 = 3;

// Layout: two bars centered in 22x22
const BAR_W: i32 = 8;
const GAP: i32 = 2;
const MARGIN_X: i32 = 2; // (22 - 8 - 2 - 8) / 2
const MARGIN_Y: i32 = 2;
const BAR_H: i32 = ICON_SIZE - MARGIN_Y * 2; // 18

// Colors (R, G, B)
const COLOR_HIGH: (u8, u8, u8) = (0xcc, 0x66, 0x66);
const COLOR_WARN: (u8, u8, u8) = (0xcc, 0x88, 0x44);
const COLOR_MED: (u8, u8, u8) = (0xb0, 0x9a, 0x6d);
const COLOR_LOW: (u8, u8, u8) = (0x7a, 0x75, 0x6d);
const COLOR_BG: (u8, u8, u8) = (0x3c, 0x3a, 0x36);

fn level_color(pct: u32) -> (u8, u8, u8) {
    if pct >= 80 {
        COLOR_HIGH
    } else if pct >= 65 {
        COLOR_WARN
    } else if pct >= 50 {
        COLOR_MED
    } else {
        COLOR_LOW
    }
}

#[derive(Clone, Default)]
struct Stats {
    cpu_pct: u32,
    mem_pct: u32,
    prev_user: u64,
    prev_nice: u64,
    prev_sys: u64,
    prev_idle: u64,
}

fn read_cpu(stats: &mut Stats) {
    let Ok(data) = std::fs::read_to_string("/proc/stat") else { return };
    let Some(line) = data.lines().next() else { return };
    let vals: Vec<u64> = line
        .split_whitespace()
        .skip(1)
        .take(4)
        .filter_map(|s| s.parse().ok())
        .collect();
    if vals.len() < 4 {
        return;
    }
    let (u, n, s, i) = (vals[0], vals[1], vals[2], vals[3]);

    if stats.prev_user > 0 || stats.prev_idle > 0 {
        let t1 = stats.prev_user + stats.prev_nice + stats.prev_sys + stats.prev_idle;
        let t2 = u + n + s + i;
        let dt = t2.saturating_sub(t1).max(1);
        let di = i.saturating_sub(stats.prev_idle);
        stats.cpu_pct = ((100 * (dt - di)) / dt).min(100) as u32;
    }

    stats.prev_user = u;
    stats.prev_nice = n;
    stats.prev_sys = s;
    stats.prev_idle = i;
}

fn read_mem(stats: &mut Stats) {
    let Ok(data) = std::fs::read_to_string("/proc/meminfo") else { return };
    let mut total = 0u64;
    let mut avail = 0u64;
    for line in data.lines() {
        if let Some(rest) = line.strip_prefix("MemTotal:") {
            total = rest.trim().split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0);
        } else if let Some(rest) = line.strip_prefix("MemAvailable:") {
            avail = rest.trim().split_whitespace().next().and_then(|s| s.parse().ok()).unwrap_or(0);
        }
        if total > 0 && avail > 0 {
            break;
        }
    }
    if total > 0 {
        stats.mem_pct = ((100 * (total - avail)) / total).min(100) as u32;
    }
}

fn render_icon(cpu_pct: u32, mem_pct: u32) -> Vec<(i32, i32, Vec<u8>)> {
    let w = ICON_SIZE as usize;
    let h = ICON_SIZE as usize;
    let mut buf = vec![0u8; w * h * 4]; // ARGB, network byte order (big-endian)

    let mut fill_rect = |x1: i32, y1: i32, x2: i32, y2: i32, a: u8, r: u8, g: u8, b: u8| {
        for y in y1.max(0)..=y2.min(ICON_SIZE - 1) {
            for x in x1.max(0)..=x2.min(ICON_SIZE - 1) {
                let off = (y as usize * w + x as usize) * 4;
                buf[off] = a;
                buf[off + 1] = r;
                buf[off + 2] = g;
                buf[off + 3] = b;
            }
        }
    };

    let bar_x1 = MARGIN_X; // left bar at x=2
    let bar_x2 = MARGIN_X + BAR_W - 1; // x=9
    let bar2_x1 = MARGIN_X + BAR_W + GAP; // right bar at x=12
    let bar2_x2 = bar2_x1 + BAR_W - 1; // x=19
    let bar_top = MARGIN_Y;
    let bar_bot = MARGIN_Y + BAR_H - 1;

    // Bar backgrounds
    let (br, bg, bb) = COLOR_BG;
    fill_rect(bar_x1, bar_top, bar_x2, bar_bot, 255, br, bg, bb);
    fill_rect(bar2_x1, bar_top, bar2_x2, bar_bot, 255, br, bg, bb);

    // CPU fill (left bar, fills from bottom)
    let cpu_fill = ((BAR_H as u32 * cpu_pct) / 100).max(if cpu_pct > 0 { 1 } else { 0 }) as i32;
    if cpu_fill > 0 {
        let (r, g, b) = level_color(cpu_pct);
        fill_rect(bar_x1, bar_bot - cpu_fill + 1, bar_x2, bar_bot, 255, r, g, b);
    }

    // Memory fill (right bar, fills from bottom)
    let mem_fill = ((BAR_H as u32 * mem_pct) / 100).max(if mem_pct > 0 { 1 } else { 0 }) as i32;
    if mem_fill > 0 {
        let (r, g, b) = level_color(mem_pct);
        fill_rect(bar2_x1, bar_bot - mem_fill + 1, bar2_x2, bar_bot, 255, r, g, b);
    }

    vec![(ICON_SIZE, ICON_SIZE, buf)]
}

#[derive(Clone)]
struct MonitorState {
    inner: Arc<Mutex<Stats>>,
}

impl MonitorState {
    fn new() -> Self {
        let mut stats = Stats::default();
        read_cpu(&mut stats); // prime CPU delta
        read_mem(&mut stats);
        Self {
            inner: Arc::new(Mutex::new(stats)),
        }
    }

    fn update(&self) {
        let mut stats = self.inner.lock().unwrap();
        read_cpu(&mut stats);
        read_mem(&mut stats);
    }

    fn cpu_pct(&self) -> u32 {
        self.inner.lock().unwrap().cpu_pct
    }

    fn mem_pct(&self) -> u32 {
        self.inner.lock().unwrap().mem_pct
    }

    fn tooltip(&self) -> String {
        let s = self.inner.lock().unwrap();
        format!("CPU: {}%  Mem: {}%", s.cpu_pct, s.mem_pct)
    }
}

struct StatusNotifierItem {
    state: MonitorState,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str {
        "SystemServices"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        "system-monitor"
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        "System Monitor"
    }
    #[zbus(property)]
    fn status(&self) -> &str {
        "Active"
    }
    #[zbus(property)]
    fn icon_name(&self) -> &str {
        ""
    }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> {
        render_icon(self.state.cpu_pct(), self.state.mem_pct())
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

    #[zbus(signal, name = "NewToolTip")]
    async fn new_tool_tip(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

async fn register_sni(conn: &Connection) {
    let _ = conn
        .call_method(
            Some("org.kde.StatusNotifierWatcher"),
            "/StatusNotifierWatcher",
            Some("org.kde.StatusNotifierWatcher"),
            "RegisterStatusNotifierItem",
            &BUS_NAME,
        )
        .await;
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let conn = Connection::session().await?;
    let state = MonitorState::new();

    let sni = StatusNotifierItem {
        state: state.clone(),
    };

    conn.object_server().at(SNI_PATH, sni).await?;
    conn.request_name(BUS_NAME).await?;
    register_sni(&conn).await;

    // Re-register when StatusNotifierWatcher reappears
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

    let mut tick = interval(Duration::from_secs(UPDATE_SECS));

    loop {
        tokio::select! {
            _ = tick.tick() => {
                state.update();
                let emitter = iface_ref.signal_emitter();
                let _ = StatusNotifierItem::new_tool_tip(&emitter).await;
            }
            Some(Ok(msg)) = futures_util::StreamExt::next(&mut watcher_stream) => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        register_sni(&conn2).await;
                    }
                }
            }
        }
    }
}
