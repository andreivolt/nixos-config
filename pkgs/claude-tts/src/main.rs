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
        /// Provider name (deepgram, elevenlabs, unrealspeech, cartesia)
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
            provider: "deepgram".to_string(),
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

enum TextSegment {
    Code(String),
    Prose(String),
}

fn process_segment(segment: &TextSegment, api_key: &str) -> String {
    let (prompt, content) = match segment {
        TextSegment::Code(code) => {
            if code.trim().is_empty() {
                return String::new();
            }
            (
                "Convert this code to a brief spoken description (1-2 sentences). Describe what it accomplishes as if explaining to someone listening. Be natural and conversational. Output only the description.",
                code.as_str()
            )
        }
        TextSegment::Prose(text) => {
            if text.trim().is_empty() {
                return String::new();
            }
            (
                "Convert this text for text-to-speech (will be read verbatim by TTS). Rules:
- Numbered lists: write \"Number one:\", \"Number two:\", etc.
- Bullet lists: write \"First,\", \"Next,\", \"Also,\" etc.
- File paths: convert slashes to words (e.g., src/components/Button.tsx → \"src slash components slash Button dot tsx\")
- Inline code in backticks: just remove the backticks, keep the text
- Remove markdown formatting (**, *, #, [], etc.) but keep the words
- Keep technical terms and variable names exactly as written
- Output only the converted text, nothing else.",
                text.as_str()
            )
        }
    };

    let client = reqwest::blocking::Client::new();
    let response = client
        .post("https://openrouter.ai/api/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&serde_json::json!({
            "model": "anthropic/claude-haiku-4.5",
            "max_tokens": 500,
            "messages": [
                {
                    "role": "user",
                    "content": format!("{}\n\n{}", prompt, content)
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
                    .unwrap_or_else(|| match segment {
                        TextSegment::Code(_) => "[code]".to_string(),
                        TextSegment::Prose(t) => t.clone(),
                    })
            } else {
                match segment {
                    TextSegment::Code(_) => "[code]".to_string(),
                    TextSegment::Prose(t) => t.clone(),
                }
            }
        }
        Err(_) => match segment {
            TextSegment::Code(_) => "[code]".to_string(),
            TextSegment::Prose(t) => t.clone(),
        },
    }
}

fn format_for_audio(text: &str) -> String {
    use rayon::prelude::*;
    use regex::Regex;

    let api_key = match std::env::var("OPENROUTER_API_KEY") {
        Ok(key) => key,
        Err(_) => return text.to_string(), // No API key, return as-is
    };

    // Split text into code blocks and prose segments
    let code_block_re = Regex::new(r"```(?:\w+)?\n?([\s\S]*?)```").unwrap();

    let mut segments: Vec<TextSegment> = Vec::new();
    let mut last_end = 0;

    for cap in code_block_re.captures_iter(text) {
        let m = cap.get(0).unwrap();
        let code = cap.get(1).map(|c| c.as_str()).unwrap_or("");

        // Add prose before this code block
        if m.start() > last_end {
            let prose = &text[last_end..m.start()];
            if !prose.trim().is_empty() {
                segments.push(TextSegment::Prose(prose.to_string()));
            }
        }

        // Add code block
        if !code.trim().is_empty() {
            segments.push(TextSegment::Code(code.to_string()));
        }

        last_end = m.end();
    }

    // Add remaining prose after last code block
    if last_end < text.len() {
        let prose = &text[last_end..];
        if !prose.trim().is_empty() {
            segments.push(TextSegment::Prose(prose.to_string()));
        }
    }

    // If no segments (no code blocks), treat entire text as prose
    if segments.is_empty() {
        segments.push(TextSegment::Prose(text.to_string()));
    }

    // Process all segments in parallel (limit to 10 to avoid too many API calls)
    let processed: Vec<String> = segments
        .par_iter()
        .take(10)
        .map(|seg| process_segment(seg, &api_key))
        .collect();

    // Join processed segments
    let result = processed.join(" ");

    // Final cleanup: normalize whitespace
    let whitespace_re = Regex::new(r"\s+").unwrap();
    whitespace_re.replace_all(&result, " ").trim().to_string()
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
    use portable_pty::{CommandBuilder, PtySize, native_pty_system};
    use std::io::Write;

    let lang = if config.language_check {
        detect_language(text).unwrap_or_else(|| config.language.clone())
    } else {
        config.language.clone()
    };

    let bin_name = match config.provider.as_str() {
        "deepgram" => "deepgram-tts",
        "elevenlabs" => "elevenlabs",
        "unrealspeech" => "unrealspeech",
        "cartesia" => "cartesia",
        other => anyhow::bail!("Unknown provider: {}", other),
    };

    let mut cmd = CommandBuilder::new(bin_name);

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
        "deepgram" => {
            // Deepgram uses SOX tempo for pitch-correct speed (0.5-2.0)
            if config.speed != 1.0 {
                let dg_speed = config.speed.clamp(0.5, 2.0);
                cmd.args(["--speed", &dg_speed.to_string()]);
            }
        }
        _ => {}
    }

    // Create PTY so the TTS tool thinks it's connected to a terminal and plays audio
    let pty_system = native_pty_system();
    let pair = pty_system.openpty(PtySize {
        rows: 24,
        cols: 80,
        pixel_width: 0,
        pixel_height: 0,
    }).context("Failed to open PTY")?;

    let mut child = pair.slave.spawn_command(cmd)
        .context("Failed to spawn TTS process")?;

    // Write text to PTY master (stdin of child)
    let mut writer = pair.master.take_writer()
        .context("Failed to get PTY writer")?;
    writer.write_all(text.as_bytes())?;
    drop(writer);  // Close stdin

    // Wait for child to finish
    let _status = child.wait()
        .context("Failed to wait for TTS process")?;

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
                    "deepgram" | "elevenlabs" | "unrealspeech" | "cartesia" => {
                        config.provider = name.clone();
                        save_config(&config)?;
                        println!("Provider set to: {}", name);
                    }
                    _ => {
                        eprintln!("Unknown provider: {}", name);
                        eprintln!("Valid providers: deepgram, elevenlabs, unrealspeech, cartesia");
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

                    // Deduplication: hash content to avoid re-speaking same text
                    use std::collections::hash_map::DefaultHasher;
                    use std::hash::{Hash, Hasher};
                    let mut hasher = DefaultHasher::new();
                    text_to_speak.hash(&mut hasher);
                    let new_hash = hasher.finish().to_string();

                    let hash_file = "/tmp/claude-tts-last-hash";
                    let last_hash = fs::read_to_string(hash_file).unwrap_or_default();

                    // Only speak if content is different from last time
                    if new_hash != last_hash {
                        // Kill previous TTS only when we have new content
                        if config.interrupt {
                            kill_previous_tts();
                        }

                        // Update hash
                        let _ = fs::write(hash_file, &new_hash);

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
    }

    Ok(())
}
