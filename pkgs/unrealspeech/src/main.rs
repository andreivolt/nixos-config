
use anyhow::{anyhow, Result};
use clap::Parser;
use futures::future::join_all;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::env;
use std::io::{self, Read, Write};
use rodio::{Decoder, OutputStream, Sink};
use std::io::Cursor;
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration};

#[derive(Parser, Clone)]
#[command(about = "Convert text to speech using UnrealSpeech API")]
struct Args {
    /// Voice ID (Scarlett, Dan, Liv, Will, Amy, etc.)
    #[arg(short = 'v', long = "voice-id", default_value = "Liv")]
    voice_id: String,

    /// Bitrate (320k, 256k, 192k, 128k, 64k, 32k)
    #[arg(short = 'b', long = "bitrate", default_value = "320k")]
    bitrate: String,

    /// Speed (-1.0 to 1.0, 0=normal)
    #[arg(short = 's', long = "speed", default_value = "0.0")]
    speed: f32,

    /// Pitch (0.5 to 1.5)
    #[arg(short = 'p', long = "pitch", default_value = "1.0")]
    pitch: f32,

    /// Codec (pcm_s16le, libmp3lame, pcm_mulaw)
    #[arg(short = 'c', long = "codec", default_value = "pcm_s16le")]
    codec: String,

    /// Temperature (0.1 to 1.0)
    #[arg(short = 't', long = "temperature", default_value = "0.25")]
    temperature: f32,

    /// Text to synthesize
    text: Vec<String>,
}

#[derive(Serialize)]
struct StreamRequest {
    #[serde(rename = "Text")]
    text: String,
    #[serde(rename = "VoiceId")]
    voice_id: String,
    #[serde(rename = "Bitrate")]
    bitrate: String,
    #[serde(rename = "Speed")]
    speed: f32,
    #[serde(rename = "Pitch")]
    pitch: f32,
    #[serde(rename = "Codec")]
    codec: String,
    #[serde(rename = "Temperature")]
    temperature: f32,
}

#[derive(Serialize)]
struct SpeechRequest {
    #[serde(rename = "Text")]
    text: String,
    #[serde(rename = "VoiceId")]
    voice_id: String,
    #[serde(rename = "Bitrate")]
    bitrate: String,
    #[serde(rename = "Speed")]
    speed: f32,
    #[serde(rename = "Pitch")]
    pitch: f32,
}

#[derive(Deserialize)]
struct SpeechResponse {
    #[serde(rename = "OutputUri")]
    output_uri: Option<String>,
}

#[derive(Clone)]
struct UnrealSpeechClient {
    client: reqwest::Client,
    api_key: String,
}

impl UnrealSpeechClient {
    fn new(api_key: String) -> Self {
        Self {
            client: reqwest::Client::new(),
            api_key,
        }
    }

    async fn stream(&self, request: &StreamRequest) -> Result<Vec<u8>> {
        let response = self
            .client
            .post("https://api.v7.unrealspeech.com/stream")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(request)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(anyhow!("API request failed: {}", response.status()));
        }

        let bytes = response.bytes().await?;
        Ok(bytes.to_vec())
    }

    async fn speech(&self, request: &SpeechRequest) -> Result<Option<String>> {
        let response = self
            .client
            .post("https://api.v7.unrealspeech.com/speech")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .header("Content-Type", "application/json")
            .json(request)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(anyhow!("API request failed: {}", response.status()));
        }

        let speech_response: SpeechResponse = response.json().await?;
        Ok(speech_response.output_uri)
    }
}

fn split_at_sentence_boundary(text: &str, max_length: usize) -> (String, String) {
    if text.len() <= max_length {
        return (text.to_string(), String::new());
    }

    let truncated = &text[..max_length];
    let last_punct = ['.', '!', '?']
        .iter()
        .map(|&c| truncated.rfind(c))
        .filter_map(|pos| pos)
        .max();

    if let Some(pos) = last_punct {
        let split_point = pos + 1;
        return (
            text[..split_point].trim().to_string(),
            text[split_point..].trim().to_string(),
        );
    }

    // Fallback to word boundary
    let words: Vec<&str> = truncated.split_whitespace().collect();
    if words.len() > 1 {
        let first_part = words[..words.len() - 1].join(" ");
        let remaining = text[first_part.len()..].trim().to_string();
        return (first_part, remaining);
    }

    (text[..max_length].to_string(), text[max_length..].to_string())
}

