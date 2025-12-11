
use anyhow::{Context, Result};
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use pulldown_cmark::{Parser as MarkdownParser, Event, Tag};
use regex::Regex;
use rodio::{Decoder, OutputStream, Sink};
use std::env;
use std::io::{self, Read, Write, Cursor};
use std::sync::{Arc, Mutex};
use textwrap::Options;
use tokio::sync::mpsc;
use futures::StreamExt;

#[derive(Parser, Debug)]
#[command(author, version, about = "Convert text to speech using Deepgram TTS", long_about = None)]
struct Args {
    /// Text to convert to speech (or read from stdin)
    text: Option<String>,

    /// Output audio file (default: stdout if piped, play directly if not)
    #[arg(short, long)]
    output: Option<String>,

    /// Voice model (default: aura-2-thalia-en)
    #[arg(short, long, default_value = "aura-2-thalia-en")]
    model: String,

    /// List available voice models
    #[arg(long)]
    list_models: bool,

    /// Don't clean markdown formatting
    #[arg(long)]
    no_clean: bool,
}

#[derive(serde::Serialize)]
struct TextRequest {
    text: String,
}

fn split_text(text: &str, max_length: usize) -> Vec<String> {
    if text.len() <= max_length {
        return vec![text.to_string()];
    }

    // Use textwrap with sentence-aware splitting
    let options = Options::new(max_length)
        .break_words(false);

    // First try to split on sentence boundaries
    let sentence_regex = Regex::new(r"[.!?]\s+").unwrap();
    let sentences: Vec<&str> = sentence_regex.split(text).collect();

    let mut chunks = Vec::new();
    let mut current_text = String::new();

    for sentence in sentences {
        // Check if adding this sentence would exceed the limit
        let test_text = if current_text.is_empty() {
            sentence.to_string()
        } else {
            format!("{} {}", current_text, sentence)
        };

        if test_text.len() <= max_length {
            current_text = test_text;
        } else {
            // If current_text is not empty, save it as a chunk
            if !current_text.is_empty() {
                chunks.push(current_text.clone());
                current_text.clear();
            }

            // If this single sentence is too long, wrap it
            if sentence.len() > max_length {
                let wrapped = textwrap::wrap(sentence, &options);
                chunks.extend(wrapped.into_iter().map(|s| s.to_string()));
            } else {
                current_text = sentence.to_string();
            }
        }
    }

    // Don't forget the last chunk
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
            Event::Code(text) => output.push_str(&text), // Include inline code content
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
            Event::Start(Tag::Heading(_, _, _)) => {},
            Event::End(Tag::Heading(_, _, _)) => output.push(' '),
            _ => {}
        }
    }

    // Clean up excessive whitespace
    let whitespace_regex = Regex::new(r"\s{2,}").unwrap();
    whitespace_regex.replace_all(&output, " ").trim().to_string()
}

fn list_models() {
    let models = [
        "aura-2-thalia-en", "aura-2-andromeda-en", "aura-2-helena-en", "aura-2-apollo-en",
        "aura-2-arcas-en", "aura-2-aries-en", "aura-2-amalthea-en", "aura-2-asteria-en",
        "aura-2-athena-en", "aura-2-atlas-en", "aura-2-aurora-en", "aura-2-callista-en",
        "aura-2-cora-en", "aura-2-cordelia-en", "aura-2-delia-en", "aura-2-draco-en",
        "aura-2-electra-en", "aura-2-harmonia-en", "aura-2-hera-en", "aura-2-hermes-en",
        "aura-2-hyperion-en", "aura-2-iris-en", "aura-2-janus-en", "aura-2-juno-en",
        "aura-2-jupiter-en", "aura-2-luna-en", "aura-2-mars-en", "aura-2-minerva-en",
        "aura-2-neptune-en", "aura-2-odysseus-en", "aura-2-ophelia-en", "aura-2-orion-en",
        "aura-2-orpheus-en", "aura-2-pandora-en", "aura-2-phoebe-en", "aura-2-pluto-en",
        "aura-2-saturn-en", "aura-2-selene-en", "aura-2-theia-en", "aura-2-vesta-en",
        "aura-2-zeus-en"
    ];

    println!("Available voice models:");
    models.iter().for_each(|model| println!("  {}", model));
}

#[tokio::main]
async fn main() -> Result<()> {

    let args = Args::parse();

    // Get API key from environment
    let api_key = env::var("DEEPGRAM_API_KEY")
        .context("DEEPGRAM_API_KEY environment variable not set")?;

    if args.list_models {
        list_models();
        return Ok(());
    }

    // Get text input
    let text = if let Some(text) = args.text {
        text
    } else {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer.trim().to_string()
    };

    anyhow::ensure!(!text.is_empty(), "No text provided");

    // Clean markdown formatting unless disabled
    let text = if args.no_clean {
        text
    } else {
        clean_markdown(&text)
    };

    // Split text into chunks if needed (Deepgram TTS limit is 2000 chars)
    let chunks = split_text(&text, 2000);


    // Determine output mode
    let is_piped = !atty::is(atty::Stream::Stdout);

    // Start spinner for interactive mode
    let spinner = if !is_piped && args.output.is_none() {
        let pb = ProgressBar::new_spinner();
        pb.set_style(ProgressStyle::default_spinner()
            .template("{spinner:.green} {msg}")
            .unwrap());
        pb.set_message("Processing...");
        pb.enable_steady_tick(std::time::Duration::from_millis(100));
        Some(pb)
    } else {
        None
    };


    // Process chunks based on output mode
    let client = reqwest::Client::new();
    let url_base = format!("https://api.deepgram.com/v1/speak?model={}", args.model);

    let result = if let Some(output_path) = args.output {
        // File output - need to collect all chunks first
        process_chunks_for_file(&chunks, &client, &url_base, &api_key, &output_path).await
    } else if is_piped {
        // Stdout output - need to collect all chunks first
        process_chunks_for_stdout(&chunks, &client, &url_base, &api_key).await
    } else {
        // Direct playback - stream as chunks arrive
        process_chunks_streaming(&chunks, &client, &url_base, &api_key).await
    };

    // Stop spinner
    if let Some(pb) = spinner {
        pb.finish_and_clear();
    }

    result
}


