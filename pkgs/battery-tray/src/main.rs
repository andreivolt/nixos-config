use std::sync::{Arc, Mutex};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const UPOWER_BATTERY: &str = "/org/freedesktop/UPower/devices/battery_macsmc_battery";
const UPOWER_AC: &str = "/org/freedesktop/UPower/devices/line_power_macsmc_ac";
const ICON_SIZE: i32 = 20;
const FONT_SIZE: f64 = 10.0;

fn lerp_color(c0: (u8, u8, u8), c1: (u8, u8, u8), t: f64) -> (u8, u8, u8) {
    let t = t.clamp(0.0, 1.0);
    (
        (c0.0 as f64 + t * (c1.0 as f64 - c0.0 as f64)).round() as u8,
        (c0.1 as f64 + t * (c1.1 as f64 - c0.1 as f64)).round() as u8,
        (c0.2 as f64 + t * (c1.2 as f64 - c0.2 as f64)).round() as u8,
    )
}

fn text_color(pct: u32) -> (u8, u8, u8) {
    const STOPS: &[(f64, (u8, u8, u8))] = &[
        (0.0, (0xcc, 0x66, 0x66)),   // red
        (25.0, (0xde, 0x93, 0x5f)),  // orange
        (50.0, (0xf0, 0xc6, 0x74)),  // yellow
        (100.0, (0xaa, 0xaa, 0xaa)), // gray
    ];
    let p = pct as f64;
    let mut i = 0;
    while i + 1 < STOPS.len() && STOPS[i + 1].0 <= p {
        i += 1;
    }
    if i + 1 >= STOPS.len() {
        return STOPS[STOPS.len() - 1].1;
    }
    let (p0, c0) = STOPS[i];
    let (p1, c1) = STOPS[i + 1];
    lerp_color(c0, c1, (p - p0) / (p1 - p0))
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

fn surface_to_pixmap(surface: &mut cairo::ImageSurface) -> Vec<(i32, i32, Vec<u8>)> {
    surface.flush();
    let size = surface.width();
    let stride = surface.stride() as usize;
    let data = surface.data().unwrap();

    let mut buf = vec![0u8; (size * size * 4) as usize];
    for y in 0..size as usize {
        for x in 0..size as usize {
            let src = y * stride + x * 4;
            let dst = (y * size as usize + x) * 4;
            let a = data[src + 3];
            if a > 0 {
                let r = ((data[src + 2] as u32 * 255) / a as u32).min(255) as u8;
                let g = ((data[src + 1] as u32 * 255) / a as u32).min(255) as u8;
                let b = ((data[src] as u32 * 255) / a as u32).min(255) as u8;
                buf[dst] = a;
                buf[dst + 1] = r;
                buf[dst + 2] = g;
                buf[dst + 3] = b;
            }
        }
    }

    vec![(size, size, buf)]
}

fn set_color(cr: &cairo::Context, color: (u8, u8, u8)) {
    cr.set_source_rgba(
        f64::from(color.0) / 255.0,
        f64::from(color.1) / 255.0,
        f64::from(color.2) / 255.0,
        1.0,
    );
}

fn render_icon(pct: u32, charging: bool, scale: f64) -> Vec<(i32, i32, Vec<u8>)> {
    let size = (f64::from(ICON_SIZE) * scale).round() as i32;
    let center = f64::from(size) / 2.0;
    let radius = center - 1.0 * scale;
    let color = text_color(pct);

    let mut surface = cairo::ImageSurface::create(cairo::Format::ARgb32, size, size).unwrap();
    let cr = cairo::Context::new(&surface).unwrap();

    cr.arc(center, center, radius, 0.0, 2.0 * std::f64::consts::PI);
    set_color(&cr, color);
    if charging {
        cr.fill().unwrap();
    } else {
        cr.set_line_width(1.0 * scale);
        cr.stroke().unwrap();
    }

    if pct < 100 {
        let text = format!("{}", pct);
        let text_color = if charging { (0, 0, 0) } else { (0xaa, 0xaa, 0xaa) };

        let layout = pangocairo::functions::create_layout(&cr);
        let mut font = pango::FontDescription::new();
        font.set_family(env!("FONT_FAMILY"));
        font.set_weight(pango::Weight::Bold);
        font.set_absolute_size(FONT_SIZE * scale * f64::from(pango::SCALE));
        layout.set_font_description(Some(&font));
        layout.set_text(&text);

        let (text_w, text_h) = layout.pixel_size();
        cr.move_to(
            (f64::from(size) - f64::from(text_w)) / 2.0,
            (f64::from(size) - f64::from(text_h)) / 2.0,
        );
        set_color(&cr, text_color);
        pangocairo::functions::show_layout(&cr, &layout);
    }

    drop(cr);
    surface_to_pixmap(&mut surface)
}

// UPower State: 1=Charging, 2=Discharging, 3=Empty, 4=FullyCharged, 5=PendingCharge, 6=PendingDischarge
fn is_charging(state: u32) -> bool {
    matches!(state, 1 | 5)
}

struct BatteryReading {
    pct: u32,
    charging: bool,
    time_to_full: i64,
    time_to_empty: i64,
}

async fn get_upower_property<T: TryFrom<zbus::zvariant::OwnedValue>>(conn: &Connection, path: &str, prop: &str) -> Option<T> {
    conn.call_method(
        Some("org.freedesktop.UPower"),
        path,
        Some("org.freedesktop.DBus.Properties"),
        "Get",
        &("org.freedesktop.UPower.Device", prop),
    )
    .await
    .ok()
    .and_then(|r| r.body().deserialize::<zbus::zvariant::OwnedValue>().ok())
    .and_then(|v| T::try_from(v).ok())
}

async fn read_battery(system_conn: &Connection) -> BatteryReading {
    let pct: f64 = get_upower_property(system_conn, UPOWER_BATTERY, "Percentage").await.unwrap_or(0.0);
    let pct = pct.round() as u32;

    let state: u32 = get_upower_property(system_conn, UPOWER_BATTERY, "State").await.unwrap_or(0);
    let ac_online: bool = get_upower_property(system_conn, UPOWER_AC, "Online").await.unwrap_or(false);
    let charging = is_charging(state) || ac_online;
    let time_to_full: i64 = get_upower_property(system_conn, UPOWER_BATTERY, "TimeToFull").await.unwrap_or(0);
    let time_to_empty: i64 = get_upower_property(system_conn, UPOWER_BATTERY, "TimeToEmpty").await.unwrap_or(0);

    BatteryReading { pct, charging, time_to_full, time_to_empty }
}

fn format_duration(secs: i64) -> String {
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
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> {
        let r = self.inner.lock().unwrap();
        render_icon(r.pct, r.charging, self.scale)
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

struct Sni {
    state: BatteryState,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl Sni {
    #[zbus(property)]
    fn category(&self) -> &str { "SystemServices" }
    #[zbus(property)]
    fn id(&self) -> &str { "battery-tray" }
    #[zbus(property)]
    fn title(&self) -> &str { "Battery" }
    #[zbus(property)]
    fn status(&self) -> &str { "Active" }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> { self.state.icon_pixmap() }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool { false }
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

    let system_conn = Connection::system().await?;
    let initial = read_battery(&system_conn).await;
    let state = BatteryState {
        inner: Arc::new(Mutex::new(initial)),
        scale,
    };

    let session_conn = Connection::session().await?;
    let bus_name = "org.kde.StatusNotifierItem-battery-tray";
    session_conn.object_server().at(SNI_PATH, Sni { state: state.clone() }).await?;
    session_conn.request_name(bus_name).await?;
    register_sni(&session_conn, bus_name).await;

    // watch for SNI watcher restarts
    let watcher_rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .path("/org/freedesktop/DBus")?
        .build();
    let mut watcher_stream =
        zbus::MessageStream::for_match_rule(watcher_rule, &session_conn, Some(16)).await?;

    // watch UPower battery property changes on system bus
    let upower_rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path(UPOWER_BATTERY)?
        .build();
    let upower_stream =
        zbus::MessageStream::for_match_rule(upower_rule, &system_conn, Some(16)).await?;

    // watch AC adapter — UPower delays battery State on plug-in by ~3s, but AC Online changes instantly
    let ac_rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path(UPOWER_AC)?
        .build();
    let ac_stream =
        zbus::MessageStream::for_match_rule(ac_rule, &system_conn, Some(16)).await?;

    let iface = session_conn
        .object_server()
        .interface::<_, Sni>(SNI_PATH)
        .await?;

    let mut last_charging = state.inner.lock().unwrap().charging;
    // after plug-in, suppress false readings for this duration (USB-C PD negotiation causes transient disconnects)
    let mut suppress_uncharge_until: Option<tokio::time::Instant> = None;
    let mut upower_events = futures_util::stream::select(upower_stream, ac_stream);

    loop {
        tokio::select! {
            Some(Ok(_)) = futures_util::StreamExt::next(&mut upower_events) => {
                let reading = read_battery(&system_conn).await;
                if reading.charging && !last_charging {
                    // plug-in: commit immediately, suppress PD negotiation bounces for 2s
                    last_charging = true;
                    suppress_uncharge_until = Some(tokio::time::Instant::now() + tokio::time::Duration::from_secs(2));
                    *state.inner.lock().unwrap() = reading;
                    let e = iface.signal_emitter();
                    let _ = Sni::new_icon(&e).await;
                    let _ = Sni::new_tool_tip(&e).await;
                } else if !reading.charging && last_charging {
                    let suppressed = suppress_uncharge_until.map_or(false, |t| tokio::time::Instant::now() < t);
                    if !suppressed {
                        // real unplug: instant
                        last_charging = false;
                        suppress_uncharge_until = None;
                        *state.inner.lock().unwrap() = reading;
                        let e = iface.signal_emitter();
                        let _ = Sni::new_icon(&e).await;
                        let _ = Sni::new_tool_tip(&e).await;
                    }
                } else {
                    // same charging state: update percentage/tooltip
                    *state.inner.lock().unwrap() = reading;
                    let e = iface.signal_emitter();
                    let _ = Sni::new_icon(&e).await;
                    let _ = Sni::new_tool_tip(&e).await;
                }
            }
            Some(Ok(msg)) = futures_util::StreamExt::next(&mut watcher_stream) => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        register_sni(&session_conn, bus_name).await;
                    }
                }
            }
        }
    }
}
