use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::process::Command;
use std::{env, fs};

// --- Types ---

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Session {
    windows: Vec<Window>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct Window {
    #[serde(rename = "type")]
    win_type: String,
    class: String,
    title: String,
    workspace: String,
    position: Vec<i32>,
    size: Vec<i32>,
    floating: bool,
    pinned: bool,
    fullscreen: i32,
    monitor: i32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pid: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cmdline: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cwd: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tabs: Option<Vec<Tab>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    kitty_pid: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    meta: Option<HashMap<String, String>>,
}

impl From<&HyprClient> for Window {
    fn from(c: &HyprClient) -> Self {
        Window {
            class: c.class.clone(),
            title: c.title.clone(),
            workspace: c.workspace.name.clone(),
            position: c.at.clone(),
            size: c.size.clone(),
            floating: c.floating,
            pinned: c.pinned,
            fullscreen: c.fullscreen,
            monitor: c.monitor,
            ..Default::default()
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Tab {
    layout: String,
    windows: Vec<TabWindow>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct TabWindow {
    title: String,
    cwd: String,
    cmdline: Vec<String>,
    pid: u32,
    is_active: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    meta: Option<HashMap<String, String>>,
}

#[derive(Debug, Deserialize)]
struct HyprClient {
    class: String,
    title: String,
    workspace: HyprWorkspace,
    at: Vec<i32>,
    size: Vec<i32>,
    floating: bool,
    pinned: bool,
    fullscreen: i32,
    monitor: i32,
    pid: u32,
}

#[derive(Debug, Deserialize)]
struct HyprWorkspace {
    name: String,
}

// --- Paths ---

fn session_dir() -> PathBuf {
    let home = env::var("HOME").unwrap();
    PathBuf::from(home).join(".local/state/hypr-session")
}

fn session_file() -> PathBuf {
    session_dir().join("session.json")
}

fn event_socket_path() -> PathBuf {
    let xdg = env::var("XDG_RUNTIME_DIR").unwrap();
    let sig = env::var("HYPRLAND_INSTANCE_SIGNATURE").unwrap();
    PathBuf::from(format!("{}/hypr/{}/.socket2.sock", xdg, sig))
}

// --- Helpers ---

const SKIP_CLASSES: &[&str] = &["launcher", "clipboard", "picker"];
const SAVE_EVENTS: &[&str] = &["openwindow", "closewindow", "movewindow", "workspace", "pin"];

fn hyprctl(args: &[&str]) -> Option<String> {
    let output = Command::new("hyprctl").args(args).output().ok()?;
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).into_owned())
    } else {
        None
    }
}

fn proc_cmdline(pid: u32) -> Option<Vec<String>> {
    let data = fs::read_to_string(format!("/proc/{}/cmdline", pid)).ok()?;
    let args: Vec<String> = data
        .split('\0')
        .filter(|s| !s.is_empty())
        .map(String::from)
        .collect();
    if args.is_empty() { None } else { Some(args) }
}

fn proc_cwd(pid: u32) -> Option<String> {
    fs::read_link(format!("/proc/{}/cwd", pid))
        .ok()
        .map(|p| p.to_string_lossy().into_owned())
}

fn kitty_session(pid: u32) -> Option<Vec<(i64, Vec<Tab>)>> {
    let socket = format!("unix:/tmp/kitty-{}", pid);
    let output = Command::new("kitty")
        .args(["@", "ls", "--to", &socket])
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let data: Vec<Value> = serde_json::from_slice(&output.stdout).ok()?;
    let mut result = Vec::new();
    for w in &data {
        let id = w["id"].as_i64()?;
        let tabs_val = w["tabs"].as_array()?;
        let mut tabs = Vec::new();
        for t in tabs_val {
            let layout = t["layout"].as_str().unwrap_or("").to_string();
            let empty_vec = vec![];
            let wins_val = t["windows"].as_array().unwrap_or(&empty_vec);
            let mut wins = Vec::new();
            for win in wins_val {
                let fg = &win["foreground_processes"][0];
                wins.push(TabWindow {
                    title: win["title"].as_str().unwrap_or("").to_string(),
                    cwd: fg["cwd"].as_str().unwrap_or("").to_string(),
                    cmdline: fg["cmdline"]
                        .as_array()
                        .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
                        .unwrap_or_default(),
                    pid: fg["pid"].as_u64().unwrap_or(0) as u32,
                    is_active: win["is_active"].as_bool().unwrap_or(false),
                    meta: None,
                });
            }
            tabs.push(Tab { layout, windows: wins });
        }
        result.push((id, tabs));
    }
    Some(result)
}

fn load_session() -> Session {
    let path = session_file();
    fs::read_to_string(&path)
        .ok()
        .and_then(|data| serde_json::from_str(&data).ok())
        .unwrap_or(Session { windows: vec![] })
}

fn atomic_write(path: &std::path::Path, content: &str) {
    let tmp = path.with_extension("tmp");
    fs::write(&tmp, content).expect("write tmp");
    fs::rename(&tmp, path).expect("rename");
}

fn save_session(session: &Session) {
    let content = serde_json::to_string_pretty(session).unwrap();
    atomic_write(&session_file(), &content);
}

fn extract_meta(session: &Session) -> HashMap<String, HashMap<String, String>> {
    let mut meta_map = HashMap::new();
    for w in &session.windows {
        match w.win_type.as_str() {
            "kitty" => {
                if let Some(tabs) = &w.tabs {
                    for tab in tabs {
                        for win in &tab.windows {
                            if let Some(m) = &win.meta {
                                meta_map.insert(win.pid.to_string(), m.clone());
                            }
                        }
                    }
                }
            }
            "generic" => {
                if let (Some(pid), Some(m)) = (w.pid, &w.meta) {
                    meta_map.insert(pid.to_string(), m.clone());
                }
            }
            _ => {}
        }
    }
    meta_map
}

// --- Save ---

fn do_save() -> usize {
    let prev_meta: HashMap<String, HashMap<String, String>> = extract_meta(&load_session())
        .into_iter()
        .filter(|(pid, _)| std::path::Path::new(&format!("/proc/{}", pid)).exists())
        .collect();

    let clients_json = match hyprctl(&["clients", "-j"]) {
        Some(j) => j,
        None => return 0,
    };
    let clients: Vec<HyprClient> = serde_json::from_str(&clients_json).unwrap_or_default();

    let kitty_pids: Vec<u32> = clients
        .iter()
        .filter(|c| c.class == "kitty")
        .map(|c| c.pid)
        .collect::<std::collections::HashSet<_>>()
        .into_iter()
        .collect();

    let kitty_sessions: HashMap<u32, Vec<(i64, Vec<Tab>)>> = kitty_pids
        .iter()
        .filter_map(|&pid| {
            kitty_session(pid).map(|mut s| {
                s.sort_by_key(|(id, _)| *id);
                (pid, s)
            })
        })
        .collect();

    let mut kitty_counters: HashMap<u32, usize> = kitty_pids.iter().map(|&p| (p, 0)).collect();

    let mut windows = Vec::new();
    for c in &clients {
        if SKIP_CLASSES.contains(&c.class.as_str()) {
            continue;
        }

        if c.class == "kitty" {
            let pid = c.pid;
            if let Some(ks) = kitty_sessions.get(&pid) {
                let idx = kitty_counters.get(&pid).copied().unwrap_or(0);
                *kitty_counters.entry(pid).or_insert(0) += 1;

                if let Some((_, tabs)) = ks.get(idx) {
                    let tabs_with_meta: Vec<Tab> = tabs
                        .iter()
                        .map(|tab| Tab {
                            layout: tab.layout.clone(),
                            windows: tab
                                .windows
                                .iter()
                                .map(|w| {
                                    let m = prev_meta.get(&w.pid.to_string()).cloned();
                                    TabWindow {
                                        meta: m,
                                        ..w.clone()
                                    }
                                })
                                .collect(),
                        })
                        .collect();

                    windows.push(Window {
                        win_type: "kitty".into(),
                        tabs: Some(tabs_with_meta),
                        kitty_pid: Some(pid),
                        ..Window::from(c)
                    });
                }
            }
        } else {
            let pid = c.pid;
            windows.push(Window {
                win_type: "generic".into(),
                pid: Some(pid),
                cmdline: proc_cmdline(pid),
                cwd: proc_cwd(pid),
                meta: prev_meta.get(&pid.to_string()).cloned(),
                ..Window::from(c)
            });
        }
    }

    let count = windows.len();
    let session = Session { windows };
    save_session(&session);
    count
}


// --- Meta ---

fn set_meta_for_pid(pid: &str, key: &str, value: &str) {
    let mut session = load_session();
    for w in &mut session.windows {
        match w.win_type.as_str() {
            "kitty" => {
                if let Some(tabs) = &mut w.tabs {
                    for tab in tabs {
                        for win in &mut tab.windows {
                            if win.pid.to_string() == pid {
                                win.meta
                                    .get_or_insert_with(HashMap::new)
                                    .insert(key.to_string(), value.to_string());
                            }
                        }
                    }
                }
            }
            "generic" => {
                if w.pid.map(|p| p.to_string()) == Some(pid.to_string()) {
                    w.meta
                        .get_or_insert_with(HashMap::new)
                        .insert(key.to_string(), value.to_string());
                }
            }
            _ => {}
        }
    }
    save_session(&session);
}

// --- Watch ---

fn watch_and_save() {
    let dir = session_dir();
    fs::create_dir_all(&dir).expect("create session dir");

    eprintln!("Watching hyprland events, saving to {:?}", session_file());
    let n = do_save();
    eprintln!("Initial save: {} windows", n);

    let socket_path = event_socket_path();
    let stream = UnixStream::connect(&socket_path).expect("connect to hyprland socket");
    eprintln!("Connected to hyprland event socket");

    let reader = BufReader::new(stream);
    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                eprintln!("Read error: {}", e);
                break;
            }
        };
        if let Some(event) = line.split(">>").next() {
            if SAVE_EVENTS.contains(&event) {
                let n = do_save();
                eprintln!("saved {} windows ({})", n, event);
            }
        }
    }
}

