use std::collections::VecDeque;
use std::env;
use std::sync::{Arc, Mutex};
use std::time::Instant;
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

fn set_pixel(buf: &mut [u8], w: usize, x: usize, y: usize, r: u8, g: u8, b: u8) {
    let off = (y * w + x) * 4;
    buf[off] = 255;
    buf[off + 1] = r;
    buf[off + 2] = g;
    buf[off + 3] = b;
}

fn pct_to_y(h: usize, pct: u32) -> usize {
    let fill_h = ((h as u32 * pct) / 100).max(1) as usize;
    h - fill_h
}

fn draw_connected_line(
    buf: &mut [u8],
    w: usize,
    _h: usize,
    x: usize,
    cur_y: usize,
    prev_y: Option<usize>,
    r: u8,
    g: u8,
    b: u8,
) {
    let y_min = if let Some(py) = prev_y { cur_y.min(py) } else { cur_y };
    let y_max = if let Some(py) = prev_y { cur_y.max(py) } else { cur_y };
    for y in y_min..=y_max {
        set_pixel(buf, w, x, y, r, g, b);
    }
}

fn render_sparkline(history: &VecDeque<u32>) -> Vec<(i32, i32, Vec<u8>)> {
    let w = ICON_SIZE as usize;
    let h = ICON_SIZE as usize;
    let mut buf = vec![0u8; w * h * 4];

    let offset = HISTORY_LEN.saturating_sub(history.len());
    let mut prev_y: Option<usize> = None;
    for (i, &pct) in history.iter().enumerate() {
        let x = offset + i;
        if x >= w {
            break;
        }
        let cur_y = pct_to_y(h, pct);
        let (r, g, b) = level_color(pct);
        draw_connected_line(&mut buf, w, h, x, cur_y, prev_y, r, g, b);
        prev_y = Some(cur_y);
    }

    vec![(ICON_SIZE, ICON_SIZE, buf)]
}

fn format_rate(bps: u64) -> String {
    if bps >= 1_000_000_000 {
        format!("{:.1} GB/s", bps as f64 / 1_000_000_000.0)
    } else if bps >= 1_000_000 {
        format!("{:.1} MB/s", bps as f64 / 1_000_000.0)
    } else if bps >= 1_000 {
        format!("{:.0} KB/s", bps as f64 / 1_000.0)
    } else {
        format!("{} B/s", bps)
    }
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

struct NetBytesState {
    prev_rx: u64,
    prev_tx: u64,
    last_read: Instant,
    initialized: bool,
}

fn read_net_bytes() -> (u64, u64) {
    let Ok(data) = std::fs::read_to_string("/proc/net/dev") else { return (0, 0) };
    let mut total_rx = 0u64;
    let mut total_tx = 0u64;
    for line in data.lines().skip(2) {
        let Some((iface, rest)) = line.split_once(':') else { continue };
        if iface.trim() == "lo" {
            continue;
        }
        let vals: Vec<u64> = rest
            .split_whitespace()
            .filter_map(|s| s.parse().ok())
            .collect();
        if vals.len() >= 10 {
            total_rx += vals[0];
            total_tx += vals[8];
        }
    }
    (total_rx, total_tx)
}

#[derive(Clone, Copy)]
enum Metric {
    Cpu,
    Mem,
    NetRx,
    NetTx,
}

impl Metric {
    fn from_arg(s: &str) -> Option<Self> {
        match s {
            "cpu" => Some(Self::Cpu),
            "mem" => Some(Self::Mem),
            "net-rx" => Some(Self::NetRx),
            "net-tx" => Some(Self::NetTx),
            _ => None,
        }
    }

    fn bus_name(&self) -> &'static str {
        match self {
            Self::Cpu => "org.kde.StatusNotifierItem-cpu-monitor",
            Self::Mem => "org.kde.StatusNotifierItem-mem-monitor",
            Self::NetRx => "org.kde.StatusNotifierItem-net-rx-monitor",
            Self::NetTx => "org.kde.StatusNotifierItem-net-tx-monitor",
        }
    }

    fn id(&self) -> &'static str {
        match self {
            Self::Cpu => "cpu-monitor",
            Self::Mem => "mem-monitor",
            Self::NetRx => "net-rx-monitor",
            Self::NetTx => "net-tx-monitor",
        }
    }

    fn title(&self) -> &'static str {
        match self {
            Self::Cpu => "CPU",
            Self::Mem => "Memory",
            Self::NetRx => "Network ↓",
            Self::NetTx => "Network ↑",
        }
    }

    fn interval_secs(&self) -> u64 {
        match self {
            Self::Cpu => 2,
            Self::Mem => 10,
            Self::NetRx | Self::NetTx => 2,
        }
    }

    fn is_net(&self) -> bool {
        matches!(self, Self::NetRx | Self::NetTx)
    }
}

