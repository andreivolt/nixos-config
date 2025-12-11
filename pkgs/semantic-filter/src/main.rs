use clap::Parser;
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use sha2::{Digest, Sha256};

#[derive(Parser)]
#[command(name = "semantic-filter")]
#[command(about = "Filter text semantically based on a prompt using LLM")]
struct Args {
    /// The prompt to filter by
    prompt: String,

    /// Filter by paragraphs instead of lines
    #[arg(short, long)]
    paragraphs: bool,

    /// Return only top N most relevant items
    #[arg(short = 'n', long)]
    top_n: Option<usize>,

    /// LLM model to use
    #[arg(short, long, default_value = "gpt-4o")]
    model: String,

    /// Show reasoning
    #[arg(short, long)]
    verbose: bool,
}

#[derive(Serialize, Deserialize)]
struct CacheEntry {
    result: String,
}

fn get_cache_dir() -> PathBuf {
    dirs::cache_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("semantic-filter")
}

fn get_cache_key(text: &str, filter_prompt: &str, model: &str, paragraphs: bool, top_n: Option<usize>, verbose: bool) -> String {
    let mut hasher = Sha256::new();
    hasher.update(text.as_bytes());
    hasher.update(filter_prompt.as_bytes());
    hasher.update(model.as_bytes());
    hasher.update(&[paragraphs as u8]);
    hasher.update(&top_n.unwrap_or(0).to_le_bytes());
    hasher.update(&[verbose as u8]);
    hex::encode(hasher.finalize())
}

fn load_cache(cache_key: &str) -> Option<String> {
    let cache_dir = get_cache_dir();
    let cache_file = cache_dir.join(format!("{}.json", cache_key));

    if let Ok(content) = fs::read_to_string(&cache_file) {
        if let Ok(entry) = serde_json::from_str::<CacheEntry>(&content) {
            return Some(entry.result);
        }
    }
    None
}

fn save_cache(cache_key: &str, result: &str) {
    let cache_dir = get_cache_dir();
    if let Err(_) = fs::create_dir_all(&cache_dir) {
        return;
    }

    let cache_file = cache_dir.join(format!("{}.json", cache_key));
    let entry = CacheEntry {
        result: result.to_string(),
    };

    if let Ok(json) = serde_json::to_string(&entry) {
        let _ = fs::write(&cache_file, json);
    }
}

fn filter_text(text: &str, filter_prompt: &str, model: &str, paragraphs: bool, top_n: Option<usize>, verbose: bool) -> Result<String, Box<dyn std::error::Error>> {
    let cache_key = get_cache_key(text, filter_prompt, model, paragraphs, top_n, verbose);

    if let Some(cached_result) = load_cache(&cache_key) {
        return Ok(cached_result);
    }

    let item_type = if paragraphs { "paragraphs" } else { "lines" };
    let top_n_instruction = if let Some(n) = top_n {
        format!("- Return at most {} most relevant items", n)
    } else {
        String::new()
    };

    let verbose_instruction = if verbose {
        "- First provide a brief reasoning section starting with \"REASONING:\" on its own line, then after a blank line provide the filtered text"
    } else {
        ""
    };

    let system_prompt = format!(
        "You are a semantic text filter. Given text content and a filter prompt, you must return only the parts that are semantically relevant to the prompt.

Filter prompt: {}

Instructions:
- Return the filtered text directly, not as JSON
- Keep only {} that are relevant to the filter prompt
- You can filter out off-topic sentences within paragraphs if needed
- Maintain the original formatting and structure
- Do not add any commentary or explanations
{}
{}

Respond with the filtered text only.",
        filter_prompt, item_type, top_n_instruction, verbose_instruction
    );

    let cmd = Command::new("llm")
        .arg("prompt")
        .arg("-m")
        .arg(model)
        .arg("-s")
        .arg(&system_prompt)
        .arg(text)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    let output = cmd.wait_with_output()?;

    if !output.status.success() {
        return Err(format!("LLM command failed: {}", String::from_utf8_lossy(&output.stderr)).into());
    }

    let result = String::from_utf8(output.stdout)?.trim().to_string();
    save_cache(&cache_key, &result);

    Ok(result)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let mut input_text = String::new();
    io::stdin().read_to_string(&mut input_text)?;

    let items: Vec<String> = if args.paragraphs {
        input_text
            .split("\n\n")
            .map(|p| p.trim().to_string())
            .filter(|p| !p.is_empty())
            .collect()
    } else {
        input_text
            .lines()
            .map(|line| line.trim().to_string())
            .filter(|line| !line.is_empty())
            .collect()
    };

    if items.is_empty() {
        return Ok(());
    }

    let formatted_text = if args.paragraphs {
        items.join("\n\n")
    } else {
        items.join("\n")
    };

    let result = filter_text(&formatted_text, &args.prompt, &args.model, args.paragraphs, args.top_n, args.verbose)?;

    // Handle verbose output
    let output = if args.verbose && result.starts_with("REASONING:") {
        if let Some(double_newline_pos) = result.find("\n\n") {
            let reasoning_part = &result[..double_newline_pos];
            let reasoning = reasoning_part.strip_prefix("REASONING:\n").unwrap_or(&reasoning_part[10..]);
            eprintln!("# Reasoning: {}\n", reasoning);
            &result[double_newline_pos + 2..]
        } else {
            &result
        }
    } else {
        &result
    };

    // Ensure blank lines between paragraphs
    let lines: Vec<&str> = output.split('\n').collect();
    let mut formatted_output = Vec::new();

    for line in lines {
        if !line.trim().is_empty() {
            formatted_output.push(line.to_string());
            formatted_output.push(String::new()); // Add blank line after each paragraph
        }
    }

    // Remove trailing blank line if present
    if formatted_output.last() == Some(&String::new()) {
        formatted_output.pop();
    }

    println!("{}", formatted_output.join("\n"));

    Ok(())
}