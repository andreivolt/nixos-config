use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;

#[derive(Parser)]
#[command(about = "TTS hook for Claude Code")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Enable TTS
    Enable,
    /// Disable TTS
    Disable,
    /// Show current status
    Status,
    /// Set or show provider
    Provider {
        /// Provider name (deepgram-tts, elevenlabs, unrealspeech, cartesia)
        name: Option<String>,
    },
    /// Set or show default language
    Language {
        /// ISO 639-1 language code (e.g., en, es, fr)
        code: Option<String>,
    },
    /// Enable or disable language detection
    LanguageCheck {
        /// on/off
        state: Option<String>,
    },
    /// Enable or disable audio formatting (process through Haiku)
    AudioFormat {
        /// on/off
        state: Option<String>,
    },
    /// Enable or disable interrupt mode (kill previous TTS)
    Interrupt {
        /// on/off
        state: Option<String>,
    },
    /// Set playback speed (1.0 = normal, 1.5 = 50% faster)
    Speed {
        /// Speed multiplier (0.5-3.0)
        value: Option<f32>,
    },
    /// Speak text from stdin
    Speak,
}

#[derive(Serialize, Deserialize, Clone)]
struct Config {
    enabled: bool,
    provider: String,
    language_check: bool,
    language: String,
    #[serde(default = "default_true")]
    audio_format: bool,  // Process through Haiku to make audio-friendly
    #[serde(default = "default_true")]
    interrupt: bool,     // Kill previous TTS when new response starts
    #[serde(default = "default_speed")]
    speed: f32,          // Playback speed (1.0 = normal, 1.5 = 50% faster)
}

fn default_true() -> bool { true }
fn default_speed() -> f32 { 1.3 }

impl Default for Config {
    fn default() -> Self {
        Self {
            enabled: true,
            provider: "deepgram-tts".to_string(),
            language_check: false,
            language: "en".to_string(),
            audio_format: true,
            interrupt: true,
            speed: 1.3,
        }
    }
}

fn config_path() -> PathBuf {
    dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("~/.config"))
        .join("claude-tts")
        .join("config.json")
}

fn load_config() -> Config {
    let path = config_path();
    if path.exists() {
        fs::read_to_string(&path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default()
    } else {
        Config::default()
    }
}

fn save_config(config: &Config) -> Result<()> {
    let path = config_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let json = serde_json::to_string_pretty(config)?;
    fs::write(&path, json)?;
    Ok(())
}

#[derive(Deserialize)]
struct HookInput {
    transcript_path: Option<String>,
}

#[derive(Deserialize)]
struct TranscriptEntry {
    #[serde(rename = "type")]
    entry_type: Option<String>,
    message: Option<Message>,
}

#[derive(Deserialize)]
struct Message {
    content: Option<serde_json::Value>,
}

fn extract_last_response(transcript_path: &str) -> Option<String> {
    let path = shellexpand::tilde(transcript_path).to_string();
    let content = fs::read_to_string(&path).ok()?;

    // JSONL format - read lines in reverse to find last assistant message
    for line in content.lines().rev() {
        if let Ok(entry) = serde_json::from_str::<TranscriptEntry>(line) {
            if entry.entry_type.as_deref() == Some("assistant") {
                if let Some(message) = entry.message {
                    if let Some(content) = message.content {
                        // Only return if we actually found text content
                        if let Some(text) = extract_text_from_content(&content) {
                            return Some(text);
                        }
                        // Otherwise continue searching for an entry with text
                    }
                }
            }
        }
    }
    None
}

fn extract_text_from_content(content: &serde_json::Value) -> Option<String> {
    match content {
        serde_json::Value::String(s) => Some(s.clone()),
        serde_json::Value::Array(arr) => {
            let texts: Vec<String> = arr
                .iter()
                .filter_map(|item| {
                    if item.get("type")?.as_str()? == "text" {
                        item.get("text")?.as_str().map(|s| s.to_string())
                    } else {
                        None
                    }
                })
                .collect();
            if texts.is_empty() {
                None
            } else {
                Some(texts.join("\n"))
            }
        }
        _ => None,
    }
}

fn kill_previous_tts() {
    use std::process::Command;
    // Kill any running TTS processes
    let _ = Command::new("pkill").arg("-f").arg("claude-tts speak").output();
    let _ = Command::new("pkill").arg("-f").arg("deepgram-tts").output();
    let _ = Command::new("pkill").arg("-f").arg("elevenlabs").output();
    let _ = Command::new("pkill").arg("-f").arg("unrealspeech").output();
}

fn summarize_code_block(code: &str) -> String {
    let api_key = match std::env::var("OPENROUTER_API_KEY") {
        Ok(key) => key,
        Err(_) => return "[code block]".to_string(),
    };

    let client = reqwest::blocking::Client::new();
    let response = client
        .post("https://openrouter.ai/api/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&serde_json::json!({
            "model": "anthropic/claude-haiku-4.5",
            "max_tokens": 100,
            "messages": [
                {
                    "role": "user",
                    "content": format!("Convert this code to a brief spoken description (1-2 sentences). Describe what it accomplishes as if explaining to someone listening. Be natural and conversational. Output only the description.\n\n{}", code)
                }
            ]
        }))
        .send();

    match response {
        Ok(resp) => {
            if let Ok(json) = resp.json::<serde_json::Value>() {
                json["choices"][0]["message"]["content"]
                    .as_str()
                    .map(|s| s.trim().to_string())
                    .unwrap_or_else(|| "[code block]".to_string())
            } else {
                "[code block]".to_string()
            }
        }
        Err(_) => "[code block]".to_string(),
    }
}

