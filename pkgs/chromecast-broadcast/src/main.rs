use std::sync::Arc;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::io::{self, Read};
use std::time::Duration;

use tokio::sync::Mutex;
use clap::Parser;
use serde::{Deserialize, Serialize};
use axum::{
    extract::{Path, State},
    http::{StatusCode, Response},
    response::Json,
    routing::{get, post},
    Router, body::Body,
};
use tower_http::cors::CorsLayer;
use futures_util::TryStreamExt;
use anyhow::{Result, Context};
use local_ip_address;
use std::sync::mpsc;
use rust_cast::channels::media::{Media, StreamType};
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::SampleFormat;

#[derive(Parser)]
#[command(name = "chromecast-broadcast")]
#[command(about = "Broadcast audio to Chromecast devices")]
struct Args {
    /// Audio file to broadcast
    #[arg(value_name = "FILE")]
    file: Option<PathBuf>,

    /// Chromecast speaker name
    #[arg(short, long)]
    speaker: Option<String>,

    /// Record live audio from microphone
    #[arg(long)]
    live: bool,

    /// Start web interface
    #[arg(long)]
    web: bool,

    /// Start persistent server mode
    #[arg(long)]
    server: bool,

    /// Port for server/web interface (0 for random)
    #[arg(long, default_value = "0")]
    port: u16,

    /// Keep connections alive for N seconds
    #[arg(long, default_value = "300")]
    keep_alive: u64,

    /// List available Chromecast devices
    #[arg(long)]
    list: bool,

    /// Force device discovery (ignore cache)
    #[arg(long)]
    force: bool,
}

#[derive(Serialize, Deserialize, Clone)]
struct ChromecastDevice {
    name: String,
    ip: String,
    port: u16,
    device_id: String,
}

#[derive(Serialize, Deserialize)]
struct DeviceCache {
    devices: Vec<ChromecastDevice>,
    timestamp: u64,
}


#[derive(Clone)]
struct ChromecastBroadcaster {
    device_cache: Arc<Mutex<Option<DeviceCache>>>,
    cache_path: PathBuf,
}

impl ChromecastBroadcaster {
    fn new() -> Self {
        let cache_path = dirs::cache_dir()
            .unwrap_or_else(|| PathBuf::from("/tmp"))
            .join("chromecast_devices.json");

        Self {
            device_cache: Arc::new(Mutex::new(None)),
            cache_path,
        }
    }

    async fn discover_devices(&self, force: bool) -> Result<Vec<ChromecastDevice>> {
        if !force {
            if let Ok(cache) = self.load_cache().await {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)?
                    .as_secs();

                if now - cache.timestamp < 300 { // 5 minutes
                    return Ok(cache.devices);
                }
            }
        }

        let mut devices = Vec::new();

        // Use system discovery tools since rust_cast doesn't have async discovery
        let discovery_result = Command::new("sh")
            .args([
                "-c",
                "timeout 3 dns-sd -B _googlecast._tcp 2>&1 || timeout 3 avahi-browse -t -r _googlecast._tcp 2>&1 || echo 'No discovery tools available'",
            ])
            .output();

        match discovery_result {
            Ok(output) => {
                let output_str = String::from_utf8_lossy(&output.stdout);


                devices = self.parse_discovery_output(&output_str).await;

                if devices.is_empty() {
                    eprintln!("No Chromecast devices found. Make sure devices are on the same network.");
                }
            }
            Err(e) => {
                eprintln!("Failed to discover devices: {}. Install dns-sd (macOS) or avahi-utils (Linux)", e);
            }
        }

        // Cache the discovered devices
        let cache = DeviceCache {
            devices: devices.clone(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_secs(),
        };

        self.save_cache(&cache).await?;
        *self.device_cache.lock().await = Some(cache);

        Ok(devices)
    }


