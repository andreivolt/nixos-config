use std::env;
use std::sync::{Arc, Mutex};
use std::time::Instant;
use tokio::time::{interval, Duration};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const ICON_SIZE: i32 = 20;
const W: usize = ICON_SIZE as usize;
const H: usize = ICON_SIZE as usize;
const BAR_H: usize = H;
const BG: (u8, u8, u8) = (0x20, 0x20, 0x20);

fn lerp(a: u8, b: u8, t: f32) -> u8 {
    (a as f32 + (b as f32 - a as f32) * t).round() as u8
}

fn intensity_color(pct: u32) -> (u8, u8, u8) {
    let t = (pct.min(100) as f32) / 100.0;
    let stops: &[(f32, u8, u8, u8)] = &[
        (0.00, 70, 70, 70),
        (0.40, 100, 100, 90),
        (0.55, 200, 170, 50),
        (0.70, 210, 130, 40),
        (0.85, 214, 60, 50),
        (1.00, 180, 40, 140),
    ];
    for i in 1..stops.len() {
        if t <= stops[i].0 {
            let (p0, r0, g0, b0) = stops[i - 1];
            let (p1, r1, g1, b1) = stops[i];
            let f = (t - p0) / (p1 - p0);
            return (lerp(r0, r1, f), lerp(g0, g1, f), lerp(b0, b1, f));
        }
    }
    let s = stops.last().unwrap();
    (s.1, s.2, s.3)
}

fn set_pixel(buf: &mut [u8], x: usize, y: usize, r: u8, g: u8, b: u8) {
    let off = (y * W + x) * 4;
    buf[off] = 255;
    buf[off + 1] = r;
    buf[off + 2] = g;
    buf[off + 3] = b;
}

fn render_dual_bars(left_pct: u32, right_pct: u32) -> Vec<(i32, i32, Vec<u8>)> {
    let mut buf = vec![0u8; W * H * 4];

    // Bar backgrounds (left: cols 0-7, gap: 8-11, right: cols 12-19)
    for y in 0..BAR_H {
        for x in 0..=7 {
            set_pixel(&mut buf, x, y, BG.0, BG.1, BG.2);
        }
        for x in 12..=19 {
            set_pixel(&mut buf, x, y, BG.0, BG.1, BG.2);
        }
    }

    // Left bar fill
    let lf = if left_pct > 0 {
        ((BAR_H as u32 * left_pct) / 100).max(1) as usize
    } else {
        0
    };
    if lf > 0 {
        let (r, g, b) = intensity_color(left_pct);
        for y in (BAR_H - lf)..BAR_H {
            for x in 0..=7 {
                set_pixel(&mut buf, x, y, r, g, b);
            }
        }
    }

    // Right bar fill
    let rf = if right_pct > 0 {
        ((BAR_H as u32 * right_pct) / 100).max(1) as usize
    } else {
        0
    };
    if rf > 0 {
        let (r, g, b) = intensity_color(right_pct);
        for y in (BAR_H - rf)..BAR_H {
            for x in 12..=19 {
                set_pixel(&mut buf, x, y, r, g, b);
            }
        }
    }

    vec![(ICON_SIZE, ICON_SIZE, buf)]
}

#[derive(Default)]
struct CpuState {
    prev_user: u64,
    prev_nice: u64,
    prev_sys: u64,
    prev_idle: u64,
}

fn read_cpu(state: &mut CpuState) -> u32 {
    let Ok(data) = std::fs::read_to_string("/proc/stat") else {
        return 0;
    };
    let Some(line) = data.lines().next() else {
        return 0;
    };
    let vals: Vec<u64> = line
        .split_whitespace()
        .skip(1)
        .take(4)
        .filter_map(|s| s.parse().ok())
        .collect();
    if vals.len() < 4 {
        return 0;
    }
    let (u, n, s, i) = (vals[0], vals[1], vals[2], vals[3]);
    let pct = if state.prev_user > 0 || state.prev_idle > 0 {
        let t1 = state.prev_user + state.prev_nice + state.prev_sys + state.prev_idle;
        let t2 = u + n + s + i;
        let dt = t2.saturating_sub(t1).max(1);
        let di = i.saturating_sub(state.prev_idle);
        ((100 * (dt - di)) / dt).min(100) as u32
    } else {
        0
    };
    state.prev_user = u;
    state.prev_nice = n;
    state.prev_sys = s;
    state.prev_idle = i;
    pct
}

