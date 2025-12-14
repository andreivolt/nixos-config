
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

    /// Transition duration in seconds
    #[arg(short = 'd', long = "duration", default_value = "0", global = true)]
    duration: f32,
}

#[derive(Subcommand)]
enum Commands {
    /// List discovered lights
    #[command(visible_alias = "ls")]
    List {
        /// Force fresh device discovery (bypass cache)
        #[arg(long = "scan")]
        scan: bool,
    },
    /// Turn lights on
    On {
        /// Light names to target (default: all lights)
        targets: Vec<String>,
    },
    /// Turn lights off
    Off {
        /// Light names to target (default: all lights)
        targets: Vec<String>,
    },
    /// Set brightness, color, or temperature
    Set {
        /// Arguments: [TARGETS...] <VALUE>
        /// Value can be: brightness (50), relative (+10, -5), kelvin (3500k),
        /// preset (sunset), color (red), or HSBK (120,80,100,3500)
        args: Vec<String>,
        /// Open TUI menu to select preset/color
        #[arg(short = 'm', long = "menu")]
        menu: bool,
        /// Open GTK color wheel dialog (zenity)
        #[arg(short = 'g', long = "gui")]
        gui: bool,
    },
    /// Generate shell completion script
    Completion {
        /// Shell to generate completion for
        #[arg(value_enum)]
        shell: Shell,
    },
}

/// Parsed value from the `set` command
#[derive(Debug, Clone)]
enum SetValue {
    /// Absolute brightness (0-100)
    Brightness(u8),
    /// Relative brightness change (+/- percentage)
    BrightnessRelative(i16),
    /// Absolute temperature in Kelvin
    Temperature(u16),
    /// Relative temperature change (+/- Kelvin)
    TemperatureRelative(i32),
    /// Color specification (preset name, color name, or HSBK string)
    Color(String),
    /// Hex color (#rrggbb)
    HexColor(String),
}

/// Result of parsing the args for the `set` command
struct ParsedSetArgs {
    targets: Vec<String>,
    value: Option<SetValue>,
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

    /// Resolve target names to CachedLight entries
    /// Resolution order: exact match, then case-insensitive match
    fn resolve_targets(&self, target_names: &[String], discovered: &[CachedLight]) -> (Vec<CachedLight>, Vec<String>) {
        let mut matched = Vec::new();
        let mut unmatched = Vec::new();

        for name in target_names {
            // Try exact match first
            if let Some(light) = discovered.iter().find(|l| l.label == *name) {
                matched.push(light.clone());
                continue;
            }

            // Try case-insensitive match
            if let Some(light) = discovered.iter().find(|l| l.label.eq_ignore_ascii_case(name)) {
                matched.push(light.clone());
                continue;
            }

            unmatched.push(name.clone());
        }

        (matched, unmatched)
    }

