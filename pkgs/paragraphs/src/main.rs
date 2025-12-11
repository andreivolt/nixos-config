
use std::env;
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::exit;
use tiktoken_rs::{cl100k_base, CoreBPE};
use sha2::{Sha256, Digest};
use directories::ProjectDirs;
use genai::chat::{ChatMessage, ChatRequest, ChatOptions};
use genai::Client;

const MAX_TOKENS: usize = 60000;

fn get_cache_dir() -> PathBuf {
    if let Some(proj_dirs) = ProjectDirs::from("", "", "paragraphs") {
        proj_dirs.cache_dir().to_path_buf()
    } else {
        PathBuf::from(".cache/paragraphs")
    }
}

fn hash_text(text: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(text.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn chunk_text(text: &str, tokenizer: &CoreBPE) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let tokens = tokenizer.encode_with_special_tokens(text);
    let mut chunks = Vec::new();

    for i in (0..tokens.len()).step_by(MAX_TOKENS) {
        let end = (i + MAX_TOKENS).min(tokens.len());
        let chunk_tokens = &tokens[i..end];
        let chunk_text = tokenizer.decode(chunk_tokens.to_vec())?;
        chunks.push(chunk_text);
    }

    Ok(chunks)
}

async fn split_into_paragraphs_cached(text: &str) -> Result<String, Box<dyn std::error::Error>> {
    // Create cache directory if it doesn't exist
    let cache_dir = get_cache_dir();
    fs::create_dir_all(&cache_dir)?;

    // Check cache
    let text_hash = hash_text(text);
    let cache_file = cache_dir.join(format!("{}.txt", text_hash));

    if cache_file.exists() {
        return Ok(fs::read_to_string(cache_file)?);
    }

    // Process text
    let tokenizer = cl100k_base()?;
    let chunks = chunk_text(text, &tokenizer)?;
    let mut processed_chunks = Vec::new();

    // Initialize genai client
    let client = Client::default();

    let mut options = ChatOptions::default();
    options.temperature = Some(0.3);

    for chunk in chunks {
        let prompt = format!(
            "Split this text into meaningful paragraphs. Each paragraph should represent a coherent topic or thought. Return only the formatted text with proper paragraph breaks (double newlines between paragraphs).\n\nText:\n{}",
            chunk
        );

        let chat_req = ChatRequest::new(vec![
            ChatMessage::system("You are a helpful assistant that splits text into meaningful paragraphs."),
            ChatMessage::user(prompt),
        ]);

        let chat_res = client
            .exec_chat("gemini-2.5-flash", chat_req, Some(&options))
            .await?;

        if let Some(content) = chat_res.content_text_as_str() {
            processed_chunks.push(content.trim().to_string());
        }
    }

    let result = processed_chunks.join("\n\n");

    // Cache result
    fs::write(cache_file, &result)?;

    Ok(result)
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = env::args().collect();

    let mut text = String::new();

    if args.len() > 1 {
        // Read from file
        match fs::read_to_string(&args[1]) {
            Ok(content) => text = content,
            Err(_) => {
                eprintln!("Error: File '{}' not found", args[1]);
                exit(1);
            }
        }
    } else {
        // Read from stdin
        match io::stdin().read_to_string(&mut text) {
            Ok(_) => {},
            Err(e) => {
                eprintln!("Error reading from stdin: {}", e);
                exit(1);
            }
        }
    }

    if text.trim().is_empty() {
        eprintln!("Error: No input text provided");
        exit(1);
    }

    match split_into_paragraphs_cached(&text).await {
        Ok(result) => println!("{}", result),
        Err(e) => {
            eprintln!("Error: {}", e);
            exit(1);
        }
    }
}