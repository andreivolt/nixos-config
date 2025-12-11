use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::SampleRate;
use crossbeam_channel::{unbounded, Sender};
use futures::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;
use tokio_tungstenite::{connect_async, tungstenite::Message};

const SAMPLE_RATE: u32 = 16000;
const CHANNELS: u16 = 1;

#[derive(Parser)]
#[command(name = "dictate", about = "Voice-to-text dictation")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    #[arg(short, long)]
    lang: Option<String>,

    #[arg(short, long)]
    model: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    Toggle,
    Start,
    Stop,
    Status,
    Mode { mode: Option<String> },
    Lang { lang: Option<String> },
    #[command(name = "_run", hide = true)]
    Run,
}

#[derive(Serialize, Deserialize)]
struct LiveResponse {
    #[serde(rename = "type")]
    message_type: Option<String>,
    channel: Option<LiveChannel>,
    is_final: Option<bool>,
}

#[derive(Serialize, Deserialize)]
struct LiveChannel {
    alternatives: Vec<LiveAlternative>,
}

#[derive(Serialize, Deserialize)]
struct LiveAlternative {
    transcript: String,
}

struct Config {
    state_file: PathBuf,
    pid_file: PathBuf,
    transcript_file: PathBuf,
    audio_file: PathBuf,
    lang_file: PathBuf,
    mode_file: PathBuf,
    sound_dir: PathBuf,
}

impl Config {
    fn new() -> Self {
        let runtime_dir = PathBuf::from(
            std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".to_string())
        );
        let state_dir = dirs::state_dir()
            .unwrap_or_else(|| dirs::home_dir().unwrap_or_default().join(".local/state"))
            .join("dictate");
        let config_dir = dirs::config_dir()
            .unwrap_or_else(|| dirs::home_dir().unwrap_or_default().join(".config"));

        let _ = fs::create_dir_all(&state_dir);

        Self {
            state_file: runtime_dir.join("dictate.state"),
            pid_file: runtime_dir.join("dictate.pid"),
            transcript_file: runtime_dir.join("dictate.transcript"),
            audio_file: runtime_dir.join("dictate.wav"),
            lang_file: state_dir.join("language"),
            mode_file: state_dir.join("mode"),
            sound_dir: config_dir.join("dictate/sounds"),
        }
    }
}

fn get_api_key() -> Result<String> {
    std::env::var("DEEPGRAM_API_KEY").or_else(|_| {
        let env_file = dirs::home_dir().unwrap_or_default().join(".config/env");
        if let Ok(content) = fs::read_to_string(&env_file) {
            for line in content.lines() {
                if line.starts_with("export DEEPGRAM_API_KEY=") {
                    return Ok(line.trim_start_matches("export DEEPGRAM_API_KEY=")
                        .trim_matches('"').trim_matches('\'').to_string());
                }
            }
        }
        Err(std::env::VarError::NotPresent)
    }).context("DEEPGRAM_API_KEY not set in env or ~/.config/env")
}

fn get_audio_config() -> Result<(cpal::Device, cpal::StreamConfig, u32)> {
    let host = cpal::default_host();
    let device = host.default_input_device().context("No input device")?;

    let config_range = device.supported_input_configs()?
        .filter(|c| c.channels() <= CHANNELS && c.sample_format() == cpal::SampleFormat::F32)
        .min_by_key(|c| {
            let (min, max) = (c.min_sample_rate().0, c.max_sample_rate().0);
            if SAMPLE_RATE >= min && SAMPLE_RATE <= max { 0 }
            else { (min as i32 - SAMPLE_RATE as i32).abs().min((max as i32 - SAMPLE_RATE as i32).abs()) }
        })
        .context("No suitable audio config")?;

    let rate = if SAMPLE_RATE >= config_range.min_sample_rate().0 && SAMPLE_RATE <= config_range.max_sample_rate().0 {
        SAMPLE_RATE
    } else {
        config_range.min_sample_rate().0.max(config_range.max_sample_rate().0.min(SAMPLE_RATE))
    };

    let config = config_range.with_sample_rate(SampleRate(rate)).config();
    Ok((device, config, rate))
}

struct Dictate {
    config: Config,
    lang: String,
    model: String,
    mode: String,
}

impl Dictate {
    fn new(lang_override: Option<String>, model_override: Option<String>) -> Self {
        let config = Config::new();

        let lang = lang_override.unwrap_or_else(|| {
            fs::read_to_string(&config.lang_file)
                .map(|s| s.trim().to_string())
                .unwrap_or_else(|_| std::env::var("DICTATE_LANG").unwrap_or_else(|_| "multi".to_string()))
        });

        let model = model_override.unwrap_or_else(|| {
            std::env::var("DICTATE_MODEL").unwrap_or_else(|_| "nova-3".to_string())
        });

        let mode = fs::read_to_string(&config.mode_file)
            .map(|s| s.trim().to_string())
            .unwrap_or_else(|_| "live".to_string());

        Self { config, lang, model, mode }
    }