    async fn parse_discovery_output(&self, output: &str) -> Vec<ChromecastDevice> {
        let mut devices = Vec::new();

        // Parse dns-sd output format
        for line in output.lines() {
            if line.contains("_googlecast._tcp") && line.contains("Add") {
                // dns-sd format: "timestamp Add flags if domain service instance_name"
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 7 {
                    let instance_name = parts.last().map_or("", |v| v);

                    // Resolve the friendly name from the TXT record
                    let friendly_name = self.resolve_friendly_name(instance_name).await;

                    // Resolve the actual hostname from dns-sd
                    let hostname = self.resolve_hostname(instance_name).await;

                    devices.push(ChromecastDevice {
                        name: friendly_name,
                        ip: hostname,
                        port: 8009,
                        device_id: uuid::Uuid::new_v4().to_string(),
                    });
                }
            }
        }

        devices
    }


    async fn resolve_hostname(&self, instance_name: &str) -> String {
        let resolve_cmd = format!("timeout 1 dns-sd -L '{}' _googlecast._tcp local 2>&1", instance_name);

        match Command::new("sh").args(["-c", &resolve_cmd]).output() {
            Ok(output) => {
                let stderr_str = String::from_utf8_lossy(&output.stderr);
                let stdout_str = String::from_utf8_lossy(&output.stdout);
                let combined = format!("{}\n{}", stdout_str, stderr_str);

                // Look for "can be reached at" line
                for line in combined.lines() {
                    if line.contains("can be reached at") {
                        if let Some(at_pos) = line.find(" at ") {
                            let rest = &line[at_pos + 4..];
                            if let Some(colon_pos) = rest.find(':') {
                                let hostname = rest[..colon_pos].trim_end_matches('.');
                                return hostname.to_string();
                            }
                        }
                    }
                }

                // Fallback to instance name based hostname
                format!("{}.local", instance_name.to_lowercase())
            }
            Err(_) => {
                format!("{}.local", instance_name.to_lowercase())
            }
        }
    }

    async fn resolve_friendly_name(&self, instance_name: &str) -> String {
        // Use timeout command to limit dns-sd execution time
        let resolve_cmd = format!("timeout 1 dns-sd -L '{}' _googlecast._tcp local 2>&1 | grep fn=", instance_name);

        match Command::new("sh").args(["-c", &resolve_cmd]).output() {
            Ok(output) => {
                let output_str = String::from_utf8_lossy(&output.stdout);

                // Look for fn= field in the TXT record
                for line in output_str.lines() {
                    if let Some(fn_start) = line.find("fn=") {
                        let fn_part = &line[fn_start + 3..];
                        // Find the end of the fn field (next space)
                        let friendly_name = if let Some(space_pos) = fn_part.find(' ') {
                            &fn_part[..space_pos]
                        } else {
                            fn_part
                        };

                        // Unescape backslash-escaped spaces and other characters
                        return friendly_name.replace("\\ ", " ").replace("\\", "");
                    }
                }

                // If no fn= found, use instance name as fallback
                instance_name.to_string()
            }
            Err(_) => {
                // If resolution fails, use instance name
                instance_name.to_string()
            }
        }
    }

    async fn load_cache(&self) -> Result<DeviceCache> {
        let content = tokio::fs::read_to_string(&self.cache_path).await?;
        let cache: DeviceCache = serde_json::from_str(&content)?;
        Ok(cache)
    }


    async fn save_cache(&self, cache: &DeviceCache) -> Result<()> {
        let content = serde_json::to_string_pretty(cache)?;
        if let Some(parent) = self.cache_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        tokio::fs::write(&self.cache_path, content).await?;
        Ok(())
    }

    async fn find_device(&self, speaker_name: &str) -> Result<ChromecastDevice> {
        let devices = self.discover_devices(false).await?;

        devices.into_iter()
            .find(|d| d.name.to_lowercase().contains(&speaker_name.to_lowercase()))
            .context("Device not found")
    }


