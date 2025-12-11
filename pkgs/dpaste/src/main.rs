
use anyhow::Result;
use clap::Parser;
use std::io::{self, Read};

#[derive(Parser)]
#[command(about = "Upload text to dpaste.org")]
struct Args {
    /// File to upload (reads from stdin if not provided)
    file: Option<String>,

    /// Syntax highlighting
    #[arg(short, long, default_value = "text")]
    syntax: String,

    /// Title for the paste
    #[arg(short, long, default_value = "")]
    title: String,

    /// Expiry in days (1, 7, 30, 365)
    #[arg(short, long, default_value = "7", value_parser = validate_expiry)]
    expiry: u32,

    /// Open URL in browser
    #[arg(short, long)]
    open: bool,

    /// Copy URL to clipboard
    #[arg(short, long)]
    copy: bool,
}

fn validate_expiry(s: &str) -> Result<u32, String> {
    match s.parse::<u32>() {
        Ok(days) if [1, 7, 30, 365].contains(&days) => Ok(days),
        _ => Err("Expiry must be 1, 7, 30, or 365 days".to_string()),
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let content = match &args.file {
        Some(path) => std::fs::read_to_string(path)?,
        None => {
            let mut buffer = String::new();
            io::stdin().read_to_string(&mut buffer)?;
            buffer
        }
    };

    let client = reqwest::Client::new();
    let form = reqwest::multipart::Form::new()
        .text("content", content)
        .text("syntax", args.syntax)
        .text("title", args.title)
        .text("expiry_days", args.expiry.to_string());

    let response = client
        .post("https://dpaste.org/api/")
        .multipart(form)
        .send()
        .await?;

    let url = response.text().await?;
    let raw_url = format!("{}/raw", url.trim().trim_matches('"'));

    if args.copy {
        let mut clipboard_success = false;

        // Try native clipboard first if not on Android/Termux
        #[cfg(not(target_os = "android"))]
        {
            if let Ok(mut cb) = arboard::Clipboard::new() {
                if cb.set_text(&raw_url).is_ok() {
                    clipboard_success = true;
                }
            }
        }

        // If native clipboard failed or on Android, try termux-clipboard-set
        if !clipboard_success {
            if let Ok(_) = std::process::Command::new("termux-clipboard-set")
                .stdin(std::process::Stdio::piped())
                .spawn()
                .and_then(|mut child| {
                    use std::io::Write;
                    if let Some(stdin) = child.stdin.as_mut() {
                        stdin.write_all(raw_url.as_bytes())?;
                    }
                    child.wait()
                }) {
                eprintln!("Copied to clipboard using termux-clipboard-set");
            } else {
                eprintln!("Warning: Failed to copy to clipboard");
                eprintln!("On Termux: Install Termux:API app and termux-api package for clipboard support");
            }
        }
    }

    if args.open {
        if let Err(_) = std::process::Command::new("open").arg(&raw_url).spawn() {
            // Termux fallback: use termux-open-url
            if let Err(_) = std::process::Command::new("termux-open-url").arg(&raw_url).spawn() {
                // Try xdg-open as another fallback
                if let Err(_) = std::process::Command::new("xdg-open").arg(&raw_url).spawn() {
                    eprintln!("Warning: Failed to open URL in browser");
                    eprintln!("Fallback: Install termux-tools or manually open: {}", raw_url);
                }
            }
        }
    }

    println!("{}", raw_url);
    Ok(())
}