fn read_mem() -> u32 {
    let Ok(data) = std::fs::read_to_string("/proc/meminfo") else {
        return 0;
    };
    let mut total = 0u64;
    let mut avail = 0u64;
    for line in data.lines() {
        if let Some(rest) = line.strip_prefix("MemTotal:") {
            total = rest
                .trim()
                .split_whitespace()
                .next()
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
        } else if let Some(rest) = line.strip_prefix("MemAvailable:") {
            avail = rest
                .trim()
                .split_whitespace()
                .next()
                .and_then(|s| s.parse().ok())
                .unwrap_or(0);
        }
        if total > 0 && avail > 0 {
            break;
        }
    }
    if total > 0 {
        ((100 * (total - avail)) / total).min(100) as u32
    } else {
        0
    }
}

fn read_net_bytes() -> (u64, u64) {
    let Ok(data) = std::fs::read_to_string("/proc/net/dev") else {
        return (0, 0);
    };
    let (mut rx, mut tx) = (0u64, 0u64);
    for line in data.lines().skip(2) {
        let Some((iface, rest)) = line.split_once(':') else {
            continue;
        };
        if iface.trim() == "lo" {
            continue;
        }
        let vals: Vec<u64> = rest
            .split_whitespace()
            .filter_map(|s| s.parse().ok())
            .collect();
        if vals.len() >= 10 {
            rx += vals[0];
            tx += vals[8];
        }
    }
    (rx, tx)
}

fn format_rate(bps: u64) -> String {
    if bps >= 1_000_000_000 {
        format!("{:.1} GB/s", bps as f64 / 1e9)
    } else if bps >= 1_000_000 {
        format!("{:.1} MB/s", bps as f64 / 1e6)
    } else if bps >= 1_000 {
        format!("{:.0} KB/s", bps as f64 / 1e3)
    } else {
        format!("{} B/s", bps)
    }
}

#[derive(Clone, Copy)]
enum Mode {
    CpuMem,
    Net,
}

impl Mode {
    fn from_arg(s: &str) -> Option<Self> {
        match s {
            "cpu-mem" => Some(Self::CpuMem),
            "net" => Some(Self::Net),
            _ => None,
        }
    }
    fn bus_name(&self) -> &'static str {
        match self {
            Self::CpuMem => "org.kde.StatusNotifierItem-cpu-mem-monitor",
            Self::Net => "org.kde.StatusNotifierItem-net-monitor",
        }
    }
    fn id(&self) -> &'static str {
        match self {
            Self::CpuMem => "cpu-mem-monitor",
            Self::Net => "net-monitor",
        }
    }
    fn title(&self) -> &'static str {
        match self {
            Self::CpuMem => "CPU / Memory",
            Self::Net => "Network",
        }
    }
}

struct MonitorState {
    mode: Mode,
    cpu: Mutex<CpuState>,
    cpu_pct: Mutex<u32>,
    mem_pct: Mutex<u32>,
    net_prev: Mutex<Option<(u64, u64, Instant)>>,
    rx_rate: Mutex<u64>,
    tx_rate: Mutex<u64>,
    rx_peak: Mutex<u64>,
    tx_peak: Mutex<u64>,
}

impl MonitorState {
    fn new(mode: Mode) -> Self {
        Self {
            mode,
            cpu: Mutex::new(CpuState::default()),
            cpu_pct: Mutex::new(0),
            mem_pct: Mutex::new(0),
            net_prev: Mutex::new(None),
            rx_rate: Mutex::new(0),
            tx_rate: Mutex::new(0),
            rx_peak: Mutex::new(0),
            tx_peak: Mutex::new(0),
        }
    }