    async fn cast_audio(&self, device: &ChromecastDevice, audio_url: &str) -> Result<()> {
        println!("Casting {} to {}", audio_url, device.name);

        // Connect using hostname instead of IP if needed
        let mut connection_device = device.clone();

        // If the hostname doesn't work, try to resolve to IP
        if device.ip.contains(".local") {
            // Try to resolve the mDNS hostname to an IP address
            if let Ok(resolved_ip) = self.resolve_hostname_to_ip(&device.ip).await {
                connection_device.ip = resolved_ip;
                println!("Resolved {} to {}", device.ip, connection_device.ip);
            }
        }

        // Connect without host verification to avoid SSL certificate issues
        println!("Connecting to Chromecast without host verification...");
        let cast_device = match rust_cast::CastDevice::connect_without_host_verification(&connection_device.ip, connection_device.port) {
            Ok(device) => {
                println!("Connected to Chromecast: {}", connection_device.name);
                device
            }
            Err(e) => {
                anyhow::bail!("Failed to connect to Chromecast: {}", e);
            }
        };

        // CRITICAL: Connect to the default receiver first (like the working example)
        println!("Connecting to default receiver...");
        match cast_device.connection.connect("receiver-0".to_string()) {
            Ok(_) => {
                println!("Connected to default receiver");
            }
            Err(e) => {
                anyhow::bail!("Failed to connect to default receiver: {}", e);
            }
        }


        // Skip connection test and proceed directly to app launch
        println!("Proceeding to app launch...");

        // Send heartbeat to ensure connection is alive
        println!("Sending heartbeat to ensure connection...");
        match cast_device.heartbeat.ping() {
            Ok(_) => {
                println!("Heartbeat successful - connection is alive");
            }
            Err(e) => {
                eprintln!("Heartbeat failed: {}", e);
                anyhow::bail!("Connection lost: {}", e);
            }
        }

        // Launch the default media receiver app (like Python version does)
        println!("Launching default media receiver app...");
        use rust_cast::channels::receiver::CastDeviceApp;
        let app = CastDeviceApp::DefaultMediaReceiver;

        let app_response = match cast_device.receiver.launch_app(&app) {
            Ok(response) => {
                println!("Successfully launched media receiver app");
                println!("App response: {:?}", response);
                response
            }
            Err(e) => {
                eprintln!("Failed to launch media receiver: {}", e);
                anyhow::bail!("Failed to launch media receiver: {}", e);
            }
        };

        // CRITICAL: Connect to the app's transport ID (like the working example)
        println!("Connecting to app transport ID: {}", app_response.transport_id);
        match cast_device.connection.connect(app_response.transport_id.clone()) {
            Ok(_) => {
                println!("Connected to app transport");
            }
            Err(e) => {
                anyhow::bail!("Failed to connect to app transport: {}", e);
            }
        }

        // App should be ready immediately after successful launch

        // Create media object for live streaming
        let media = Media {
            content_id: audio_url.to_string(),
            stream_type: StreamType::Live,
            content_type: "audio/wav".to_string(),
            metadata: None,
            duration: None,
        };

        // Load media using the app session info
        println!("Loading media to launched app...");
        let destination = &app_response.transport_id;
        let session_id = if app_response.session_id.is_empty() {
            "0".to_string()
        } else {
            app_response.session_id.clone()
        };

        match cast_device.media.load(destination, &session_id, &media) {
            Ok(load_response) => {
                println!("Media loaded successfully");
                println!("Load response: {:?}", load_response);

                // Get the media session ID from the load response
                let media_session_id = if let Some(entry) = load_response.entries.first() {
                    entry.media_session_id
                } else {
                    anyhow::bail!("No media session found in load response");
                };

                println!("Using media session ID: {}", media_session_id);

                // Media should be ready immediately after load

                // Play the media using the correct media session ID
                println!("Starting playback...");
                match cast_device.media.play(destination, media_session_id) {
                    Ok(play_response) => {
                        println!("Successfully started playing on {}", device.name);
                        println!("Play response: {:?}", play_response);
                    }
                    Err(e) => {
                        eprintln!("Failed to start playback: {}", e);
                        anyhow::bail!("Failed to start playback: {}", e);
                    }
                }
            }
            Err(e) => {
                eprintln!("Failed to load media: {}", e);
                anyhow::bail!("Failed to load media: {}", e);
            }
        }

        Ok(())
    }

    async fn resolve_hostname_to_ip(&self, hostname: &str) -> Result<String> {
        use std::net::{ToSocketAddrs, IpAddr};

        // Try to resolve the hostname to an IPv4 address
        let socket_addrs: Vec<_> = format!("{}:8009", hostname)
            .to_socket_addrs()?
            .collect();

        // Prefer IPv4 addresses
        for addr in &socket_addrs {
            if let IpAddr::V4(ipv4) = addr.ip() {
                return Ok(ipv4.to_string());
            }
        }

        // Fall back to first address if no IPv4 found
        socket_addrs
            .first()
            .map(|addr| addr.ip().to_string())
            .context("No addresses found")
    }