    /// Try to parse an argument as a SetValue
    /// Returns Some(SetValue) if it looks like a value, None if it should be treated as a target
    fn try_parse_value(&self, arg: &str, light_names: &[String]) -> Option<SetValue> {
        // If arg exactly matches a light name, it's a target, not a value
        if light_names.iter().any(|name| name == arg) {
            return None;
        }

        // Try parsing as relative brightness (+10, -20)
        if let Some(rest) = arg.strip_prefix('+') {
            if let Ok(n) = rest.parse::<i16>() {
                if !rest.ends_with('k') && !rest.ends_with('K') {
                    return Some(SetValue::BrightnessRelative(n));
                }
            }
        }
        if let Some(rest) = arg.strip_prefix('-') {
            if let Ok(n) = rest.parse::<i16>() {
                if !rest.ends_with('k') && !rest.ends_with('K') {
                    return Some(SetValue::BrightnessRelative(-n));
                }
            }
        }

        // Try parsing as kelvin temperature (3500k, +500k, -200k)
        let lower = arg.to_lowercase();
        if lower.ends_with('k') {
            let num_part = &arg[..arg.len() - 1];
            if let Some(rest) = num_part.strip_prefix('+') {
                if let Ok(n) = rest.parse::<i32>() {
                    return Some(SetValue::TemperatureRelative(n));
                }
            } else if let Some(rest) = num_part.strip_prefix('-') {
                if let Ok(n) = rest.parse::<i32>() {
                    return Some(SetValue::TemperatureRelative(-n));
                }
            } else if let Ok(n) = num_part.parse::<u16>() {
                return Some(SetValue::Temperature(n));
            }
        }

        // Try parsing as hex color (#rrggbb)
        if arg.starts_with('#') && (arg.len() == 7 || arg.len() == 4) {
            return Some(SetValue::HexColor(arg.to_string()));
        }

        // Check if it's a known preset or color name
        let is_preset = LIFX_THEMES.iter().any(|(name, _)| name.eq_ignore_ascii_case(arg));
        let is_color = PREDEFINED_COLORS.iter().any(|(name, _)| name.eq_ignore_ascii_case(arg));
        if is_preset || is_color {
            return Some(SetValue::Color(arg.to_string()));
        }

        // Try parsing as HSBK (hue,sat,bright,kelvin)
        let parts: Vec<&str> = arg.split(',').collect();
        if parts.len() == 4 && parts.iter().all(|p| p.parse::<f32>().is_ok()) {
            return Some(SetValue::Color(arg.to_string()));
        }

        // Try parsing as absolute brightness (plain integer 0-100)
        if let Ok(n) = arg.parse::<u8>() {
            if n <= 100 {
                return Some(SetValue::Brightness(n));
            }
        }

        // Not recognized as a value, treat as target
        None
    }

    /// Parse the args for the `set` command
    /// Separates targets from the value using smart detection
    fn parse_set_args(&self, args: &[String], discovered: &[CachedLight]) -> ParsedSetArgs {
        let light_names: Vec<String> = discovered.iter().map(|l| l.label.clone()).collect();
        let mut targets = Vec::new();
        let mut value = None;

        for arg in args {
            if let Some(v) = self.try_parse_value(arg, &light_names) {
                value = Some(v);
            } else {
                targets.push(arg.clone());
            }
        }

        ParsedSetArgs { targets, value }
    }

