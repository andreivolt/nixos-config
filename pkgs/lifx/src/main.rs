
use anyhow::{anyhow, Context, Result};
use clap::{CommandFactory, Parser, Subcommand};
use clap_complete::{generate, Shell};
use lifx_core::{BuildOptions, Message, RawMessage, HSBK};
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::net::{IpAddr, Ipv4Addr, SocketAddr, UdpSocket};
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::net::UdpSocket as TokioUdpSocket;
use tokio::time::{sleep, timeout};

// LIFX Protocol Constants
const LIFX_PORT: u16 = 56700;
const DISCOVERY_TIMEOUT: Duration = Duration::from_secs(3);
const COMMAND_TIMEOUT: Duration = Duration::from_secs(2);

// Color themes from the original script
const LIFX_THEMES: &[(&str, &str)] = &[
    ("sunset", "12,75,80,2500"),
    ("candlelight", "35,100,25,1500"),
    ("fireplace", "25,100,40,2000"),
    ("dawn", "25,60,60,3000"),
    ("reading", "0,0,80,4000"),
    ("concentrate", "0,0,100,6500"),
    ("energize", "200,100,100,5500"),
    ("relax", "240,30,50,2700"),
    ("sleep", "0,100,5,2000"),
    ("romantic", "330,70,30,2200"),
    ("party", "300,100,100,3500"),
    ("movie", "240,100,20,2700"),
    ("forest", "120,80,60,3500"),
    ("ocean", "200,100,70,4000"),
    ("spring", "90,70,80,4500"),
    ("autumn", "30,90,70,2800"),
];

// Predefined colors with HSBK values
const PREDEFINED_COLORS: &[(&str, &str)] = &[
    ("red", "0,100,100,3500"),
    ("green", "120,100,100,3500"),
    ("blue", "240,100,100,3500"),
    ("yellow", "60,100,100,3500"),
    ("orange", "36,100,100,3500"),
    ("purple", "280,100,100,3500"),
    ("cyan", "180,100,100,3500"),
    ("white", "0,0,100,3500"),
];

#[derive(Parser)]
#[command(name = "lifx")]
#[command(about = "Control LIFX smart lights via LAN protocol")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Apply to all lights
    #[arg(short = 'a', long = "all")]
    all_lights: bool,

    /// Apply to specific light names
    #[arg(short = 'n', long = "name")]
    names: Vec<String>,

    /// Apply to lights in group
    #[arg(short = 'g', long = "group")]
    group: Option<String>,

    /// Transition duration in seconds
    #[arg(short = 'd', long = "duration", default_value = "0")]
    duration: f32,
}

