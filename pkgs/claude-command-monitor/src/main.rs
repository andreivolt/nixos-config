use anyhow::Result;
use clap::Parser;
use futures::StreamExt;
use notify::{Event, EventKind, RecursiveMode, Watcher};
use serde_json::Value;
use std::fs::OpenOptions;
use std::io::Write;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;

#[derive(Parser)]
#[command(name = "claude-command-monitor")]
#[command(about = "Monitor Claude project files for ommands")]
struct Args {
    /// Write commands to zsh history file (~/.local/state/zsh/history)
    #[arg(short, long)]
    write_history: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let claude_dir = dirs::home_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?
        .join(".config/claude/projects");

    eprintln!("Monitoring: {} (write_to_history: {})", claude_dir.display(), args.write_history);

    let (tx, rx) = mpsc::channel(100);

    let mut watcher = notify::recommended_watcher(move |res: Result<Event, notify::Error>| {
        if let Ok(event) = res {
            if matches!(event.kind, EventKind::Modify(_) | EventKind::Create(_)) {
                event
                    .paths
                    .into_iter()
                    .filter(|path| path.extension().map_or(false, |ext| ext == "jsonl"))
                    .for_each(|path| {
                        let _ = tx.blocking_send(path);
                    });
            }
        }
    })?;

    watcher.watch(&claude_dir, RecursiveMode::Recursive)?;

    let mut stream = ReceiverStream::new(rx);

    while let Some(path) = stream.next().await {
        if let Some(commands) = process_file(path).await {
            for cmd in commands {
                println!("{}", cmd);

                if args.write_history {
                    if let Err(e) = write_to_zsh_history(&cmd) {
                        eprintln!("Failed to write to history: {}", e);
                    }
                }
            }
        }
    }

    Ok(())
}

async fn process_file(path: std::path::PathBuf) -> Option<Vec<String>> {
    let content = std::fs::read_to_string(&path).ok()?;
    let last_line = content.lines().last()?;
    let json = serde_json::from_str::<Value>(last_line).ok()?;
    extract_bash_commands(&json)
}

fn extract_bash_commands(json: &Value) -> Option<Vec<String>> {
    let commands: Vec<String> = json
        .get("message")?
        .get("content")?
        .as_array()?
        .iter()
        .filter_map(|item| {
            if item.get("name")?.as_str() == Some("Bash") {
                item.get("input")?.get("command")?.as_str().map(String::from)
            } else {
                None
            }
        })
        .collect();

    if commands.is_empty() {
        None
    } else {
        Some(commands)
    }
}

fn write_to_zsh_history(command: &str) -> Result<()> {
    let history_file = dirs::home_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?
        .join(".local/state/zsh/history");

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)?
        .as_secs();

    let entry = format!(": {}:0;{}\n", timestamp, command);

    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(history_file)?;

    file.write_all(entry.as_bytes())?;

    Ok(())
}