use std::env;
use std::io::Write;
use std::os::unix::net::UnixDatagram;
use std::process::Command;
use std::time::Duration;

const STEP: i32 = 5;

fn socket_path() -> String {
    let runtime = env::var("XDG_RUNTIME_DIR").expect("XDG_RUNTIME_DIR not set");
    format!("{}/volume.sock", runtime)
}

fn wob_path() -> String {
    let runtime = env::var("XDG_RUNTIME_DIR").expect("XDG_RUNTIME_DIR not set");
    format!("{}/wob.sock", runtime)
}

fn send_wob(vol: i32) {
    let path = wob_path();
    if let Ok(mut f) = std::fs::OpenOptions::new().write(true).open(&path) {
        let _ = writeln!(f, "{}", vol);
    }
}

fn get_volume() -> (i32, bool) {
    let output = Command::new("wpctl")
        .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
        .output();
    match output {
        Ok(out) => {
            let s = String::from_utf8_lossy(&out.stdout);
            let muted = s.contains("[MUTED]");
            let vol = s
                .split_whitespace()
                .nth(1)
                .and_then(|v| v.parse::<f64>().ok())
                .map(|v| (v * 100.0) as i32)
                .unwrap_or(50);
            (vol, muted)
        }
        Err(_) => (50, false),
    }
}

fn set_volume(vol: i32) {
    let _ = Command::new("wpctl")
        .args(["set-volume", "@DEFAULT_AUDIO_SINK@", &format!("{}%", vol)])
        .status();
}

fn toggle_mute() {
    let _ = Command::new("wpctl")
        .args(["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        .status();
}

fn client(cmd: &str) {
    let path = socket_path();
    let sock = UnixDatagram::unbound().expect("failed to create socket");
    let _ = sock.send_to(cmd.as_bytes(), &path);
}

fn daemon() {
    let path = socket_path();
    let _ = std::fs::remove_file(&path);

    let sock = UnixDatagram::bind(&path).expect("failed to bind socket");
    sock.set_read_timeout(Some(Duration::from_millis(50)))
        .expect("failed to set timeout");

    let (init_vol, init_muted) = get_volume();
    let mut vol = init_vol;
    let mut muted = init_muted;

    if muted {
        send_wob(0);
    } else {
        send_wob(vol);
    }

    eprintln!("volume daemon: started (vol={}, muted={})", vol, muted);

    let mut buf = [0u8; 32];
    let mut pending_delta: i32 = 0;

    loop {
        match sock.recv(&mut buf) {
            Ok(n) => {
                let cmd = std::str::from_utf8(&buf[..n]).unwrap_or("").trim();
                match cmd {
                    "up" => {
                        if muted {
                            muted = false;
                            toggle_mute();
                        }
                        pending_delta += STEP;
                        let preview = (vol + pending_delta).clamp(0, 100);
                        send_wob(preview);
                    }
                    "down" => {
                        if muted {
                            muted = false;
                            toggle_mute();
                        }
                        pending_delta -= STEP;
                        let preview = (vol + pending_delta).clamp(0, 100);
                        send_wob(preview);
                    }
                    "mute" => {
                        // flush any pending delta first
                        if pending_delta != 0 {
                            vol = (vol + pending_delta).clamp(0, 100);
                            set_volume(vol);
                            pending_delta = 0;
                        }
                        toggle_mute();
                        let (new_vol, new_muted) = get_volume();
                        vol = new_vol;
                        muted = new_muted;
                        if muted {
                            send_wob(0);
                        } else {
                            send_wob(vol);
                        }
                    }
                    _ => {}
                }
            }
            Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                // timeout — flush pending delta
                if pending_delta != 0 {
                    vol = (vol + pending_delta).clamp(0, 100);
                    set_volume(vol);
                    pending_delta = 0;
                }
            }
            Err(_) => {
                // transient error, continue
            }
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let cmd = args.get(1).map(|s| s.as_str()).unwrap_or("");

    match cmd {
        "daemon" => daemon(),
        "up" | "down" | "mute" => client(cmd),
        _ => {
            let _ = writeln!(std::io::stderr(), "usage: volume <daemon|up|down|mute>");
            std::process::exit(1);
        }
    }
}