#[derive(Subcommand)]
enum Commands {
    /// List discovered lights
    List {
        /// Force rescan for devices
        #[arg(short = 'r', long = "rescan")]
        rescan: bool,
    },
    /// Turn lights on
    On,
    /// Turn lights off
    Off,
    /// Set light color
    Color {
        /// Color specification (HSBK, kelvin, theme, or predefined)
        color: Option<String>,
    },
    /// Set brightness (0-100)
    Brightness {
        level: u8,
    },
    /// Increase brightness
    Brighter {
        #[arg(default_value = "10")]
        amount: u8,
    },
    /// Decrease brightness
    Dimmer {
        #[arg(default_value = "10")]
        amount: u8,
    },
    /// Make lights warmer
    Warmer {
        #[arg(default_value = "100")]
        amount: u16,
    },
    /// Make lights cooler
    Cooler {
        #[arg(default_value = "100")]
        amount: u16,
    },
    /// Clear device cache
    ClearCache,
    /// Generate shell completion script
    Completion {
        /// Shell to generate completion for
        #[arg(value_enum)]
        shell: Shell,
    },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct CachedLight {
    label: String,
    target: u64,
    ip_addr: IpAddr,
    mac_addr: [u8; 6],
    power: Option<u16>,
    color: Option<CachedHSBK>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct CachedHSBK {
    hue: u16,
    saturation: u16,
    brightness: u16,
    kelvin: u16,
}

impl From<HSBK> for CachedHSBK {
    fn from(hsbk: HSBK) -> Self {
        CachedHSBK {
            hue: hsbk.hue,
            saturation: hsbk.saturation,
            brightness: hsbk.brightness,
            kelvin: hsbk.kelvin,
        }
    }
}

impl From<CachedHSBK> for HSBK {
    fn from(cached: CachedHSBK) -> Self {
        HSBK {
            hue: cached.hue,
            saturation: cached.saturation,
            brightness: cached.brightness,
            kelvin: cached.kelvin,
        }
    }
}

#[derive(Debug)]
struct LifxDevice {
    target: u64,
    ip_addr: IpAddr,
    socket: Arc<UdpSocket>,
}

impl LifxDevice {
    fn new(target: u64, ip_addr: IpAddr) -> Result<Self> {
        let socket = UdpSocket::bind("0.0.0.0:0").context("Failed to bind UDP socket")?;
        socket.set_read_timeout(Some(COMMAND_TIMEOUT))?;

        Ok(LifxDevice {
            target,
            ip_addr,
            socket: Arc::new(socket),
        })
    }

    fn send_with_flags(&self, message: Message, res_required: bool, ack_required: bool) -> Result<Option<Vec<u8>>> {
        let build_options = BuildOptions {
            target: Some(self.target),
            res_required,
            ack_required,
            ..Default::default()
        };
        let raw_message = RawMessage::build(&build_options, message).context("Failed to build message")?;
        let bytes = raw_message.pack().context("Failed to pack message")?;
        let addr = SocketAddr::new(self.ip_addr, LIFX_PORT);
        self.socket
            .send_to(&bytes, addr)
            .context("Failed to send message")?;

        if res_required {
            let mut buf = [0; 1024];
            let (len, _) = self.socket.recv_from(&mut buf).context("Failed to receive response")?;
            Ok(Some(buf[..len].to_vec()))
        } else {
            Ok(None)
        }
    }

    fn send_message(&self, message: Message) -> Result<()> {
        self.send_with_flags(message, false, false)?;
        Ok(())
    }

    fn send_message_ack(&self, message: Message) -> Result<()> {
        // Ask for an ACK when we care about reliability (like power changes)
        self.send_with_flags(message, false, true)?;
        Ok(())
    }

    fn send_message_with_response(&self, message: Message) -> Result<Vec<u8>> {
        self.send_with_flags(message, true, false)?
            .ok_or_else(|| anyhow!("No response data received"))
    }

    fn query_message(&self, message: Message) -> Result<Message> {
        let data = self.send_message_with_response(message)?;
        let raw_msg = RawMessage::unpack(&data)?;
        let message = Message::from_raw(&raw_msg)?;
        Ok(message)
    }

    fn set_power(&self, level: u16, duration_ms: u32) -> Result<()> {
        let msg = Message::LightSetPower {
            level,
            duration: duration_ms,
        };
        self.send_message_ack(msg)
    }
}

struct LifxController {
    cache_file: PathBuf,
    last_used_file: PathBuf,
    brightness_memory_file: PathBuf,
}

impl LifxController {
    fn new() -> Result<Self> {
        let state_dir = dirs::state_dir()
            .or_else(|| dirs::home_dir().map(|d| d.join(".local/state")))
            .ok_or_else(|| anyhow!("Cannot determine state directory"))?;

        std::fs::create_dir_all(&state_dir).context("Failed to create state directory")?;

        Ok(LifxController {
            cache_file: state_dir.join("lifx.json"),
            last_used_file: state_dir.join("lifx_last_used.json"),
            brightness_memory_file: state_dir.join("lifx_brightness_memory.json"),
        })
    }

    async fn discover_lights(&self, use_cache: bool) -> Result<Vec<CachedLight>> {
        if use_cache && self.cache_file.exists() {
            if let Ok(cached) = self.load_cache() {
                return Ok(cached);
            }
        }

        println!("Discovering LIFX lights...");
        let discovered = self.perform_discovery().await?;
        self.save_cache(&discovered)?;
        Ok(discovered)
    }

    async fn perform_discovery(&self) -> Result<Vec<CachedLight>> {
        let socket = TokioUdpSocket::bind("0.0.0.0:0")
            .await
            .context("Failed to bind UDP socket")?;
        socket.set_broadcast(true).context("Failed to enable broadcast")?;

        // Send GetService message to discover devices
        let build_options = BuildOptions {
            target: None, // Broadcast to all devices
            res_required: false,
            ack_required: false,
            ..Default::default()
        };
        let discovery_message =
            RawMessage::build(&build_options, Message::GetService).context("Failed to build discovery message")?;

        let bytes = discovery_message.pack().context("Failed to pack discovery message")?;
        let broadcast_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::BROADCAST), LIFX_PORT);
        socket
            .send_to(&bytes, broadcast_addr)
            .await
            .context("Failed to send discovery message")?;

        let mut discovered = Vec::new();
        let mut seen_targets = HashSet::new();
        let deadline = Instant::now() + DISCOVERY_TIMEOUT;

        while Instant::now() < deadline {
            let remaining = deadline.duration_since(Instant::now());
            if remaining.is_zero() {
                break;
            }

            let mut buf = [0; 1024];
            match timeout(remaining, socket.recv_from(&mut buf)).await {
                Ok(Ok((len, addr))) => {
                    if let Ok(device) = self.process_discovery_response(&buf[..len], addr.ip()).await {
                        if seen_targets.insert(device.target) {
                            discovered.push(device);
                        }
                    }
                }
                _ => break,
            }
        }

        Ok(discovered)
    }