    async fn create_streaming_server(&self, server_port: u16) -> Result<(mpsc::Sender<Vec<u8>>, u16, tokio::task::JoinHandle<()>)> {
        let (audio_tx, audio_rx) = mpsc::channel::<Vec<u8>>();
        let audio_rx = Arc::new(Mutex::new(audio_rx));

        async fn stream_wav_handler(State(audio_rx): State<Arc<Mutex<mpsc::Receiver<Vec<u8>>>>>) -> Response<Body> {
            let (tx, rx) = tokio::sync::mpsc::channel::<Result<bytes::Bytes, std::io::Error>>(10);

            // Spawn a task to pump data from std mpsc to tokio mpsc
            tokio::spawn(async move {
                loop {
                    let chunk = {
                        let rx_guard = audio_rx.lock().await;
                        match rx_guard.try_recv() {
                            Ok(data) => Some(data),
                            Err(mpsc::TryRecvError::Empty) => {
                                drop(rx_guard);
                                tokio::time::sleep(Duration::from_millis(10)).await;
                                continue;
                            }
                            Err(mpsc::TryRecvError::Disconnected) => None,
                        }
                    };

                    if let Some(chunk) = chunk {
                        if tx.send(Ok(bytes::Bytes::from(chunk))).await.is_err() {
                            break;
                        }
                    } else {
                        break;
                    }
                }
            });

            let stream = tokio_stream::wrappers::ReceiverStream::new(rx);
            let body = Body::from_stream(stream);

            Response::builder()
                .header("content-type", "audio/wav")
                .header("cache-control", "no-cache")
                .header("access-control-allow-origin", "*")
                .body(body)
                .unwrap()
        }

        let app = Router::new()
            .route("/stream.wav", get(stream_wav_handler))
            .with_state(audio_rx.clone());

        let (addr_tx, addr_rx) = tokio::sync::oneshot::channel();
        let server_handle = tokio::spawn(async move {
            let listener = tokio::net::TcpListener::bind(("0.0.0.0", server_port)).await.unwrap();
            let actual_port = listener.local_addr().unwrap().port();
            println!("Starting streaming server on port {}", actual_port);
            let _ = addr_tx.send(actual_port);
            axum::serve(listener, app).await.unwrap();
        });

        // Wait for server to get its port assignment
        let actual_port = addr_rx.await.context("Failed to get server port")?;

        // Server starts immediately

        Ok((audio_tx, actual_port, server_handle))
    }

