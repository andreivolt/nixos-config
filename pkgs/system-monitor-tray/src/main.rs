use std::collections::VecDeque;
use std::env;
use std::sync::{Arc, Mutex};
use tokio::time::{interval, Duration};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const ICON_SIZE: i32 = 20;
const HISTORY_LEN: usize = ICON_SIZE as usize;

const COLOR_HIGH: (u8, u8, u8) = (0xd6, 0x50, 0x50);
const COLOR_WARN: (u8, u8, u8) = (0xd4, 0x9a, 0x4e);
const COLOR_MED: (u8, u8, u8) = (0x9a, 0x8e, 0x6a);
const COLOR_LOW: (u8, u8, u8) = (0x58, 0x58, 0x56);
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

fn render_sparkline(history: &VecDeque<u32>) -> Vec<(i32, i32, Vec<u8>)> {
    let w = ICON_SIZE as usize;
    let h = ICON_SIZE as usize;
    let mut buf = vec![0u8; w * h * 4];

    let set_pixel = |buf: &mut Vec<u8>, x: usize, y: usize, a: u8, r: u8, g: u8, b: u8| {
        let off = (y * w + x) * 4;
        buf[off] = a;
        buf[off + 1] = r;
        buf[off + 2] = g;
        buf[off + 3] = b;
    };

    // Draw connected sparkline, newest on right
    let offset = HISTORY_LEN.saturating_sub(history.len());
    let mut prev_y: Option<usize> = None;
    for (i, &pct) in history.iter().enumerate() {
        let x = offset + i;
        if x >= w {
            break;
        }
        let fill_h = ((h as u32 * pct) / 100).max(if pct > 0 { 1 } else { 0 }) as usize;
        let cur_y = h - fill_h;
        let (r, g, b) = level_color(pct);
        if let Some(py) = prev_y {
            let y_min = cur_y.min(py);
            let y_max = cur_y.max(py);
            for y in y_min..=y_max {
                set_pixel(&mut buf, x, y, 255, r, g, b);
            }
        } else {
            set_pixel(&mut buf, x, cur_y, 255, r, g, b);
        }
        prev_y = Some(cur_y);
    }

    vec![(ICON_SIZE, ICON_SIZE, buf)]
}

#[derive(Clone, Default)]
struct CpuState {
    prev_user: u64,
    prev_nice: u64,
    prev_sys: u64,
    prev_idle: u64,
}

fn read_cpu(state: &mut CpuState) -> u32 {
    let Ok(data) = std::fs::read_to_string("/proc/stat") else { return 0 };
    let Some(line) = data.lines().next() else { return 0 };
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
    let Ok(data) = std::fs::read_to_string("/proc/meminfo") else { return 0 };
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
        ((100 * (total - avail)) / total).min(100) as u32
    } else {
        0
    }
}

enum Metric {
    Cpu,
    Mem,
}

impl Metric {
    fn from_arg(s: &str) -> Option<Self> {
        match s {
            "cpu" => Some(Self::Cpu),
            "mem" => Some(Self::Mem),
            _ => None,
        }
    }

    fn bus_name(&self) -> &'static str {
        match self {
            Self::Cpu => "org.kde.StatusNotifierItem-cpu-monitor",
            Self::Mem => "org.kde.StatusNotifierItem-mem-monitor",
        }
    }

    fn id(&self) -> &'static str {
        match self {
            Self::Cpu => "cpu-monitor",
            Self::Mem => "mem-monitor",
        }
    }

    fn title(&self) -> &'static str {
        match self {
            Self::Cpu => "CPU",
            Self::Mem => "Memory",
        }
    }

    fn interval_secs(&self) -> u64 {
        match self {
            Self::Cpu => 2,
            Self::Mem => 10,
        }
    }
}

#[derive(Clone)]
struct MonitorState {
    history: Arc<Mutex<VecDeque<u32>>>,
    cpu_state: Arc<Mutex<CpuState>>,
}

impl MonitorState {
    fn new() -> Self {
        Self {
            history: Arc::new(Mutex::new(VecDeque::with_capacity(HISTORY_LEN))),
            cpu_state: Arc::new(Mutex::new(CpuState::default())),
        }
    }

    fn push_cpu(&self) {
        let pct = read_cpu(&mut self.cpu_state.lock().unwrap());
        let mut h = self.history.lock().unwrap();
        if h.len() >= HISTORY_LEN {
            h.pop_front();
        }
        h.push_back(pct);
    }

    fn push_mem(&self) {
        let pct = read_mem();
        let mut h = self.history.lock().unwrap();
        if h.len() >= HISTORY_LEN {
            h.pop_front();
        }
        h.push_back(pct);
    }

    fn current(&self) -> u32 {
        self.history.lock().unwrap().back().copied().unwrap_or(0)
    }

    fn icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        render_sparkline(&self.history.lock().unwrap())
    }

    fn tooltip(&self, label: &str) -> String {
        format!("{}: {}%", label, self.current())
    }
}

struct StatusNotifierItem {
    state: MonitorState,
    id: &'static str,
    title: &'static str,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str {
        "SystemServices"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        self.id
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        self.title
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
        (String::new(), vec![], self.state.tooltip(self.title), String::new())
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
    let metric = env::args()
        .nth(1)
        .and_then(|s| Metric::from_arg(&s))
        .expect("usage: system-monitor-tray <cpu|mem>");

    let conn = Connection::session().await?;
    let state = MonitorState::new();

    // Prime initial reading
    match &metric {
        Metric::Cpu => { state.push_cpu(); }
        Metric::Mem => { state.push_mem(); }
    }

    let sni = StatusNotifierItem {
        state: state.clone(),
        id: metric.id(),
        title: metric.title(),
    };

    let bus_name = metric.bus_name();
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

    let mut tick = interval(Duration::from_secs(metric.interval_secs()));

    loop {
        tokio::select! {
            _ = tick.tick() => {
                match &metric {
                    Metric::Cpu => state.push_cpu(),
                    Metric::Mem => state.push_mem(),
                }
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