    /// Apply a SetValue to lights
    async fn apply_set_value(&self, lights: &[CachedLight], value: &SetValue, duration_ms: u32) -> Result<()> {
        match value {
            SetValue::Brightness(level) => {
                self.set_brightness(lights, *level, duration_ms).await?;
            }
            SetValue::BrightnessRelative(amount) => {
                self.adjust_brightness(lights, *amount, duration_ms).await?;
            }
            SetValue::Temperature(kelvin) => {
                // Set temperature while preserving brightness
                for light in lights {
                    let device = LifxDevice::new(light.target, light.ip_addr)?;
                    self.ensure_powered_on(&device, duration_ms).await?;

                    let current_color = self.get_light_color(&device).await.unwrap_or(HSBK {
                        hue: 0,
                        saturation: 0,
                        brightness: 65535,
                        kelvin: 3500,
                    });

                    let new_color = HSBK {
                        hue: 0,
                        saturation: 0,
                        brightness: current_color.brightness,
                        kelvin: *kelvin,
                    };

                    let message = Message::LightSetColor {
                        reserved: 0,
                        color: new_color,
                        duration: duration_ms,
                    };

                    device
                        .send_message(message)
                        .with_context(|| format!("Failed to set temperature for {}", light.label))?;

                    println!("{}: {}K", light.label, kelvin);
                }
            }
            SetValue::TemperatureRelative(amount) => {
                self.adjust_temperature(lights, *amount, duration_ms).await?;
            }
            SetValue::Color(color_spec) => {
                self.set_color(lights, color_spec, duration_ms).await?;
                for light in lights {
                    println!("{}: {}", light.label, color_spec);
                }
            }
            SetValue::HexColor(hex) => {
                let hsbk = self.hex_to_hsbk(hex)?;
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

                    println!("{}: {}", light.label, hex);
                }
            }
        }
        Ok(())
    }

    /// Convert hex color (#rrggbb) to HSBK
    fn hex_to_hsbk(&self, hex: &str) -> Result<HSBK> {
        let hex = hex.trim_start_matches('#');

        let (r, g, b) = if hex.len() == 6 {
            let r = u8::from_str_radix(&hex[0..2], 16).context("Invalid red component")?;
            let g = u8::from_str_radix(&hex[2..4], 16).context("Invalid green component")?;
            let b = u8::from_str_radix(&hex[4..6], 16).context("Invalid blue component")?;
            (r, g, b)
        } else if hex.len() == 3 {
            let r = u8::from_str_radix(&hex[0..1], 16).context("Invalid red component")? * 17;
            let g = u8::from_str_radix(&hex[1..2], 16).context("Invalid green component")? * 17;
            let b = u8::from_str_radix(&hex[2..3], 16).context("Invalid blue component")? * 17;
            (r, g, b)
        } else {
            return Err(anyhow!("Invalid hex color format"));
        };

        // Convert RGB to HSB
        let r_f = r as f32 / 255.0;
        let g_f = g as f32 / 255.0;
        let b_f = b as f32 / 255.0;

        let max = r_f.max(g_f).max(b_f);
        let min = r_f.min(g_f).min(b_f);
        let delta = max - min;

        let brightness = max;
        let saturation = if max == 0.0 { 0.0 } else { delta / max };

        let hue = if delta == 0.0 {
            0.0
        } else if max == r_f {
            60.0 * (((g_f - b_f) / delta) % 6.0)
        } else if max == g_f {
            60.0 * (((b_f - r_f) / delta) + 2.0)
        } else {
            60.0 * (((r_f - g_f) / delta) + 4.0)
        };

        let hue = if hue < 0.0 { hue + 360.0 } else { hue };

        Ok(HSBK {
            hue: (hue / 360.0 * 65535.0) as u16,
            saturation: (saturation * 65535.0) as u16,
            brightness: (brightness * 65535.0) as u16,
            kelvin: 3500,
        })
    }

    /// Launch zenity color picker and return selected color
    async fn gui_color_picker(&self) -> Result<SetValue> {
        let output = std::process::Command::new("zenity")
            .args(["--color-selection", "--show-palette"])
            .output()
            .context("Failed to launch zenity. Is it installed?")?;

        if !output.status.success() {
            return Err(anyhow!("Color selection cancelled"));
        }

        let color_str = String::from_utf8_lossy(&output.stdout).trim().to_string();

        // zenity outputs either rgb(r,g,b) or #rrggbb depending on version
        if color_str.starts_with("rgb(") {
            // Parse rgb(r,g,b) format
            let inner = color_str.trim_start_matches("rgb(").trim_end_matches(')');
            let parts: Vec<&str> = inner.split(',').collect();
            if parts.len() == 3 {
                let r: u8 = parts[0].trim().parse().context("Invalid red")?;
                let g: u8 = parts[1].trim().parse().context("Invalid green")?;
                let b: u8 = parts[2].trim().parse().context("Invalid blue")?;
                return Ok(SetValue::HexColor(format!("#{:02x}{:02x}{:02x}", r, g, b)));
            }
        } else if color_str.starts_with('#') {
            return Ok(SetValue::HexColor(color_str));
        }

        Err(anyhow!("Could not parse color from zenity: {}", color_str))
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    let controller = LifxController::new()?;
    let duration_ms = (cli.duration * 1000.0) as u32;

    // Handle symlink shortcuts for on/off
    if let Some(program_name) = std::env::args().next() {
        let name = std::path::Path::new(&program_name)
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("");

        if name == "on" || name == "off" {
            let discovered = controller.discover_lights(true).await?;
            // When invoked via symlink, apply to all lights
            controller.set_power(&discovered, name == "on", duration_ms).await?;
            controller.save_last_used(&discovered)?;
            return Ok(());
        }
    }

    match cli.command {
        Some(Commands::List { scan }) => {
            let mut discovered = controller.discover_lights(!scan).await?;

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

        Some(Commands::On { targets }) => {
            let discovered = controller.discover_lights(true).await?;

            let target_lights = if targets.is_empty() {
                // No targets = all lights
                discovered.clone()
            } else {
                let (matched, unmatched) = controller.resolve_targets(&targets, &discovered);
                for name in &unmatched {
                    eprintln!("warning: no light matching '{}'", name);
                }
                if matched.is_empty() {
                    let available: Vec<_> = discovered.iter().map(|l| l.label.as_str()).collect();
                    return Err(anyhow!("error: no lights matched\navailable: {}", available.join(", ")));
                }
                matched
            };

            controller.set_power(&target_lights, true, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Off { targets }) => {
            let discovered = controller.discover_lights(true).await?;

            let target_lights = if targets.is_empty() {
                // No targets = all lights
                discovered.clone()
            } else {
                let (matched, unmatched) = controller.resolve_targets(&targets, &discovered);
                for name in &unmatched {
                    eprintln!("warning: no light matching '{}'", name);
                }
                if matched.is_empty() {
                    let available: Vec<_> = discovered.iter().map(|l| l.label.as_str()).collect();
                    return Err(anyhow!("error: no lights matched\navailable: {}", available.join(", ")));
                }
                matched
            };

            controller.set_power(&target_lights, false, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Set { args, menu, gui }) => {
            let discovered = controller.discover_lights(true).await?;

            // Parse arguments into targets and value
            let parsed = controller.parse_set_args(&args, &discovered);

            // Determine target lights
            let target_lights = if parsed.targets.is_empty() {
                // No targets = all lights
                discovered.clone()
            } else {
                let (matched, unmatched) = controller.resolve_targets(&parsed.targets, &discovered);
                for name in &unmatched {
                    eprintln!("warning: no light matching '{}'", name);
                }
                if matched.is_empty() {
                    let available: Vec<_> = discovered.iter().map(|l| l.label.as_str()).collect();
                    return Err(anyhow!("error: no lights matched\navailable: {}", available.join(", ")));
                }
                matched
            };

            // Determine the value to set
            let value = if gui {
                // Use zenity color picker
                controller.gui_color_picker().await?
            } else if menu {
                // Use TUI menu
                let color_spec = controller.interactive_color_selection().await?;
                SetValue::Color(color_spec)
            } else if let Some(v) = parsed.value {
                v
            } else {
                return Err(anyhow!(
                    "error: missing value\n\
                    usage: lifx set [TARGETS...] <VALUE>\n\
                    \n\
                    VALUE can be:\n\
                    \x20 50        brightness (0-100)\n\
                    \x20 +10, -5   relative brightness\n\
                    \x20 3500k     temperature in Kelvin\n\
                    \x20 +500k     relative temperature\n\
                    \x20 sunset    preset name\n\
                    \x20 red       color name\n\
                    \x20 #ff6b35   hex color\n\
                    \n\
                    Or use interactive mode:\n\
                    \x20 lifx set --menu   TUI preset selector\n\
                    \x20 lifx set --gui    GTK color wheel"
                ));
            };

            controller.apply_set_value(&target_lights, &value, duration_ms).await?;
            controller.save_last_used(&target_lights)?;
        }

        Some(Commands::Completion { shell }) => {
            let mut cmd = Cli::command();
            let name = cmd.get_name().to_string();
            generate(shell, &mut cmd, name, &mut std::io::stdout());
        }

        None => {
            // Default: list lights
            let mut discovered = controller.discover_lights(true).await?;

            if discovered.is_empty() {
                println!("No LIFX lights found on the network.");
                return Ok(());
            }

            for light in &mut discovered {
                let _ = controller.get_light_info(light).await;
            }

            for light in &discovered {
                println!("{}", controller.format_light_info(light));
            }
        }
    }

    Ok(())
}