// --- Restore ---

fn shell_quote(s: &str) -> String {
    if s.chars()
        .all(|c| c.is_ascii_alphanumeric() || "_./:=@,+-".contains(c))
    {
        s.to_string()
    } else {
        format!("'{}'", s.replace('\'', "'\\''"))
    }
}

fn cmdline_to_sh(cmdline: &[String]) -> String {
    cmdline.iter().map(|s| shell_quote(s)).collect::<Vec<_>>().join(" ")
}

fn unwrap_cmdline(cmdline: &[String]) -> Vec<String> {
    // Unwrap kitten run-shell wrappers (from kitty --hold)
    if let Some(first) = cmdline.first() {
        if first.ends_with("/kitten") || first == "kitten" {
            if cmdline.get(1).map(|s| s.as_str()) == Some("run-shell") {
                // Real command starts after the last --flag argument
                let cmd_start = cmdline[2..]
                    .iter()
                    .position(|a| !a.starts_with("--"))
                    .map(|i| i + 2)
                    .unwrap_or(cmdline.len());
                return cmdline[cmd_start..].to_vec();
            }
        }
    }
    cmdline.to_vec()
}

fn enrich_cmdline(cmdline: &[String], meta: Option<&HashMap<String, String>>) -> Vec<String> {
    let cmdline = unwrap_cmdline(cmdline);
    if let Some(sid) = meta.and_then(|m| m.get("claude-session-id")) {
        if let Some(base) = cmdline.first() {
            if base.ends_with("claude") || base.ends_with("/claude") {
                let args: Vec<String> = cmdline[1..]
                    .iter()
                    .filter(|a| *a != "-r" && *a != "--resume")
                    .cloned()
                    .collect();
                let mut result = vec![base.clone(), "--resume".into(), sid.clone()];
                result.extend(args);
                return result;
            }
        }
    }
    cmdline
}