    fn play_sound(&self, name: &str) {
        let sound_file = self.config.sound_dir.join(format!("{}.wav", name));
        if sound_file.exists() {
            let _ = Command::new("pw-play").arg(&sound_file).spawn();
        }
    }

    fn update_state(&self, state: &str) {
        let _ = fs::write(&self.config.state_file, state);
    }

    fn get_state(&self) -> String {
        fs::read_to_string(&self.config.state_file)
            .map(|s| s.trim().to_string())
            .unwrap_or_else(|_| "idle".to_string())
    }

    fn is_recording(&self) -> bool {
        if self.get_state() != "recording" {
            return false;
        }
        if let Ok(pid_str) = fs::read_to_string(&self.config.pid_file) {
            if let Ok(pid) = pid_str.trim().parse::<i32>() {
                return std::path::Path::new(&format!("/proc/{}", pid)).exists();
            }
        }
        false
    }

    fn type_text(&self, text: &str) {
        if !text.is_empty() {
            let _ = Command::new("wtype").arg("--").arg(format!("{} ", text)).status();
        }
    }

    fn copy_to_clipboard(&self, text: &str) {
        if let Ok(mut child) = Command::new("wl-copy").stdin(std::process::Stdio::piped()).spawn() {
            if let Some(stdin) = child.stdin.as_mut() {
                let _ = stdin.write_all(text.as_bytes());
            }
            let _ = child.wait();
        }
    }

    fn stop(&self) -> Result<()> {
        // Kill the recording process
        if let Ok(pid_str) = fs::read_to_string(&self.config.pid_file) {
            if let Ok(pid) = pid_str.trim().parse::<i32>() {
                let _ = Command::new("kill").arg("-TERM").arg(pid.to_string()).status();
                thread::sleep(Duration::from_millis(100));
                let _ = Command::new("kill").arg("-KILL").arg(pid.to_string()).status();
            }
        }
        let _ = fs::remove_file(&self.config.pid_file);
        self.update_state("idle");
        self.play_sound("stop");
        Ok(())
    }

    fn status(&self) {
        let state = if self.is_recording() { "recording" } else { "idle" };
        println!("{} (mode: {}, lang: {}, model: {})", state, self.mode, self.lang, self.model);
    }

    fn set_mode(&self, mode: Option<String>) {
        match mode {
            Some(m) if ["live", "vad", "batch"].contains(&m.as_str()) => {
                let _ = fs::write(&self.config.mode_file, &m);
                println!("Mode: {}", m);
            }
            Some(m) => println!("Invalid mode '{}'. Use: live, vad, batch", m),
            None => println!("Mode: {} (available: live, vad, batch)", self.mode),
        }
    }

    fn set_lang(&self, lang: Option<String>) {
        match lang {
            Some(l) => {
                let _ = fs::write(&self.config.lang_file, &l);
                println!("Language: {}", l);
            }
            None => println!("Language: {}", self.lang),
        }
    }
}

// ============ LIVE MODE ============

fn capture_audio_stream(tx: Sender<Vec<u8>>, stop: Arc<AtomicBool>) -> Result<()> {
    let (device, config, _) = get_audio_config()?;
    let stop_cb = stop.clone();

    let stream = device.build_input_stream(
        &config,
        move |data: &[f32], _| {
            if stop_cb.load(Ordering::Relaxed) { return; }
            let pcm: Vec<u8> = data.iter()
                .flat_map(|&s| ((s * 32767.0).clamp(-32768.0, 32767.0) as i16).to_le_bytes())
                .collect();
            let _ = tx.send(pcm);
        },
        |e| eprintln!("Audio error: {}", e),
        None,
    )?;

    stream.play()?;
    while !stop.load(Ordering::Relaxed) {
        thread::sleep(Duration::from_millis(10));
    }
    Ok(())
}