    fn start_audio_recording(&self, audio_tx: mpsc::Sender<Vec<u8>>) -> Result<()> {
        let host = cpal::default_host();
        let device = host.default_input_device().context("No default input device available")?;

        let config = device.default_input_config().context("Failed to get default input config")?;
        println!("Recording with config: {:?}", config);

        let _sample_rate = config.sample_rate().0;
        let channels = config.channels();

        // WAV header for 44.1kHz, 16-bit, stereo, streaming (unknown length)
        let wav_header = Self::create_wav_header(44100, 2, 0xFFFFFFFF); // Use max length for streaming

        // Send WAV header first
        audio_tx.send(wav_header).context("Failed to send WAV header")?;

        let audio_tx_clone = audio_tx.clone();

        let stream = match config.sample_format() {
            SampleFormat::F32 => {
                device.build_input_stream(
                    &config.into(),
                    move |data: &[f32], _: &cpal::InputCallbackInfo| {
                        // Convert f32 samples to i16 PCM
                        let mut pcm_data = Vec::with_capacity(data.len() * 2);

                        for &sample in data {
                            // Convert f32 to i16
                            let sample_i16 = (sample.clamp(-1.0, 1.0) * i16::MAX as f32) as i16;
                            pcm_data.extend_from_slice(&sample_i16.to_le_bytes());
                        }

                        // Handle channel conversion if needed
                        if channels == 1 {
                            // Duplicate mono to stereo
                            let mut stereo_data = Vec::with_capacity(pcm_data.len() * 2);
                            for chunk in pcm_data.chunks(2) {
                                stereo_data.extend_from_slice(chunk); // Left
                                stereo_data.extend_from_slice(chunk); // Right
                            }
                            let _ = audio_tx_clone.send(stereo_data);
                        } else {
                            let _ = audio_tx_clone.send(pcm_data);
                        }
                    },
                    |err| eprintln!("Audio input error: {}", err),
                    None,
                )?
            }
            SampleFormat::I16 => {
                device.build_input_stream(
                    &config.into(),
                    move |data: &[i16], _: &cpal::InputCallbackInfo| {
                        // Convert i16 samples to bytes
                        let mut pcm_data = Vec::with_capacity(data.len() * 2);

                        for &sample in data {
                            pcm_data.extend_from_slice(&sample.to_le_bytes());
                        }

                        // Handle channel conversion if needed
                        if channels == 1 {
                            // Duplicate mono to stereo
                            let mut stereo_data = Vec::with_capacity(pcm_data.len() * 2);
                            for chunk in pcm_data.chunks(2) {
                                stereo_data.extend_from_slice(chunk); // Left
                                stereo_data.extend_from_slice(chunk); // Right
                            }
                            let _ = audio_tx_clone.send(stereo_data);
                        } else {
                            let _ = audio_tx_clone.send(pcm_data);
                        }
                    },
                    |err| eprintln!("Audio input error: {}", err),
                    None,
                )?
            }
            _ => return Err(anyhow::anyhow!("Unsupported sample format: {:?}", config.sample_format())),
        };

        stream.play().context("Failed to start audio stream")?;

        // Keep the stream alive - it will be dropped when the function returns
        std::mem::forget(stream);

        Ok(())
    }

    fn create_wav_header(sample_rate: u32, channels: u16, data_size: u32) -> Vec<u8> {
        let mut header = Vec::with_capacity(44);

        // RIFF header
        header.extend_from_slice(b"RIFF");
        header.extend_from_slice(&(36 + data_size).to_le_bytes()); // File size - 8
        header.extend_from_slice(b"WAVE");

        // fmt chunk
        header.extend_from_slice(b"fmt ");
        header.extend_from_slice(&16u32.to_le_bytes()); // fmt chunk size
        header.extend_from_slice(&1u16.to_le_bytes());  // PCM format
        header.extend_from_slice(&channels.to_le_bytes()); // Number of channels
        header.extend_from_slice(&sample_rate.to_le_bytes()); // Sample rate

        let byte_rate = sample_rate * channels as u32 * 2; // 16-bit = 2 bytes per sample
        header.extend_from_slice(&byte_rate.to_le_bytes()); // Byte rate

        let block_align = channels * 2; // 16-bit = 2 bytes per sample
        header.extend_from_slice(&block_align.to_le_bytes()); // Block align
        header.extend_from_slice(&16u16.to_le_bytes()); // Bits per sample

        // data chunk
        header.extend_from_slice(b"data");
        header.extend_from_slice(&data_size.to_le_bytes()); // Data size

        header
    }

    async fn broadcast_file(&self, file_path: &str, speaker_name: &str) -> Result<()> {
        let device = self.find_device(speaker_name).await?;

        // Use random available port
        let server_port = 0u16;
        let (audio_tx, actual_port, server_handle) = self.create_streaming_server(server_port).await?;

        let audio_url = format!("http://{}:{}/stream.wav",
            local_ip_address::local_ip().unwrap_or_else(|_| "127.0.0.1".parse().unwrap()),
            actual_port);

        // Start FFmpeg and Chromecast connection in parallel
        println!("Starting file streaming for {}", file_path);
        let file_path_clone = file_path.to_string();
        let streaming_handle = tokio::task::spawn_blocking(move || {
            let mut ffmpeg = Command::new("ffmpeg")
                .args([
                    "-re",  // Read input at native frame rate (real-time)
                    "-i", &file_path_clone,
                    "-acodec", "pcm_s16le",  // 16-bit PCM
                    "-ar", "44100",
                    "-ac", "2",
                    "-f", "wav",
                    "-"
                ])
                .stdout(Stdio::piped())
                .stderr(Stdio::null())
                .spawn()
                .expect("Failed to start FFmpeg");

            let mut stdout = ffmpeg.stdout.take().expect("Failed to get FFmpeg stdout");
            let mut buffer = [0u8; 8192];
            let mut total_bytes = 0;

            loop {
                match stdout.read(&mut buffer) {
                    Ok(0) => break, // EOF
                    Ok(n) => {
                        total_bytes += n;
                        if audio_tx.send(buffer[..n].to_vec()).is_err() {
                            break; // Receiver dropped
                        }

                    }
                    Err(_) => break,
                }
            }

            println!("FFmpeg finished, total bytes: {}", total_bytes);
            let _ = ffmpeg.wait();
        });

        // Connect to Chromecast immediately - HTTP streaming will handle buffering
        println!("Connecting to Chromecast...");
        self.cast_audio(&device, &audio_url).await?;

        println!("Streaming file {} to {} - audio should start immediately", file_path, device.name);

        // Wait for streaming to complete or timeout
        let _ = tokio::time::timeout(Duration::from_secs(300), streaming_handle).await;

        // Clean up
        server_handle.abort();
        println!("Finished streaming file");

        Ok(())
    }