const SELF_RESTORE_APPS: &[&str] = &["chromium-browser", "firefox"];

fn hypr_exec(workspace: &str, cmd: &str) {
    let full = format!("[workspace {} silent] {}", workspace, cmd);
    eprintln!("  exec: {}", full);
    let _ = Command::new("hyprctl")
        .args(["dispatch", "exec", &full])
        .output();
}

fn resolve_cmdline(tw: &TabWindow) -> Vec<String> {
    let fg = enrich_cmdline(&tw.cmdline, tw.meta.as_ref());
    let is_shell = fg
        .first()
        .map(|s| s.ends_with("/zsh") || s.ends_with("/bash") || s.ends_with("/fish"))
        .unwrap_or(false);
    if is_shell { vec![] } else { fg }
}

fn write_kitty_session(tabs: &[Tab]) -> PathBuf {
    static COUNTER: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);
    let n = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let path = std::env::temp_dir().join(format!("kitty-session-{}-{}.conf", std::process::id(), n));

    let mut lines = Vec::new();
    for (ti, tab) in tabs.iter().enumerate() {
        for (wi, tw) in tab.windows.iter().enumerate() {
            let fg = resolve_cmdline(tw);
            if ti == 0 && wi == 0 {
                lines.push(format!("cd {}", tw.cwd));
            } else if wi == 0 {
                lines.push(format!("new_tab"));
                lines.push(format!("cd {}", tw.cwd));
                lines.push("launch".to_string());
            } else {
                lines.push(format!("cd {}", tw.cwd));
                lines.push("launch".to_string());
            }
            if !fg.is_empty() {
                // Escape for kitty session send_text (newline = \r)
                lines.push(format!("send_text {}\r", cmdline_to_sh(&fg)));
            }
        }
    }

    fs::write(&path, lines.join("\n")).expect("write kitty session file");
    path
}