async fn run_live(dictate: &Dictate) -> Result<()> {
    let api_key = get_api_key()?;
    let (_, _, rate) = get_audio_config()?;

    let params = format!(
        "model={}&language={}&encoding=linear16&sample_rate={}&channels={}&smart_format=true&interim_results=true&endpointing=300",
        dictate.model, dictate.lang, rate, CHANNELS
    );
    let ws_url = format!("wss://api.deepgram.com/v1/listen?{}", params);

    let request = tokio_tungstenite::tungstenite::http::Request::builder()
        .method("GET")
        .uri(&ws_url)
        .header("Host", "api.deepgram.com")
        .header("Upgrade", "websocket")
        .header("Connection", "Upgrade")
        .header("Sec-WebSocket-Key", "dGhlIHNhbXBsZSBub25jZQ==")
        .header("Sec-WebSocket-Version", "13")
        .header("Authorization", format!("Token {}", api_key))
        .body(())?;

    let (ws_stream, _) = connect_async(request).await.context("WebSocket connect failed")?;
    let (mut ws_tx, mut ws_rx) = ws_stream.split();

    let (audio_tx, audio_rx) = unbounded::<Vec<u8>>();
    let stop = Arc::new(AtomicBool::new(false));
    let stop_audio = stop.clone();
    let stop_sender = stop.clone();

    let audio_thread = thread::spawn(move || capture_audio_stream(audio_tx, stop_audio));

    let sender_task = tokio::spawn(async move {
        while !stop_sender.load(Ordering::Relaxed) {
            if let Ok(data) = audio_rx.recv_timeout(Duration::from_millis(10)) {
                if !data.is_empty() && ws_tx.send(Message::Binary(data)).await.is_err() {
                    break;
                }
            }
        }
    });

    let _ = fs::write(&dictate.config.transcript_file, "");
    let transcript_file = dictate.config.transcript_file.clone();
    let mut full_transcript = String::new();

    let receiver_task = tokio::spawn(async move {
        while let Some(Ok(Message::Text(text))) = ws_rx.next().await {
            let Ok(resp) = serde_json::from_str::<LiveResponse>(&text) else { continue };
            if resp.message_type.as_deref() != Some("Results") { continue }
            let Some(alt) = resp.channel.and_then(|c| c.alternatives.into_iter().next()) else { continue };
            if alt.transcript.is_empty() || !resp.is_final.unwrap_or(false) { continue }

            let _ = Command::new("wtype").arg("--").arg(format!("{} ", &alt.transcript)).status();
            full_transcript.push_str(&alt.transcript);
            full_transcript.push(' ');
            let _ = fs::write(&transcript_file, &full_transcript);

            if let Ok(mut child) = Command::new("wl-copy").stdin(std::process::Stdio::piped()).spawn() {
                if let Some(stdin) = child.stdin.as_mut() {
                    let _ = stdin.write_all(full_transcript.as_bytes());
                }
                let _ = child.wait();
            }
        }
    });

    tokio::signal::ctrl_c().await.ok();
    stop.store(true, Ordering::Relaxed);

    let _ = tokio::time::timeout(Duration::from_millis(200), async {
        let _ = tokio::join!(sender_task, receiver_task);
    }).await;

    let _ = audio_thread.join();
    Ok(())
}

// ============ BATCH MODE ============

