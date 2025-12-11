
use std::collections::HashMap;
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::exit;
use std::sync::Arc;
use tiktoken_rs::{cl100k_base, get_bpe_from_model, CoreBPE};
use sha2::{Sha256, Digest};
use directories::ProjectDirs;
use genai::chat::{ChatMessage, ChatRequest, ChatOptions};
use genai::Client;
use clap::Parser;
use futures::future::join_all;
use regex::Regex;

#[derive(Parser)]
#[command(name = "translate")]
#[command(about = "Translate text using AI models")]
struct Args {
    #[arg(short = 't', long, help = "Target language for translation")]
    target_lang: String,

    #[arg(short = 'm', long, default_value = "gemini-2.5-flash", help = "Model to use")]
    model: String,

    #[arg(long, default_value = "2000", help = "Max tokens per chunk")]
    max_tokens: usize,

    #[arg(short = 'v', long, help = "Verbose output")]
    verbose: bool,

    #[arg(short = 'l', long, default_value = "en", help = "Source language")]
    lang: String,

    #[arg(short = 'p', long, help = "Additional context or adjustments for translation")]
    prompt: Option<String>,

    #[arg(long, default_value = "5", help = "Maximum number of parallel requests")]
    max_parallel: usize,
}

struct TextChunker {
    max_tokens: usize,
    tokenizer: CoreBPE,
    sentence_endings: Regex,
}

impl TextChunker {
    fn new(max_tokens: usize, model: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let tokenizer = match get_bpe_from_model(model) {
            Ok(bpe) => bpe,
            Err(_) => cl100k_base()?,
        };

        let sentence_endings = Regex::new(r"[.!?]+\s+")?;

        Ok(TextChunker {
            max_tokens,
            tokenizer,
            sentence_endings,
        })
    }

    fn count_tokens(&self, text: &str) -> usize {
        self.tokenizer.encode_with_special_tokens(text).len()
    }

    fn split_into_sentences(&self, text: &str) -> Vec<String> {
        self.sentence_endings
            .split(text)
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect()
    }

    fn chunk_by_sentences(&self, text: &str) -> Vec<String> {
        let sentences = self.split_into_sentences(text);
        let mut chunks = Vec::new();
        let mut current_chunk = Vec::new();
        let mut current_tokens = 0;

        for sentence in sentences {
            let sentence_tokens = self.count_tokens(&sentence);

            if sentence_tokens > self.max_tokens {
                if !current_chunk.is_empty() {
                    chunks.push(current_chunk.join(" "));
                    current_chunk.clear();
                    current_tokens = 0;
                }
                chunks.push(sentence);
            } else if current_tokens + sentence_tokens > self.max_tokens {
                if !current_chunk.is_empty() {
                    chunks.push(current_chunk.join(" "));
                }
                current_chunk = vec![sentence];
                current_tokens = sentence_tokens;
            } else {
                current_chunk.push(sentence);
                current_tokens += sentence_tokens;
            }
        }

        if !current_chunk.is_empty() {
            chunks.push(current_chunk.join(" "));
        }

        chunks
    }
}

fn get_cache_dir() -> PathBuf {
    if let Some(proj_dirs) = ProjectDirs::from("", "", "translate") {
        proj_dirs.cache_dir().to_path_buf()
    } else {
        PathBuf::from(".cache/translate")
    }
}

fn hash_request(chunk: &str, target_lang: &str, model: &str, custom_prompt: &Option<String>) -> String {
    let mut hasher = Sha256::new();
    hasher.update(chunk.as_bytes());
    hasher.update(target_lang.as_bytes());
    hasher.update(model.as_bytes());
    if let Some(prompt) = custom_prompt {
        hasher.update(prompt.as_bytes());
    }
    format!("{:x}", hasher.finalize())
}

