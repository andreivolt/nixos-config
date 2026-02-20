use futures_util::StreamExt;
use std::process::Command;
use std::sync::{Arc, Mutex};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const LAN_MOUSE_BIN: &str = env!("LAN_MOUSE_BIN");
const BUS_NAME: &str = "org.kde.StatusNotifierItem-lan-mouse";
const SNI_PATH: &str = "/StatusNotifierItem";

#[derive(Clone)]
struct State {
    inner: Arc<Mutex<bool>>,
}

impl State {
    fn new(active: bool) -> Self {
        Self {
            inner: Arc::new(Mutex::new(active)),
        }
    }
    fn get(&self) -> bool {
        *self.inner.lock().unwrap()
    }
    fn set(&self, v: bool) {
        *self.inner.lock().unwrap() = v;
    }
}

struct StatusNotifierItem {
    state: State,
    icon_theme_path: String,
    toggle_tx: tokio::sync::mpsc::UnboundedSender<()>,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str {
        "ApplicationStatus"
    }
    #[zbus(property)]
    fn id(&self) -> &str {
        "lan-mouse-tray"
    }
    #[zbus(property)]
    fn title(&self) -> &str {
        "Lan Mouse"
    }
    #[zbus(property)]
    fn status(&self) -> &str {
        "Active"
    }
    #[zbus(property)]
    fn icon_name(&self) -> String {
        if self.state.get() {
            "lan-mouse-on".into()
        } else {
            "lan-mouse-off".into()
        }
    }
    #[zbus(property)]
    fn icon_theme_path(&self) -> &str {
        &self.icon_theme_path
    }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool {
        false
    }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        let tip = if self.state.get() {
            "Lan Mouse: ON"
        } else {
            "Lan Mouse: OFF"
        };
        (String::new(), vec![], tip.into(), String::new())
    }

    fn activate(&self, _x: i32, _y: i32) {
        let _ = self.toggle_tx.send(());
    }
    fn secondary_activate(&self, _x: i32, _y: i32) {}
    fn context_menu(&self, _x: i32, _y: i32) {}
    fn scroll(&self, _delta: i32, _orientation: &str) {}

    #[zbus(signal)]
    async fn new_icon(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
    #[zbus(signal)]
    async fn new_tooltip(emitter: &SignalEmitter<'_>) -> zbus::Result<()>;
}

fn icon_theme_path() -> String {
    env!("ICON_THEME_PATH").to_string()
}

fn query_capture_active() -> bool {
    Command::new(LAN_MOUSE_BIN)
        .args(["cli", "list"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).contains("active: true"))
        .unwrap_or(false)
}

fn set_capture(active: bool) {
    let subcmd = if active { "activate" } else { "deactivate" };
    let _ = Command::new(LAN_MOUSE_BIN)
        .args(["cli", subcmd, "0"])
        .status();
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

    let active = query_capture_active();
    let icon_theme_path = icon_theme_path();
    let state = State::new(active);

    let (toggle_tx, mut toggle_rx) = tokio::sync::mpsc::unbounded_channel::<()>();

    let sni = StatusNotifierItem {
        state: state.clone(),
        icon_theme_path,
        toggle_tx,
    };

    conn.object_server().at(SNI_PATH, sni).await?;
    conn.request_name(BUS_NAME).await?;
    register_sni(&conn).await;

    // Re-register when StatusNotifierWatcher reappears
    let conn2 = conn.clone();
    let rule_watcher = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .path("/org/freedesktop/DBus")?
        .build();
    let mut watcher_stream =
        zbus::MessageStream::for_match_rule(rule_watcher, &conn, Some(16)).await?;

    let iface_ref = conn
        .object_server()
        .interface::<_, StatusNotifierItem>(SNI_PATH)
        .await?;

    loop {
        tokio::select! {
            Some(()) = toggle_rx.recv() => {
                let was_active = state.get();
                set_capture(!was_active);
                let new_active = query_capture_active();
                state.set(new_active);
                if new_active != was_active {
                    let emitter = iface_ref.signal_emitter();
                    let _ = StatusNotifierItem::new_icon(&emitter).await;
                    let _ = StatusNotifierItem::new_tooltip(&emitter).await;
                }
            }
            Some(Ok(msg)) = watcher_stream.next() => {
                if let Ok(body) = msg.body().deserialize::<(String, String, String)>() {
                    if body.0 == "org.kde.StatusNotifierWatcher" && !body.2.is_empty() {
                        register_sni(&conn2).await;
                    }
                }
            }
        }
    }
}
