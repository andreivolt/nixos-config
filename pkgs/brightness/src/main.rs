// Brightness control with DPMS support and wob OSD
//
// Backlight zones (Apple Silicon, max=509):
//   raw 0:    dimmest visible level; pressing down triggers DPMS off
//   raw 1-2:  dead zone (visually identical to 0, skipped in both directions)
//   raw 3+:   normal range with perceptual (exponential) steps
//
// DPMS wake: Hyprland auto-wakes DPMS on keypress before this runs,
// so we can't detect "was DPMS off". Instead, DPMS-off sets raw to 0.
// First up from raw 0 sets raw 1 (same visual = dim level shown).
// Second up sees raw<3 and jumps to 3 (first distinct brightness).

use std::fs;
use std::io::Write;
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::process::Command;
use std::thread;
use std::time::Duration;

use anyhow::{Context, Result};
use clap::Parser;
use serde::Deserialize;
use zbus::blocking::Connection;

const EXPONENT: f64 = 4.0;
const STEP_PERCENT: f64 = 1.0;
const DEAD_ZONE_END: u32 = 3;
const DDC_STEP: u32 = 5;
const DDC_LEVELS: [u32; 21] = [
    0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 21, 23, 25, 27, 29, 31, 33, 35, 68, 100,
];

#[derive(Parser)]
enum Action {
    Up,
    Down,
}

#[derive(Deserialize)]
struct Monitor {
    name: String,
    focused: bool,
}

fn focused_monitor() -> Result<String> {
    let output = Command::new("hyprctl")
        .args(["monitors", "-j"])
        .output()?;
    let monitors: Vec<Monitor> = serde_json::from_slice(&output.stdout)?;
    monitors
        .into_iter()
        .find(|m| m.focused)
        .map(|m| m.name)
        .context("no focused monitor")
}

struct Backlight {
    path: PathBuf,
    name: String,
    max: u32,
    conn: Connection,
}

impl Backlight {
    fn detect() -> Option<Self> {
        let base = PathBuf::from("/sys/class/backlight");
        let entry = fs::read_dir(&base).ok()?.next()?.ok()?;
        let path = entry.path();
        let name = entry.file_name().to_str()?.to_string();
        let max: u32 = fs::read_to_string(path.join("max_brightness"))
            .ok()?
            .trim()
            .parse()
            .ok()?;
        let conn = Connection::system().ok()?;
        Some(Backlight {
            path,
            name,
            max,
            conn,
        })
    }

    fn raw(&self) -> Result<u32> {
        Ok(fs::read_to_string(self.path.join("brightness"))?
            .trim()
            .parse()?)
    }

    fn set_raw(&self, value: u32) -> Result<()> {
        self.conn
            .call_method(
                Some("org.freedesktop.login1"),
                "/org/freedesktop/login1/session/auto",
                Some("org.freedesktop.login1.Session"),
                "SetBrightness",
                &("backlight", &*self.name, value),
            )
            .map_err(|e| anyhow::anyhow!("SetBrightness: {e}"))?;
        Ok(())
    }

    fn percent(&self) -> Result<u32> {
        Ok((self.raw()? as f64 / self.max as f64 * 100.0).round() as u32)
    }

    fn exp_percent(&self, raw: u32) -> f64 {
        let ratio = raw as f64 / self.max as f64;
        ratio.powf(1.0 / EXPONENT) * 100.0
    }

    fn raw_from_exp(&self, pct: f64) -> u32 {
        let raw = (pct / 100.0).powf(EXPONENT) * self.max as f64;
        (raw.round() as u32).min(self.max)
    }

    fn step_up(&self) -> Result<()> {
        let raw = self.raw()?;
        let new = match raw {
            0 => 1,
            r if r < DEAD_ZONE_END => DEAD_ZONE_END,
            _ => {
                let new_pct = (self.exp_percent(raw) + STEP_PERCENT).min(100.0);
                self.raw_from_exp(new_pct).max(raw + 1)
            }
        };
        self.set_raw(new.min(self.max))
    }

    fn step_down(&self) -> Result<bool> {
        let raw = self.raw()?;
        match raw {
            0..=1 => {
                self.set_raw(0)?;
                Ok(true)
            }
            2..=DEAD_ZONE_END => {
                self.set_raw(0)?;
                Ok(false)
            }
            _ => {
                let new_pct = (self.exp_percent(raw) - STEP_PERCENT).max(0.0);
                let mut new = self.raw_from_exp(new_pct).min(raw - 1);
                if new > 0 && new < DEAD_ZONE_END {
                    new = DEAD_ZONE_END;
                }
                self.set_raw(new)?;
                Ok(false)
            }
        }
    }
}

fn ddc_bus() -> Result<u32> {
    let cache = "/tmp/ddc-bus";
    if let Ok(v) = fs::read_to_string(cache) {
        if let Ok(bus) = v.trim().parse() {
            return Ok(bus);
        }
    }
    let output = Command::new("ddcutil")
        .args(["detect", "--brief"])
        .output()?;
    let text = String::from_utf8_lossy(&output.stdout);
    let bus: u32 = text
        .lines()
        .filter_map(|l| l.strip_prefix("/dev/i2c-"))
        .next()
        .context("no DDC display")?
        .trim()
        .parse()?;
    fs::write(cache, bus.to_string())?;
    Ok(bus)
}

fn ddc_brightness() -> Result<u32> {
    let cache = "/tmp/ddc-brightness";
    match fs::read_to_string(cache) {
        Ok(v) => Ok(v.trim().parse().unwrap_or(50)),
        Err(_) => {
            fs::write(cache, "50")?;
            Ok(50)
        }
    }
}

fn set_ddc_brightness(percent: u32) -> Result<u32> {
    let percent = percent.clamp(0, 100);
    let ddc_value = DDC_LEVELS[(percent / 5) as usize];
    let bus = ddc_bus()?;
    Command::new("ddcutil")
        .args([
            &format!("--bus={bus}"),
            "--skip-ddc-checks",
            "--noverify",
            "setvcp",
            "10",
            &ddc_value.to_string(),
        ])
        .spawn()?;
    fs::write("/tmp/ddc-brightness", percent.to_string())?;
    Ok(percent)
}

fn send_wob(value: u32) {
    let Ok(xdg) = std::env::var("XDG_RUNTIME_DIR") else {
        return;
    };
    if let Ok(mut stream) = UnixStream::connect(format!("{xdg}/wob.sock")) {
        let _ = writeln!(stream, "{value}");
    }
}

fn dpms_off() {
    thread::spawn(|| {
        thread::sleep(Duration::from_millis(200));
        let _ = Command::new("hyprctl")
            .args(["dispatch", "dpms", "off"])
            .output();
    });
}

fn main() -> Result<()> {
    let action = Action::parse();
    let monitor = focused_monitor()?;
    let backlight = if monitor.starts_with("eDP") {
        Backlight::detect()
    } else {
        None
    };

    match (&action, &backlight) {
        (Action::Up, Some(bl)) => {
            bl.step_up()?;
            send_wob(bl.percent()?);
        }
        (Action::Down, Some(bl)) => {
            if bl.step_down()? {
                dpms_off();
            } else {
                send_wob(bl.percent()?);
            }
        }
        (Action::Up, None) => {
            let current = ddc_brightness()?;
            let result = set_ddc_brightness(current + DDC_STEP)?;
            send_wob(result);
        }
        (Action::Down, None) => {
            let current = ddc_brightness()?;
            let result = set_ddc_brightness(current.saturating_sub(DDC_STEP))?;
            send_wob(result);
        }
    }

    Ok(())
}