fn launch_window(win: &Window) {
    match win.win_type.as_str() {
        "kitty" => {
            let tabs = match win.tabs.as_ref() {
                Some(t) if !t.is_empty() => t,
                _ => return,
            };
            let session_file = write_kitty_session(tabs);
            let class_flag = if win.class != "kitty" {
                format!(" --class {}", shell_quote(&win.class))
            } else {
                String::new()
            };
            let kitty_cmd = format!(
                "kitty{} --session {}",
                class_flag,
                shell_quote(&session_file.to_string_lossy())
            );
            hypr_exec(&win.workspace, &kitty_cmd);
        }
        "generic" => {
            if SELF_RESTORE_APPS.contains(&win.class.as_str()) {
                let app = win.class.split('-').next().unwrap_or(&win.class);
                hypr_exec(&win.workspace, app);
            } else if let Some(cmdline) = &win.cmdline {
                let enriched = enrich_cmdline(cmdline, win.meta.as_ref());
                if !enriched.is_empty() {
                    let cmd = cmdline_to_sh(&enriched);
                    let full = match &win.cwd {
                        Some(cwd) => format!("cd {} && {}", shell_quote(cwd), cmd),
                        None => cmd,
                    };
                    hypr_exec(&win.workspace, &full);
                }
            }
        }
        _ => {}
    }
}

fn restore_session() {
    // guard: skip if windows already exist
    if let Some(clients_json) = hyprctl(&["clients", "-j"]) {
        if let Ok(clients) = serde_json::from_str::<Vec<HyprClient>>(&clients_json) {
            let real = clients
                .iter()
                .any(|c| !SKIP_CLASSES.contains(&c.class.as_str()));
            if real {
                eprintln!("Windows already open, skipping restore");
                std::process::exit(0);
            }
        }
    }

    let session = load_session();
    if session.windows.is_empty() {
        eprintln!("No session to restore");
        std::process::exit(1);
    }
    eprintln!("Restoring {} windows", session.windows.len());
    for win in &session.windows {
        eprintln!(
            "[{}] {} — {}",
            win.workspace,
            win.class,
            &win.title[..win.title.len().min(50)]
        );
        launch_window(win);
        std::thread::sleep(std::time::Duration::from_millis(700));
    }
}

// --- Show ---

fn show_session() {
    let session = load_session();
    if session.windows.is_empty() {
        eprintln!("No session to show");
        std::process::exit(1);
    }
    println!("{} windows:", session.windows.len());
    for win in &session.windows {
        println!("  [{}] {} — {}", win.workspace, win.class, win.title);
        match win.win_type.as_str() {
            "kitty" => {
                if let Some(tabs) = &win.tabs {
                    for tab in tabs {
                        for w in &tab.windows {
                            print!("    {} in {}", cmdline_to_sh(&w.cmdline), w.cwd);
                            if let Some(m) = &w.meta {
                                print!("  {:?}", m);
                            }
                            println!();
                        }
                    }
                }
            }
            "generic" => {
                if let Some(cmdline) = &win.cmdline {
                    print!("    {} ", cmdline_to_sh(cmdline));
                }
                if let Some(cwd) = &win.cwd {
                    print!("in {}", cwd);
                }
                if let Some(m) = &win.meta {
                    print!("  {:?}", m);
                }
                println!();
            }
            _ => {}
        }
    }
}

// --- CLI ---

fn main() {
    let args: Vec<String> = env::args().collect();
    let cmd = args.get(1).map(|s| s.as_str());

    match cmd {
        Some("watch") => watch_and_save(),
        Some("restore") => restore_session(),
        Some("show") => show_session(),
        Some("meta") => {
            let pid = args.get(2).expect("Usage: hypr-session meta <pid> <key> <value>");
            let key = args.get(3).expect("Usage: hypr-session meta <pid> <key> <value>");
            let value = args.get(4).expect("Usage: hypr-session meta <pid> <key> <value>");
            set_meta_for_pid(pid, key, value);
            eprintln!("Meta set for PID {}", pid);
        }
        Some("claude-hook") => {
            let input: Value = serde_json::from_reader(std::io::stdin()).unwrap_or_default();
            if let Some(sid) = input.get("session_id").and_then(|v| v.as_str()) {
                let ppid = std::os::unix::process::parent_id();
                set_meta_for_pid(&ppid.to_string(), "claude-session-id", sid);
            }
        }
        _ => {
            eprintln!("Usage: hypr-session <watch|restore|show|meta|claude-hook>");
            std::process::exit(1);
        }
    }
}
