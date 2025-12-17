
use clap::{Arg, Command};
use futures_util::StreamExt;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::collections::HashMap;
use std::env;
use std::io::{self, Write, Read};
use std::process;

#[derive(Debug, Serialize, Deserialize)]
struct Voice {
    voice_id: String,
    name: String,
    description: Option<String>,
    labels: Option<HashMap<String, String>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct VoicesResponse {
    voices: Vec<Voice>,
}

#[derive(Debug, Serialize)]
struct VoiceSettings {
    stability: f32,
    similarity_boost: f32,
}

#[derive(Debug, Serialize)]
struct TextToSpeechRequest {
    text: String,
    voice_settings: VoiceSettings,
    model_id: String,
    language_code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    speed: Option<f32>,
}

fn get_language_codes() -> HashMap<&'static str, &'static str> {
    [
        ("en", "English"),
        ("ro", "Romanian (Română)"),
        ("es", "Spanish (Español)"),
        ("fr", "French (Français)"),
        ("de", "German (Deutsch)"),
        ("it", "Italian (Italiano)"),
        ("pt", "Portuguese (Português)"),
        ("pl", "Polish (Polski)"),
        ("nl", "Dutch (Nederlands)"),
        ("sv", "Swedish (Svenska)"),
        ("cs", "Czech (Čeština)"),
        ("tr", "Turkish (Türkçe)"),
        ("ru", "Russian (Русский)"),
        ("zh", "Chinese (中文)"),
        ("ja", "Japanese (日本語)"),
        ("ko", "Korean (한국어)"),
        ("ar", "Arabic (العربية)"),
        ("hi", "Hindi (हिन्दी)"),
        ("hu", "Hungarian (Magyar)"),
        ("el", "Greek (Ελληνικά)"),
        ("da", "Danish (Dansk)"),
        ("fi", "Finnish (Suomi)"),
        ("no", "Norwegian (Norsk)"),
        ("uk", "Ukrainian (Українська)"),
        ("bg", "Bulgarian (Български)"),
        ("hr", "Croatian (Hrvatski)"),
        ("sk", "Slovak (Slovenčina)"),
        ("id", "Indonesian (Bahasa Indonesia)"),
        ("ms", "Malay (Bahasa Melayu)"),
        ("vi", "Vietnamese (Tiếng Việt)"),
        ("th", "Thai (ไทย)"),
        ("he", "Hebrew (עברית)"),
        ("lt", "Lithuanian (Lietuvių)"),
        ("lv", "Latvian (Latviešu)"),
        ("et", "Estonian (Eesti)"),
        ("sl", "Slovenian (Slovenščina)"),
        ("fa", "Persian (فارسی)"),
        ("bn", "Bengali (বাংলা)"),
        ("ta", "Tamil (தமிழ்)"),
        ("te", "Telugu (తెలుగు)"),
        ("mr", "Marathi (मराठी)"),
        ("ur", "Urdu (اردو)"),
        ("gu", "Gujarati (ગુજરાતી)"),
        ("kn", "Kannada (ಕನ್ನಡ)"),
        ("ml", "Malayalam (മലയാളം)"),
        ("pa", "Punjabi (ਪੰਜਾਬੀ)"),
    ]
    .into_iter()
    .collect()
}

fn get_models() -> HashMap<&'static str, serde_json::Value> {
    [
        ("eleven_multilingual_v2", json!({
            "name": "Multilingual v2",
            "description": "Most life-like, emotionally rich model. Best for voiceovers and audiobooks.",
            "languages": 29,
            "supports_language_code": false,
            "latency": "medium"
        })),
        ("eleven_flash_v2_5", json!({
            "name": "Flash v2.5",
            "description": "Ultra-low latency (~75ms), supports language enforcement.",
            "languages": 32,
            "supports_language_code": true,
            "latency": "ultra-low"
        })),
        ("eleven_turbo_v2_5", json!({
            "name": "Turbo v2.5",
            "description": "Good balance of quality and latency, supports language enforcement.",
            "languages": 32,
            "supports_language_code": true,
            "latency": "low"
        })),
        ("eleven_flash_v2", json!({
            "name": "Flash v2",
            "description": "Ultra-low latency, English only.",
            "languages": 1,
            "supports_language_code": false,
            "latency": "ultra-low"
        })),
        ("eleven_turbo_v2", json!({
            "name": "Turbo v2",
            "description": "Low latency, English only.",
            "languages": 1,
            "supports_language_code": false,
            "latency": "low"
        })),
        ("eleven_monolingual_v1", json!({
            "name": "English v1",
            "description": "Original model, English only.",
            "languages": 1,
            "supports_language_code": false,
            "latency": "medium"
        })),
        ("eleven_multilingual_v1", json!({
            "name": "Multilingual v1",
            "description": "Experimental multilingual model, not recommended.",
            "languages": 8,
            "supports_language_code": false,
            "latency": "medium"
        })),
    ]
    .into_iter()
    .collect()
}

