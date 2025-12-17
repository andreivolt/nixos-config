use anyhow::{Context, Result};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use pulldown_cmark::{Event, Parser as MarkdownParser, Tag};
use regex::Regex;
use rodio::{buffer::SamplesBuffer, OutputStream, Sink};
use serde::{Deserialize, Serialize};
use std::env;
use std::io::{self, Read, Write};
use std::sync::{Arc, Mutex};
use textwrap::Options;
use tokio::sync::mpsc;
use futures::StreamExt;

const DEFAULT_VOICE_ID: &str = "f786b574-daa5-4673-aa0c-cbe3e8534c02"; // Katie - Friendly Fixer
const DEFAULT_MODEL_ID: &str = "sonic-3";
const API_VERSION: &str = "2025-04-16";

#[derive(Parser, Debug)]
#[command(author, version, about = "Convert text to speech using Cartesia TTS", long_about = None)]
struct Args {
    /// Text to convert to speech (or read from stdin)
    text: Option<String>,

    /// Output audio file (default: play directly)
    #[arg(short, long)]
    output: Option<String>,

    /// Voice ID
    #[arg(short, long, default_value = DEFAULT_VOICE_ID)]
    voice: String,

    /// Model ID
    #[arg(short, long, default_value = DEFAULT_MODEL_ID)]
    model: String,

    /// Speech speed (0.6 to 1.5, default 1.0)
    #[arg(short, long, default_value = "1.0")]
    speed: f32,

    /// Volume (0.5 to 2.0, default 1.0)
    #[arg(long, default_value = "1.0")]
    volume: f32,

    /// Emotion: neutral, angry, excited, content, sad, scared
    #[arg(short, long, default_value = "neutral")]
    emotion: String,

    /// Audio format: wav-s16 (default), wav-f32, mp3, raw-s16, raw-f32
    #[arg(short, long, default_value = "wav-s16")]
    format: String,

    /// List available voices
    #[arg(long)]
    list_voices: bool,

    /// Don't clean markdown formatting
    #[arg(long)]
    no_clean: bool,
}

#[derive(Serialize)]
struct Voice {
    mode: String,
    id: String,
}

#[derive(Serialize, Clone)]
struct OutputFormat {
    container: String,
    encoding: String,
    sample_rate: u32,
}

fn parse_format(format: &str) -> OutputFormat {
    match format {
        "wav-f32" => OutputFormat {
            container: "wav".to_string(),
            encoding: "pcm_f32le".to_string(),
            sample_rate: 44100,
        },
        "mp3" => OutputFormat {
            container: "mp3".to_string(),
            encoding: "mp3".to_string(),
            sample_rate: 44100,
        },
        "raw-s16" => OutputFormat {
            container: "raw".to_string(),
            encoding: "pcm_s16le".to_string(),
            sample_rate: 44100,
        },
        "raw-f32" => OutputFormat {
            container: "raw".to_string(),
            encoding: "pcm_f32le".to_string(),
            sample_rate: 44100,
        },
        _ => OutputFormat { // wav-s16 default
            container: "wav".to_string(),
            encoding: "pcm_s16le".to_string(),
            sample_rate: 44100,
        },
    }
}

#[derive(Serialize, Clone)]
struct GenerationConfig {
    speed: f32,
    volume: f32,
    emotion: String,
}

#[derive(Clone)]
struct TtsConfig {
    voice_id: String,
    model_id: String,
    language: String,
    output_format: OutputFormat,
    generation_config: GenerationConfig,
}

#[derive(Serialize)]
struct TtsRequest {
    model_id: String,
    transcript: String,
    voice: Voice,
    output_format: OutputFormat,
    language: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    generation_config: Option<GenerationConfig>,
}

#[derive(Deserialize)]
struct VoicesResponse {
    data: Vec<VoiceInfo>,
}

#[derive(Deserialize)]
struct VoiceInfo {
    id: String,
    name: String,
    language: String,
}

#[derive(Deserialize)]
struct SseChunk {
    data: Option<String>,
    done: Option<bool>,
}

fn split_text(text: &str, max_length: usize) -> Vec<String> {
    if text.len() <= max_length {
        return vec![text.to_string()];
    }

    let options = Options::new(max_length).break_words(false);
    let sentence_regex = Regex::new(r"[.!?]\s+").unwrap();
    let sentences: Vec<&str> = sentence_regex.split(text).collect();

    let mut chunks = Vec::new();
    let mut current_text = String::new();

    for sentence in sentences {
        let test_text = if current_text.is_empty() {
            sentence.to_string()
        } else {
            format!("{} {}", current_text, sentence)
        };

        if test_text.len() <= max_length {
            current_text = test_text;
        } else {
            if !current_text.is_empty() {
                chunks.push(current_text.clone());
                current_text.clear();
            }

            if sentence.len() > max_length {
                let wrapped = textwrap::wrap(sentence, &options);
                chunks.extend(wrapped.into_iter().map(|s| s.to_string()));
            } else {
                current_text = sentence.to_string();
            }
        }
    }

    if !current_text.is_empty() {
        chunks.push(current_text);
    }

    chunks
}