async fn translate_chunk_cached(
    chunk: String,
    target_lang: String,
    model: String,
    custom_prompt: Option<String>,
    client: Arc<Client>,
    chunk_id: usize,
) -> (usize, Result<String, String>) {
    let cache_dir = get_cache_dir();
    if let Err(e) = fs::create_dir_all(&cache_dir) {
        return (chunk_id, Err(format!("Failed to create cache directory: {}", e)));
    }

    let cache_hash = hash_request(&chunk, &target_lang, &model, &custom_prompt);
    let cache_file = cache_dir.join(format!("{}.txt", cache_hash));

    if cache_file.exists() {
        if let Ok(cached_result) = fs::read_to_string(&cache_file) {
            return (chunk_id, Ok(cached_result));
        }
    }

    let base_prompt = format!("Translate the following text to {}.", target_lang);
    let full_prompt = if let Some(custom) = &custom_prompt {
        format!("{}\n\n{}", base_prompt, custom)
    } else {
        base_prompt
    };

    let prompt = format!(
        "{}
Only output the translation, no explanations or comments.

Text to translate:
{}",
        full_prompt, chunk
    );

    let chat_req = ChatRequest::new(vec![
        ChatMessage::system("You are a helpful translation assistant."),
        ChatMessage::user(prompt),
    ]);

    let mut options = ChatOptions::default();
    options.temperature = Some(0.3);

    match client.exec_chat(&model, chat_req, Some(&options)).await {
        Ok(chat_res) => {
            if let Some(content) = chat_res.content_text_as_str() {
                let result = content.trim().to_string();
                let _ = fs::write(&cache_file, &result);
                (chunk_id, Ok(result))
            } else {
                (chunk_id, Err("No content in response".to_string()))
            }
        }
        Err(e) => (chunk_id, Err(format!("Translation error: {}", e))),
    }
}

async fn parallel_translate(
    chunks: Vec<String>,
    target_lang: String,
    model: String,
    custom_prompt: Option<String>,
    max_parallel: usize,
) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = Arc::new(Client::default());
    let semaphore = Arc::new(tokio::sync::Semaphore::new(max_parallel));

    let tasks: Vec<_> = chunks
        .into_iter()
        .enumerate()
        .map(|(i, chunk)| {
            let client = Arc::clone(&client);
            let target_lang = target_lang.clone();
            let model = model.clone();
            let custom_prompt = custom_prompt.clone();
            let semaphore = Arc::clone(&semaphore);

            tokio::spawn(async move {
                let _permit = semaphore.acquire().await.unwrap();
                translate_chunk_cached(chunk, target_lang, model, custom_prompt, client, i).await
            })
        })
        .collect();

    let results = join_all(tasks).await;
    let mut translations: HashMap<usize, String> = HashMap::new();

    for result in results {
        match result {
            Ok((chunk_id, Ok(translation))) => {
                translations.insert(chunk_id, translation);
            }
            Ok((chunk_id, Err(error))) => {
                translations.insert(chunk_id, format!("[ERROR translating chunk {}: {}]", chunk_id, error));
            }
            Err(e) => {
                return Err(format!("Task execution error: {}", e).into());
            }
        }
    }

    let mut sorted_translations: Vec<_> = translations.into_iter().collect();
    sorted_translations.sort_by_key(|&(id, _)| id);

    Ok(sorted_translations.into_iter().map(|(_, translation)| translation).collect())
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    let mut text = String::new();

    match io::stdin().read_to_string(&mut text) {
        Ok(_) => {},
        Err(e) => {
            eprintln!("Error reading from stdin: {}", e);
            exit(1);
        }
    }

    if text.trim().is_empty() {
        eprintln!("Error: No input text provided");
        exit(1);
    }

    let chunker = match TextChunker::new(args.max_tokens, &args.model) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error initializing chunker: {}", e);
            exit(1);
        }
    };

    if args.verbose {
        eprintln!("Chunking text with max {} tokens per chunk...", args.max_tokens);
        eprintln!("Source language: {}", args.lang);
    }

    let chunks = chunker.chunk_by_sentences(&text);

    if args.verbose {
        eprintln!("Created {} chunks", chunks.len());
        for (i, chunk) in chunks.iter().enumerate() {
            let tokens = chunker.count_tokens(chunk);
            eprintln!("  Chunk {}: {} tokens", i + 1, tokens);
        }
        eprintln!("\nTranslating to {} using {}...", args.target_lang, args.model);
        eprintln!("Max parallel requests: {}", args.max_parallel);
    }

    match parallel_translate(chunks, args.target_lang, args.model, args.prompt, args.max_parallel).await {
        Ok(translations) => {
            let output = translations.join("\n\n");
            println!("{}", output);

            if args.verbose {
                eprintln!("\nTranslation complete!");
            }
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            exit(1);
        }
    }
}