    async fn process_discovery_response(&self, data: &[u8], ip: IpAddr) -> Result<CachedLight> {
        let raw_msg = RawMessage::unpack(data).context("Failed to unpack discovery response")?;
        let target = raw_msg.frame_addr.target;

        Ok(CachedLight {
            label: format!("LIFX Light {}", target & 0xFFFF),
            target,
            ip_addr: ip,
            mac_addr: [0; 6],
            power: None,
            color: None,
        })
    }

    fn load_cache(&self) -> Result<Vec<CachedLight>> {
        let data = std::fs::read_to_string(&self.cache_file).context("Failed to read cache file")?;
        let cached: Vec<CachedLight> = serde_json::from_str(&data).context("Failed to parse cache file")?;
        Ok(cached)
    }

    fn save_cache(&self, lights: &[CachedLight]) -> Result<()> {
        let data = serde_json::to_string_pretty(lights).context("Failed to serialize cache")?;
        std::fs::write(&self.cache_file, data).context("Failed to write cache file")?;
        Ok(())
    }

    fn save_last_used(&self, lights: &[CachedLight]) -> Result<()> {
        let data = serde_json::to_string_pretty(lights).context("Failed to serialize last used")?;
        std::fs::write(&self.last_used_file, data).context("Failed to write last used file")?;
        Ok(())
    }

    fn load_last_used(&self) -> Result<Vec<CachedLight>> {
        let data = std::fs::read_to_string(&self.last_used_file).context("Failed to read last used file")?;
        let last_used: Vec<CachedLight> = serde_json::from_str(&data).context("Failed to parse last used file")?;
        Ok(last_used)
    }

    fn get_remembered_brightness(&self, target: u64) -> Option<u16> {
        if !self.brightness_memory_file.exists() {
            return None;
        }

        let data = std::fs::read_to_string(&self.brightness_memory_file).ok()?;
        let memory: HashMap<u64, u16> = serde_json::from_str(&data).ok()?;
        memory.get(&target).copied()
    }