fn format_for_audio(text: &str) -> String {
    use rayon::prelude::*;
    use regex::Regex;

    // Find all code blocks and their positions
    let code_block_re = Regex::new(r"```(?:\w+)?\n?([\s\S]*?)```").unwrap();
    let code_blocks: Vec<(usize, usize, String)> = code_block_re
        .captures_iter(text)
        .map(|cap| {
            let m = cap.get(0).unwrap();
            let code = cap.get(1).map(|c| c.as_str()).unwrap_or("");
            (m.start(), m.end(), code.to_string())
        })
        .collect();

    // Summarize code blocks in parallel (limit to 5 to avoid too many API calls)
    let summaries: Vec<String> = code_blocks
        .par_iter()
        .take(5)
        .map(|(_, _, code)| summarize_code_block(code))
        .collect();

    // Replace code blocks with summaries
    let mut result = text.to_string();
    for (i, (start, end, _)) in code_blocks.iter().enumerate().rev() {
        let summary = summaries.get(i).cloned().unwrap_or_else(|| "[code]".to_string());
        result.replace_range(*start..*end, &format!("({})", summary));
    }

    // Clean up remaining markdown
    let inline_code_re = Regex::new(r"`([^`]+)`").unwrap();
    result = inline_code_re.replace_all(&result, "$1").to_string();

    let header_re = Regex::new(r"(?m)^#{1,6}\s*").unwrap();
    result = header_re.replace_all(&result, "").to_string();

    let bold_re = Regex::new(r"\*\*([^*]+)\*\*").unwrap();
    result = bold_re.replace_all(&result, "$1").to_string();

    // Simple italic removal (after bold is already removed)
    let italic_re = Regex::new(r"\*([^*]+)\*").unwrap();
    result = italic_re.replace_all(&result, "$1").to_string();

    let link_re = Regex::new(r"\[([^\]]+)\]\([^)]+\)").unwrap();
    result = link_re.replace_all(&result, "$1").to_string();

    let bullet_re = Regex::new(r"(?m)^[\s]*[-*+]\s+").unwrap();
    result = bullet_re.replace_all(&result, "").to_string();

    let numbered_re = Regex::new(r"(?m)^\s*\d+\.\s+").unwrap();
    result = numbered_re.replace_all(&result, "").to_string();

    let newlines_re = Regex::new(r"\n{3,}").unwrap();
    result = newlines_re.replace_all(&result, "\n\n").to_string();

    result.trim().to_string()
}

fn detect_language(text: &str) -> Option<String> {
    // Use OpenRouter API for language detection - take first 50 words
    let sample: String = text
        .split_whitespace()
        .take(50)
        .collect::<Vec<_>>()
        .join(" ");

    let api_key = std::env::var("OPENROUTER_API_KEY").ok()?;

    let client = reqwest::blocking::Client::new();
    let response = client
        .post("https://openrouter.ai/api/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&serde_json::json!({
            "model": "anthropic/claude-haiku-4.5",
            "max_tokens": 4,
            "messages": [
                {
                    "role": "user",
                    "content": format!("What language is this text? Reply with ONLY the ISO 639-1 two-letter code (e.g., en, es, fr), nothing else.\n\n{}", sample)
                }
            ]
        }))
        .send()
        .ok()?;

    let json: serde_json::Value = response.json().ok()?;
    let result = json["choices"][0]["message"]["content"]
        .as_str()?
        .trim()
        .to_lowercase();

    // Validate it's a 2-letter code
    if result.len() == 2 && result.chars().all(|c| c.is_ascii_lowercase()) {
        Some(result)
    } else {
        None
    }
}