#[derive(Clone)]
struct MonitorState {
    history: Arc<Mutex<VecDeque<u32>>>,
    cpu_state: Arc<Mutex<CpuState>>,
    net_bytes: Arc<Mutex<NetBytesState>>,
    net_rates: Arc<Mutex<VecDeque<u64>>>,
    current_rate: Arc<Mutex<u64>>,
    peak_rate: Arc<Mutex<u64>>,
}

impl MonitorState {
    fn new() -> Self {
        Self {
            history: Arc::new(Mutex::new(VecDeque::with_capacity(HISTORY_LEN))),
            cpu_state: Arc::new(Mutex::new(CpuState::default())),
            net_bytes: Arc::new(Mutex::new(NetBytesState {
                prev_rx: 0,
                prev_tx: 0,
                last_read: Instant::now(),
                initialized: false,
            })),
            net_rates: Arc::new(Mutex::new(VecDeque::with_capacity(HISTORY_LEN))),
            current_rate: Arc::new(Mutex::new(0)),
            peak_rate: Arc::new(Mutex::new(0)),
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

    fn push_net(&self, metric: Metric) {
        let (rx_total, tx_total) = read_net_bytes();
        let mut nb = self.net_bytes.lock().unwrap();

        // Counter reset = network change (new interface, reconnect) — reset scale
        if nb.initialized && (rx_total < nb.prev_rx || tx_total < nb.prev_tx) {
            *self.peak_rate.lock().unwrap() = 0;
            self.net_rates.lock().unwrap().clear();
        }

        if nb.initialized {
            let elapsed = nb.last_read.elapsed().as_secs_f64().max(0.1);
            let rx = (rx_total.saturating_sub(nb.prev_rx) as f64 / elapsed) as u64;
            let tx = (tx_total.saturating_sub(nb.prev_tx) as f64 / elapsed) as u64;
            let rate = match metric {
                Metric::NetRx => rx,
                Metric::NetTx => tx,
                _ => 0,
            };

            *self.current_rate.lock().unwrap() = rate;

            let mut peak = self.peak_rate.lock().unwrap();
            *peak = (*peak).max(rate);
            drop(peak);

            let mut rates = self.net_rates.lock().unwrap();
            if rates.len() >= HISTORY_LEN {
                rates.pop_front();
            }
            rates.push_back(rate);
        }
        nb.prev_rx = rx_total;
        nb.prev_tx = tx_total;
        nb.last_read = Instant::now();
        nb.initialized = true;
    }

    fn current(&self) -> u32 {
        self.history.lock().unwrap().back().copied().unwrap_or(0)
    }

    fn icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        render_sparkline(&self.history.lock().unwrap())
    }

    fn net_icon(&self) -> Vec<(i32, i32, Vec<u8>)> {
        let rates = self.net_rates.lock().unwrap();
        let peak = *self.peak_rate.lock().unwrap();
        let pcts: VecDeque<u32> = if peak == 0 {
            rates.iter().map(|_| 0u32).collect()
        } else {
            rates
                .iter()
                .map(|&r| ((r as f64 / peak as f64).sqrt() * 100.0).round().min(100.0) as u32)
                .collect()
        };
        render_sparkline(&pcts)
    }

    fn tooltip_pct(&self, label: &str) -> String {
        format!("{}: {}%", label, self.current())
    }

    fn tooltip_net(&self, metric: Metric) -> String {
        let arrow = match metric {
            Metric::NetRx => "↓",
            Metric::NetTx => "↑",
            _ => "",
        };
        format!("{} {}", arrow, format_rate(*self.current_rate.lock().unwrap()))
    }
}

struct StatusNotifierItem {
    state: MonitorState,
    id: &'static str,
    title: &'static str,
    metric: Metric,
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
        if self.metric.is_net() {
            self.state.net_icon()
        } else {
            self.state.icon()
        }
    }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        let tip = match self.metric {
            Metric::Cpu | Metric::Mem => self.state.tooltip_pct(self.title),
            m @ (Metric::NetRx | Metric::NetTx) => self.state.tooltip_net(m),
        };
        (String::new(), vec![], tip, String::new())
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
        .expect("usage: system-monitor-tray <cpu|mem|net-rx|net-tx>");

    let conn = Connection::session().await?;
    let state = MonitorState::new();

    // Prime initial reading
    match metric {
        Metric::Cpu => state.push_cpu(),
        Metric::Mem => state.push_mem(),
        m if m.is_net() => state.push_net(m),
        _ => {}
    }

    let sni = StatusNotifierItem {
        state: state.clone(),
        id: metric.id(),
        title: metric.title(),
        metric,
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
                match metric {
                    Metric::Cpu => state.push_cpu(),
                    Metric::Mem => state.push_mem(),
                    m if m.is_net() => state.push_net(m),
                    _ => {}
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