    async fn get_target_lights(&self, cli: &Cli, discovered: &[CachedLight]) -> Result<Vec<CachedLight>> {
        let mut target_lights = Vec::new();

        if cli.all_lights {
            target_lights = discovered.to_vec();
        } else if !cli.names.is_empty() {
            for name in &cli.names {
                if let Some(light) = discovered.iter().find(|l| l.label == *name) {
                    target_lights.push(light.clone());
                } else {
                    eprintln!("Warning: No light found with name '{}'", name);
                }
            }
            if target_lights.is_empty() {
                return Err(anyhow!("No matching lights found for specified names"));
            }
        } else if let Some(_group) = &cli.group {
            return Err(anyhow!("Group functionality not yet implemented"));
        } else if let Ok(last_used) = self.load_last_used() {
            target_lights = last_used;
        } else {
            return Err(anyhow!("No target specified and no last used lights found. Use --all, --name, or --group"));
        }

        for light in &mut target_lights {
            let _ = self.get_light_info(light).await;
        }

        Ok(target_lights)
    }

    async fn ensure_powered_on(&self, device: &LifxDevice, duration_ms: u32) -> Result<()> {
        let is_off = match device.query_message(Message::LightGetPower) {
            Ok(Message::LightStatePower { level }) => level == 0,
            _ => false,
        };
        if is_off {
            // Wake the lamp first so subsequent SetColor/brightness is applied
            device.set_power(65535, duration_ms)?;
            // tiny delay to let firmware apply the power transition
            sleep(Duration::from_millis(80)).await;
        }
        Ok(())
    }

    async fn set_power(&self, lights: &[CachedLight], power_on: bool, duration_ms: u32) -> Result<()> {
        if power_on {
            for light in lights {
                let device = LifxDevice::new(light.target, light.ip_addr)?;
                // Always use LightSetPower to wake the device
                device
                    .set_power(65535, duration_ms)
                    .with_context(|| format!("Failed to power on {}", light.label))?;
                // Optional: restore previous brightness if remembered (post-wake)
                if let Some(brightness) = self.get_remembered_brightness(light.target) {
                    sleep(Duration::from_millis(80)).await;
                    let current_color = self
                        .get_light_color(&device)
                        .await
                        .unwrap_or(HSBK {
                            hue: 0,
                            saturation: 0,
                            brightness: 65535,
                            kelvin: 3500,
                        });
                    let restored_color = HSBK {
                        hue: current_color.hue,
                        saturation: current_color.saturation,
                        brightness,
                        kelvin: current_color.kelvin,
                    };
                    let message = Message::LightSetColor {
                        reserved: 0,
                        color: restored_color,
                        duration: duration_ms,
                    };
                    device
                        .send_message(message)
                        .with_context(|| format!("Failed to restore brightness for {}", light.label))?;
                }
                println!("{}: on", light.label);
            }
        } else {
            // Capture brightness memory before turning off
            let mut memory: HashMap<u64, u16> = if self.brightness_memory_file.exists() {
                let data =
                    std::fs::read_to_string(&self.brightness_memory_file).context("Failed to read brightness memory file")?;
                serde_json::from_str(&data).unwrap_or_default()
            } else {
                HashMap::new()
            };

            for light in lights {
                let device = LifxDevice::new(light.target, light.ip_addr)?;

                if let Ok(cur) = self.get_light_color(&device).await {
                    if cur.brightness > 0 {
                        memory.insert(light.target, cur.brightness);
                    }
                }

                // Use LightSetPower to actually power off (not just set brightness 0)
                device
                    .set_power(0, duration_ms)
                    .with_context(|| format!("Failed to power off {}", light.label))?;
                println!("{}: off", light.label);
            }

            // Save memory file once
            let data = serde_json::to_string_pretty(&memory).context("Failed to serialize brightness memory")?;
            std::fs::write(&self.brightness_memory_file, data).context("Failed to write brightness memory file")?;
        }
        Ok(())
    }