async fn list_voices(client: &Client, api_key: &str) -> anyhow::Result<()> {
    let response = client
        .get("https://api.elevenlabs.io/v1/voices")
        .header("xi-api-key", api_key)
        .send()
        .await?;

    let voices: VoicesResponse = response.json().await?;

    for voice in voices.voices {
        let mut lang_info = Vec::new();

        if let Some(labels) = &voice.labels {
            if let Some(language) = labels.get("language") {
                lang_info.push(format!("Primary: {}", language));
            }
            if let Some(accent) = labels.get("accent") {
                lang_info.push(format!("Accent: {}", accent));
            }
        }

        let lang_str = if lang_info.is_empty() {
            String::new()
        } else {
            format!(" [{}]", lang_info.join(", "))
        };

        if let Some(desc) = &voice.description {
            println!("{}: {}{} - {}", voice.voice_id, voice.name, lang_str, desc);
        } else {
            println!("{}: {}{}", voice.voice_id, voice.name, lang_str);
        }
    }

    Ok(())
}

async fn resolve_voice_id(client: &Client, api_key: &str, voice_input: &str) -> anyhow::Result<String> {
    // Check if it's already a voice ID (starts with common prefixes)
    if voice_input.starts_with("21m") || voice_input.starts_with("9BW") ||
       voice_input.starts_with("EXA") || voice_input.starts_with("FGY") ||
       voice_input.starts_with("IKn") || voice_input.starts_with("JBF") ||
       voice_input.starts_with("TxG") || voice_input.starts_with("Gqz") {
        return Ok(voice_input.to_string());
    }

    // Try to find by name
    let response = client
        .get("https://api.elevenlabs.io/v1/voices")
        .header("xi-api-key", api_key)
        .send()
        .await?;

    let voices: VoicesResponse = response.json().await?;

    for voice in voices.voices {
        if voice.name.to_lowercase() == voice_input.to_lowercase() {
            return Ok(voice.voice_id);
        }
    }

    anyhow::bail!("Voice '{}' not found", voice_input);
}