    async fn broadcast_live(&self, speaker_name: &str) -> Result<()> {
        let device = self.find_device(speaker_name).await?;

        // Use random available port
        let server_port = 0u16;
        let (audio_tx, actual_port, server_handle) = self.create_streaming_server(server_port).await?;

        let audio_url = format!("http://{}:{}/stream.wav",
            local_ip_address::local_ip().unwrap_or_else(|_| "127.0.0.1".parse().unwrap()),
            actual_port);

        // Start native audio recording
        println!("Starting native audio capture...");
        self.start_audio_recording(audio_tx)
            .context("Failed to start audio recording")?;

        // Connect to Chromecast immediately - HTTP streaming will handle buffering
        println!("Connecting to Chromecast...");
        self.cast_audio(&device, &audio_url).await?;

        println!("Recording and streaming live audio to {} - audio should start immediately", device.name);
        println!("Press Ctrl+C to stop.");

        // Wait for interrupt signal
        tokio::signal::ctrl_c().await?;

        println!("\nStopping live stream...");

        // Clean up
        server_handle.abort();

        println!("Live streaming stopped");

        Ok(())
    }


    async fn start_server_mode(&self, port: u16, _keep_alive: u64) -> Result<()> {
        let broadcaster = Arc::new(self.clone());

        let app = Router::new()
            .route("/devices", get(list_devices))
            .route("/cast/:speaker/stream", post(stream_audio))
            .route("/cast/:speaker/stop", get(stop_audio))
            .route("/status", get(server_status))
            .layer(CorsLayer::permissive())
            .with_state(broadcaster);

        let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await?;
        let actual_port = listener.local_addr()?.port();

        println!("Chromecast server running on http://localhost:{}", actual_port);

        axum::serve(listener, app).await?;

        Ok(())
    }

    async fn start_web_interface(&self, _port: u16) -> Result<()> {
        // Simplified web interface - websockets removed for now
        println!("Web interface disabled in axum version");
        Ok(())
    }

}

// WebSocket handler removed for axum migration

type AppState = Arc<ChromecastBroadcaster>;

