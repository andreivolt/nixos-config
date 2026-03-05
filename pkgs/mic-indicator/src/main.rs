use std::cell::RefCell;
use std::collections::HashSet;
use std::rc::Rc;

use pipewire as pw;
use pw::main_loop::MainLoopBox;
use pw::context::ContextBox;
use tokio::sync::watch;
use zbus::{interface, Connection};

const SNI_PATH: &str = "/StatusNotifierItem";
const BUS_NAME: &str = "org.kde.StatusNotifierItem-mic-indicator";
const ICON_SIZE: i32 = 20;
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

async fn show() -> Option<Connection> {
    let conn = Connection::session().await.ok()?;
    conn.object_server().at(SNI_PATH, StatusNotifierItem).await.ok()?;
    conn.request_name(BUS_NAME).await.ok()?;
    register_sni(&conn).await;
    Some(conn)
}

fn pipewire_monitor(tx: watch::Sender<bool>) {
    pw::init();

    let mainloop = MainLoopBox::new(None).expect("PipeWire MainLoop");
    let context = ContextBox::new(&mainloop.loop_(), None).expect("PipeWire Context");
    let core = context.connect(None).expect("PipeWire connect");
    let registry = core.get_registry().expect("PipeWire registry");

    let streams: Rc<RefCell<HashSet<u32>>> = Rc::new(RefCell::new(HashSet::new()));
    let tx = Rc::new(tx);

    let sa = streams.clone();
    let ta = tx.clone();
    let sr = streams.clone();
    let tr = tx.clone();

    let _listener = registry
        .add_listener_local()
        .global(move |global| {
            if let Some(props) = &global.props {
                if props.get("media.class") == Some("Stream/Input/Audio")
                    && props.get("application.name").is_some()
                {
                    sa.borrow_mut().insert(global.id);
                    let _ = ta.send(true);
                }
            }
        })
        .global_remove(move |id| {
            let mut s = sr.borrow_mut();
            if s.remove(&id) && s.is_empty() {
                let _ = tr.send(false);
            }
        })
        .register();

    mainloop.run();

    unsafe { pw::deinit(); }
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let (tx, mut rx) = watch::channel(false);

    std::thread::spawn(move || pipewire_monitor(tx));

    let mut sni_conn: Option<Connection> = None;

    loop {
        rx.changed().await?;
        let recording = *rx.borrow();

        if recording && sni_conn.is_none() {
            sni_conn = show().await;
        } else if !recording && sni_conn.is_some() {
            sni_conn = None;
        }
    }
}
