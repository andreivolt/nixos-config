
use anyhow::{Context, Result};
use clap::Parser;
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::SampleRate;
use crossbeam_channel::{unbounded, Sender};
use futures::{SinkExt, StreamExt};
use indicatif::{ProgressBar, ProgressStyle};
use mime_guess::from_path;
use reqwest::multipart;
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::env;
use std::fs;
use std::io::{self, IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;
use tokio_tungstenite::{connect_async, tungstenite::Message};

// Audio configuration for live transcription
const SAMPLE_RATE: u32 = 16000;
const CHANNELS: u16 = 1;

// File size limit (2GB)
const MAX_FILE_SIZE: u64 = 2 * 1024 * 1024 * 1024;

// Video formats that need audio extraction
const VIDEO_FORMATS: &[&str] = &[
    "video/mp4", "video/avi", "video/mov", "video/mkv", "video/webm",
    "video/wmv", "video/flv", "video/m4v", "video/3gp", "video/quicktime"
];

const VIDEO_EXTENSIONS: &[&str] = &[
    "mp4", "avi", "mov", "mkv", "webm", "wmv", "flv", "m4v", "3gp", "qt"
];

// Model choices - matching Python version
const NOVA_MODELS: &[&str] = &[
    "nova-2", "nova-2-meeting", "nova-2-phonecall", "nova-2-voicemail",
    "nova-2-finance", "nova-2-conversationalai", "nova-2-video",
    "nova-2-medical", "nova-2-drivethru", "nova-2-automotive", "nova-3"
];

const WHISPER_MODELS: &[&str] = &[
    "whisper-tiny", "whisper-base", "whisper-small", "whisper-medium", "whisper-large"
];

const ENHANCED_MODELS: &[&str] = &[
    "enhanced", "enhanced-general", "enhanced-meeting", "enhanced-phonecall", "enhanced-finance"
];

const BASE_MODELS: &[&str] = &[
    "base", "meeting", "phonecall", "finance", "conversationalai", "voicemail", "video", "custom"
];

const NOVA_3_MODELS: &[&str] = &["nova-3", "nova-3-general", "nova-3-medical"];

// Redaction categories - matching Python version
const REDACT_CHOICES: &[&str] = &[
    "pci", "pii", "numbers", "true", "false", "aggressive_numbers", "ssn",
    "account_number", "address", "banking_information", "blood_type",
    "credit_card", "credit_card_cvv", "credit_card_expiration",
    "date", "date_interval", "date_of_birth", "drivers_license",
    "drug", "duration", "email_address", "event", "filename",
    "gender_sexuality", "healthcare_number", "injury", "ip_address",
    "language", "location", "marital_status", "medical_condition",
    "medical_process", "money", "nationality", "occupation",
    "organization", "passport_number", "password", "person_age",
    "person_name", "phone_number", "physical_attribute", "political_affiliation",
    "religion", "statistics", "time", "url", "username", "vehicle_id",
    "zodiac_sign", "routing_number"
];

#[derive(Parser, Debug, Clone)]
#[command(author, version, about = "Audio transcription using Deepgram API", long_about = None)]
struct Args {
    /// Input file paths or URLs
    input_files: Vec<String>,

    /// Model to use
    /// Available models:
    /// Nova-3: nova-3, nova-3-general, nova-3-medical
    /// Nova-2: nova-2, nova-2-general, nova-2-meeting, nova-2-finance, nova-2-conversationalai,
    ///         nova-2-voicemail, nova-2-video, nova-2-medical, nova-2-drivethru, nova-2-automotive
    /// Nova: nova, nova-general, nova-phonecall, nova-medical
    /// Enhanced: enhanced, enhanced-general, enhanced-meeting, enhanced-phonecall, enhanced-finance
    /// Base: base, meeting, phonecall, finance, conversationalai, voicemail, video, custom
    #[arg(short, long, default_value = "nova-3")]
    model: String,

    /// Disable smart formatting
    #[arg(long)]
    no_smart_format: bool,

    /// Disable speaker diarization
    #[arg(long)]
    no_diarize: bool,

    /// Disable paragraph detection
    #[arg(long)]
    no_paragraphs: bool,

    /// Disable utterance segmentation
    #[arg(long)]
    no_utterances: bool,

    /// Add punctuation
    #[arg(long)]
    punctuate: bool,

    /// Convert numbers to digits
    #[arg(long)]
    numerals: bool,

    /// Filter profanity
    #[arg(long)]
    profanity_filter: bool,

    /// Convert measurements to abbreviations
    #[arg(long)]
    measurements: bool,

    /// Format dictation commands
    #[arg(long)]
    dictation: bool,

    /// Include filler words
    #[arg(long)]
    filler_words: bool,

    /// Language code (BCP-47 format)
    /// Supported languages: bg, ca, cs, da, da-DK, de, de-CH, el, en, en-AU, en-GB, en-IN, en-NZ, en-US,
    /// es, es-419, es-LATAM, et, fi, fr, fr-CA, hi, hi-Latn, hu, id, it, ja, ko, ko-KR, lt, lv, ms,
    /// nl, nl-BE, no, pl, pt, pt-BR, pt-PT, ro, ru, sk, sv, sv-SE, taq, th, th-TH, tr, uk, vi,
    /// zh, zh-CN, zh-HK, zh-Hans, zh-Hant, zh-TW
    #[arg(long, default_value = "en")]
    language: String,

    /// Auto-detect language
    #[arg(long)]
    detect_language: bool,

    /// Process channels independently
    #[arg(long)]
    multichannel: bool,

    /// Number of independent audio channels
    #[arg(long)]
    channels: Option<u32>,

    /// Utterance split duration
    #[arg(long, default_value = "0.8")]
    utt_split: f64,

    /// Detect entities
    #[arg(long)]
    detect_entities: bool,

    /// Detect topics
    #[arg(long)]
    detect_topics: bool,

    /// Identify topics
    #[arg(long)]
    topics: bool,

    /// Detect speaker intents
    #[arg(long)]
    intents: bool,

    /// Analyze sentiment
    #[arg(long)]
    sentiment: bool,

    /// Generate summary
    #[arg(long)]
    summarize: Option<String>,

    /// Boost keywords (format: word:boost). Use 'keyterms' for Nova-3 models.
    /// Example: --keywords "neural:2.5" --keywords "networks:1.8"
    #[arg(long)]
    keywords: Vec<String>,

    /// Key terms for Nova-3 models (format: word:boost)
    /// Example: --keyterms "artificial:2.0" --keyterms "intelligence:1.5"
    #[arg(long)]
    keyterms: Vec<String>,

    /// Search for terms
    #[arg(long)]
    search: Vec<String>,

    /// Replace terms (format: from:to)
    #[arg(long)]
    replace: Vec<String>,

    /// Redact sensitive info
    /// Available options: true, false, pci, pii, numbers, aggressive_numbers, ssn,
    /// account_number, address, banking_information, blood_type, credit_card,
    /// credit_card_cvv, credit_card_expiration, date, date_interval, date_of_birth,
    /// drivers_license, drug, duration, email_address, event, filename, gender_sexuality,
    /// healthcare_number, injury, ip_address, language, location, marital_status,
    /// medical_condition, medical_process, money, nationality, occupation, organization,
    /// passport_number, password, person_age, person_name, phone_number, physical_attribute,
    /// political_affiliation, religion, statistics, time, url, username, vehicle_id,
    /// zodiac_sign, routing_number
    #[arg(long)]
    redact: Vec<String>,

    /// Custom topic for detection
    #[arg(long)]
    custom_topic: Option<String>,

    /// Custom topic mode
    /// Allowed values: strict, extended
    #[arg(long, default_value = "extended")]
    custom_topic_mode: String,

    /// Tag for the request
    #[arg(long)]
    tag: Option<String>,

    /// URL for receiving results
    #[arg(long)]
    callback: Option<String>,

    /// Model tier level
    #[arg(long)]
    tier: Option<String>,

    /// Max transcript alternatives
    #[arg(long)]
    alternatives: Option<u32>,

    /// Audio encoding for streaming
    /// Supported encodings: linear16, flac, mulaw, amr-nb, amr-wb, opus, speex, ogg-opus
    #[arg(long)]
    encoding: Option<String>,

    /// Sample rate in Hz
    #[arg(long)]
    sample_rate: Option<u32>,

    /// Model version
    #[arg(long, default_value = "latest")]
    version: String,

    /// Chunk duration in minutes
    #[arg(long, default_value = "90")]
    chunk_minutes: u32,

    /// Output file for chunking mode
    #[arg(short, long, default_value = "transcription.json")]
    output: String,

    /// Enable live transcription from microphone
    #[arg(long)]
    live: bool,

    /// Output full JSON response
    #[arg(long)]
    json: bool,

    /// Utterance end timeout (seconds). Use with interim_results
    #[arg(long)]
    utterance_end: Option<f64>,

    /// Endpointing timeout (milliseconds). Set to false to disable
    #[arg(long, default_value = "300")]
    endpointing: String,

    /// Opt out of Model Improvement Program
    #[arg(long)]
    mip_opt_out: bool,

    /// Callback method for webhook
    /// Allowed values: POST, GET, PUT, DELETE
    #[arg(long, default_value = "POST")]
    callback_method: String,

    /// Extra parameters (format: key=value)
    #[arg(long)]
    extra: Vec<String>,

    /// Disable caching (always fetch fresh transcription)
    #[arg(long)]
    no_cache: bool,
}

#[derive(Serialize, Deserialize, Debug)]
struct DeepgramResponse {
    results: Results,
}

#[derive(Serialize, Deserialize, Debug)]
struct Results {
    channels: Vec<Channel>,
    #[serde(default)]
    summary: Option<Summary>,
    #[serde(default)]
    topics: Option<Topics>,
    #[serde(default)]
    intents: Option<Intents>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Channel {
    alternatives: Vec<Alternative>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Alternative {
    transcript: String,
    #[serde(default)]
    paragraphs: Option<Paragraphs>,
    #[serde(default)]
    words: Option<Vec<Word>>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Paragraphs {
    transcript: String,
    paragraphs: Vec<Paragraph>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Paragraph {
    sentences: Vec<Sentence>,
    #[serde(default)]
    speaker: Option<u32>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Sentence {
    text: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct Word {
    word: String,
    #[serde(default)]
    start: Option<f64>,
    #[serde(default)]
    end: Option<f64>,
    #[serde(default)]
    speaker: Option<u32>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Summary {
    #[serde(default)]
    short: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Topics {
    segments: Vec<TopicSegment>,
}

#[derive(Serialize, Deserialize, Debug)]
struct TopicSegment {
    topics: Vec<Topic>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Topic {
    topic: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct Intents {
    segments: Vec<IntentSegment>,
}

#[derive(Serialize, Deserialize, Debug)]
struct IntentSegment {
    intent: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct LiveResponse {
    #[serde(rename = "type")]
    message_type: Option<String>,
    #[serde(flatten)]
    content: LiveContent,
    is_final: Option<bool>,
    error: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(untagged)]
enum LiveContent {
    Results {
        channel: LiveChannel
    },
    Event {
        channel: Option<Vec<u32>>,
        timestamp: Option<f64>,
    },
    Unknown(serde_json::Value),
}

#[derive(Serialize, Deserialize, Debug)]
struct LiveChannel {
    alternatives: Vec<LiveAlternative>,
}

#[derive(Serialize, Deserialize, Debug)]
struct LiveAlternative {
    transcript: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct ChunkResult {
    result: Option<DeepgramResponse>,
    error: Option<String>,
    chunk_index: usize,
    chunk_file: String,
}

async fn get_audio_duration(file_path: &str) -> Result<f64> {
    let output = Command::new("ffprobe")
        .args(&["-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", file_path])
        .output()
        .context("Failed to execute ffprobe")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!("ffprobe failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    let duration_str = String::from_utf8(output.stdout).context("Invalid UTF-8 from ffprobe")?;
    let duration: f64 = duration_str.trim().parse().context("Failed to parse duration")?;
    Ok(duration)
}

fn check_file_size(file_path: &str) -> Result<u64> {
    let metadata = fs::metadata(file_path).context("Failed to get file metadata")?;
    let file_size = metadata.len();

    if file_size > MAX_FILE_SIZE {
        return Err(anyhow::anyhow!(
            "File size ({:.1} GB) exceeds the 2GB limit. Consider extracting audio from video files.",
            file_size as f64 / 1024.0 / 1024.0 / 1024.0
        ));
    }

    Ok(file_size)
}

fn is_video_file(file_path: &str) -> bool {
    let mime_type = from_path(file_path).first_or_octet_stream();

    // Check MIME type first
    if VIDEO_FORMATS.contains(&mime_type.as_ref()) {
        return true;
    }

    // Check file extension as fallback
    if let Some(extension) = Path::new(file_path).extension() {
        if let Some(ext_str) = extension.to_str() {
            return VIDEO_EXTENSIONS.contains(&ext_str.to_lowercase().as_str());
        }
    }

    false
}

async fn get_audio_codec(video_path: &str) -> Result<String> {
    let output = Command::new("ffprobe")
        .args(&[
            "-v", "quiet",
            "-select_streams", "a:0",
            "-show_entries", "stream=codec_name",
            "-of", "csv=p=0",
            video_path
        ])
        .output()
        .context("Failed to execute ffprobe")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!("ffprobe failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    let codec = String::from_utf8(output.stdout)
        .context("Invalid UTF-8 from ffprobe")?
        .trim()
        .to_string();

    Ok(codec)
}

async fn extract_audio_from_video(video_path: &str) -> Result<String> {
    let video_stem = Path::new(video_path).file_stem()
        .ok_or_else(|| anyhow::anyhow!("Invalid video file path"))?
        .to_str()
        .ok_or_else(|| anyhow::anyhow!("Invalid video file name"))?;

    // Get audio codec information
    let audio_codec = get_audio_codec(video_path).await?;

    // Deepgram-supported audio formats
    let supported_codecs = ["mp3", "aac", "flac", "opus", "vorbis", "wav", "pcm_s16le"];

    let (audio_path, should_copy) = if supported_codecs.contains(&audio_codec.as_str()) {
        // Extract without re-encoding for supported formats
        let extension = match audio_codec.as_str() {
            "mp3" => "mp3",
            "aac" => "aac",
            "flac" => "flac",
            "opus" => "opus",
            "vorbis" => "ogg",
            _ => "m4a", // Default for other supported formats
        };
        (format!("{}_audio.{}", video_stem, extension), true)
    } else {
        // Re-encode to MP3 for unsupported formats
        (format!("{}_audio.mp3", video_stem), false)
    };

    let mut ffmpeg_args = vec![
        "-y", // Overwrite output file
        "-i", video_path,
        "-vn", // No video
    ];

    if should_copy {
        // Copy audio stream without re-encoding
        ffmpeg_args.extend_from_slice(&["-c:a", "copy"]);
    } else {
        // Re-encode to MP3 with good quality
        ffmpeg_args.extend_from_slice(&["-c:a", "libmp3lame", "-b:a", "192k"]);
    }

    ffmpeg_args.push(&audio_path);

    let output = Command::new("ffmpeg")
        .args(&ffmpeg_args)
        .output()
        .context("Failed to execute ffmpeg")?;

    if !output.status.success() {
        return Err(anyhow::anyhow!(
            "ffmpeg failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    Ok(audio_path)
}

async fn chunk_audio(file_path: &str, chunk_minutes: u32) -> Result<Vec<String>> {
    let total_duration = get_audio_duration(file_path).await?;
    let chunk_duration = chunk_minutes as f64 * 60.0;

    let file_stem = Path::new(file_path).file_stem()
        .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?
        .to_str()
        .ok_or_else(|| anyhow::anyhow!("Invalid file name"))?;

    let output_dir = format!("{}_chunks", file_stem);
    fs::create_dir_all(&output_dir).context("Failed to create chunks directory")?;

    let total_chunks = (total_duration / chunk_duration).ceil() as usize;

    let mut chunks = Vec::new();
    let file_ext = Path::new(file_path).extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or("mp4");

    for i in 0..total_chunks {
        let start_time = i as f64 * chunk_duration;
        let chunk_path = format!("{}/chunk_{:03}.{}", output_dir, i, file_ext);

        let output = Command::new("ffmpeg")
            .args(&[
                "-y", "-i", file_path,
                "-ss", &start_time.to_string(),
                "-t", &chunk_duration.to_string(),
                "-c", "copy",
                &chunk_path
            ])
            .output()
            .context("Failed to execute ffmpeg")?;

        if !output.status.success() {
            eprintln!("Warning: Failed to create chunk {}: {}", i, String::from_utf8_lossy(&output.stderr));
            continue;
        }

        chunks.push(chunk_path);
    }

    Ok(chunks)
}


async fn transcribe_chunk(client: &reqwest::Client, chunk_path: &str, chunk_index: usize, args: &Args, api_key: &str) -> ChunkResult {
    let file_size = match fs::metadata(chunk_path) {
        Ok(metadata) => metadata.len(),
        Err(e) => {
            return ChunkResult {
                result: None,
                error: Some(format!("Failed to get file metadata: {}", e)),
                chunk_index,
                chunk_file: chunk_path.to_string(),
            };
        }
    };

    if file_size == 0 {
        return ChunkResult {
            result: None,
            error: Some("Chunk file is empty".to_string()),
            chunk_index,
            chunk_file: chunk_path.to_string(),
        };
    }


    let file_data = match fs::read(chunk_path) {
        Ok(data) => data,
        Err(e) => {
            return ChunkResult {
                result: None,
                error: Some(format!("Failed to read chunk file: {}", e)),
                chunk_index,
                chunk_file: chunk_path.to_string(),
            };
        }
    };

    let params = build_query_params(args);
    let url = format!("https://api.deepgram.com/v1/listen?{}", params.join("&"));

    let mime_type = from_path(chunk_path).first_or_octet_stream();
    let part = multipart::Part::bytes(file_data)
        .file_name(Path::new(chunk_path).file_name().unwrap().to_str().unwrap().to_string())
        .mime_str(mime_type.as_ref()).unwrap();

    let form = multipart::Form::new().part("file", part);

    let response = match client
        .post(&url)
        .header("Authorization", format!("Token {}", api_key))
        .multipart(form)
        .send()
        .await
    {
        Ok(resp) => resp,
        Err(e) => {
            return ChunkResult {
                result: None,
                error: Some(format!("Request failed: {}", e)),
                chunk_index,
                chunk_file: chunk_path.to_string(),
            };
        }
    };

    if !response.status().is_success() {
        let status = response.status();
        let error_text = response.text().await.unwrap_or_default();
        return ChunkResult {
            result: None,
            error: Some(format!("HTTP {}: {}", status, error_text)),
            chunk_index,
            chunk_file: chunk_path.to_string(),
        };
    }

    match response.json::<DeepgramResponse>().await {
        Ok(mut result) => {
            // Adjust timestamps for chunk offset (matching Python logic)
            let time_offset_seconds = (chunk_index as u32 * args.chunk_minutes * 60) as f64;

            // Adjust word timestamps if present
            for channel in &mut result.results.channels {
                for alternative in &mut channel.alternatives {
                    if let Some(ref mut words) = alternative.words {
                        for word in words {
                            if let Some(ref mut start) = word.start {
                                *start += time_offset_seconds;
                            }
                            if let Some(ref mut end) = word.end {
                                *end += time_offset_seconds;
                            }
                        }
                    }
                }
            }

            ChunkResult {
                result: Some(result),
                error: None,
                chunk_index,
                chunk_file: chunk_path.to_string(),
            }
        }
        Err(e) => ChunkResult {
            result: None,
            error: Some(format!("Failed to parse response: {}", e)),
            chunk_index,
            chunk_file: chunk_path.to_string(),
        },
    }
}

fn build_query_params(args: &Args) -> Vec<String> {
    let mut params = Vec::new();

    // Core parameters
    params.push(format!("model={}", args.model));
    params.push(format!("language={}", args.language));
    params.push(format!("version={}", args.version));
    params.push(format!("utt_split={}", args.utt_split));

    // Boolean parameters
    if !args.no_smart_format { params.push("smart_format=true".to_string()); }
    if !args.no_diarize { params.push("diarize=true".to_string()); }
    if !args.no_paragraphs { params.push("paragraphs=true".to_string()); }
    if !args.no_utterances { params.push("utterances=true".to_string()); }
    if args.punctuate { params.push("punctuate=true".to_string()); }
    if args.numerals { params.push("numerals=true".to_string()); }
    if args.profanity_filter { params.push("profanity_filter=true".to_string()); }
    if args.measurements { params.push("measurements=true".to_string()); }
    if args.dictation { params.push("dictation=true".to_string()); }
    if args.filler_words { params.push("filler_words=true".to_string()); }
    if args.detect_language { params.push("detect_language=true".to_string()); }
    if args.multichannel { params.push("multichannel=true".to_string()); }
    if args.detect_entities { params.push("detect_entities=true".to_string()); }
    if args.detect_topics { params.push("detect_topics=true".to_string()); }
    if args.topics { params.push("topics=true".to_string()); }
    if args.intents { params.push("intents=true".to_string()); }
    if args.sentiment { params.push("sentiment=true".to_string()); }

    // Optional parameters
    if let Some(channels) = args.channels {
        params.push(format!("channels={}", channels));
    }
    if let Some(tier) = &args.tier {
        params.push(format!("tier={}", tier));
    }
    if let Some(alternatives) = args.alternatives {
        params.push(format!("alternatives={}", alternatives));
    }
    if let Some(encoding) = &args.encoding {
        params.push(format!("encoding={}", encoding));
    }
    if let Some(sample_rate) = args.sample_rate {
        params.push(format!("sample_rate={}", sample_rate));
    }
    if let Some(summarize) = &args.summarize {
        params.push(format!("summarize={}", summarize));
    }
    if let Some(custom_topic) = &args.custom_topic {
        params.push(format!("custom_topic={}", custom_topic));
        params.push(format!("custom_topic_mode={}", args.custom_topic_mode));
    }
    if let Some(tag) = &args.tag {
        params.push(format!("tag={}", tag));
    }
    if let Some(callback) = &args.callback {
        params.push(format!("callback={}", callback));
    }

    // Optional parameters with values
    if let Some(utterance_end) = args.utterance_end {
        params.push(format!("utterance_end={}", utterance_end));
    }
    if args.mip_opt_out {
        params.push("mip_opt_out=true".to_string());
    }
    if args.callback.is_some() {
        params.push(format!("callback_method={}", args.callback_method));
    }

    // Multiple value parameters
    for keyword in &args.keywords {
        params.push(format!("keywords={}", keyword));
    }

    for keyterm in &args.keyterms {
        params.push(format!("keyterms={}", keyterm));
    }

    for search_term in &args.search {
        params.push(format!("search={}", search_term));
    }

    for replace_term in &args.replace {
        params.push(format!("replace={}", replace_term));
    }

    for redact_category in &args.redact {
        params.push(format!("redact={}", redact_category));
    }

    // Extra parameters
    for extra_param in &args.extra {
        if let Some((key, value)) = extra_param.split_once('=') {
            params.push(format!("{}={}", key, value));
        }
    }

    params
}

async fn process_single_file(client: &reqwest::Client, input_file: &str, args: &Args, api_key: &str) -> Result<()> {
    // For local files, check cache first
    if !input_file.starts_with("http") && !args.no_cache {
        let file_hash = compute_file_hash(input_file)?;
        let cache_key = compute_cache_key(&file_hash, args);
        if let Some(cached) = get_cached_response(&cache_key).await {
            if args.json {
                println!("{}", serde_json::to_string_pretty(&cached)?);
            } else {
                format_output(&cached, args);
            }
            return Ok(());
        }
    }

    let params = build_query_params(args);
    let url = format!("https://api.deepgram.com/v1/listen?{}", params.join("&"));

    let response = if input_file.starts_with("http") {
        // URL input - no caching (URLs can change content)
        let body = serde_json::json!({ "url": input_file });
        client
            .post(&url)
            .header("Authorization", format!("Token {}", api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .send()
            .await?
    } else {
        // File input
        let file_data = fs::read(input_file).context("Failed to read input file")?;
        let mime_type = from_path(input_file).first_or_octet_stream();

        // Show progress bar for file upload
        let file_size = file_data.len() as u64;
        let pb = ProgressBar::new(file_size);
        pb.set_style(ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})")
            .unwrap()
            .progress_chars("#>-"));

        pb.set_message("Uploading file");

        // Simulate progress during upload
        let pb_clone = pb.clone();
        let file_size_clone = file_size;
        tokio::spawn(async move {
            let mut progress = 0;
            while progress < file_size_clone {
                let increment = (file_size_clone / 100).max(1024); // At least 1KB increments
                progress = (progress + increment).min(file_size_clone);
                pb_clone.set_position(progress);
                tokio::time::sleep(Duration::from_millis(50)).await;
            }
        });

        let response = client
            .post(&url)
            .header("Authorization", format!("Token {}", api_key))
            .header("Content-Type", mime_type.as_ref())
            .body(file_data)
            .send()
            .await?;

        pb.finish_with_message("Upload complete");
        response
    };

    if !response.status().is_success() {
        let status = response.status();
        let error_text = response.text().await.unwrap_or_default();
        return Err(anyhow::anyhow!("Request failed: HTTP {} - {}", status, error_text));
    }

    let result: DeepgramResponse = response.json().await?;

    // Cache local file results
    if !input_file.starts_with("http") {
        let file_hash = compute_file_hash(input_file)?;
        let cache_key = compute_cache_key(&file_hash, args);
        if let Err(e) = save_to_cache(&cache_key, &result).await {
            eprintln!("Warning: Failed to cache response: {}", e);
        }
    }

    if args.json {
        println!("{}", serde_json::to_string_pretty(&result)?);
        return Ok(());
    }

    format_output(&result, args);
    Ok(())
}

async fn process_chunks(chunks: Vec<String>, args: &Args, api_key: &str) -> Result<()> {
    let client = reqwest::Client::new();
    let mut results = Vec::new();

    let pb = ProgressBar::new(chunks.len() as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} {msg}")
        .unwrap()
        .progress_chars("#>-"));

    for (i, chunk) in chunks.iter().enumerate() {
        pb.set_message(format!("Processing chunk {}", i + 1));
        let result = transcribe_chunk(&client, chunk, i, args, api_key).await;
        results.push(result);
        pb.inc(1);
    }

    pb.finish_with_message("Transcription complete!");

    // Write results to files
    let json_output = serde_json::to_string_pretty(&results)?;
    fs::write(&args.output, json_output)?;

    let text_output = args.output.replace(".json", ".txt");
    let mut text_file = fs::File::create(&text_output)?;

    writeln!(text_file, "Transcript for {} audio chunks", chunks.len())?;
    writeln!(text_file, "{}", "=".repeat(50))?;
    writeln!(text_file)?;

    for result in &results {
        if let Some(ref deepgram_result) = result.result {
            writeln!(text_file, "Chunk {}:", result.chunk_index + 1)?;
            let transcript = &deepgram_result.results.channels[0].alternatives[0].transcript;
            writeln!(text_file, "{}", transcript)?;
            writeln!(text_file)?;
        } else if let Some(ref error) = result.error {
            writeln!(text_file, "Chunk {} ERROR: {}", result.chunk_index + 1, error)?;
            writeln!(text_file)?;
        }
    }


    Ok(())
}

fn format_output(result: &DeepgramResponse, args: &Args) {
    let channel = &result.results.channels[0];
    let alternative = &channel.alternatives[0];

    // Check for speaker diarization
    let mut unique_speakers = std::collections::HashSet::new();
    if !args.no_diarize {
        if let Some(ref paragraphs) = alternative.paragraphs {
            for paragraph in &paragraphs.paragraphs {
                if let Some(speaker) = paragraph.speaker {
                    unique_speakers.insert(speaker);
                }
            }
        } else if let Some(ref words) = alternative.words {
            for word in words {
                if let Some(speaker) = word.speaker {
                    unique_speakers.insert(speaker);
                }
            }
        }
    }

    let show_speakers = !args.no_diarize && unique_speakers.len() > 1;

    // Output transcript
    if !args.no_paragraphs && alternative.paragraphs.is_some() {
        let paragraphs = alternative.paragraphs.as_ref().unwrap();

        for paragraph in &paragraphs.paragraphs {
            if let Some(speaker) = paragraph.speaker {
                if show_speakers {
                    println!("\nSpeaker {}:", speaker);
                }
            }

            for sentence in &paragraph.sentences {
                print!("{} ", sentence.text);
            }
            println!();
        }
    } else if show_speakers && alternative.words.is_some() {
        let words = alternative.words.as_ref().unwrap();
        let mut current_speaker = None;

        for word in words {
            if let Some(speaker) = word.speaker {
                if current_speaker != Some(speaker) {
                    if current_speaker.is_some() {
                        println!();
                    }
                    print!("\nSpeaker {}: ", speaker);
                    current_speaker = Some(speaker);
                }
            }
            print!("{} ", word.word);
        }
        println!();
    } else {
        println!("{}", alternative.transcript);
    }

    // Additional output sections
    if let Some(ref summary) = result.results.summary {
        println!("\n--- Summary ---");
        if let Some(ref short) = summary.short {
            println!("{}", short);
        }
    }

    if let Some(ref topics) = result.results.topics {
        println!("\n--- Topics ---");
        for segment in &topics.segments {
            let topic_names: Vec<String> = segment.topics.iter().map(|t| t.topic.clone()).collect();
            if !topic_names.is_empty() {
                println!("Topics: {}", topic_names.join(", "));
            }
        }
    }

    if let Some(ref intents) = result.results.intents {
        println!("\n--- Intents ---");
        for segment in &intents.segments {
            if !segment.intent.is_empty() {
                println!("Intent: {}", segment.intent);
            }
        }
    }
}

async fn live_transcription(args: &Args, api_key: &str) -> Result<()> {

    // Set up audio capture first to get the actual sample rate
    let (audio_tx, audio_rx) = unbounded::<Vec<u8>>();
    let stop_flag = Arc::new(AtomicBool::new(false));
    let stop_flag_clone = stop_flag.clone();

    // Get audio config and start capture
    let actual_sample_rate = {
        let host = cpal::default_host();
        let device = host.default_input_device()
            .ok_or_else(|| anyhow::anyhow!("No default input device found"))?;


        let supported_configs = device.supported_input_configs()
            .context("Failed to get supported configs")?;

        let config_range = supported_configs
            .filter(|config| config.channels() <= CHANNELS && config.sample_format() == cpal::SampleFormat::F32)
            .min_by_key(|config| {
                let min_rate = config.min_sample_rate().0;
                let max_rate = config.max_sample_rate().0;
                if SAMPLE_RATE >= min_rate && SAMPLE_RATE <= max_rate {
                    0
                } else {
                    std::cmp::min(
                        (min_rate as i32 - SAMPLE_RATE as i32).abs(),
                        (max_rate as i32 - SAMPLE_RATE as i32).abs()
                    )
                }
            })
            .ok_or_else(|| anyhow::anyhow!("No suitable audio config found"))?;

        let target_rate = if SAMPLE_RATE >= config_range.min_sample_rate().0 && SAMPLE_RATE <= config_range.max_sample_rate().0 {
            SAMPLE_RATE
        } else if SAMPLE_RATE < config_range.min_sample_rate().0 {
            config_range.min_sample_rate().0
        } else {
            config_range.max_sample_rate().0
        };

        target_rate
    };

    // Build WebSocket URL with actual audio parameters
    let mut live_args = args.clone();
    live_args.encoding = Some("linear16".to_string());
    live_args.sample_rate = Some(actual_sample_rate);
    live_args.channels = Some(CHANNELS as u32);

    let params = build_query_params(&live_args);
    let ws_url = format!("wss://api.deepgram.com/v1/listen?{}", params.join("&"));

    // Add live-specific parameters
    let ws_url = format!("{}&interim_results=true&vad_events=true&endpointing={}",
                        ws_url, args.endpointing);

    // Create properly formatted WebSocket request
    let url = url::Url::parse(&ws_url).context("Invalid WebSocket URL")?;

    let request = tokio_tungstenite::tungstenite::http::Request::builder()
        .method("GET")
        .uri(ws_url.as_str())
        .header("Host", url.host_str().unwrap_or("api.deepgram.com"))
        .header("Upgrade", "websocket")
        .header("Connection", "Upgrade")
        .header("Sec-WebSocket-Key", "dGhlIHNhbXBsZSBub25jZQ==")
        .header("Sec-WebSocket-Version", "13")
        .header("Authorization", format!("Token {}", api_key))
        .body(())
        .context("Failed to build WebSocket request")?;

    // Connect to WebSocket
    let (ws_stream, _) = connect_async(request).await
        .context("Failed to connect to Deepgram WebSocket")?;

    let (mut ws_sender, mut ws_receiver) = ws_stream.split();

    // Start audio capture in a separate thread with the actual sample rate
    let audio_handle = thread::spawn(move || {
        capture_audio_with_rate(audio_tx, stop_flag_clone, actual_sample_rate)
    });

    // Send audio data to WebSocket
    let audio_sender = {
        let stop_flag = stop_flag.clone();
        tokio::spawn(async move {
            while !stop_flag.load(Ordering::Relaxed) {
                match audio_rx.recv_timeout(Duration::from_millis(10)) {
                    Ok(audio_data) => {
                        if !audio_data.is_empty() {
                            if let Err(e) = ws_sender.send(Message::Binary(audio_data)).await {
                                eprintln!("Failed to send audio data: {}", e);
                                break;
                            }
                        }
                    }
                    Err(_) => {
                        // Timeout is normal, continue loop
                        continue;
                    }
                }
            }
        })
    };

    // Use plain output if stdout is piped (not a terminal)
    let plain_output = !io::stdout().is_terminal();
    let message_handler = tokio::spawn(async move {
        while let Some(msg) = ws_receiver.next().await {
            match msg {
                Ok(Message::Text(text)) => {
                    if let Ok(response) = serde_json::from_str::<serde_json::Value>(&text) {
                        handle_live_response(response, plain_output);
                    }
                }
                Ok(Message::Close(frame)) => {
                    if let Some(frame) = frame {
                        eprintln!("\nWebSocket closed: {} - {}", frame.code, frame.reason);
                    } else {
                        eprintln!("\nWebSocket connection closed");
                    }
                    break;
                }
                Err(e) => {
                    eprintln!("WebSocket error: {}", e);
                    break;
                }
                _ => {}
            }
        }
    });

    // Wait for Ctrl+C
    tokio::signal::ctrl_c().await.context("Failed to listen for Ctrl+C")?;

    // Cleanup
    stop_flag.store(true, Ordering::Relaxed);

    // Wait for tasks to complete
    let _ = tokio::time::timeout(Duration::from_millis(200), async {
        let _ = tokio::join!(audio_sender, message_handler);
    }).await;

    // Wait for audio thread to finish
    if let Err(e) = audio_handle.join() {
        eprintln!("Audio thread error: {:?}", e);
    }

    Ok(())
}

fn capture_audio_with_rate(tx: Sender<Vec<u8>>, stop_flag: Arc<AtomicBool>, target_sample_rate: u32) -> Result<()> {
    let host = cpal::default_host();
    let device = host.default_input_device()
        .ok_or_else(|| anyhow::anyhow!("No default input device found"))?;

    // Try to get the best config for the device
    let supported_configs = device.supported_input_configs()
        .context("Failed to get supported configs")?;

    // Find a config that matches our requirements or is close
    let config_range = supported_configs
        .filter(|config| config.channels() <= CHANNELS && config.sample_format() == cpal::SampleFormat::F32)
        .min_by_key(|config| {
            // Prefer configs closer to our target sample rate
            let min_rate = config.min_sample_rate().0;
            let max_rate = config.max_sample_rate().0;
            if target_sample_rate >= min_rate && target_sample_rate <= max_rate {
                0 // Perfect match
            } else {
                std::cmp::min(
                    (min_rate as i32 - target_sample_rate as i32).abs(),
                    (max_rate as i32 - target_sample_rate as i32).abs()
                )
            }
        })
        .ok_or_else(|| anyhow::anyhow!("No suitable audio config found"))?;

    let config = config_range.with_sample_rate(SampleRate(target_sample_rate));


    let stop_flag_callback = stop_flag.clone();
    let samples_sent = Arc::new(std::sync::atomic::AtomicU64::new(0));
    let samples_sent_callback = samples_sent.clone();

    let stream = device.build_input_stream(
        &config.config(),
        move |data: &[f32], _: &cpal::InputCallbackInfo| {
            if stop_flag_callback.load(Ordering::Relaxed) {
                return;
            }

            // Convert f32 samples to i16 PCM
            let mut pcm_data = Vec::with_capacity(data.len() * 2);
            for &sample in data {
                let sample_i16 = (sample * 32767.0).clamp(-32768.0, 32767.0) as i16;
                pcm_data.extend_from_slice(&sample_i16.to_le_bytes());
            }

            // Send audio data if it contains actual samples
            if !pcm_data.is_empty() {
                if tx.send(pcm_data).is_ok() {
                    samples_sent_callback.fetch_add(data.len() as u64, Ordering::Relaxed);
                }
            }
        },
        |err| eprintln!("Audio stream error: {}", err),
        None,
    )?;

    stream.play()?;

    // Keep the stream alive
    while !stop_flag.load(Ordering::Relaxed) {
        thread::sleep(Duration::from_millis(10));
    }

    Ok(())
}

fn handle_live_response(response: serde_json::Value, plain: bool) {
    match serde_json::from_value::<LiveResponse>(response.clone()) {
        Ok(live_response) => {
            // Handle error messages first
            if let Some(error) = live_response.error {
                eprintln!("Deepgram error: {}", error);
                return;
            }

            // Handle different message types
            match live_response.message_type.as_deref() {
                Some("Results") => {
                    if let Some(transcript) = extract_transcript_from_response(&live_response) {
                        let is_final = live_response.is_final.unwrap_or(false);

                        if plain {
                            // Plain output for scripting - only final results, one per line
                            if is_final {
                                println!("{}", transcript);
                            }
                        } else {
                            if is_final {
                                // Final transcript - print in green
                                print!("\r\x1b[92m{}\x1b[0m\n", transcript);
                            } else {
                                // Interim transcript - print in gray, overwriting previous
                                print!("\r\x1b[90m{}\x1b[0m", transcript);
                            }
                            io::stdout().flush().unwrap();
                        }
                    }
                },
                Some("Metadata") => {
                    // Metadata received - connection is working
                },
                Some("SpeechStarted") => {
                    // Speech started - audio is being processed
                },
                Some("UtteranceEnd") => {
                    if !plain {
                        println!(); // New line after utterance
                    }
                },
                Some("CloseStream") => {
                },
                _ => {
                    // Handle legacy format or unknown types
                    if let Some(transcript) = extract_transcript_from_response(&live_response) {
                        let is_final = live_response.is_final.unwrap_or(false);

                        if plain {
                            if is_final {
                                println!("{}", transcript);
                            }
                        } else {
                            if is_final {
                                print!("\r\x1b[92m{}\x1b[0m\n", transcript);
                            } else {
                                print!("\r\x1b[90m{}\x1b[0m", transcript);
                            }
                            io::stdout().flush().unwrap();
                        }
                    } else {
                        // Unknown message format - ignore
                    }
                }
            }
        },
        Err(_) => {
            // Fallback for malformed responses - ignore
        }
    }
}

fn extract_transcript_from_response(response: &LiveResponse) -> Option<String> {
    match &response.content {
        LiveContent::Results { channel } => {
            let transcript = channel.alternatives.first()?.transcript.clone();
            if transcript.is_empty() {
                None
            } else {
                Some(transcript)
            }
        },
        _ => None,
    }
}

fn validate_args(mut args: Args) -> Result<Args> {
    // Model validation
    let all_models: Vec<&str> = NOVA_MODELS.iter()
        .chain(WHISPER_MODELS.iter())
        .chain(ENHANCED_MODELS.iter())
        .chain(BASE_MODELS.iter())
        .chain(NOVA_3_MODELS.iter())
        .copied()
        .collect();

    if !all_models.contains(&args.model.as_str()) {
        return Err(anyhow::anyhow!(
            "Invalid model '{}'. Available models: {}",
            args.model,
            all_models.join(", ")
        ));
    }

    // Redaction validation
    for redact_item in &args.redact {
        if !REDACT_CHOICES.contains(&redact_item.as_str()) {
            return Err(anyhow::anyhow!(
                "Invalid redaction category '{}'. Available options: {}",
                redact_item,
                REDACT_CHOICES.join(", ")
            ));
        }
    }

    // Keywords format validation
    for keyword in &args.keywords {
        if !keyword.contains(':') {
            return Err(anyhow::anyhow!(
                "Keywords must be in 'word:boost' format, got: {}",
                keyword
            ));
        }
    }

    // Keyterms format validation
    for keyterm in &args.keyterms {
        if !keyterm.contains(':') {
            return Err(anyhow::anyhow!(
                "Keyterms must be in 'word:boost' format, got: {}",
                keyterm
            ));
        }
    }

    // Replace format validation
    for replace_item in &args.replace {
        if !replace_item.contains(':') {
            return Err(anyhow::anyhow!(
                "Replace must be in 'from:to' format, got: {}",
                replace_item
            ));
        }
    }

    // Extra format validation
    for extra_item in &args.extra {
        if !extra_item.contains('=') {
            return Err(anyhow::anyhow!(
                "Extra must be in 'key=value' format, got: {}",
                extra_item
            ));
        }
    }

    // Feature dependencies validation (matching Python logic)
    if !args.no_paragraphs &&
       !args.punctuate &&
       args.no_diarize &&
       !args.multichannel &&
       args.no_smart_format {
        return Err(anyhow::anyhow!(
            "--paragraphs requires --punctuate, --diarize, --multichannel, or --smart-format"
        ));
    }

    // Language-specific validations
    if args.language != "en" && args.sentiment {
        return Err(anyhow::anyhow!(
            "--sentiment is only supported for English (--language en)"
        ));
    }

    // Whisper model limitations
    let is_whisper = WHISPER_MODELS.contains(&args.model.as_str());
    if is_whisper && !args.search.is_empty() {
        return Err(anyhow::anyhow!(
            "--search is not supported with Whisper models"
        ));
    }

    // Auto-select keywords vs keyterms based on model
    if !args.keywords.is_empty() && NOVA_3_MODELS.contains(&args.model.as_str()) && args.keyterms.is_empty() {
        eprintln!("Note: Converting --keywords to --keyterms for Nova-3 model");
        args.keyterms = args.keywords.clone();
        args.keywords.clear();
    }

    // Live streaming locale conversion
    if args.live && args.language == "en" {
        args.language = "en-US".to_string();
    }

    Ok(args)
}

// ============================================================================
// Caching
// ============================================================================

fn get_cache_dir() -> Result<PathBuf> {
    let cache_dir = if let Ok(xdg_cache) = env::var("XDG_CACHE_HOME") {
        PathBuf::from(xdg_cache).join("deepgram")
    } else if let Ok(home) = env::var("HOME") {
        PathBuf::from(home).join(".cache").join("deepgram")
    } else {
        return Err(anyhow::anyhow!("Cannot determine cache directory"));
    };
    Ok(cache_dir)
}

fn compute_file_hash(file_path: &str) -> Result<String> {
    let file_data = fs::read(file_path).context("Failed to read file for hashing")?;
    let mut hasher = Sha256::new();
    hasher.update(&file_data);
    Ok(format!("{:x}", hasher.finalize()))
}

/// Build a cache key from file hash and transcription-affecting parameters
fn compute_cache_key(file_hash: &str, args: &Args) -> String {
    // Only include parameters that affect the transcription output
    // Excludes: json (output format), output (file path), live, no_cache, chunk_minutes,
    //           tag, callback, callback_method, mip_opt_out
    let cache_params = serde_json::json!({
        "model": args.model,
        "language": args.language,
        "version": args.version,
        "smart_format": !args.no_smart_format,
        "diarize": !args.no_diarize,
        "paragraphs": !args.no_paragraphs,
        "utterances": !args.no_utterances,
        "utt_split": args.utt_split,
        "punctuate": args.punctuate,
        "numerals": args.numerals,
        "profanity_filter": args.profanity_filter,
        "measurements": args.measurements,
        "dictation": args.dictation,
        "filler_words": args.filler_words,
        "detect_language": args.detect_language,
        "multichannel": args.multichannel,
        "channels": args.channels,
        "detect_entities": args.detect_entities,
        "detect_topics": args.detect_topics,
        "topics": args.topics,
        "intents": args.intents,
        "sentiment": args.sentiment,
        "summarize": args.summarize,
        "keywords": args.keywords,
        "keyterms": args.keyterms,
        "search": args.search,
        "replace": args.replace,
        "redact": args.redact,
        "custom_topic": args.custom_topic,
        "custom_topic_mode": args.custom_topic_mode,
        "tier": args.tier,
        "alternatives": args.alternatives,
        "encoding": args.encoding,
        "sample_rate": args.sample_rate,
        "extra": args.extra,
    });

    let params_str = serde_json::to_string(&cache_params).unwrap();
    let mut hasher = Sha256::new();
    hasher.update(file_hash.as_bytes());
    hasher.update(params_str.as_bytes());
    format!("{:x}", hasher.finalize())
}

async fn get_cached_response(cache_key: &str) -> Option<DeepgramResponse> {
    let cache_dir = get_cache_dir().ok()?;
    let data = cacache::read(&cache_dir, cache_key).await.ok()?;
    serde_json::from_slice(&data).ok()
}

async fn save_to_cache(cache_key: &str, response: &DeepgramResponse) -> Result<()> {
    let cache_dir = get_cache_dir()?;
    let data = serde_json::to_vec(response)?;
    cacache::write(&cache_dir, cache_key, data).await?;
    Ok(())
}

/// Process a single file with direct output (for single-file mode)
async fn process_file(client: &reqwest::Client, input_file: &str, args: &Args, api_key: &str) -> Result<()> {
    if input_file.starts_with("http") {
        process_single_file(client, input_file, args, api_key).await
    } else {
        check_file_size(input_file)?;

        let processed_file = if is_video_file(input_file) {
            extract_audio_from_video(input_file).await?
        } else {
            input_file.to_string()
        };

        let should_chunk = match get_audio_duration(&processed_file).await {
            Ok(duration) => duration > 7200.0,
            Err(_) => false,
        };

        let result = if should_chunk {
            let chunks = chunk_audio(&processed_file, args.chunk_minutes).await?;
            process_chunks(chunks, args, api_key).await
        } else {
            process_single_file(client, &processed_file, args, api_key).await
        };

        if processed_file != input_file {
            if let Err(e) = fs::remove_file(&processed_file) {
                eprintln!("Warning: Failed to clean up extracted audio file: {}", e);
            }
        }

        result
    }
}

/// Transcribe a file and return the result (for parallel multi-file mode)
/// Returns (DeepgramResponse, Option<extracted_file_path_to_cleanup>)
async fn transcribe_file(client: &reqwest::Client, input_file: &str, args: &Args, api_key: &str) -> Result<(DeepgramResponse, Option<String>)> {
    if input_file.starts_with("http") {
        let response = transcribe_url(client, input_file, args, api_key).await?;
        Ok((response, None))
    } else {
        check_file_size(input_file)?;

        let (processed_file, extracted) = if is_video_file(input_file) {
            let extracted = extract_audio_from_video(input_file).await?;
            (extracted.clone(), Some(extracted))
        } else {
            (input_file.to_string(), None)
        };

        let response = transcribe_local_file(client, &processed_file, args, api_key).await?;
        Ok((response, extracted))
    }
}

/// Transcribe a URL and return the response
async fn transcribe_url(client: &reqwest::Client, url: &str, args: &Args, api_key: &str) -> Result<DeepgramResponse> {
    let params = build_query_params(args);
    let api_url = format!("https://api.deepgram.com/v1/listen?{}", params.join("&"));

    let body = serde_json::json!({ "url": url });
    let response = client
        .post(&api_url)
        .header("Authorization", format!("Token {}", api_key))
        .header("Content-Type", "application/json")
        .json(&body)
        .send()
        .await?;

    if !response.status().is_success() {
        let status = response.status();
        let error_text = response.text().await.unwrap_or_default();
        return Err(anyhow::anyhow!("Request failed: HTTP {} - {}", status, error_text));
    }

    response.json().await.context("Failed to parse response")
}

/// Transcribe a local file and return the response (with caching)
async fn transcribe_local_file(client: &reqwest::Client, file_path: &str, args: &Args, api_key: &str) -> Result<DeepgramResponse> {
    // Compute file hash for cache key
    let file_hash = compute_file_hash(file_path)?;
    let cache_key = compute_cache_key(&file_hash, args);

    // Check cache unless --no-cache
    if !args.no_cache {
        if let Some(cached) = get_cached_response(&cache_key).await {
            return Ok(cached);
        }
    }

    let params = build_query_params(args);
    let url = format!("https://api.deepgram.com/v1/listen?{}", params.join("&"));

    let file_data = fs::read(file_path).context("Failed to read input file")?;
    let mime_type = from_path(file_path).first_or_octet_stream();

    let response = client
        .post(&url)
        .header("Authorization", format!("Token {}", api_key))
        .header("Content-Type", mime_type.as_ref())
        .body(file_data)
        .send()
        .await?;

    if !response.status().is_success() {
        let status = response.status();
        let error_text = response.text().await.unwrap_or_default();
        return Err(anyhow::anyhow!("Request failed: HTTP {} - {}", status, error_text));
    }

    let result: DeepgramResponse = response.json().await.context("Failed to parse response")?;

    // Save to cache
    if let Err(e) = save_to_cache(&cache_key, &result).await {
        eprintln!("Warning: Failed to cache response: {}", e);
    }

    Ok(result)
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();


    let api_key = env::var("DEEPGRAM_API_KEY")
        .context("DEEPGRAM_API_KEY environment variable not set")?;

    // Validate and fix arguments (matching Python validation logic)
    let validated_args = validate_args(args)?;

    if validated_args.live {
        return live_transcription(&validated_args, &api_key).await;
    }

    if validated_args.input_files.is_empty() {
        return Err(anyhow::anyhow!("Input file is required (or use --live for live transcription)"));
    }

    let client = reqwest::Client::new();

    if validated_args.input_files.len() == 1 {
        // Single file - process directly
        let input_file = &validated_args.input_files[0];
        process_file(&client, input_file, &validated_args, &api_key).await?;
    } else {
        // Multiple files - process in parallel, output in order
        let futures: Vec<_> = validated_args.input_files.iter().enumerate().map(|(i, input_file)| {
            let client = client.clone();
            let args = validated_args.clone();
            let api_key = api_key.clone();
            let input_file = input_file.clone();
            async move {
                let result = transcribe_file(&client, &input_file, &args, &api_key).await;
                (i, input_file, result)
            }
        }).collect();

        let mut results: Vec<_> = futures::future::join_all(futures).await;
        results.sort_by_key(|(i, _, _)| *i);

        for (_, input_file, result) in results {
            match result {
                Ok((response, extracted_file)) => {
                    eprintln!("\n--- {} ---", input_file);
                    if validated_args.json {
                        println!("{}", serde_json::to_string_pretty(&response)?);
                    } else {
                        format_output(&response, &validated_args);
                    }
                    // Clean up extracted audio file if it was created
                    if let Some(extracted) = extracted_file {
                        if let Err(e) = fs::remove_file(&extracted) {
                            eprintln!("Warning: Failed to clean up extracted audio file: {}", e);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("\n--- {} ---", input_file);
                    eprintln!("Error: {}", e);
                }
            }
        }
    }

    Ok(())
}