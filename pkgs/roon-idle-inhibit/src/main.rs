use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::env;
use std::process::Stdio;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use tokio::net::TcpStream;
use tokio::process::{Child, Command};
use tokio::sync::Mutex;
use tokio_tungstenite::{connect_async, tungstenite::Message, MaybeTlsStream, WebSocketStream};

const EXTENSION_ID: &str = "com.andrei.roon-idle-inhibit";
const DISPLAY_NAME: &str = "Idle Inhibit";

static REQUEST_ID: AtomicUsize = AtomicUsize::new(1);

#[derive(Debug, Clone, Deserialize)]
struct Zone {
    zone_id: String,
    #[allow(dead_code)]
    display_name: String,
    state: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Config {
    tokens: HashMap<String, String>,
}

impl Config {
    fn load() -> Self {
        let path = config_path();
        std::fs::read_to_string(&path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or(Config {
                tokens: HashMap::new(),
            })
    }

    fn save(&self) {
        let path = config_path();
        if let Some(parent) = std::path::Path::new(&path).parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let _ = std::fs::write(&path, serde_json::to_string_pretty(self).unwrap());
    }
}

fn config_path() -> String {
    env::var("ROON_IDLE_INHIBIT_CONFIG")
        .unwrap_or_else(|_| "/var/lib/roon-idle-inhibit/config.json".to_string())
}

struct InhibitGuard {
    child: Option<Child>,
}

impl InhibitGuard {
    fn new() -> Self {
        Self { child: None }
    }

