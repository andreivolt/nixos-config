use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::mpsc;
use tokio::time::{sleep, Duration};
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
    let output = Command::new("pw-cli")
        .args(["ls", "Node"])
        .output()
        .await;
    let Ok(o) = output else { return false };
    let text = String::from_utf8_lossy(&o.stdout);

    // Parse pw-cli output into node blocks, check for client input streams
    // (nodes with both Stream/Input/Audio and application.name)
    // This excludes hardware effect nodes like audio_effect.j413-mic
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
    fn category(&self) -> &str {
        "Hardware"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        "mic-indicator"
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        "Microphone"
    }
    #[zbus(property)]
    fn status(&self) -> &str {
        "Active"
    }
    #[zbus(property)]
    fn icon_pixmap(&self) -> Vec<(i32, i32, Vec<u8>)> {
        render_icon()
    }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        (
            String::new(),
            vec![],
            "Microphone in use".into(),
            String::new(),
        )
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

async fn show(conn: &Connection) {
    let _ = conn
        .request_name(BUS_NAME)
        .await;
    register_sni(conn).await;
}

async fn hide(conn: &Connection) {
    let _ = conn
        .release_name(BUS_NAME)
        .await;
}

async fn run_pw_monitor(tx: mpsc::Sender<()>) {
    loop {
        let child = Command::new("pw-mon")
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::null())
            .spawn();

        if let Ok(mut child) = child {
            if let Some(stdout) = child.stdout.take() {
                let reader = BufReader::new(stdout);
                let mut lines = reader.lines();
                while let Ok(Some(line)) = lines.next_line().await {
                    if line.contains("added") || line.contains("removed") {
                        let _ = tx.send(()).await;
                    }
                }
            }
            let _ = child.wait().await;
        }

        sleep(Duration::from_secs(1)).await;
    }
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let visible = Arc::new(AtomicBool::new(false));

    let conn = Connection::session().await?;
    conn.object_server().at(SNI_PATH, StatusNotifierItem).await?;

    // Set initial state
    if check_mic().await {
        show(&conn).await;
        visible.store(true, Ordering::Relaxed);
    }

    // Re-register when StatusNotifierWatcher restarts
    let conn2 = conn.clone();
    let visible2 = visible.clone();
    let rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .path("/org/freedesktop/DBus")?
        .build();
    let mut watcher_stream =
        zbus::MessageStream::for_match_rule(rule, &conn, Some(16)).await?;

    let (tx, mut rx) = mpsc::channel(16);
    tokio::spawn(run_pw_monitor(tx));

    loop {
        tokio::select! {
            Some(()) = rx.recv() => {
                sleep(Duration::from_millis(100)).await;
                while rx.try_recv().is_ok() {}

                let was = visible.load(Ordering::Relaxed);
                let is = check_mic().await;
                if is && !was {
                    show(&conn).await;
                    visible.store(true, Ordering::Relaxed);
                } else if !is && was {
                    hide(&conn).await;
                    visible.store(false, Ordering::Relaxed);
                }
            }
            Some(Ok(msg)) = futures_util::StreamExt::next(&mut watcher_stream) => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        if visible2.load(Ordering::Relaxed) {
                            register_sni(&conn2).await;
                        }
                    }
                }
            }
        }
    }
}