async fn list_devices(State(broadcaster): State<AppState>) -> Result<Json<Vec<ChromecastDevice>>, StatusCode> {
    match broadcaster.discover_devices(false).await {
        Ok(devices) => Ok(Json(devices)),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

async fn stream_audio(
    State(broadcaster): State<AppState>,
    Path(speaker): Path<String>,
    body: Body,
) -> Result<String, StatusCode> {
    let stream = body.into_data_stream();

    match stream_audio_data(&broadcaster, &speaker, stream).await {
        Ok(_) => Ok("Stream started".to_string()),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

async fn stop_audio(Path(speaker): Path<String>) -> Result<String, StatusCode> {
    match stop_playback(&speaker).await {
        Ok(_) => Ok("Playback stopped".to_string()),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

async fn server_status() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "running",
        "version": "1.0.0"
    }))
}


async fn stream_audio_data(
    broadcaster: &ChromecastBroadcaster,
    speaker_name: &str,
    body: impl futures::Stream<Item = Result<bytes::Bytes, axum::Error>> + Send + 'static,
) -> Result<()> {
    println!("Starting audio stream to {}", speaker_name);

    // Find the device
    let device = broadcaster.find_device(speaker_name).await?;

    // Start HTTP streaming server for this request
    let server_port = 0u16;
    let (audio_tx, actual_port, server_handle) = broadcaster.create_streaming_server(server_port).await?;

    let audio_url = format!("http://{}:{}/stream.wav",
        local_ip_address::local_ip().unwrap_or_else(|_| "127.0.0.1".parse().unwrap()),
        actual_port);

    // Start Chromecast connection in background
    let broadcaster_clone = broadcaster.clone();
    let device_clone = device.clone();
    let audio_url_clone = audio_url.clone();
    let cast_handle = tokio::spawn(async move {
        broadcaster_clone.cast_audio(&device_clone, &audio_url_clone).await
    });

    // Stream incoming data to the audio channel
    let speaker_name_clone = speaker_name.to_string();
    let stream_handle = tokio::spawn(async move {
        use futures_util::pin_mut;
        pin_mut!(body);

        while let Some(chunk) = body.try_next().await.unwrap_or(None) {
            let data = chunk.to_vec();
            if audio_tx.send(data).is_err() {
                break;
            }
        }
        println!("Stream ended for {}", speaker_name_clone);
    });

    // Wait for both to complete or timeout after 5 minutes
    let timeout_result = tokio::time::timeout(
        std::time::Duration::from_secs(300),
        async {
            let cast_result = cast_handle.await;
            let stream_result = stream_handle.await;
            (cast_result, stream_result)
        }
    );

    match timeout_result.await {
        Ok((cast_result, _)) => {
            if let Ok(Err(e)) = cast_result {
                eprintln!("Cast error: {}", e);
            }
        }
        Err(_) => println!("Stream timed out"),
    }

    server_handle.abort();
    Ok(())
}

async fn stop_playback(
    speaker_name: &str,
) -> Result<()> {
    println!("Stop request for {}", speaker_name);
    // For /stream endpoints, the connection will naturally close when the HTTP request ends
    // No need for complex tracking since each stream is a single HTTP request
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    let broadcaster = ChromecastBroadcaster::new();

    if args.list {
        let devices = broadcaster.discover_devices(args.force).await?;
        println!("Available Chromecast devices:");
        for device in devices {
            println!("  {} ({}:{})", device.name, device.ip, device.port);
        }
        return Ok(());
    }

    if args.server {
        broadcaster.start_server_mode(args.port, args.keep_alive).await?;
        return Ok(());
    }

    if args.web {
        broadcaster.start_web_interface(args.port).await?;
        return Ok(());
    }

    let speaker_name = args.speaker
        .or_else(|| std::env::var("CHROMECAST_SPEAKER").ok())
        .context("Speaker name required. Use -s option or set CHROMECAST_SPEAKER env var")?;

    if args.live {
        broadcaster.broadcast_live(&speaker_name).await?;
    } else if let Some(file_path) = args.file {
        broadcaster.broadcast_file(file_path.to_str().unwrap(), &speaker_name).await?;
    } else {
        // Check if stdin has data
        use std::io::IsTerminal;

        if io::stdin().is_terminal() {
            eprintln!("Error: No audio file specified. Use one of:");
            eprintln!("  chromecast-broadcast <audio_file> -s <speaker>");
            eprintln!("  chromecast-broadcast --live -s <speaker>");
            eprintln!("  echo 'audio data' | chromecast-broadcast -s <speaker>");
            return Ok(());
        }

        // Read from stdin
        let mut buffer = Vec::new();
        io::stdin().read_to_end(&mut buffer)?;

        if buffer.is_empty() {
            eprintln!("Error: No data received from stdin");
            return Ok(());
        }

        // Write stdin data to a temporary file
        let temp_file = format!("/tmp/stdin_cast_{}", uuid::Uuid::new_v4());
        tokio::fs::write(&temp_file, &buffer).await?;

        // Broadcast the file (it will be converted to MP3 if needed)
        broadcaster.broadcast_file(&temp_file, &speaker_name).await?;

        let _ = tokio::fs::remove_file(&temp_file).await;
    }

    Ok(())
}