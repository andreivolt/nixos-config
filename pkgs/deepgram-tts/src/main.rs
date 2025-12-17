use anyhow::{Context, Result};
use clap::Parser;
use pulldown_cmark::{Event, Parser as MarkdownParser, Tag};
use regex::Regex;
use std::env;
use std::io::{self, Read, Write};
use std::process::{Command, Stdio};
use textwrap::Options;
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

    /// Playback speed (0.5-2.0, default: 1.0) - uses SOX tempo for pitch-correct speed
    #[arg(short, long, default_value = "1.0")]
    speed: f32,

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
        "aura-2-zeus-en",
    ];

    println!("Available voice models:");
    models.iter().for_each(|model| println!("  {}", model));
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

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
    let text = if args.no_clean { text } else { clean_markdown(&text) };

    // Split text into chunks if needed (Deepgram TTS limit is 2000 chars)
    let chunks = split_text(&text, 2000);

    // Fetch all audio chunks from Deepgram
    let client = reqwest::Client::new();
    let url = format!("https://api.deepgram.com/v1/speak?model={}", args.model);

    let mut all_audio = Vec::new();
    for chunk_text in &chunks {
        let request_body = TextRequest {
            text: chunk_text.clone(),
        };

        let response = client
            .post(&url)
            .header("Content-Type", "application/json")
            .header("Authorization", format!("Token {}", api_key))
            .json(&request_body)
            .send()
            .await
            .context("Failed to send request to Deepgram")?;

        if !response.status().is_success() {
            let status = response.status();
            let error_body = response.text().await.unwrap_or_default();
            anyhow::bail!("Deepgram API error {}: {}", status, error_body);
        }

        let mut stream = response.bytes_stream();
        while let Some(chunk) = stream.next().await {
            all_audio.extend_from_slice(&chunk.context("Failed to read response chunk")?);
        }
    }

    // Determine output mode
    let is_piped = !atty::is(atty::Stream::Stdout);

    if let Some(output_path) = args.output {
        // File output - apply tempo if needed
        if (args.speed - 1.0).abs() < 0.01 {
            std::fs::write(&output_path, &all_audio)?;
        } else {
            let output = Command::new("sox")
                .args(["-t", "mp3", "-", &output_path, "tempo", &args.speed.to_string()])
                .stdin(Stdio::piped())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn()
                .context("Failed to spawn sox")?;
            output.stdin.unwrap().write_all(&all_audio)?;
        }
    } else if is_piped {
        // Stdout output - apply tempo if needed
        if (args.speed - 1.0).abs() < 0.01 {
            io::stdout().write_all(&all_audio)?;
        } else {
            let mut sox = Command::new("sox")
                .args(["-t", "mp3", "-", "-t", "mp3", "-", "tempo", &args.speed.to_string()])
                .stdin(Stdio::piped())
                .stdout(Stdio::piped())
                .stderr(Stdio::null())
                .spawn()
                .context("Failed to spawn sox")?;
            sox.stdin.take().unwrap().write_all(&all_audio)?;
            let output = sox.wait_with_output()?;
            io::stdout().write_all(&output.stdout)?;
        }
    } else {
        // Direct playback via sox
        let mut sox_args = vec!["-t", "mp3", "-", "-d"];
        let speed_str = args.speed.to_string();
        if (args.speed - 1.0).abs() >= 0.01 {
            sox_args.extend(["tempo", &speed_str]);
        }

        let mut sox = Command::new("sox")
            .args(&sox_args)
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .context("Failed to spawn sox for playback")?;

        sox.stdin.take().unwrap().write_all(&all_audio)?;
        sox.wait()?;
    }

    Ok(())
}
