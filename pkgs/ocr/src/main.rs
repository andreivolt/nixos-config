
use anyhow::{anyhow, Result};
use base64::{engine::general_purpose, Engine as _};
use clap::Parser;
use copypasta::{ClipboardContext, ClipboardProvider};
use genai::chat::{ChatMessage, ChatRequest, MessageContent, ContentPart, ChatOptions};
use genai::Client;
use is_terminal::IsTerminal;
use mime_guess::from_path;
use std::fs;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::Command;
use tempfile::NamedTempFile;

#[derive(Parser)]
#[command(name = "ocr")]
#[command(about = "Extract text from images using AI vision models")]
#[command(arg_required_else_help = false)]
struct Args {
    /// Image file to extract text from (defaults to stdin if not provided)
    image_file: Option<PathBuf>,

    /// Preserve original layout as closely as possible
    #[arg(short, long)]
    layout: bool,

    /// Custom prompt to append to the default OCR prompt
    #[arg(short, long)]
    prompt: Option<String>,

    /// Copy text to clipboard
    #[arg(short, long)]
    copy: bool,

    /// Take a screenshot first using the screenshot script
    #[arg(short, long)]
    screenshot: bool,

    /// LLM model to use for OCR (e.g., gpt-4o, claude-3-5-sonnet-20241022)
    #[arg(short, long, default_value = "gemini-2.5-flash")]
    model: String,
}

fn get_mime_type(file_path: &PathBuf) -> Option<String> {
    from_path(file_path).first().map(|mime| mime.to_string())
}

fn take_screenshot() -> Result<PathBuf> {
    let temp_file = NamedTempFile::with_suffix(".png")?;
    let temp_path = temp_file.path().to_path_buf();

    let output = Command::new("screenshot")
        .arg("selection")
        .arg(&temp_path)
        .output()?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow!("Screenshot command failed: {}", stderr));
    }

    if !temp_path.exists() || fs::metadata(&temp_path)?.len() == 0 {
        return Err(anyhow!("Screenshot was not created or is empty"));
    }

    // Keep the file alive by forgetting the NamedTempFile
    std::mem::forget(temp_file);
    Ok(temp_path)
}

async fn run_ocr(
    image_path: &PathBuf,
    layout_mode: bool,
    custom_prompt: Option<&str>,
    model: &str,
) -> Result<String> {
    let function_description = "You are an AI assistant specialized in optical character recognition (OCR) and text extraction from images.";

    let base_prompt = if layout_mode {
        "OCR this image and preserve the original layout as closely as possible. Maintain spacing, alignment, and visual structure exactly as shown in the image."
    } else {
        "OCR this image and extract just the text. Return only the extracted text with no additional formatting, explanation, or commentary."
    };

    let prompt = if let Some(custom) = custom_prompt {
        format!("{}\n\n{}\n\nAdditional instructions: {}", function_description, base_prompt, custom)
    } else {
        format!("{}\n\n{}", function_description, base_prompt)
    };

    let mime_type = get_mime_type(image_path)
        .ok_or_else(|| anyhow!("Could not determine MIME type for '{}'", image_path.display()))?;

    if !mime_type.starts_with("image/") {
        return Err(anyhow!("'{}' is not an image file (detected: {})", image_path.display(), mime_type));
    }

    // Read and encode image
    let image_data = fs::read(image_path)?;
    let base64_image = general_purpose::STANDARD.encode(&image_data);

    // Create chat request with image using base64 method
    let parts = vec![
        ContentPart::from_text(prompt),
        ContentPart::from_image_base64(&mime_type, base64_image)
    ];
    let content = MessageContent::from_parts(parts);
    let chat_req = ChatRequest::new(vec![
        ChatMessage::user(content)
    ]);

    let client = Client::default();
    let model_name = model;

    // Check if we have the necessary API key for the model
    let needs_api_key = match model_name {
        m if m.starts_with("gpt") => std::env::var("OPENAI_API_KEY").is_err(),
        m if m.starts_with("claude") => std::env::var("ANTHROPIC_API_KEY").is_err(),
        m if m.starts_with("gemini") => std::env::var("GEMINI_API_KEY").is_err(),
        _ => false,
    };

    if needs_api_key {
        return Err(anyhow!("API key not found for model '{}'", model_name));
    }

    // Use temperature 0 for deterministic OCR results
    let options = ChatOptions::default().with_temperature(0.0);

    let chat_res = client.exec_chat(model_name, chat_req, Some(&options)).await
        .map_err(|e| anyhow!("LLM request failed: {}", e))?;

    Ok(chat_res.content_text_as_str().unwrap_or("NO ANSWER").to_string())
}

fn extract_code_blocks(text: &str) -> Vec<String> {
    use regex::Regex;

    let re = Regex::new(r"```[^\n]*\n([\s\S]*?)```").unwrap();
    re.captures_iter(text)
        .map(|cap| cap[1].trim().to_string())
        .collect()
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let image_path = if args.screenshot {
        if args.image_file.is_some() {
            return Err(anyhow!("Cannot specify both --screenshot and image file"));
        }
        take_screenshot()?
    } else if let Some(path) = args.image_file {
        if !path.exists() {
            return Err(anyhow!("File '{}' not found", path.display()));
        }
        if !path.is_file() {
            return Err(anyhow!("'{}' is not a file", path.display()));
        }
        path
    } else {
        // Read from stdin
        if io::stdin().is_terminal() {
            return Err(anyhow!("No image file specified and stdin is empty"));
        }

        let mut data = Vec::new();
        io::stdin().read_to_end(&mut data)?;
        if data.is_empty() {
            return Err(anyhow!("No data received from stdin"));
        }

        // Try to detect image type from data
        let suffix = if data.starts_with(&[0x89, 0x50, 0x4E, 0x47]) {
            ".png"
        } else if data.starts_with(&[0xFF, 0xD8, 0xFF]) {
            ".jpg"
        } else if data.starts_with(b"GIF89a") || data.starts_with(b"GIF87a") {
            ".gif"
        } else if data.starts_with(b"RIFF") && data.len() > 11 && &data[8..12] == b"WEBP" {
            ".webp"
        } else {
            // Default to PNG as it's most common for screenshots
            ".png"
        };

        let temp_file = NamedTempFile::with_suffix(suffix)?;
        fs::write(temp_file.path(), data)?;
        let temp_path = temp_file.path().to_path_buf();
        std::mem::forget(temp_file); // Keep file alive
        temp_path
    };

    let result = run_ocr(&image_path, args.layout, args.prompt.as_deref(), &args.model).await?;

    // Extract code blocks if present
    let extracted = extract_code_blocks(&result);
    let output = if !extracted.is_empty() {
        extracted.join("\n\n")
    } else {
        result.clone()
    };

    if args.copy {
        let mut ctx = ClipboardContext::new()
            .map_err(|e| anyhow!("Failed to access clipboard: {}", e))?;
        ctx.set_contents(output.clone())
            .map_err(|e| anyhow!("Failed to copy to clipboard: {}", e))?;
        println!("Text copied to clipboard");
    } else {
        print!("{}", output);
    }

    Ok(())
}