    async fn set_color(&self, lights: &[CachedLight], color_spec: &str, duration_ms: u32) -> Result<()> {
        let hsbk = self.parse_color_spec(color_spec)?;
        for light in lights {
            let device = LifxDevice::new(light.target, light.ip_addr)?;
            self.ensure_powered_on(&device, duration_ms).await?;

            let message = Message::LightSetColor {
                reserved: 0,
                color: hsbk,
                duration: duration_ms,
            };
            device
                .send_message(message)
                .with_context(|| format!("Failed to set color for {}", light.label))?;
        }
        Ok(())
    }

    async fn set_brightness(&self, lights: &[CachedLight], level: u8, duration_ms: u32) -> Result<()> {
        for light in lights {
            let device = LifxDevice::new(light.target, light.ip_addr)?;
            self.ensure_powered_on(&device, duration_ms).await?;

            // Get current color to preserve hue, saturation, kelvin
            let current_color = self.get_light_color(&device).await.unwrap_or(HSBK {
                hue: 0,
                saturation: 0,
                brightness: 65535,
                kelvin: 3500,
            });

            let new_brightness = (level as f32 / 100.0 * 65535.0) as u16;
            let new_color = HSBK {
                hue: current_color.hue,
                saturation: current_color.saturation,
                brightness: new_brightness,
                kelvin: current_color.kelvin,
            };

            let message = Message::LightSetColor {
                reserved: 0,
                color: new_color,
                duration: duration_ms,
            };

            device
                .send_message(message)
                .with_context(|| format!("Failed to set brightness for {}", light.label))?;
        }
        Ok(())
    }

    async fn adjust_brightness(&self, lights: &[CachedLight], amount: i16, duration_ms: u32) -> Result<()> {
        for light in lights {
            let device = LifxDevice::new(light.target, light.ip_addr)?;
            self.ensure_powered_on(&device, duration_ms).await?;

            let current_color = self.get_light_color(&device).await.unwrap_or(HSBK {
                hue: 0,
                saturation: 0,
                brightness: 32768,
                kelvin: 3500,
            });

            let current_brightness_pct = current_color.brightness as f32 / 65535.0 * 100.0;
            let new_brightness_pct = (current_brightness_pct + amount as f32).clamp(0.0, 100.0);
            let new_brightness = (new_brightness_pct / 100.0 * 65535.0) as u16;

            let new_color = HSBK {
                hue: current_color.hue,
                saturation: current_color.saturation,
                brightness: new_brightness,
                kelvin: current_color.kelvin,
            };

            let message = Message::LightSetColor {
                reserved: 0,
                color: new_color,
                duration: duration_ms,
            };

            device
                .send_message(message)
                .with_context(|| format!("Failed to adjust brightness for {}", light.label))?;

            println!("{}: {:.0}% → {:.0}%", light.label, current_brightness_pct, new_brightness_pct);
        }
        Ok(())
    }

    async fn adjust_temperature(&self, lights: &[CachedLight], amount: i32, duration_ms: u32) -> Result<()> {
        for light in lights {
            let device = LifxDevice::new(light.target, light.ip_addr)?;
            self.ensure_powered_on(&device, duration_ms).await?;

            let current_color = self.get_light_color(&device).await.unwrap_or(HSBK {
                hue: 0,
                saturation: 0,
                brightness: 65535,
                kelvin: 3500,
            });

            let current_kelvin = current_color.kelvin as i32;
            let new_kelvin = (current_kelvin + amount).clamp(1500, 9000) as u16;

            let new_color = HSBK {
                hue: current_color.hue,
                saturation: current_color.saturation,
                brightness: current_color.brightness,
                kelvin: new_kelvin,
            };

            let message = Message::LightSetColor {
                reserved: 0,
                color: new_color,
                duration: duration_ms,
            };

            device
                .send_message(message)
                .with_context(|| format!("Failed to adjust temperature for {}", light.label))?;

            println!("{}: {}K → {}K", light.label, current_kelvin, new_kelvin);
        }
        Ok(())
    }

