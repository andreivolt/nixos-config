
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
    if let Some(proj_dirs) = ProjectDirs::from("", "", "correct") {
        proj_dirs.cache_dir().to_path_buf()
    } else {
        PathBuf::from(".cache/correct")
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

async fn correct_text_cached(text: &str) -> Result<String, Box<dyn std::error::Error>> {
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
    options.temperature = Some(0.1);

    for chunk in chunks {
        let prompt = format!(
            "Fix only orthographic errors (spelling, punctuation, capitalization) and egregious grammatical errors in the following text.\n\nCRITICAL RULES:\n- Keep the original meaning and style intact\n- Do NOT rephrase or restructure sentences\n- Do NOT change vocabulary unless it's clearly misspelled\n- Only fix obvious spelling mistakes, missing punctuation, and clear grammatical errors\n- Preserve the author's voice and tone completely\n- If unsure whether something is an error, leave it unchanged\n\nText to correct:\n{}",
            chunk
        );

        let chat_req = ChatRequest::new(vec![
            ChatMessage::system("You are a careful proofreader who fixes only obvious errors while preserving the original text's style and meaning."),
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
        // Treat multiple args as text to correct
        text = args[1..].join(" ");
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

    match correct_text_cached(&text).await {
        Ok(result) => println!("{}", result),
        Err(e) => {
            eprintln!("Error: {}", e);
            exit(1);
        }
    }
}