async fn text_to_speech(
    client: &Client,
    api_key: &str,
    text: &str,
    voice_id: &str,
    model: &str,
    language_code: Option<&str>,
    stability: f32,
    similarity_boost: f32,
    speed: Option<f32>,
) -> anyhow::Result<()> {
    let voice_settings = VoiceSettings {
        stability,
        similarity_boost,
    };

    // Clamp speed to API limits (0.7-1.2)
    let clamped_speed = speed.map(|s| s.clamp(0.7, 1.2));

    let mut request = TextToSpeechRequest {
        text: text.to_string(),
        voice_settings,
        model_id: model.to_string(),
        language_code: language_code.map(|s| s.to_string()),
        speed: clamped_speed,
    };

    // Check if model supports language_code
    let models = get_models();
    if let Some(model_info) = models.get(model) {
        let supports_language_code = model_info["supports_language_code"].as_bool().unwrap_or(false);

        if language_code.is_some() && !supports_language_code {
            eprintln!("\n⚠️  WARNING: Model '{}' does NOT support language_code parameter!", model);
            eprintln!("Language will be auto-detected from your text.");
            eprintln!("\nTo use language enforcement, switch to one of these models:");
            eprintln!("  - eleven_turbo_v2_5 (use -m eleven_turbo_v2_5)");
            eprintln!("  - eleven_flash_v2_5 (use -m eleven_flash_v2_5)");
            eprintln!("\nFor multilingual without language enforcement, write your text in the target language.");
            request.language_code = None;
        }
    }

    let response = client
        .post(&format!("https://api.elevenlabs.io/v1/text-to-speech/{}/stream", voice_id))
        .header("xi-api-key", api_key)
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await?;

    if !response.status().is_success() {
        let error_text = response.text().await?;
        anyhow::bail!("API error: {}", error_text);
    }

    let mut stream = response.bytes_stream();

    if atty::is(atty::Stream::Stdout) {
        // TTY: collect audio and play it with rodio
        let mut audio_data = Vec::new();
        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            audio_data.extend_from_slice(&chunk);
        }

        // Play audio using rodio
        let (_stream, stream_handle) = rodio::OutputStream::try_default()?;
        let sink = rodio::Sink::try_new(&stream_handle)?;

        let cursor = std::io::Cursor::new(audio_data);
        let source = rodio::Decoder::new(cursor)?;

        sink.append(source);
        sink.play();

        // Wait for playback to finish
        sink.sleep_until_end();
    } else {
        // Non-TTY: stream to stdout
        let mut stdout = io::stdout();
        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            stdout.write_all(&chunk)?;
            stdout.flush()?;
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let matches = Command::new("elevenlabs-rs")
        .about("Convert text to speech using ElevenLabs API")
        .arg(Arg::new("text")
            .help("Text to convert")
            .num_args(0..)
            .trailing_var_arg(true))
        .arg(Arg::new("voice")
            .short('v')
            .long("voice")
            .help("Voice ID or name")
            .default_value("EXAVITQu4vr4xnSDxMaL"))
        .arg(Arg::new("model")
            .short('m')
            .long("model")
            .help("Model to use")
            .default_value("eleven_multilingual_v2"))
        .arg(Arg::new("language")
            .short('l')
            .long("language")
            .help("Language code - ONLY works with eleven_turbo_v2_5 and eleven_flash_v2_5 models"))
        .arg(Arg::new("stability")
            .short('s')
            .long("stability")
            .help("Voice stability (0.0-1.0)")
            .default_value("0.3")
            .value_parser(clap::value_parser!(f32)))
        .arg(Arg::new("similarity-boost")
            .short('b')
            .long("similarity-boost")
            .help("Similarity boost (0.0-1.0)")
            .default_value("0.5")
            .value_parser(clap::value_parser!(f32)))
        .arg(Arg::new("list-voices")
            .long("list-voices")
            .help("List available voices")
            .action(clap::ArgAction::SetTrue))
        .arg(Arg::new("list-languages")
            .long("list-languages")
            .help("List common language codes")
            .action(clap::ArgAction::SetTrue))
        .arg(Arg::new("list-models")
            .long("list-models")
            .help("List available models and their capabilities")
            .action(clap::ArgAction::SetTrue))
        .arg(Arg::new("speed")
            .long("speed")
            .help("Playback speed (0.7-1.2, default 1.0)")
            .value_parser(clap::value_parser!(f32)))
        .get_matches();

    if matches.get_flag("list-models") {
        let models = get_models();
        println!("Available ElevenLabs Models:");
        println!("{}", "=".repeat(80));

        for (model_id, info) in models {
            println!("\nModel ID: {}", model_id);
            println!("Name: {}", info["name"].as_str().unwrap_or(""));
            println!("Description: {}", info["description"].as_str().unwrap_or(""));
            println!("Languages: {}", info["languages"].as_u64().unwrap_or(0));
            println!("Supports language_code: {}",
                if info["supports_language_code"].as_bool().unwrap_or(false) { "YES" } else { "NO" });
            println!("Latency: {}", info["latency"].as_str().unwrap_or(""));
        }

        println!("\n{}", "=".repeat(80));
        println!("Note: Only Flash v2.5 and Turbo v2.5 support the language_code parameter!");
        return Ok(());
    }

    if matches.get_flag("list-languages") {
        let languages = get_language_codes();
        println!("Common language codes for ElevenLabs:");
        println!("{}", "-".repeat(40));

        let mut sorted_langs: Vec<_> = languages.iter().collect();
        sorted_langs.sort_by_key(|&(code, _)| code);

        for (code, name) in sorted_langs {
            println!("{}: {}", code, name);
        }

        println!("\nIMPORTANT NOTES:");
        println!("- Language codes ONLY work with eleven_turbo_v2_5 and eleven_flash_v2_5 models");
        println!("- For other models (like eleven_multilingual_v2), the language is auto-detected from text");
        println!("- For best results with non-English, write your text in the target language");
        return Ok(());
    }

    let api_key = env::var("ELEVENLABS_API_KEY")
        .map_err(|_| anyhow::anyhow!("ELEVENLABS_API_KEY environment variable not set"))?;

    let client = Client::new();

    if matches.get_flag("list-voices") {
        list_voices(&client, &api_key).await?;
        return Ok(());
    }

    let text = if let Some(text_args) = matches.get_many::<String>("text") {
        text_args.map(|s| s.as_str()).collect::<Vec<_>>().join(" ")
    } else {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer.trim().to_string()
    };

    if text.is_empty() {
        eprintln!("Error: No text provided");
        process::exit(1);
    }

    let voice_input = matches.get_one::<String>("voice").unwrap();
    let voice_id = resolve_voice_id(&client, &api_key, voice_input).await?;

    let model = matches.get_one::<String>("model").unwrap();
    let language_code = matches.get_one::<String>("language").map(|s| s.as_str());
    let stability = *matches.get_one::<f32>("stability").unwrap();
    let similarity_boost = *matches.get_one::<f32>("similarity-boost").unwrap();
    let speed = matches.get_one::<f32>("speed").copied();

    if let Some(lang) = language_code {
        let languages = get_language_codes();
        if !languages.contains_key(lang) && lang.len() != 2 {
            eprintln!("Warning: '{}' may not be a valid language code. Use --list-languages to see common codes.", lang);
        }
        eprintln!("Using language code: {}", lang);
    }

    text_to_speech(&client, &api_key, &text, &voice_id, model, language_code, stability, similarity_boost, speed).await?;

    Ok(())
}