    async fn get_light_color(&self, device: &LifxDevice) -> Result<HSBK> {
        let response = device.query_message(Message::LightGet)?;
        if let Message::LightState { color, .. } = response {
            Ok(color)
        } else {
            Err(anyhow!("Unexpected response message type"))
        }
    }

    fn parse_color_spec(&self, spec: &str) -> Result<HSBK> {
        // Handle kelvin temperature (e.g., "3500k")
        if spec.ends_with('k') || spec.ends_with('K') {
            let kelvin_str = &spec[..spec.len() - 1];
            let kelvin: u16 = kelvin_str.parse().context("Invalid kelvin value")?;
            return Ok(HSBK {
                hue: 0,
                saturation: 0,
                brightness: 65535,
                kelvin,
            });
        }

        // Handle predefined colors
        for (name, hsbk_str) in PREDEFINED_COLORS {
            if spec.eq_ignore_ascii_case(name) {
                return self.parse_hsbk_string(hsbk_str);
            }
        }

        // Handle themes
        for (name, hsbk_str) in LIFX_THEMES {
            if spec.eq_ignore_ascii_case(name) {
                return self.parse_hsbk_string(hsbk_str);
            }
        }

        // Handle HSBK string (e.g., "240,100,100,3500")
        self.parse_hsbk_string(spec)
    }

    fn parse_hsbk_string(&self, hsbk_str: &str) -> Result<HSBK> {
        let parts: Vec<&str> = hsbk_str.split(',').collect();
        if parts.len() != 4 {
            return Err(anyhow!("HSBK format should be 'hue,saturation,brightness,kelvin'"));
        }

        let h: f32 = parts[0].parse().context("Invalid hue")?;
        let s: f32 = parts[1].parse().context("Invalid saturation")?;
        let b: f32 = parts[2].parse().context("Invalid brightness")?;
        let k: u16 = parts[3].parse().context("Invalid kelvin")?;

        if !(0.0..=360.0).contains(&h) {
            return Err(anyhow!("Hue must be 0-360°"));
        }
        if !(0.0..=100.0).contains(&s) {
            return Err(anyhow!("Saturation must be 0-100%"));
        }
        if !(0.0..=100.0).contains(&b) {
            return Err(anyhow!("Brightness must be 0-100%"));
        }
        if !(1500..=9000).contains(&k) {
            return Err(anyhow!("Kelvin must be 1500-9000"));
        }

        Ok(HSBK {
            hue: (h / 360.0 * 65535.0) as u16,
            saturation: (s / 100.0 * 65535.0) as u16,
            brightness: (b / 100.0 * 65535.0) as u16,
            kelvin: k,
        })
    }

    async fn interactive_color_selection(&self) -> Result<String> {
        let mut options = Vec::new();

        for (name, hsbk) in PREDEFINED_COLORS {
            options.push(format!("{} - {}", name, hsbk));
        }
        for (name, hsbk) in LIFX_THEMES {
            options.push(format!("{} (theme) - {}", name, hsbk));
        }

        let selection = dialoguer::FuzzySelect::new()
            .with_prompt("Select a color")
            .items(&options)
            .interact_opt()
            .context("Color selection failed")?;

        if let Some(idx) = selection {
            let selected = &options[idx];
            if let Some(hsbk_part) = selected.split(" - ").last() {
                return Ok(hsbk_part.to_string());
            }
        }

        Err(anyhow!("No color selected"))
    }

    async fn get_light_info(&self, light: &mut CachedLight) -> Result<()> {
        let device = LifxDevice::new(light.target, light.ip_addr)?;

        if let Ok(Message::StateLabel { label }) = device.query_message(Message::GetLabel) {
            light.label = label.to_string();
        }

        if let Ok(Message::LightStatePower { level }) = device.query_message(Message::LightGetPower) {
            light.power = Some(level);
        }

        if let Ok(Message::LightState { color, .. }) = device.query_message(Message::LightGet) {
            light.color = Some(color.into());
        }

        Ok(())
    }