fn record_to_file(path: &PathBuf, stop: Arc<AtomicBool>) -> Result<()> {
    let (device, config, rate) = get_audio_config()?;
    let spec = hound::WavSpec {
        channels: CHANNELS,
        sample_rate: rate,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let mut writer = hound::WavWriter::create(path, spec)?;
    let stop_cb = stop.clone();
    let samples = Arc::new(std::sync::Mutex::new(Vec::<i16>::new()));
    let samples_cb = samples.clone();

    let stream = device.build_input_stream(
        &config,
        move |data: &[f32], _| {
            if stop_cb.load(Ordering::Relaxed) { return; }
            let mut buf = samples_cb.lock().unwrap();
            for &s in data {
                buf.push((s * 32767.0).clamp(-32768.0, 32767.0) as i16);
            }
        },
        |e| eprintln!("Audio error: {}", e),
        None,
    )?;

    stream.play()?;
    while !stop.load(Ordering::Relaxed) {
        thread::sleep(Duration::from_millis(50));
        let mut buf = samples.lock().unwrap();
        for &s in buf.iter() {
            writer.write_sample(s)?;
        }
        buf.clear();
    }

    // Write remaining samples
    let buf = samples.lock().unwrap();
    for &s in buf.iter() {
        writer.write_sample(s)?;
    }
    writer.finalize()?;
    Ok(())
}

fn transcribe_file(path: &PathBuf, lang: &str, model: &str) -> Result<String> {
    let api_key = get_api_key()?;
    let url = format!(
        "https://api.deepgram.com/v1/listen?model={}&language={}&smart_format=true",
        model, lang
    );

    let audio_data = fs::read(path)?;
    let client = reqwest::blocking::Client::new();
    let response = client.post(&url)
        .header("Authorization", format!("Token {}", api_key))
        .header("Content-Type", "audio/wav")
        .body(audio_data)
        .send()?
        .text()?;

    let json: serde_json::Value = serde_json::from_str(&response)?;
    let transcript = json["results"]["channels"][0]["alternatives"][0]["transcript"]
        .as_str()
        .unwrap_or("")
        .to_string();

    Ok(transcript)
}

fn run_batch(dictate: &Dictate) -> Result<()> {
    let stop = Arc::new(AtomicBool::new(false));
    let stop_clone = stop.clone();
    let audio_file = dictate.config.audio_file.clone();

    // Record in background thread
    let record_thread = thread::spawn(move || record_to_file(&audio_file, stop_clone));

    // Wait for signal
    let rt = tokio::runtime::Runtime::new()?;
    rt.block_on(tokio::signal::ctrl_c()).ok();
    stop.store(true, Ordering::Relaxed);

    record_thread.join().map_err(|_| anyhow::anyhow!("Record thread panicked"))??;

    // Transcribe
    let transcript = transcribe_file(&dictate.config.audio_file, &dictate.lang, &dictate.model)?;

    if !transcript.is_empty() {
        dictate.type_text(&transcript);
        let _ = fs::write(&dictate.config.transcript_file, &transcript);
        dictate.copy_to_clipboard(&transcript);
    }

    let _ = fs::remove_file(&dictate.config.audio_file);
    Ok(())
}

// ============ VAD MODE ============

fn run_vad(dictate: &Dictate) -> Result<()> {
    let _ = fs::write(&dictate.config.transcript_file, "");
    let mut full_transcript = String::new();
    let chunk_file = dictate.config.audio_file.with_extension("chunk.wav");

    loop {
        // Record with silence detection using sox
        let status = Command::new("sox")
            .args(["-d", chunk_file.to_str().unwrap()])
            .args(["silence", "1", "0.1", "1%", "1", "0.8", "1%"])
            .stderr(std::process::Stdio::null())
            .status();

        if status.is_err() || !status.unwrap().success() {
            break;
        }

        // Check if file exists and has content
        let size = fs::metadata(&chunk_file).map(|m| m.len()).unwrap_or(0);
        if size < 1000 {
            continue;
        }

        // Transcribe chunk
        if let Ok(transcript) = transcribe_file(&chunk_file, &dictate.lang, &dictate.model) {
            if !transcript.is_empty() {
                dictate.type_text(&transcript);
                full_transcript.push_str(&transcript);
                full_transcript.push(' ');
                let _ = fs::write(&dictate.config.transcript_file, &full_transcript);
                dictate.copy_to_clipboard(&full_transcript);
            }
        }

        let _ = fs::remove_file(&chunk_file);
    }

    let _ = fs::remove_file(&chunk_file);
    Ok(())
}

// ============ ENTRY POINTS ============

fn start_recording(dictate: &Dictate) -> Result<()> {
    if dictate.is_recording() {
        return Ok(());
    }

    let exe_path = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("dictate"));
    let api_key = get_api_key().unwrap_or_default();
    let wayland = std::env::var("WAYLAND_DISPLAY").unwrap_or_else(|_| "wayland-1".to_string());
    let xdg_runtime = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| format!("/run/user/{}", unsafe { libc::getuid() }));

    let child = Command::new("setsid")
        .args([exe_path.to_str().unwrap(), "--lang", &dictate.lang, "--model", &dictate.model, "_run"])
        .env("DEEPGRAM_API_KEY", &api_key)
        .env("WAYLAND_DISPLAY", &wayland)
        .env("XDG_RUNTIME_DIR", &xdg_runtime)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()?;

    fs::write(&dictate.config.pid_file, child.id().to_string())?;
    dictate.update_state("recording");
    dictate.play_sound("start");
    Ok(())
}

fn run_foreground(dictate: &Dictate) -> Result<()> {
    fs::write(&dictate.config.pid_file, std::process::id().to_string())?;

    let result = match dictate.mode.as_str() {
        "live" => {
            let rt = tokio::runtime::Runtime::new()?;
            rt.block_on(run_live(dictate))
        }
        "batch" => run_batch(dictate),
        "vad" => run_vad(dictate),
        _ => {
            let rt = tokio::runtime::Runtime::new()?;
            rt.block_on(run_live(dictate))
        }
    };

    dictate.update_state("idle");
    dictate.play_sound("stop");
    let _ = fs::remove_file(&dictate.config.pid_file);
    result
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let dictate = Dictate::new(cli.lang, cli.model);

    match cli.command.unwrap_or(Commands::Toggle) {
        Commands::Toggle => {
            if dictate.is_recording() { dictate.stop() }
            else { start_recording(&dictate) }
        }
        Commands::Start => start_recording(&dictate),
        Commands::Stop => dictate.stop(),
        Commands::Status => { dictate.status(); Ok(()) }
        Commands::Mode { mode } => { dictate.set_mode(mode); Ok(()) }
        Commands::Lang { lang } => { dictate.set_lang(lang); Ok(()) }
        Commands::Run => run_foreground(&dictate),
    }
}
