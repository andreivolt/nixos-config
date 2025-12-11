
use anyhow::{anyhow, Result};
use chrono::{DateTime, Duration, Local};
use clap::{Parser, ValueEnum};
use comfy_table::{modifiers::UTF8_ROUND_CORNERS, presets::UTF8_FULL, Table};
use dirs::cache_dir;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{self, Cursor, Read, Write};
use tungstenite::{connect, Message};
use is_terminal::IsTerminal;
use rodio::{Decoder, OutputStream, Sink};
use derive_more::Display;
use std::path::{Path, PathBuf};

const DEFAULT_VOICE: &str = "en-US-AriaNeural";
const DEFAULT_LOCALE: &str = "en-US";
const DEFAULT_FORMAT: &str = "audio-48khz-192kbitrate-mono-mp3";
const MAX_PLAIN_TEXT_S0: usize = 20000; // Standard tier

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Voice {
    #[serde(rename = "Name")]
    name: String,
    #[serde(rename = "DisplayName")]
    display_name: String,
    #[serde(rename = "LocalName")]
    local_name: String,
    #[serde(rename = "ShortName")]
    short_name: String,
    #[serde(rename = "Gender")]
    gender: String,
    #[serde(rename = "Locale")]
    locale: String,
    #[serde(rename = "LocaleName")]
    locale_name: String,
    #[serde(rename = "SampleRateHertz")]
    sample_rate_hertz: String,
    #[serde(rename = "VoiceType")]
    voice_type: String,
    #[serde(rename = "Status")]
    status: String,
    #[serde(rename = "StyleList", default)]
    style_list: Vec<String>,
    #[serde(rename = "RolePlayList", default)]
    role_play_list: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct TokenCache {
    token: String,
    expiry: DateTime<Local>,
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
#[command(about = "Azure Speech Service Text-to-Speech CLI with advanced SSML support")]
struct Args {
    /// Text to synthesize (or read from stdin)
    text: Vec<String>,

    /// Voice name
    #[arg(short, long, default_value = DEFAULT_VOICE)]
    voice: String,

    /// Voice locale
    #[arg(short, long, default_value = DEFAULT_LOCALE)]
    locale: String,

    /// Language code (shorthand for locale, e.g., 'fr' for French)
    #[arg(long)]
    lang: Option<String>,

    /// Speaking rate (e.g., slow, medium, fast, +20%, -10%)
    #[arg(short, long)]
    rate: Option<String>,

    /// Voice pitch (e.g., low, medium, high, +2st, -50Hz)
    #[arg(short, long)]
    pitch: Option<String>,

    /// Voice volume (e.g., silent, soft, medium, loud, +6dB)
    #[arg(long)]
    volume: Option<String>,

    /// Speaking style (e.g., cheerful, sad, angry, excited)
    #[arg(short, long)]
    style: Option<String>,

    /// Style intensity (0.01-2.0, default varies by style)
    #[arg(long)]
    style_degree: Option<String>,

    /// Role-play (e.g., Girl, Boy, YoungAdultFemale, OlderAdultMale)
    #[arg(long)]
    role: Option<String>,

    /// Audio output format
    #[arg(long, default_value = DEFAULT_FORMAT)]
    format: String,

    /// Audio quality preset (overrides --format)
    #[arg(long, value_enum)]
    quality: Option<AudioQuality>,

    /// Audio tempo adjustment
    #[arg(short, long, default_value = "1.0")]
    tempo: f32,

    /// Save audio to file
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Max characters per chunk
    #[arg(long)]
    chunk_size: Option<usize>,

    /// List available voices
    #[arg(long)]
    list_voices: bool,

    /// Show neural voices only
    #[arg(long)]
    neural_only: bool,

    /// Show voices with styles
    #[arg(long)]
    styles_only: bool,

    /// Filter by gender
    #[arg(long, value_enum)]
    gender: Option<Gender>,

    /// Voice type preference
    #[arg(long, value_enum, default_value = "neural")]
    voice_type: Option<VoiceType>,

    /// Show available styles in voice list
    #[arg(long)]
    show_styles: bool,

    /// Refresh cached voice list
    #[arg(long)]
    refresh_voices: bool,

    /// List available audio formats
    #[arg(long)]
    list_formats: bool,

    /// Test mode - generates silence for testing audio playback
    #[arg(long, hide = true)]
    test_mode: bool,
}

#[derive(Debug, Clone, Copy, ValueEnum, Display)]
enum AudioQuality {
    #[display("high")]
    High,
    #[display("standard")]
    Standard,
    #[display("low")]
    Low,
}

#[derive(Debug, Clone, Copy, ValueEnum, Display)]
enum Gender {
    #[display("Male")]
    Male,
    #[display("Female")]
    Female,
}

#[derive(Debug, Clone, Copy, ValueEnum, Display)]
enum VoiceType {
    #[display("Neural")]
    Neural,
    #[display("Standard")]
    Standard,
    #[display("Studio")]
    Studio,
}

struct AzureSpeechSynthesizer {
    region: String,
    key: String,
    base_url: String,
    token_url: String,
    voices_cache: PathBuf,
    token_cache: PathBuf,
    agent: ureq::Agent,
}

impl AzureSpeechSynthesizer {
    fn new(region: String, key: String) -> Result<Self> {
        let cache_dir = cache_dir()
            .ok_or_else(|| anyhow!("Failed to get cache directory"))?
            .join("azure-speech");
        fs::create_dir_all(&cache_dir)?;

        let voices_cache = cache_dir.join("voices.json");
        let token_cache = cache_dir.join("token.json");

        Ok(Self {
            base_url: format!("https://{}.tts.speech.microsoft.com", region),
            token_url: format!(
                "https://{}.api.cognitive.microsoft.com/sts/v1.0/issueToken",
                region
            ),
            region,
            key,
            voices_cache,
            token_cache,
            agent: ureq::Agent::new(),
        })
    }

    fn get_access_token(&self) -> Result<String> {
        // Check cached token
        if self.token_cache.exists() {
            if let Ok(content) = fs::read_to_string(&self.token_cache) {
                if let Ok(cache) = serde_json::from_str::<TokenCache>(&content) {
                    if cache.expiry > Local::now() {
                        return Ok(cache.token);
                    }
                }
            }
        }

        // Fetch new token
        let response = self
            .agent
            .post(&self.token_url)
            .set("Content-Type", "application/x-www-form-urlencoded")
            .set("Content-Length", "0")
            .set("Ocp-Apim-Subscription-Key", &self.key)
            .call()?;

        if response.status() != 200 {
            return Err(anyhow!(
                "Failed to get access token: {}",
                response.status()
            ));
        }

        let token = response.into_string()?;
        let expiry = Local::now() + Duration::minutes(9); // Token valid for 10min, cache for 9

        let cache = TokenCache { token: token.clone(), expiry };
        fs::write(&self.token_cache, serde_json::to_string(&cache)?)?;

        Ok(token)
    }

    fn get_voices(&self, force_refresh: bool) -> Result<Vec<Voice>> {
        // Check cached voices
        if !force_refresh && self.voices_cache.exists() {
            if let Ok(content) = fs::read_to_string(&self.voices_cache) {
                if let Ok(voices) = serde_json::from_str::<Vec<Voice>>(&content) {
                    return Ok(voices);
                }
            }
        }

        // Fetch voices
        let response = self
            .agent
            .get(&format!(
                "{}/cognitiveservices/voices/list",
                self.base_url
            ))
            .set("Ocp-Apim-Subscription-Key", &self.key)
            .call()?;

        if response.status() != 200 {
            return Err(anyhow!("Failed to get voices: {}", response.status()));
        }

        let voices: Vec<Voice> = response.into_json()?;
        fs::write(
            &self.voices_cache,
            serde_json::to_string_pretty(&voices)?,
        )?;

        Ok(voices)
    }

    fn filter_voices(
        &self,
        voices: Vec<Voice>,
        locale: Option<&str>,
        gender: Option<Gender>,
        voice_type: Option<VoiceType>,
        neural_only: bool,
        styles_only: bool,
    ) -> Vec<Voice> {
        voices
            .into_iter()
            .filter(|v| {
                if let Some(loc) = locale {
                    if !v.locale.to_lowercase().starts_with(&loc.to_lowercase()) {
                        return false;
                    }
                }
                if let Some(g) = gender {
                    if v.gender != g.to_string() {
                        return false;
                    }
                }
                if let Some(vt) = voice_type {
                    if !v.voice_type.contains(&vt.to_string()) {
                        return false;
                    }
                }
                if neural_only && !v.voice_type.contains("Neural") {
                    return false;
                }
                if styles_only && v.style_list.is_empty() {
                    return false;
                }
                true
            })
            .collect()
    }

    fn expand_language_code(lang_code: &str) -> String {
        match lang_code.to_lowercase().as_str() {
            "en" => "en-US".to_string(),
            "fr" => "fr-FR".to_string(),
            "es" => "es-ES".to_string(),
            "de" => "de-DE".to_string(),
            "it" => "it-IT".to_string(),
            "pt" => "pt-BR".to_string(),
            "ru" => "ru-RU".to_string(),
            "ja" => "ja-JP".to_string(),
            "ko" => "ko-KR".to_string(),
            "zh" => "zh-CN".to_string(),
            "ar" => "ar-SA".to_string(),
            "hi" => "hi-IN".to_string(),
            "nl" => "nl-NL".to_string(),
            "sv" => "sv-SE".to_string(),
            "da" => "da-DK".to_string(),
            "no" => "nb-NO".to_string(),
            "fi" => "fi-FI".to_string(),
            "pl" => "pl-PL".to_string(),
            "tr" => "tr-TR".to_string(),
            "th" => "th-TH".to_string(),
            "vi" => "vi-VN".to_string(),
            _ => lang_code.to_string(), // Return as-is if not recognized
        }
    }

    fn select_voice(
        &self,
        voices: &[Voice],
        target_locale: &str,
        gender: Option<Gender>,
        voice_type: Option<VoiceType>,
    ) -> Option<String> {
        let mut candidates: Vec<&Voice> = voices
            .iter()
            .filter(|v| v.locale.to_lowercase().starts_with(&target_locale.to_lowercase()))
            .collect();

        // Apply gender filter
        if let Some(g) = gender {
            candidates.retain(|v| v.gender == g.to_string());
        }

        // Apply voice type filter
        if let Some(vt) = voice_type {
            candidates.retain(|v| v.voice_type.contains(&vt.to_string()));
        }

        // Preference order: Neural > Studio > Standard
        for preference in ["Neural", "Studio", "Standard"] {
            if let Some(voice) = candidates.iter().find(|v| v.voice_type.contains(preference)) {
                return Some(voice.name.clone());
            }
        }

        // Fallback to any voice for the locale
        candidates.first().map(|v| v.name.clone())
    }

    fn build_ssml(
        &self,
        text: &str,
        voice_name: &str,
        rate: Option<&str>,
        pitch: Option<&str>,
        volume: Option<&str>,
        style: Option<&str>,
        style_degree: Option<&str>,
        role: Option<&str>,
        locale: &str,
    ) -> String {
        // Handle pre-existing SSML
        if text.trim().starts_with("<speak") {
            return text.to_string();
        }

        let mut content = text.to_string();

        // Build prosody attributes
        let mut prosody_attrs = Vec::new();
        if let Some(r) = rate {
            prosody_attrs.push(format!(r#"rate="{}""#, r));
        }
        if let Some(p) = pitch {
            prosody_attrs.push(format!(r#"pitch="{}""#, p));
        }
        if let Some(v) = volume {
            prosody_attrs.push(format!(r#"volume="{}""#, v));
        }

        // Build expression attributes
        let mut express_attrs = Vec::new();
        if let Some(s) = style {
            express_attrs.push(format!(r#"style="{}""#, s));
        }
        if let Some(sd) = style_degree {
            express_attrs.push(format!(r#"styledegree="{}""#, sd));
        }
        if let Some(r) = role {
            express_attrs.push(format!(r#"role="{}""#, r));
        }

        // Wrap in prosody if needed
        if !prosody_attrs.is_empty() {
            let prosody_str = prosody_attrs.join(" ");
            content = format!("<prosody {}>{}</prosody>", prosody_str, content);
        }

        // Wrap in expression if needed
        if !express_attrs.is_empty() {
            let express_str = express_attrs.join(" ");
            content = format!(
                "<mstts:express-as {}>{}</mstts:express-as>",
                express_str, content
            );
        }

        // Wrap in voice
        content = format!(r#"<voice name="{}">{}</voice>"#, voice_name, content);

        // Complete SSML document
        format!(
            r#"<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis"
xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="{}">
{}
</speak>"#,
            locale, content
        )
    }

    fn chunk_text(&self, text: &str, max_chars: Option<usize>) -> Vec<String> {
        let max_chars = max_chars.unwrap_or(MAX_PLAIN_TEXT_S0);

        // If text is short enough, return as single chunk
        if text.len() <= max_chars {
            return vec![text.to_string()];
        }

        let mut chunks = Vec::new();
        let mut current_chunk = String::new();

        // Split on sentence boundaries
        let sentence_re = Regex::new(r"(?<=[.!?])\s+").unwrap();
        let sentences: Vec<&str> = sentence_re.split(text).collect();

        for sentence in sentences {
            // If single sentence exceeds limit, split further
            if sentence.len() > max_chars {
                // Split on clause boundaries
                let clause_re = Regex::new(r"(?<=[,;:])\s+").unwrap();
                let clauses: Vec<&str> = clause_re.split(sentence).collect();

                for clause in clauses {
                    if current_chunk.len() + clause.len() + 1 > max_chars {
                        if !current_chunk.is_empty() {
                            chunks.push(current_chunk.trim().to_string());
                            current_chunk.clear();
                        }
                        // Handle clause that's still too long
                        if clause.len() > max_chars {
                            let mut remaining = clause;
                            while remaining.len() > max_chars {
                                chunks.push(remaining[..max_chars].trim().to_string());
                                remaining = &remaining[max_chars..];
                            }
                            current_chunk = remaining.to_string();
                        } else {
                            current_chunk = clause.to_string();
                        }
                    } else {
                        if !current_chunk.is_empty() {
                            current_chunk.push(' ');
                        }
                        current_chunk.push_str(clause);
                    }
                }
            } else {
                // Normal sentence processing
                if current_chunk.len() + sentence.len() + 1 > max_chars {
                    if !current_chunk.is_empty() {
                        chunks.push(current_chunk.trim().to_string());
                        current_chunk = sentence.to_string();
                    }
                } else {
                    if !current_chunk.is_empty() {
                        current_chunk.push(' ');
                    }
                    current_chunk.push_str(sentence);
                }
            }
        }

        if !current_chunk.is_empty() {
            chunks.push(current_chunk.trim().to_string());
        }

        chunks
    }

    fn synthesize_rest(
        &self,
        ssml: &str,
        output_format: &str,
        output_file: Option<&Path>,
        play_audio: bool,
        tempo: Option<f32>,
    ) -> Result<Vec<u8>> {
        let token = self.get_access_token()?;

        let response = self
            .agent
            .post(&format!("{}/cognitiveservices/v1", self.base_url))
            .set("Content-Type", "application/ssml+xml")
            .set("X-Microsoft-OutputFormat", output_format)
            .set("Authorization", &format!("Bearer {}", token))
            .set("User-Agent", "azure-speech-cli")
            .send_string(ssml)?;

        if response.status() != 200 {
            return Err(anyhow!(
                "Error {}: {}",
                response.status(),
                response.into_string().unwrap_or_else(|_| "Unknown error".to_string())
            ));
        }

        let mut audio_data = Vec::new();
        response.into_reader().read_to_end(&mut audio_data)?;


        if let Some(path) = output_file {
            let final_data = if output_format.starts_with("raw-") {
                create_wav_from_pcm(&audio_data, 48000, 1, 16)?
            } else {
                audio_data.clone()
            };
            fs::write(path, &final_data)?;
            println!("Audio saved to: {}", path.display());
        }

        if play_audio && output_file.is_none() {
            play_audio_data(&audio_data, output_format, tempo)?;
        }

        Ok(audio_data)
    }

    fn synthesize_streaming(
        &self,
        text: &str,
        voice_name: &str,
        output_format: &str,
        output_file: Option<&Path>,
        play_audio: bool,
        tempo: Option<f32>,
        rate: Option<&str>,
        pitch: Option<&str>,
        volume: Option<&str>,
        style: Option<&str>,
        style_degree: Option<&str>,
        role: Option<&str>,
        locale: &str,
        chunk_size: Option<usize>,
    ) -> Result<Vec<Vec<u8>>> {
        let chunks = self.chunk_text(text, chunk_size);
        let mut audio_chunks = Vec::new();

        for (_i, chunk) in chunks.iter().enumerate() {
            // Build SSML for chunk
            let ssml = self.build_ssml(
                chunk,
                voice_name,
                rate,
                pitch,
                volume,
                style,
                style_degree,
                role,
                locale,
            );

            // Create WebSocket connection
            let token = self.get_access_token()?;
            let ws_url = format!(
                "wss://{}.tts.speech.microsoft.com/cognitiveservices/websocket/v1?Authorization=Bearer%20{}",
                self.region, token
            );

            let (mut ws_stream, _) = connect(&ws_url)?;

            // Send configuration
            let config = serde_json::json!({
                "context": {
                    "synthesis": {
                        "audio": {
                            "outputFormat": output_format
                        }
                    }
                }
            });

            let config_msg = format!(
                "Path: speech.config\r\nX-RequestId: {}\r\nX-Timestamp: {}\r\nContent-Type: application/json\r\n\r\n{}",
                uuid::Uuid::new_v4(),
                chrono::Utc::now().to_rfc3339(),
                config
            );

            ws_stream.send(Message::Text(config_msg))?;

            // Send SSML
            let ssml_msg = format!(
                "Path: ssml\r\nX-RequestId: {}\r\nX-Timestamp: {}\r\nContent-Type: application/ssml+xml\r\n\r\n{}",
                uuid::Uuid::new_v4(),
                chrono::Utc::now().to_rfc3339(),
                ssml
            );

            ws_stream.send(Message::Text(ssml_msg))?;

            // Receive audio data
            let mut chunk_audio = Vec::new();
            loop {
                let msg = ws_stream.read()?;
                match msg {
                    Message::Binary(data) => {
                        // Azure WebSocket format: [length_high, length_low, ...header..., audio_data]
                        if data.len() >= 2 {
                            let header_length = ((data[0] as u16) << 8) | (data[1] as u16);
                            let audio_start = 2 + header_length as usize;
                            if audio_start < data.len() {
                                chunk_audio.extend_from_slice(&data[audio_start..]);
                            }
                        }
                    }
                    Message::Text(text) => {
                        if text.contains("Path:turn.end") {
                            break;
                        }
                    }
                    Message::Close(_) => break,
                    _ => {}
                }
            }

            if !chunk_audio.is_empty() {
                audio_chunks.push(chunk_audio.clone());

                if play_audio && output_file.is_none() {
                    // Play immediately for streaming effect
                    play_audio_data(&chunk_audio, output_format, tempo)?;
                }
            }
        }

        // If saving to file, concatenate all chunks
        if let Some(path) = output_file {
            if audio_chunks.len() == 1 {
                // Single chunk, save directly
                fs::write(path, &audio_chunks[0])?;
                println!("Audio saved to: {}", path.display());
            } else if audio_chunks.len() > 1 {
                // Multiple chunks, concatenate
                concatenate_audio_chunks(&audio_chunks, path, output_format)?;
            }
        } else if !play_audio {
            // Output to stdout if not playing and not saving to file
            let mut stdout = io::stdout();
            for chunk in &audio_chunks {
                stdout.write_all(chunk)?;
                stdout.flush()?;
            }
        }

        Ok(audio_chunks)
    }
}

fn play_audio_data(audio_data: &[u8], format: &str, tempo: Option<f32>) -> Result<()> {
    // Get the default output device
    let (_stream, stream_handle) = OutputStream::try_default()
        .map_err(|e| anyhow!("Failed to get audio output device: {}", e))?;

    // Create a sink for audio playback
    let sink = Sink::try_new(&stream_handle)
        .map_err(|e| anyhow!("Failed to create audio sink: {}", e))?;

    // Adjust playback speed if tempo is specified
    if let Some(t) = tempo {
        sink.set_speed(t);
    }

    // Check if this is raw PCM data that needs WAV header
    let audio_with_header = if format.starts_with("raw-") {
        create_wav_from_pcm(audio_data, 48000, 1, 16)?
    } else {
        audio_data.to_vec()
    };

    // Create a cursor from audio data and decode it
    let cursor = Cursor::new(audio_with_header);
    let source = Decoder::new(cursor)
        .map_err(|e| anyhow!("Failed to decode audio: {}", e))?;

    // Play the audio
    sink.append(source);
    sink.sleep_until_end();

    Ok(())
}


fn create_wav_from_pcm(pcm_data: &[u8], sample_rate: u32, channels: u16, bits_per_sample: u16) -> Result<Vec<u8>> {
    let mut wav_data = Vec::new();

    // WAV header
    wav_data.extend_from_slice(b"RIFF");
    let file_size = 36 + pcm_data.len() as u32;
    wav_data.extend_from_slice(&file_size.to_le_bytes());
    wav_data.extend_from_slice(b"WAVE");

    // Format chunk
    wav_data.extend_from_slice(b"fmt ");
    wav_data.extend_from_slice(&16u32.to_le_bytes()); // Chunk size
    wav_data.extend_from_slice(&1u16.to_le_bytes()); // Audio format (PCM)
    wav_data.extend_from_slice(&channels.to_le_bytes());
    wav_data.extend_from_slice(&sample_rate.to_le_bytes());

    let byte_rate = sample_rate * channels as u32 * bits_per_sample as u32 / 8;
    wav_data.extend_from_slice(&byte_rate.to_le_bytes());

    let block_align = channels * bits_per_sample / 8;
    wav_data.extend_from_slice(&block_align.to_le_bytes());
    wav_data.extend_from_slice(&bits_per_sample.to_le_bytes());

    // Data chunk
    wav_data.extend_from_slice(b"data");
    wav_data.extend_from_slice(&(pcm_data.len() as u32).to_le_bytes());
    wav_data.extend_from_slice(pcm_data);

    Ok(wav_data)
}


fn concatenate_audio_chunks(audio_chunks: &[Vec<u8>], output_path: &Path, format: &str) -> Result<()> {
    let combined_audio = if format.starts_with("raw-") {
        // For PCM, concatenate raw data then add WAV header
        let mut raw_combined = Vec::new();
        for chunk in audio_chunks {
            raw_combined.extend_from_slice(chunk);
        }
        create_wav_from_pcm(&raw_combined, 48000, 1, 16)?
    } else {
        // For compressed formats, simple concatenation
        let mut combined_audio = Vec::new();
        for chunk in audio_chunks {
            combined_audio.extend_from_slice(chunk);
        }
        combined_audio
    };

    fs::write(output_path, combined_audio)?;
    println!("Audio saved to: {}", output_path.display());
    Ok(())
}

fn get_audio_formats() -> std::collections::HashMap<&'static str, Vec<&'static str>> {
    let mut formats = std::collections::HashMap::new();
    formats.insert(
        "high_quality",
        vec![
            "raw-48khz-16bit-mono-pcm",
            "audio-48khz-192kbitrate-mono-mp3",
            "audio-48khz-96kbitrate-mono-mp3",
        ],
    );
    formats.insert(
        "standard",
        vec![
            "raw-24khz-16bit-mono-pcm",
            "audio-24khz-160kbitrate-mono-mp3",
            "audio-24khz-96kbitrate-mono-mp3",
        ],
    );
    formats.insert(
        "low_bandwidth",
        vec![
            "raw-16khz-16bit-mono-pcm",
            "audio-16khz-128kbitrate-mono-mp3",
            "audio-16khz-64kbitrate-mono-mp3",
        ],
    );
    formats
}

fn print_voices_table(voices: &[Voice], show_styles: bool) {
    let mut table = Table::new();
    table
        .load_preset(UTF8_FULL)
        .apply_modifier(UTF8_ROUND_CORNERS)
        .set_header(vec!["Locale", "Display Name", "Gender", "Voice Type"]);

    for voice in voices {
        let mut row = vec![
            voice.locale.clone(),
            voice.display_name.clone(),
            voice.gender.clone(),
            voice.voice_type.clone(),
        ];

        if show_styles && !voice.style_list.is_empty() {
            let styles = if voice.style_list.len() > 3 {
                format!(
                    "{}...",
                    voice.style_list[..3].join(", ")
                )
            } else {
                voice.style_list.join(", ")
            };
            row.push(styles);
            if table.column_count() == 4 {
                table.set_header(vec!["Locale", "Display Name", "Gender", "Voice Type", "Styles"]);
            }
        }

        table.add_row(row);
    }

    println!("{}", table);
}

fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let args = Args::parse();

    // Check for required environment variables
    let region = match std::env::var("AZURE_SPEECH_REGION") {
        Ok(region) => region,
        Err(_) => {
            eprintln!("Error: AZURE_SPEECH_REGION environment variable required");
            std::process::exit(1);
        }
    };
    let key = match std::env::var("AZURE_SPEECH_KEY") {
        Ok(key) => key,
        Err(_) => {
            eprintln!("Error: AZURE_SPEECH_KEY environment variable required");
            std::process::exit(1);
        }
    };

    let synthesizer = AzureSpeechSynthesizer::new(region, key)?;

    // Handle utility commands
    if args.list_formats {
        let formats = get_audio_formats();
        for (quality, format_list) in formats {
            println!("\n{}:", quality.replace('_', " ").to_uppercase());
            for fmt in format_list {
                println!("  {}", fmt);
            }
        }
        return Ok(());
    }

    if args.list_voices {
        let voices = synthesizer.get_voices(args.refresh_voices)?;
        let filtered = synthesizer.filter_voices(
            voices,
            Some(&args.locale),
            args.gender,
            args.voice_type,
            args.neural_only,
            args.styles_only,
        );
        print_voices_table(&filtered, args.show_styles);
        return Ok(());
    }

    // Get text input
    let text = if !args.text.is_empty() {
        args.text.join(" ")
    } else if !io::stdin().is_terminal() {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer
    } else {
        return Err(anyhow!("No text provided"));
    };

    // Play audio unless saving to file or stdout is not a TTY (i.e., piped)
    let should_play = args.output.is_none() && is_terminal::IsTerminal::is_terminal(&io::stdout());

    if text.trim().is_empty() {
        return Err(anyhow!("No text provided"));
    }

    // Smart voice selection
    let (selected_voice, selected_locale) = if args.lang.is_some() || args.gender.is_some() || args.voice_type.is_some() {
        // User wants smart selection
        let voices = synthesizer.get_voices(false)?;

        let target_locale = if let Some(lang) = &args.lang {
            AzureSpeechSynthesizer::expand_language_code(lang)
        } else {
            args.locale.clone()
        };

        let selected_voice = synthesizer.select_voice(
            &voices,
            &target_locale,
            args.gender,
            args.voice_type,
        ).unwrap_or_else(|| args.voice.clone());

        (selected_voice, target_locale)
    } else {
        (args.voice.clone(), args.locale.clone())
    };

    // Handle quality presets
    let output_format = if let Some(quality) = args.quality {
        let formats = get_audio_formats();
        let quality_key = format!("{}_quality", quality);
        let quality_key = match quality_key.as_str() {
            "high_quality" => "high_quality",
            "standard_quality" => "standard",
            "low_quality" => "low_bandwidth",
            _ => "standard",
        };
        formats[quality_key][0]
    } else {
        &args.format
    };

    // Build SSML
    let ssml = synthesizer.build_ssml(
        &text,
        &selected_voice,
        args.rate.as_deref(),
        args.pitch.as_deref(),
        args.volume.as_deref(),
        args.style.as_deref(),
        args.style_degree.as_deref(),
        args.role.as_deref(),
        &selected_locale,
    );


    // Always use streaming
    let use_streaming = true;
    let tempo = if args.tempo != 1.0 {
        Some(args.tempo)
    } else {
        None
    };

    if use_streaming {
        // Use streaming synthesis
        synthesizer.synthesize_streaming(
            &text,
            &selected_voice,
            output_format,
            args.output.as_deref(),
            should_play,
            tempo,
            args.rate.as_deref(),
            args.pitch.as_deref(),
            args.volume.as_deref(),
            args.style.as_deref(),
            args.style_degree.as_deref(),
            args.role.as_deref(),
            &selected_locale,
            args.chunk_size,
        )?;
    } else {
        // Use traditional REST synthesis
        synthesizer.synthesize_rest(
            &ssml,
            output_format,
            args.output.as_deref(),
            should_play,
            tempo,
        )?;
    }

    Ok(())
}