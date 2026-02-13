use futures_util::StreamExt;
use ksni::TrayMethods;
use tokio::sync::mpsc;
use zbus::Connection;

const UNIT: &str = "lan-mouse.service";
const UNIT_PATH: &str = "/org/freedesktop/systemd1/unit/lan_2dmouse_2eservice";

struct LanMouseTray {
    active: bool,
    tx: mpsc::UnboundedSender<()>,
}

impl ksni::Tray for LanMouseTray {
    fn id(&self) -> String {
        "lan-mouse-tray".into()
    }

    fn title(&self) -> String {
        if self.active {
            "Lan Mouse: ON".into()
        } else {
            "Lan Mouse: OFF".into()
        }
    }

    fn icon_pixmap(&self) -> Vec<ksni::Icon> {
        let color = if self.active { "#7a9aaa" } else { "#4d4a46" };
        render_mouse_icon(color)
    }

    fn activate(&mut self, _x: i32, _y: i32) {
        let _ = self.tx.send(());
    }

    fn menu(&self) -> Vec<ksni::MenuItem<Self>> {
        use ksni::menu::*;
        vec![
            StandardItem {
                label: if self.active {
                    "Disable".into()
                } else {
                    "Enable".into()
                },
                activate: Box::new(|this: &mut Self| {
                    let _ = this.tx.send(());
                }),
                ..Default::default()
            }
            .into(),
        ]
    }
}

fn render_mouse_icon(color: &str) -> Vec<ksni::Icon> {
    let svg = format!(
        r#"<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22">
         <path fill="{color}" d="M 11,3 C 8.23,3 6,5.45 6,8.5 v 5 c 0,3.05 2.23,5.5 5,5.5 2.77,0 5,-2.45 5,-5.5 v -5 C 16,5.45 13.77,3 11,3 Z m 0,3 c 0.55,0 1,0.45 1,1 v 2 c 0,0.55 -0.45,1 -1,1 -0.55,0 -1,-0.45 -1,-1 V 7 c 0,-0.55 0.45,-1 1,-1 z"/>
        </svg>"#
    );
    let tree = resvg::usvg::Tree::from_str(&svg, &Default::default()).unwrap();
    let size = 22;
    let mut pixmap = tiny_skia::Pixmap::new(size, size).unwrap();
    resvg::render(&tree, tiny_skia::Transform::default(), &mut pixmap.as_mut());
    // Convert from RGBA to ARGB (ksni Icon format)
    let rgba = pixmap.data();
    let mut argb = Vec::with_capacity(rgba.len());
    for chunk in rgba.chunks_exact(4) {
        argb.extend_from_slice(&[chunk[3], chunk[0], chunk[1], chunk[2]]);
    }
    vec![ksni::Icon {
        width: size as i32,
        height: size as i32,
        data: argb,
    }]
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
                let state: String = val.try_into().unwrap_or_default();
                state == "active"
            } else {
                false
            }
        }
        Err(_) => false,
    }
}

async fn toggle_unit(conn: &Connection, currently_active: bool) {
    let method = if currently_active {
        "StopUnit"
    } else {
        "StartUnit"
    };
    // Maintain state file for ConditionPathExists in the systemd unit
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

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let conn = Connection::session().await?;

    // Subscribe to systemd signals so PropertiesChanged is emitted
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

    let (tx, mut rx) = mpsc::unbounded_channel::<()>();

    let tray = LanMouseTray { active, tx };
    let handle = tray.spawn().await?;

    // Watch for PropertiesChanged on the lan-mouse unit object
    let rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path(UNIT_PATH)?
        .build();
    let mut stream = zbus::MessageStream::for_match_rule(rule, &conn, Some(16)).await?;

    loop {
        tokio::select! {
            Some(()) = rx.recv() => {
                let current = handle.update(|t: &mut LanMouseTray| t.active).await.unwrap_or(false);
                toggle_unit(&conn, current).await;
            }
            Some(_) = stream.next() => {
                let new_active = is_unit_active(&conn).await;
                handle.update(|t: &mut LanMouseTray| {
                    t.active = new_active;
                }).await;
            }
        }
    }
}