fn clean_markdown(text: &str) -> String {
    let parser = MarkdownParser::new(text);
    let mut output = String::new();
    let mut in_code_block = false;

    for event in parser {
        match event {
            Event::Start(Tag::CodeBlock(_)) => in_code_block = true,
            Event::End(Tag::CodeBlock(_)) => {
                in_code_block = false;
                output.push(' ');
            }
            Event::Code(text) => output.push_str(&text),
            Event::Text(text) => {
                if !in_code_block {
                    output.push_str(&text);
                }
            }
            Event::SoftBreak | Event::HardBreak => {
                if !in_code_block {
                    output.push(' ');
                }
            }
            Event::Start(Tag::Heading(_, _, _)) => {}
            Event::End(Tag::Heading(_, _, _)) => output.push(' '),
            _ => {}
        }
    }

    let whitespace_regex = Regex::new(r"\s{2,}").unwrap();
    whitespace_regex.replace_all(&output, " ").trim().to_string()
}

async fn fetch_voices(api_key: &str) -> Result<Vec<VoiceInfo>> {
    let client = reqwest::Client::new();
    let response = client
        .get("https://api.cartesia.ai/voices")
        .header("X-API-Key", api_key)
        .header("Cartesia-Version", API_VERSION)
        .send()
        .await?;

    if !response.status().is_success() {
        let error = response.text().await?;
        anyhow::bail!("Failed to fetch voices: {}", error);
    }

    let response: VoicesResponse = response.json().await?;
    Ok(response.data)
}

async fn list_voices(api_key: &str) -> Result<()> {
    let voices = fetch_voices(api_key).await?;
    println!("Available voices:");
    for voice in voices {
        println!("  {} - {} ({})", voice.id, voice.name, voice.language);
    }
    Ok(())
}

fn get_voice_language<'a>(voices: &'a [VoiceInfo], voice_id: &str) -> Option<&'a str> {
    voices.iter().find(|v| v.id == voice_id).map(|v| v.language.as_str())
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let api_key = env::var("CARTESIA_API_KEY")
        .context("CARTESIA_API_KEY environment variable not set")?;

    if args.list_voices {
        return list_voices(&api_key).await;
    }

    let text = if let Some(text) = args.text {
        text
    } else {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer.trim().to_string()
    };

    anyhow::ensure!(!text.is_empty(), "No text provided");

    let text = if args.no_clean {
        text
    } else {
        clean_markdown(&text)
    };

    // Cartesia supports longer text, but chunking still helps for streaming
    let chunks = split_text(&text, 4000);

    let is_piped = !atty::is(atty::Stream::Stdout);

    let spinner = if !is_piped && args.output.is_none() {
        let pb = ProgressBar::new_spinner();
        pb.set_style(
            ProgressStyle::default_spinner()
                .template("{spinner:.green} {msg}")
                .unwrap(),
        );
        pb.set_message("Processing...");
        pb.enable_steady_tick(std::time::Duration::from_millis(100));
        Some(pb)
    } else {
        None
    };

    let client = reqwest::Client::new();

    // Fetch voices to get the language for the selected voice
    let voices = fetch_voices(&api_key).await?;
    let language = get_voice_language(&voices, &args.voice)
        .unwrap_or("en")
        .to_string();

    let config = TtsConfig {
        voice_id: args.voice.clone(),
        model_id: args.model.clone(),
        language,
        output_format: parse_format(&args.format),
        generation_config: GenerationConfig {
            speed: args.speed,
            volume: args.volume,
            emotion: args.emotion.clone(),
        },
    };

    let result = if let Some(output_path) = args.output {
        process_chunks_for_file(&chunks, &client, &api_key, &config, &output_path).await
    } else if is_piped {
        process_chunks_for_stdout(&chunks, &client, &api_key, &config).await
    } else {
        process_chunks_streaming(&chunks, &client, &api_key, &config).await
    };

    if let Some(pb) = spinner {
        pb.finish_and_clear();
    }

    result
}