fn split_text_into_chunks(text: &str, max_length: usize) -> Vec<String> {
    let mut chunks = Vec::new();
    let mut current_chunk = String::new();

    let sentence_re = Regex::new(r"(?<=[.!?])\s+").unwrap();
    let sentences: Vec<&str> = sentence_re.split(text).collect();

    for sentence in sentences {
        if current_chunk.len() + sentence.len() + 1 <= max_length {
            if !current_chunk.is_empty() {
                current_chunk.push(' ');
            }
            current_chunk.push_str(sentence);
        } else {
            if !current_chunk.is_empty() {
                chunks.push(current_chunk.clone());
                current_chunk = sentence.to_string();
            } else {
                // Single sentence longer than max_length
                chunks.push(sentence.to_string());
            }
        }
    }

    if !current_chunk.is_empty() {
        chunks.push(current_chunk);
    }

    chunks
}

async fn play_audio_data(audio_data: &[u8]) -> Result<()> {
    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    let cursor = Cursor::new(audio_data.to_vec());
    let source = Decoder::new(cursor)?;

    sink.append(source);
    sink.sleep_until_end();

    Ok(())
}

async fn play_audio_url(url: &str) -> Result<()> {
    let response = reqwest::get(url).await?;
    let audio_data = response.bytes().await?;

    play_audio_data(&audio_data).await
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let api_key = env::var("UNREALSPEECH_API_KEY")
        .map_err(|_| anyhow!("UNREALSPEECH_API_KEY environment variable not set"))?;

    // Get text from args or stdin
    let text = if !args.text.is_empty() {
        args.text.join(" ")
    } else {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer.trim().to_string()
    };

    if text.is_empty() {
        return Err(anyhow!("No text provided"));
    }

    let client = UnrealSpeechClient::new(api_key);

    // Check if stdout is a pipe (not a TTY)
    let is_piped = !atty::is(atty::Stream::Stdout);

    if is_piped {
        // Output raw audio to stdout when piped
        let request = StreamRequest {
            text,
            voice_id: args.voice_id,
            bitrate: args.bitrate,
            speed: args.speed,
            pitch: args.pitch,
            codec: args.codec,
            temperature: args.temperature,
        };

        let audio_data = client.stream(&request).await?;
        io::stdout().write_all(&audio_data)?;
        io::stdout().flush()?;
        return Ok(());
    }

    // Original streaming playback behavior for TTY
    let (first_chunk, remaining_text) = split_at_sentence_boundary(&text, 500);

    // Channel for sequential playback
    let (tx, mut rx) = mpsc::unbounded_channel::<Option<String>>();

    // Start background processing
    if !remaining_text.is_empty() {
        let client_clone = client.clone();
        let args_clone = args.clone();
        let remaining_text_clone = remaining_text.clone();
        let tx_clone = tx.clone();

        tokio::spawn(async move {
            let chunks = split_text_into_chunks(&remaining_text_clone, 3000);

            // Create futures for all chunks
            let futures: Vec<_> = chunks
                .into_iter()
                .enumerate()
                .map(|(i, chunk)| {
                    let client = client_clone.clone();
                    let args = args_clone.clone();
                    async move {
                        let request = SpeechRequest {
                            text: chunk,
                            voice_id: args.voice_id,
                            bitrate: args.bitrate,
                            speed: args.speed,
                            pitch: args.pitch,
                        };
                        (i, client.speech(&request).await)
                    }
                })
                .collect();

            // Execute all futures concurrently
            let results = join_all(futures).await;

            // Sort results by index and send in order
            let mut sorted_results: Vec<_> = results.into_iter().collect();
            sorted_results.sort_by_key(|(i, _)| *i);

            for (_, result) in sorted_results {
                match result {
                    Ok(Some(url)) => {
                        if tx_clone.send(Some(url)).is_err() {
                            break;
                        }
                    }
                    Ok(None) => {
                        eprintln!("Warning: No URL returned for chunk");
                    }
                    Err(e) => {
                        eprintln!("Error processing chunk: {}", e);
                    }
                }
            }

            let _ = tx_clone.send(None); // Signal end
        });
    } else {
        let _ = tx.send(None); // No remaining text, signal end immediately
    }

    // Stream and play first chunk immediately
    let first_request = StreamRequest {
        text: first_chunk,
        voice_id: args.voice_id.clone(),
        bitrate: args.bitrate.clone(),
        speed: args.speed,
        pitch: args.pitch,
        codec: args.codec,
        temperature: args.temperature,
    };

    match client.stream(&first_request).await {
        Ok(first_audio) => {
            if let Err(e) = play_audio_data(&first_audio).await {
                eprintln!("Error playing first chunk: {}", e);
            }
        }
        Err(e) => {
            eprintln!("Error streaming first chunk: {}", e);
            std::process::exit(1);
        }
    }

    // Play remaining chunks as they become available
    while let Some(url_opt) = timeout(Duration::from_secs(30), rx.recv()).await.ok().flatten() {
        match url_opt {
            Some(url) => {
                if let Err(e) = play_audio_url(&url).await {
                    eprintln!("Error playing audio: {}", e);
                }
            }
            None => break, // End signal
        }
    }

    Ok(())
}