use futures_util::StreamExt;
use std::sync::{Arc, Mutex};
use zbus::object_server::SignalEmitter;
use zbus::{interface, Connection};

const UNIT: &str = "lan-mouse.service";
const UNIT_PATH: &str = "/org/freedesktop/systemd1/unit/lan_2dmouse_2eservice";
const BUS_NAME: &str = "org.kde.StatusNotifierItem-lan-mouse";
const SNI_PATH: &str = "/StatusNotifierItem";


#[derive(Clone)]
struct State {
    inner: Arc<Mutex<bool>>,
}

impl State {
    fn new(active: bool) -> Self {
        Self { inner: Arc::new(Mutex::new(active)) }
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
    toggle_tx: tokio::sync::mpsc::UnboundedSender<bool>,
}

#[interface(name = "org.kde.StatusNotifierItem")]
impl StatusNotifierItem {
    #[zbus(property)]
    fn category(&self) -> &str { "ApplicationStatus" }
    #[zbus(property)]
    fn id(&self) -> &str { "lan-mouse-tray" }
    #[zbus(property)]
    fn title(&self) -> &str { "Lan Mouse" }
    #[zbus(property)]
    fn status(&self) -> &str { "Active" }
    #[zbus(property)]
    fn icon_name(&self) -> String {
        if self.state.get() { "lan-mouse-on".into() } else { "lan-mouse-off".into() }
    }
    #[zbus(property)]
    fn icon_theme_path(&self) -> &str { &self.icon_theme_path }
    #[zbus(property)]
    fn item_is_menu(&self) -> bool { false }
    #[zbus(property)]
    fn tool_tip(&self) -> (String, Vec<(i32, i32, Vec<u8>)>, String, String) {
        let tip = if self.state.get() { "Lan Mouse: ON" } else { "Lan Mouse: OFF" };
        (String::new(), vec![], tip.into(), String::new())
    }

    fn activate(&self, _x: i32, _y: i32) {
        let _ = self.toggle_tx.send(self.state.get());
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
    let pkg_data = env!("ICON_THEME_PATH");
    pkg_data.to_string()
}

async fn is_unit_active(conn: &Connection) -> bool {
    let reply = conn
        .call_method(
            Some("org.freedesktop.systemd1"),
            UNIT_PATH,
            Some("org.freedesktop.DBus.Properties"),
            "Get",
            &("org.freedesktop.systemd1.Unit", "ActiveState"),
        )
        .await;
    match reply {
        Ok(msg) => {
            if let Ok(val) = msg.body().deserialize::<zbus::zvariant::OwnedValue>() {
                let s: String = val.try_into().unwrap_or_default();
                s == "active"
            } else {
                false
            }
        }
        Err(_) => false,
    }
}

async fn toggle_unit(conn: &Connection, currently_active: bool) {
    let method = if currently_active { "StopUnit" } else { "StartUnit" };
    let state_file = format!(
        "{}/.local/state/lan-mouse-disabled",
        std::env::var("HOME").unwrap_or_default()
    );
    if currently_active {
        let _ = std::fs::create_dir_all(std::path::Path::new(&state_file).parent().unwrap());
        let _ = std::fs::File::create(&state_file);
    } else {
        let _ = std::fs::remove_file(&state_file);
    }
    let _ = conn
        .call_method(
            Some("org.freedesktop.systemd1"),
            "/org/freedesktop/systemd1",
            Some("org.freedesktop.systemd1.Manager"),
            method,
            &(UNIT, "replace"),
        )
        .await;
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

    // Subscribe to systemd signals
    let _ = conn
        .call_method(
            Some("org.freedesktop.systemd1"),
            "/org/freedesktop/systemd1",
            Some("org.freedesktop.systemd1.Manager"),
            "Subscribe",
            &(),
        )
        .await;

    let active = is_unit_active(&conn).await;
    let icon_theme_path = icon_theme_path();
    let state = State::new(active);

    let (toggle_tx, mut toggle_rx) = tokio::sync::mpsc::unbounded_channel::<bool>();

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

    // Watch for PropertiesChanged on the lan-mouse unit
    let rule_props = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path(UNIT_PATH)?
        .build();
    let mut props_stream =
        zbus::MessageStream::for_match_rule(rule_props, &conn, Some(16)).await?;

    let iface_ref = conn
        .object_server()
        .interface::<_, StatusNotifierItem>(SNI_PATH)
        .await?;

    loop {
        tokio::select! {
            Some(current) = toggle_rx.recv() => {
                toggle_unit(&conn2, current).await;
            }
            Some(_) = props_stream.next() => {
                let new_active = is_unit_active(&conn2).await;
                if new_active != state.get() {
                    state.set(new_active);
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
