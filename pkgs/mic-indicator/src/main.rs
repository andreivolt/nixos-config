use tokio::process::Command;
use tokio::time::{interval, Duration};
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const BUS_NAME: &str = "org.kde.StatusNotifierItem-mic-indicator";
const ICON_SIZE: i32 = 22;
const DOT_RADIUS: f64 = 7.0;
const DOT_COLOR: (u8, u8, u8) = (0xff, 0x9f, 0x0a);

fn render_icon() -> Vec<(i32, i32, Vec<u8>)> {
    let s = ICON_SIZE as usize;
    let mut buf = vec![0u8; s * s * 4];
    let c = s as f64 / 2.0;
    for y in 0..s {
        for x in 0..s {
            let dx = x as f64 - c + 0.5;
            let dy = y as f64 - c + 0.5;
            let dist = (dx * dx + dy * dy).sqrt();
            if dist <= DOT_RADIUS {
                let alpha = ((DOT_RADIUS - dist + 0.5).min(1.0).max(0.0) * 255.0) as u8;
                let off = (y * s + x) * 4;
                buf[off] = alpha;
                buf[off + 1] = DOT_COLOR.0;
                buf[off + 2] = DOT_COLOR.1;
                buf[off + 3] = DOT_COLOR.2;
            }
        }
    }
    vec![(ICON_SIZE, ICON_SIZE, buf)]
}

async fn check_mic() -> bool {
    let Ok(o) = Command::new("pw-cli").args(["ls", "Node"]).output().await else {
        return false;
    };
    let text = String::from_utf8_lossy(&o.stdout);

    let mut is_input = false;
    let mut has_app = false;
    for line in text.lines() {
        if line.starts_with('\t') && line.contains("type PipeWire:Interface:Node") {
            if is_input && has_app {
                return true;
            }
            is_input = false;
            has_app = false;
        }
        if line.contains("media.class") && line.contains("Stream/Input/Audio") {
            is_input = true;
        }
        if line.contains("application.name") {
            has_app = true;
        }
    }
    is_input && has_app
}

struct StatusNotifierItem;

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str { "Hardware" }
    #[zbus(property)]
    fn id(&self) -> &str { "mic-indicator" }
    #[zbus(property)]
    fn title(&self) -> &str { "Microphone" }
    #[zbus(property)]
    fn status(&self) -> &str { "Active" }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> { render_icon() }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool { false }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        (String::new(), vec![], "Microphone in use".into(), String::new())
    }
    fn activate(&self, _x: i32, _y: i32) {}
    fn secondary_activate(&self, _x: i32, _y: i32) {}
    fn context_menu(&self, _x: i32, _y: i32) {}
    fn scroll(&self, _delta: i32, _orientation: &str) {}
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

/// Create a new D-Bus connection with the SNI object and register it.
/// Dropping the returned Connection unregisters the item from the tray.
async fn show() -> Option<Connection> {
    let conn = Connection::session().await.ok()?;
    conn.object_server().at(SNI_PATH, StatusNotifierItem).await.ok()?;
    conn.request_name(BUS_NAME).await.ok()?;
    register_sni(&conn).await;
    Some(conn)
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut sni_conn: Option<Connection> = None;

    if check_mic().await {
        sni_conn = show().await;
    }

    let mut tick = interval(Duration::from_secs(2));

    loop {
        tick.tick().await;

        let is = check_mic().await;
        let was = sni_conn.is_some();

        if is && !was {
            sni_conn = show().await;
        } else if !is && was {
            drop(sni_conn.take());
        }
    }
}