    fn update(&self) {
        match self.mode {
            Mode::CpuMem => {
                *self.cpu_pct.lock().unwrap() = read_cpu(&mut self.cpu.lock().unwrap());
                *self.mem_pct.lock().unwrap() = read_mem();
            }
            Mode::Net => {
                let (rx, tx) = read_net_bytes();
                let mut prev = self.net_prev.lock().unwrap();
                if let Some((prx, ptx, when)) = *prev {
                    if rx < prx || tx < ptx {
                        *self.rx_peak.lock().unwrap() = 0;
                        *self.tx_peak.lock().unwrap() = 0;
                        *self.rx_rate.lock().unwrap() = 0;
                        *self.tx_rate.lock().unwrap() = 0;
                    } else {
                        let elapsed = when.elapsed().as_secs_f64().max(0.1);
                        let rxr = ((rx - prx) as f64 / elapsed) as u64;
                        let txr = ((tx - ptx) as f64 / elapsed) as u64;
                        *self.rx_rate.lock().unwrap() = rxr;
                        *self.tx_rate.lock().unwrap() = txr;
                        let mut rxp = self.rx_peak.lock().unwrap();
                        *rxp = (*rxp).max(rxr);
                        let mut txp = self.tx_peak.lock().unwrap();
                        *txp = (*txp).max(txr);
                    }
                }
                *prev = Some((rx, tx, Instant::now()));
            }
        }
    }

    fn icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        match self.mode {
            Mode::CpuMem => {
                let cpu = *self.cpu_pct.lock().unwrap();
                let mem = *self.mem_pct.lock().unwrap();
                render_dual_bars(cpu, mem)
            }
            Mode::Net => {
                let rxr = *self.rx_rate.lock().unwrap();
                let txr = *self.tx_rate.lock().unwrap();
                let rxp = *self.rx_peak.lock().unwrap();
                let txp = *self.tx_peak.lock().unwrap();
                let rx_pct = if rxp == 0 {
                    0
                } else {
                    ((rxr as f64 / rxp as f64).sqrt() * 100.0).round().min(100.0) as u32
                };
                let tx_pct = if txp == 0 {
                    0
                } else {
                    ((txr as f64 / txp as f64).sqrt() * 100.0).round().min(100.0) as u32
                };
                render_dual_bars(rx_pct, tx_pct)
            }
        }
    }

    fn tooltip(&self) -> String {
        match self.mode {
            Mode::CpuMem => format!(
                "CPU: {}% | Mem: {}%",
                *self.cpu_pct.lock().unwrap(),
                *self.mem_pct.lock().unwrap()
            ),
            Mode::Net => format!(
                "\u{2193} {} | \u{2191} {}",
                format_rate(*self.rx_rate.lock().unwrap()),
                format_rate(*self.tx_rate.lock().unwrap())
            ),
        }
    }
}

struct StatusNotifierItem {
    state: Arc<MonitorState>,
    mode: Mode,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str {
        "SystemServices"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        self.mode.id()
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        self.mode.title()
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
    let mode = env::args()
        .nth(1)
        .and_then(|s| Mode::from_arg(&s))
        .expect("usage: system-monitor-tray <cpu-mem|net>");

    let conn = Connection::session().await?;
    let state = Arc::new(MonitorState::new(mode));
    state.update();

    let sni = StatusNotifierItem {
        state: state.clone(),
        mode,
    };

    let bus_name = mode.bus_name();
    conn.object_server().at(SNI_PATH, sni).await?;
    conn.request_name(bus_name).await?;
    register_sni(&conn, bus_name).await;

    let conn2 = conn.clone();
    let bus_name2 = bus_name;
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

    let mut tick = interval(Duration::from_secs(2));

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
                        register_sni(&conn2, bus_name2).await;
                    }
                }
            }
        }
    }
}