fn speak_text(text: &str, config: &Config) -> Result<()> {
    use rodio::{Decoder, OutputStream, Sink};
    use std::io::Cursor;
    use std::process::{Command, Stdio};

    let lang = if config.language_check {
        detect_language(text).unwrap_or_else(|| config.language.clone())
    } else {
        config.language.clone()
    };

    // Track if provider uses native speed (don't apply rodio speed then)
    let uses_native_speed = matches!(config.provider.as_str(), "elevenlabs" | "unrealspeech" | "cartesia");

    // Build command with output to stdout (piped)
    let mut cmd = Command::new(match config.provider.as_str() {
        "deepgram-tts" => "deepgram-tts",
        "elevenlabs" => "elevenlabs",
        "unrealspeech" => "unrealspeech",
        "cartesia" => "cartesia",
        other => anyhow::bail!("Unknown provider: {}", other),
    });

    // Add provider-specific args
    match config.provider.as_str() {
        "elevenlabs" => {
            // ElevenLabs native speed: 0.7-1.2 range
            if config.speed != 1.0 {
                let el_speed = config.speed.clamp(0.7, 1.2);
                cmd.args(["--speed", &el_speed.to_string()]);
            }
            if lang != "en" {
                cmd.args(["-m", "eleven_flash_v2_5", "-l", &lang]);
            }
        }
        "unrealspeech" => {
            // UnrealSpeech: -1.0 to 1.0 where 0 is normal
            // Map user's 1.0x -> 0.0, 1.3x -> 0.3, etc.
            if config.speed != 1.0 {
                let us_speed = (config.speed - 1.0).clamp(-1.0, 1.0);
                cmd.args(["-s", &us_speed.to_string()]);
            }
        }
        "cartesia" => {
            // Cartesia native speed: 0.6-1.5 range
            if config.speed != 1.0 {
                let cart_speed = config.speed.clamp(0.6, 1.5);
                cmd.args(["-s", &cart_speed.to_string()]);
            }
        }
        _ => {}
    }

    // Pipe text to stdin and capture audio from stdout
    let mut child = cmd
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .context("Failed to spawn TTS process")?;

    // Write text to stdin
    if let Some(mut stdin) = child.stdin.take() {
        use std::io::Write;
        stdin.write_all(text.as_bytes())?;
    }

    // Wait for completion and get audio data
    let output = child.wait_with_output().context("Failed to get TTS output")?;

    if output.stdout.is_empty() {
        anyhow::bail!("TTS produced no audio output");
    }

    // Play audio with rodio
    let (_stream, stream_handle) = OutputStream::try_default()
        .context("Failed to get audio output device")?;

    let sink = Sink::try_new(&stream_handle)
        .context("Failed to create audio sink")?;

    // Set playback speed only for providers without native speed support
    if !uses_native_speed && config.speed != 1.0 {
        sink.set_speed(config.speed);
    }

    // Decode and play
    let cursor = Cursor::new(output.stdout);
    let source = Decoder::new(cursor)
        .context("Failed to decode audio")?;

    sink.append(source);
    sink.sleep_until_end();

    Ok(())
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let mut config = load_config();

    match cli.command {
        Some(Commands::Enable) => {
            config.enabled = true;
            save_config(&config)?;
            println!("TTS enabled");
        }
        Some(Commands::Disable) => {
            config.enabled = false;
            save_config(&config)?;
            println!("TTS disabled");
        }
        Some(Commands::Status) => {
            println!("Enabled: {}", config.enabled);
            println!("Provider: {}", config.provider);
            println!("Language: {}", config.language);
            println!("Language check: {}", config.language_check);
            println!("Audio format: {}", config.audio_format);
            println!("Interrupt: {}", config.interrupt);
            println!("Speed: {}x", config.speed);
        }
        Some(Commands::Provider { name }) => {
            if let Some(name) = name {
                match name.as_str() {
                    "deepgram-tts" | "elevenlabs" | "unrealspeech" | "cartesia" => {
                        config.provider = name.clone();
                        save_config(&config)?;
                        println!("Provider set to: {}", name);
                    }
                    _ => {
                        eprintln!("Unknown provider: {}", name);
                        eprintln!("Valid providers: deepgram-tts, elevenlabs, unrealspeech, cartesia");
                        std::process::exit(1);
                    }
                }
            } else {
                println!("Current provider: {}", config.provider);
            }
        }
        Some(Commands::Language { code }) => {
            if let Some(code) = code {
                if code.len() == 2 && code.chars().all(|c| c.is_ascii_lowercase()) {
                    config.language = code.clone();
                    save_config(&config)?;
                    println!("Language set to: {}", code);
                } else {
                    eprintln!("Invalid language code: {} (must be ISO 639-1, e.g., en, es, fr)", code);
                    std::process::exit(1);
                }
            } else {
                println!("Current language: {}", config.language);
            }
        }
        Some(Commands::LanguageCheck { state }) => {
            if let Some(state) = state {
                match state.as_str() {
                    "on" | "true" | "1" => {
                        config.language_check = true;
                        save_config(&config)?;
                        println!("Language detection enabled");
                    }
                    "off" | "false" | "0" => {
                        config.language_check = false;
                        save_config(&config)?;
                        println!("Language detection disabled");
                    }
                    _ => {
                        eprintln!("Usage: claude-tts language-check on|off");
                        std::process::exit(1);
                    }
                }
            } else {
                println!("Language check: {}", config.language_check);
            }
        }
        Some(Commands::AudioFormat { state }) => {
            if let Some(state) = state {
                match state.as_str() {
                    "on" | "true" | "1" => {
                        config.audio_format = true;
                        save_config(&config)?;
                        println!("Audio formatting enabled");
                    }
                    "off" | "false" | "0" => {
                        config.audio_format = false;
                        save_config(&config)?;
                        println!("Audio formatting disabled");
                    }
                    _ => {
                        eprintln!("Usage: claude-tts audio-format on|off");
                        std::process::exit(1);
                    }
                }
            } else {
                println!("Audio format: {}", config.audio_format);
            }
        }
        Some(Commands::Interrupt { state }) => {
            if let Some(state) = state {
                match state.as_str() {
                    "on" | "true" | "1" => {
                        config.interrupt = true;
                        save_config(&config)?;
                        println!("Interrupt mode enabled");
                    }
                    "off" | "false" | "0" => {
                        config.interrupt = false;
                        save_config(&config)?;
                        println!("Interrupt mode disabled");
                    }
                    _ => {
                        eprintln!("Usage: claude-tts interrupt on|off");
                        std::process::exit(1);
                    }
                }
            } else {
                println!("Interrupt: {}", config.interrupt);
            }
        }
        Some(Commands::Speed { value }) => {
            if let Some(value) = value {
                if value >= 0.5 && value <= 3.0 {
                    config.speed = value;
                    save_config(&config)?;
                    println!("Speed set to: {}x", value);
                } else {
                    eprintln!("Speed must be between 0.5 and 3.0");
                    std::process::exit(1);
                }
            } else {
                println!("Speed: {}x", config.speed);
            }
        }
        Some(Commands::Speak) => {
            if !config.enabled {
                return Ok(());
            }
            let mut text = String::new();
            io::stdin().read_to_string(&mut text)?;
            if text.is_empty() {
                return Ok(());
            }
            speak_text(&text, &config)?;
        }
        None => {
            // Hook mode - read JSON from stdin
            if !config.enabled {
                return Ok(());
            }

            // Kill previous TTS if interrupt mode is enabled
            if config.interrupt {
                kill_previous_tts();
            }

            let mut input = String::new();
            io::stdin().read_to_string(&mut input)?;

            let hook_input: HookInput = serde_json::from_str(&input)
                .unwrap_or(HookInput { transcript_path: None });

            if let Some(transcript_path) = hook_input.transcript_path {
                if let Some(response) = extract_last_response(&transcript_path) {
                    // Format for audio if enabled
                    let text_to_speak = if config.audio_format {
                        format_for_audio(&response)
                    } else {
                        response
                    };

                    // Write response to temp file and spawn background process to speak it
                    use std::process::Command;
                    let temp_file = format!("/tmp/claude-tts-{}.txt", std::process::id());
                    if fs::write(&temp_file, &text_to_speak).is_ok() {
                        // Spawn shell to pipe file to claude-tts speak
                        let _ = Command::new("setsid")
                            .arg("sh")
                            .arg("-c")
                            .arg(format!(
                                "cat '{}' | claude-tts speak; rm -f '{}'",
                                &temp_file, &temp_file
                            ))
                            .stdin(std::process::Stdio::null())
                            .stdout(std::process::Stdio::null())
                            .stderr(std::process::Stdio::null())
                            .spawn();
                    }
                }
            }
        }
    }

    Ok(())
}