    async fn set_inhibit(&mut self, inhibit: bool) {
        if inhibit && self.child.is_none() {
            eprintln!("[roon-idle-inhibit] Inhibiting sleep (playback active)");
            match Command::new("systemd-inhibit")
                .args([
                    "--what=sleep",
                    "--who=roon-idle-inhibit",
                    "--why=Roon is playing",
                    "--mode=block",
                    "sleep",
                    "infinity",
                ])
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn()
            {
                Ok(child) => self.child = Some(child),
                Err(e) => eprintln!("[roon-idle-inhibit] Failed to spawn inhibitor: {}", e),
            }
        } else if !inhibit && self.child.is_some() {
            eprintln!("[roon-idle-inhibit] Releasing sleep inhibit (playback stopped)");
            if let Some(mut child) = self.child.take() {
                let _ = child.kill().await;
            }
        }
    }
}

type WsStream = WebSocketStream<MaybeTlsStream<TcpStream>>;

async fn send_request(ws: &mut WsStream, service: &str, method: &str, body: Value) -> usize {
    let req_id = REQUEST_ID.fetch_add(1, Ordering::Relaxed);
    let body_str = body.to_string();
    let msg = format!(
        "MOO/1 REQUEST {}/{}\nRequest-Id: {}\nContent-Length: {}\nContent-Type: application/json\n\n{}",
        service, method, req_id, body_str.len(), body_str
    );
    let _ = ws.send(Message::Binary(msg.into_bytes())).await;
    req_id
}

fn parse_moo_message(data: &[u8]) -> Option<(String, String, usize, Value)> {
    let text = std::str::from_utf8(data).ok()?;
    let (header, body) = text.split_once("\n\n")?;

    let lines: Vec<&str> = header.lines().collect();
    let first_line = lines.first()?;

    // Parse "MOO/1 VERB name" or "MOO/1 VERB service/method"
    let parts: Vec<&str> = first_line.splitn(3, ' ').collect();
    if parts.len() < 3 || !parts[0].starts_with("MOO/") {
        return None;
    }

    let verb = parts[1].to_string();
    let name = parts[2].to_string();

    let mut req_id = 0;
    for line in &lines[1..] {
        if let Some(id_str) = line.strip_prefix("Request-Id: ") {
            req_id = id_str.parse().unwrap_or(0);
        }
    }

    let body_json: Value = if body.is_empty() {
        json!({})
    } else {
        serde_json::from_str(body).unwrap_or(json!({}))
    };

    Some((verb, name, req_id, body_json))
}

async fn run(host: &str, port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let url = format!("ws://{}:{}/api", host, port);
    eprintln!("[roon-idle-inhibit] Connecting to {}", url);

    let (mut ws, _) = connect_async(&url).await?;
    eprintln!("[roon-idle-inhibit] Connected");

    let mut config = Config::load();
    let zones: Arc<Mutex<HashMap<String, Zone>>> = Arc::new(Mutex::new(HashMap::new()));
    let inhibit_guard = Arc::new(Mutex::new(InhibitGuard::new()));
    let mut core_id: Option<String> = None;
    let mut registered = false;
    let mut subscribed = false;

    // Request core info
    let info_req_id = send_request(&mut ws, "com.roonlabs.registry:1", "info", json!({})).await;

    loop {
        let msg = ws.next().await;
        match msg {
            Some(Ok(Message::Binary(data))) => {
                // Ignore empty keepalive messages
                if data.is_empty() {
                    continue;
                }
                if let Some((verb, name, req_id, body)) = parse_moo_message(&data) {
                    match (verb.as_str(), name.as_str()) {
                        // Response to info request
                        ("CONTINUE" | "COMPLETE", _) if req_id == info_req_id && !registered => {
                            if let Some(cid) = body.get("core_id").and_then(|v| v.as_str()) {
                                core_id = Some(cid.to_string());
                                eprintln!("[roon-idle-inhibit] Found core: {}", body.get("display_name").and_then(|v| v.as_str()).unwrap_or("unknown"));

                                // Register extension
                                let token = config.tokens.get(cid).cloned();
                                let mut reg_body = json!({
                                    "extension_id": EXTENSION_ID,
                                    "display_name": DISPLAY_NAME,
                                    "display_version": "0.1.0",
                                    "publisher": "Andrei",
                                    "email": "andrei@example.com",
                                    "required_services": ["com.roonlabs.transport:2"],
                                    "provided_services": []
                                });
                                if let Some(t) = token {
                                    reg_body["token"] = json!(t);
                                }
                                send_request(&mut ws, "com.roonlabs.registry:1", "register", reg_body).await;
                            }
                        }
                        // Registration confirmed
                        ("CONTINUE" | "COMPLETE", "Registered") if !registered => {
                            registered = true;
                            if let Some(token) = body.get("token").and_then(|v| v.as_str()) {
                                if let Some(ref cid) = core_id {
                                    config.tokens.insert(cid.clone(), token.to_string());
                                    config.save();
                                }
                            }
                            eprintln!("[roon-idle-inhibit] Registered with Roon Core");

                            // Subscribe to zones
                            send_request(
                                &mut ws,
                                "com.roonlabs.transport:2",
                                "subscribe_zones",
                                json!({"subscription_key": 1}),
                            )
                            .await;
                        }
                        ("CONTINUE", "Subscribed") | ("CONTINUE", "Changed") => {
                            let mut zones_guard = zones.lock().await;

                            // Handle zones array (initial subscription)
                            if let Some(zone_list) = body.get("zones").and_then(|v| v.as_array()) {
                                for z in zone_list {
                                    if let Ok(zone) = serde_json::from_value::<Zone>(z.clone()) {
                                        zones_guard.insert(zone.zone_id.clone(), zone);
                                    }
                                }
                            }

                            // Handle zones_added
                            if let Some(zone_list) = body.get("zones_added").and_then(|v| v.as_array()) {
                                for z in zone_list {
                                    if let Ok(zone) = serde_json::from_value::<Zone>(z.clone()) {
                                        zones_guard.insert(zone.zone_id.clone(), zone);
                                    }
                                }
                            }

                            // Handle zones_changed
                            if let Some(zone_list) = body.get("zones_changed").and_then(|v| v.as_array()) {
                                for z in zone_list {
                                    if let Ok(zone) = serde_json::from_value::<Zone>(z.clone()) {
                                        zones_guard.insert(zone.zone_id.clone(), zone);
                                    }
                                }
                            }

                            // Handle zones_removed
                            if let Some(zone_ids) = body.get("zones_removed").and_then(|v| v.as_array()) {
                                for zid in zone_ids {
                                    if let Some(id) = zid.as_str() {
                                        zones_guard.remove(id);
                                    }
                                }
                            }

                            // Check if any zone is playing
                            let any_playing = zones_guard.values().any(|z| z.state == "playing");
                            drop(zones_guard);

                            inhibit_guard.lock().await.set_inhibit(any_playing).await;
                        }
                        ("REQUEST", _) => {
                            // Respond to any request (ping, etc)
                            let response = format!(
                                "MOO/1 COMPLETE Success\nRequest-Id: {}\n\n",
                                req_id
                            );
                            let _ = ws.send(Message::Binary(response.into_bytes())).await;
                        }
                        _ => {}
                    }
                }
            }
            Some(Ok(Message::Ping(p))) => {
                let _ = ws.send(Message::Pong(p)).await;
            }
            Some(Ok(Message::Close(_))) | None => {
                eprintln!("[roon-idle-inhibit] Connection closed, reconnecting...");
                break;
            }
            Some(Err(e)) => {
                eprintln!("[roon-idle-inhibit] WebSocket error: {}", e);
                break;
            }
            _ => {}
        }
    }

    // Release inhibit on disconnect
    inhibit_guard.lock().await.set_inhibit(false).await;
    Ok(())
}

#[tokio::main]
async fn main() {
    let port: u16 = env::var("ROON_PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(9330);

    eprintln!("[roon-idle-inhibit] Starting (localhost:{})", port);

    loop {
        if let Err(e) = run("127.0.0.1", port).await {
            eprintln!("[roon-idle-inhibit] Error: {}", e);
        }
        eprintln!("[roon-idle-inhibit] Reconnecting in 5 seconds...");
        tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
    }
}