    fn format_light_info(&self, light: &CachedLight) -> String {
        let mut info = format!("{:<20}", light.label);

        if let Some(power) = light.power {
            let power_str = if power > 0 { "On " } else { "Off" };
            info.push_str(&format!(" {:<3}", power_str));
        } else {
            info.push_str(" ?  ");
        }

        if let Some(color) = &light.color {
            let h = color.hue as f32 / 65535.0 * 360.0;
            let s = color.saturation as f32 / 65535.0 * 100.0;

            if s < 5.0 {
                info.push_str(&format!(" {}K white", color.kelvin));
            } else {
                info.push_str(&format!(" {:.0}°,{:.0}%,{}K", h, s, color.kelvin));
            }
        }

        info
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    let controller = LifxController::new()?;

    // Handle symlink shortcuts for on/off
    if let Some(program_name) = std::env::args().next() {
        let name = std::path::Path::new(&program_name)
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("");

        if name == "on" || name == "off" {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller.set_power(&target_lights, name == "on", duration_ms).await?;
            controller.save_last_used(&target_lights)?;
            return Ok(());
        }
    }

    match cli.command {
        Some(Commands::List { rescan }) => {
            let mut discovered = controller.discover_lights(!rescan).await?;

            if discovered.is_empty() {
                println!("No LIFX lights found on the network.");
                return Ok(());
            }

            for light in &mut discovered {
                let _ = controller.get_light_info(light).await;
            }

            controller.save_cache(&discovered)?;

            for light in &discovered {
                println!("{}", controller.format_light_info(light));
            }
        }

        Some(Commands::On) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller.set_power(&target_lights, true, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Off) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller.set_power(&target_lights, false, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Color { ref color }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            let color_spec = if let Some(color) = color {
                color.clone()
            } else {
                controller.interactive_color_selection().await?
            };

            controller.set_color(&target_lights, &color_spec, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Brightness { level }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller.set_brightness(&target_lights, level, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Brighter { amount }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller
                .adjust_brightness(&target_lights, amount as i16, duration_ms)
                .await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Dimmer { amount }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller
                .adjust_brightness(&target_lights, -(amount as i16), duration_ms)
                .await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Warmer { amount }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller
                .adjust_temperature(&target_lights, -(amount as i32), duration_ms)
                .await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Cooler { amount }) => {
            let discovered = controller.discover_lights(true).await?;
            let target_lights = controller.get_target_lights(&cli, &discovered).await?;
            let duration_ms = (cli.duration * 1000.0) as u32;

            controller
                .adjust_temperature(&target_lights, amount as i32, duration_ms)
                .await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::ClearCache) => {
            let mut removed = Vec::new();

            if controller.cache_file.exists() {
                std::fs::remove_file(&controller.cache_file)?;
                removed.push("device cache");
            }

            if controller.last_used_file.exists() {
                std::fs::remove_file(&controller.last_used_file)?;
                removed.push("last used lights");
            }

            if removed.is_empty() {
                println!("No cache files found to clear");
            } else {
                println!("Cleared: {}", removed.join(", "));
            }
        }

        Some(Commands::Completion { shell }) => {
            let mut cmd = Cli::command();
            let name = cmd.get_name().to_string();
            generate(shell, &mut cmd, name, &mut std::io::stdout());
        }

        _ => {
            if cli.all_lights || !cli.names.is_empty() || cli.group.is_some() {
                eprintln!("No command specified. Use --help for available commands.");
                std::process::exit(1);
            } else {
                let discovered = controller.discover_lights(true).await?;
                for light in &discovered {
                    println!("{}", controller.format_light_info(light));
                }
            }
        }
    }

    Ok(())
}