async fn make_request(
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
    text: &str,
) -> Result<Vec<u8>> {
    let request = TtsRequest {
        model_id: config.model_id.clone(),
        transcript: text.to_string(),
        voice: Voice {
            mode: "id".to_string(),
            id: config.voice_id.clone(),
        },
        output_format: config.output_format.clone(),
        language: config.language.clone(),
        generation_config: Some(config.generation_config.clone()),
    };

    let response = client
        .post("https://api.cartesia.ai/tts/bytes")
        .header("X-API-Key", api_key)
        .header("Cartesia-Version", API_VERSION)
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await?;

    if !response.status().is_success() {
        let status = response.status();
        let error = response.text().await?;
        anyhow::bail!("API error ({}): {}", status, error);
    }

    let mut audio_data = Vec::new();
    let mut stream = response.bytes_stream();
    while let Some(chunk) = stream.next().await {
        audio_data.extend_from_slice(&chunk?);
    }

    Ok(audio_data)
}

async fn process_chunks_for_file(
    chunks: &[String],
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
    output_path: &str,
) -> Result<()> {
    let audio_chunks = process_all_chunks(chunks, client, api_key, config).await?;
    let combined_audio: Vec<u8> = audio_chunks.into_iter().flatten().collect();
    std::fs::write(output_path, &combined_audio)?;
    Ok(())
}

async fn process_chunks_for_stdout(
    chunks: &[String],
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
) -> Result<()> {
    let audio_chunks = process_all_chunks(chunks, client, api_key, config).await?;
    let combined_audio: Vec<u8> = audio_chunks.into_iter().flatten().collect();
    io::stdout().write_all(&combined_audio)?;
    io::stdout().flush()?;
    Ok(())
}

async fn process_chunks_streaming(
    chunks: &[String],
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
) -> Result<()> {
    let (_stream, stream_handle) =
        OutputStream::try_default().context("Failed to get default audio output device")?;

    let sink = Arc::new(Mutex::new(
        Sink::try_new(&stream_handle).context("Failed to create audio sink")?,
    ));

    let (tx, mut rx) = mpsc::channel::<Vec<i16>>(100);

    let sink_clone = sink.clone();
    let playback_handle = tokio::spawn(async move {
        while let Some(samples) = rx.recv().await {
            let buffer = SamplesBuffer::new(1, 44100, samples);
            if let Ok(sink_guard) = sink_clone.lock() {
                sink_guard.append(buffer);
            }
        }
    });

    for chunk_text in chunks {
        if let Err(e) = stream_sse(client, api_key, config, chunk_text, &tx).await {
            eprintln!("Error streaming chunk: {}", e);
        }
    }

    drop(tx);

    let _ = playback_handle.await;
    if let Ok(sink_guard) = sink.lock() {
        sink_guard.sleep_until_end();
    }

    Ok(())
}

async fn stream_sse(
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
    text: &str,
    tx: &mpsc::Sender<Vec<i16>>,
) -> Result<()> {
    // SSE streaming requires raw format for real-time playback
    let request = TtsRequest {
        model_id: config.model_id.clone(),
        transcript: text.to_string(),
        voice: Voice {
            mode: "id".to_string(),
            id: config.voice_id.clone(),
        },
        output_format: OutputFormat {
            container: "raw".to_string(),
            encoding: "pcm_s16le".to_string(),
            sample_rate: 44100,
        },
        language: config.language.clone(),
        generation_config: Some(config.generation_config.clone()),
    };

    let response = client
        .post("https://api.cartesia.ai/tts/sse")
        .header("X-API-Key", api_key)
        .header("Cartesia-Version", API_VERSION)
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await?;

    if !response.status().is_success() {
        let status = response.status();
        let error = response.text().await?;
        anyhow::bail!("API error ({}): {}", status, error);
    }

    let mut stream = response.bytes_stream();
    let mut buffer = String::new();

    while let Some(chunk) = stream.next().await {
        let bytes = chunk?;
        buffer.push_str(&String::from_utf8_lossy(&bytes));

        // Process complete SSE events
        while let Some(pos) = buffer.find("\n\n") {
            let event = buffer[..pos].to_string();
            buffer = buffer[pos + 2..].to_string();

            for line in event.lines() {
                if let Some(data) = line.strip_prefix("data: ") {
                    if let Ok(chunk) = serde_json::from_str::<SseChunk>(data) {
                        if let Some(audio_data) = chunk.data {
                            if let Ok(decoded) = BASE64.decode(&audio_data) {
                                // Convert bytes to i16 samples
                                let samples: Vec<i16> = decoded
                                    .chunks_exact(2)
                                    .map(|chunk| i16::from_le_bytes([chunk[0], chunk[1]]))
                                    .collect();
                                if !samples.is_empty() {
                                    let _ = tx.send(samples).await;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

async fn process_all_chunks(
    chunks: &[String],
    client: &reqwest::Client,
    api_key: &str,
    config: &TtsConfig,
) -> Result<Vec<Vec<u8>>> {
    let mut results = Vec::new();
    for chunk in chunks {
        let audio = make_request(client, api_key, config, chunk).await?;
        results.push(audio);
    }
    Ok(results)
}