async fn process_chunks_for_file(chunks: &[String], client: &reqwest::Client, url_base: &str, api_key: &str, output_path: &str) -> Result<()> {
    let audio_chunks = process_all_chunks(chunks, client, url_base, api_key).await;
    let combined_audio: Vec<u8> = audio_chunks.into_iter().flatten().collect();
    std::fs::write(output_path, &combined_audio)?;
    Ok(())
}

async fn process_chunks_for_stdout(chunks: &[String], client: &reqwest::Client, url_base: &str, api_key: &str) -> Result<()> {
    let audio_chunks = process_all_chunks(chunks, client, url_base, api_key).await;
    let combined_audio: Vec<u8> = audio_chunks.into_iter().flatten().collect();
    io::stdout().write_all(&combined_audio)?;
    io::stdout().flush()?;
    Ok(())
}

async fn process_chunks_streaming(chunks: &[String], client: &reqwest::Client, url_base: &str, api_key: &str) -> Result<()> {
    let (_stream, stream_handle) = OutputStream::try_default()
        .context("Failed to get default audio output device")?;

    let sink = Arc::new(Mutex::new(Sink::try_new(&stream_handle)
        .context("Failed to create audio sink")?));

    let (tx, mut rx) = mpsc::channel::<Vec<u8>>(10);

    // Spawn task to handle incoming audio chunks
    let sink_clone = sink.clone();
    let playback_handle = tokio::spawn(async move {
        let mut first_chunk = true;
        while let Some(audio_data) = rx.recv().await {
            if first_chunk {
                first_chunk = false;
            }

            let cursor = Cursor::new(audio_data);
            if let Ok(decoder) = Decoder::new(cursor) {
                if let Ok(sink_guard) = sink_clone.lock() {
                    sink_guard.append(decoder);
                }
            }
        }
    });

    // Process chunks and send audio data as it arrives
    let stream = futures::stream::iter(chunks.iter().enumerate())
        .then(|(_i, chunk_text)| {
            let client = client;
            let api_key = api_key;
            let url = url_base;
            let _total_chunks = chunks.len();
            let tx = tx.clone();

            async move {
                let request_body = TextRequest {
                    text: chunk_text.clone(),
                };

                let response = match client
                    .post(url)
                    .header("Content-Type", "application/json")
                    .header("Authorization", format!("Token {}", api_key))
                    .json(&request_body)
                    .send()
                    .await {
                        Ok(resp) => resp,
                        Err(_) => return
                    };

                if !response.status().is_success() {
                    let _status = response.status();
                    let _error_body = response.text().await.unwrap_or_default();
                    // Silently exit on HTTP errors
                    return;
                }

                let mut audio_data = Vec::new();
                let mut stream = response.bytes_stream();
                while let Some(chunk) = stream.next().await {
                    match chunk {
                        Ok(bytes) => audio_data.extend_from_slice(&bytes),
                        Err(_) => return
                    }
                }

                if !audio_data.is_empty() {
                    let _ = tx.send(audio_data).await;
                }
            }
        });

    // Start processing chunks - pin the stream for proper async iteration
    tokio::pin!(stream);
    while let Some(_) = stream.next().await {}

    // Close the channel to signal completion
    drop(tx);

    // Wait for playback to complete
    let _ = playback_handle.await;
    if let Ok(sink_guard) = sink.lock() {
        sink_guard.sleep_until_end();
    }

    Ok(())
}

async fn process_all_chunks(chunks: &[String], client: &reqwest::Client, url_base: &str, api_key: &str) -> Vec<Vec<u8>> {
    futures::stream::iter(chunks.iter().enumerate())
        .then(|(_i, chunk_text)| {
            let client = client;
            let api_key = api_key;
            let url = url_base;
            let _total_chunks = chunks.len();

            async move {
                let request_body = TextRequest {
                    text: chunk_text.clone(),
                };

                let response = match client
                    .post(url)
                    .header("Content-Type", "application/json")
                    .header("Authorization", format!("Token {}", api_key))
                    .json(&request_body)
                    .send()
                    .await {
                        Ok(resp) => resp,
                        Err(_) => std::process::exit(1)
                    };

                if !response.status().is_success() {
                    let _status = response.status();
                    let _error_body = response.text().await.unwrap_or_default();
                    // Silently exit on HTTP errors
                    std::process::exit(1);
                }

                let mut audio_data = Vec::new();
                let mut stream = response.bytes_stream();
                while let Some(chunk) = stream.next().await {
                    match chunk {
                        Ok(bytes) => audio_data.extend_from_slice(&bytes),
                        Err(_) => std::process::exit(1)
                    }
                }
                audio_data
            }
        })
        .collect::<Vec<_>>()
        .await
}