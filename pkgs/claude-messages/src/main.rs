use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::Path;
use std::process::{Command, Stdio};
use std::sync::Mutex;
use walkdir::WalkDir;
use simd_json::owned::Value;
use simd_json::prelude::*;
use rayon::prelude::*;
use clap::{Parser, Subcommand};
use std::sync::OnceLock;

static MESSAGES: OnceLock<Vec<(String, String)>> = OnceLock::new();

#[derive(Parser)]
#[command(name = "claude-messages")]
#[command(about = "Search and view Claude conversation messages")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Show message at given index (used by fzf preview)
    Preview { index: usize },
}

fn extract_text_content(content: &Value) -> Option<String> {
    match content {
        Value::String(s) => Some(s.clone()),
        Value::Array(arr) => {
            let text_parts: Vec<String> = arr
                .iter()
                .filter_map(|item| {
                    let obj = item.as_object()?;
                    if obj.get("type")?.as_str()? == "text" {
                        Some(obj.get("text")?.as_str()?.to_string())
                    } else {
                        None
                    }
                })
                .collect();

            if text_parts.is_empty() {
                None
            } else {
                Some(text_parts.join("\n"))
            }
        }
        _ => None,
    }
}

fn parse_message_line(line: String) -> Option<(String, String, String)> {
    let mut line_bytes = line.into_bytes();
    let data = simd_json::from_slice::<Value>(&mut line_bytes).ok()?;

    let message = data.get("message")?;
    let role = message.get("role")?.as_str()?;

    if role != "user" && role != "assistant" {
        return None;
    }

    let content = message.get("content")?;
    let text = extract_text_content(content)?;

    let timestamp = data.get("timestamp")
        .and_then(|t| t.as_str())
        .unwrap_or("1970-01-01T00:00:00Z")
        .to_string();

    let full_text = format!("{}: {}", role, text);
    let single_line = format!("{}: {}", role, text.replace('\n', " "));

    Some((timestamp, single_line, full_text))
}

fn get_files_by_recency() -> Vec<std::path::PathBuf> {
    let claude_dir = dirs::home_dir()
        .map(|h| h.join(".claude/projects"))
        .unwrap_or_else(|| Path::new(".").to_path_buf());

    let mut files: Vec<_> = WalkDir::new(&claude_dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter_map(|e| {
            let metadata = e.metadata().ok()?;
            if metadata.len() > 100 && e.path().extension().map_or(false, |ext| ext == "jsonl") {
                let modified = metadata.modified().ok()?;
                Some((e.path().to_path_buf(), modified))
            } else {
                None
            }
        })
        .collect();

    // Sort by modification time, most recent first
    files.sort_by(|(_, time_a), (_, time_b)| time_b.cmp(time_a));
    files.into_iter().map(|(path, _)| path).collect()
}

fn stream_messages_to_fzf(fzf_stdin: &mut std::process::ChildStdin) {
    use std::io::Write;

    let files = get_files_by_recency();
    let mut all_messages = Vec::new();
    let mut index = 0;

    for file_path in files {
        if let Ok(file) = File::open(&file_path) {
            let reader = BufReader::new(file);

            let mut file_messages: Vec<_> = reader
                .lines()
                .filter_map(|l| l.ok())
                .filter_map(parse_message_line)
                .collect();

            // Sort messages within this file by timestamp (most recent first)
            file_messages.sort_by(|(time_a, _, _), (time_b, _, _)| time_b.cmp(time_a));

            for (_, single_line, full_text) in file_messages {
                // Stream to fzf immediately
                if writeln!(fzf_stdin, "{}:{}", index, single_line).is_err() {
                    // fzf closed early, store what we have and return
                    MESSAGES.set(all_messages).ok();
                    return;
                }

                all_messages.push((single_line, full_text));
                index += 1;
            }
        }
    }

    // Store all messages for preview access
    MESSAGES.set(all_messages).ok();
}

fn get_claude_messages() -> Vec<(String, String)> {
    let files = get_files_by_recency();
    let messages_with_time = Mutex::new(Vec::new());

    files.par_iter().for_each(|file_path| {
        if let Ok(file) = File::open(file_path) {
            let reader = BufReader::new(file);

            let local_messages: Vec<_> = reader
                .lines()
                .filter_map(|l| l.ok())
                .filter_map(parse_message_line)
                .collect();

            if !local_messages.is_empty() {
                messages_with_time.lock().unwrap().extend(local_messages);
            }
        }
    });

    let mut messages_with_time = messages_with_time.into_inner().unwrap();
    messages_with_time.sort_by(|(time_a, _, _), (time_b, _, _)| time_b.cmp(time_a));
    messages_with_time.into_iter().map(|(_, single_line, full_text)| (single_line, full_text)).collect()
}

fn main() {
    use std::env;

    let cli = Cli::parse();

    // Handle preview subcommand
    if let Some(Commands::Preview { index }) = cli.command {
        // Try to get from cached messages first, fallback to full load
        if let Some(messages) = MESSAGES.get() {
            if let Some((_, full_text)) = messages.get(index) {
                print!("{}", full_text);
                return;
            }
        }

        // Fallback to full load if not cached
        let messages = get_claude_messages();
        if let Some((_, full_text)) = messages.get(index) {
            print!("{}", full_text);
        } else {
            eprintln!("Debug: Index {} not found, total messages: {}", index, messages.len());
            if !messages.is_empty() {
                eprintln!("Debug: First message preview: {}", &messages[0].1[..std::cmp::min(100, messages[0].1.len())]);
            }
        }
        return;
    }

    let messages = get_claude_messages();

    if messages.is_empty() {
        eprintln!("No messages found");
        std::process::exit(1);
    }

    // Check if stdout is a pipe/redirect (non-interactive)
    use std::io::IsTerminal;
    if !std::io::stdout().is_terminal() {
        for (_, full_text) in &messages {
            println!("{}", full_text);
        }
        return;
    }

    let script_path = env::current_exe()
        .unwrap_or_else(|_| std::path::PathBuf::from("claude-messages"));

    let preview_script = format!(
        "echo {{}} | sed 's/:.*$//' | xargs {} preview",
        script_path.to_string_lossy()
    );

    let mut fzf = Command::new("fzf")
        .arg("--bind")
        .arg("ctrl-y:execute-silent(echo {} | sed \"s/^[^:]*: //\" | pbcopy)")
        .arg("--tiebreak=index")
        .arg("--preview")
        .arg(&preview_script)
        .arg("--preview-window")
        .arg("right:50%:wrap")
        .arg("--with-nth")
        .arg("2..")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to start fzf");

    if let Some(mut stdin) = fzf.stdin.take() {
        // Stream messages to fzf in order of recency
        stream_messages_to_fzf(&mut stdin);
    }

    if let Ok(output) = fzf.wait_with_output() {
        if output.status.success() {
            let selected = String::from_utf8_lossy(&output.stdout);
            if let Some(colon_pos) = selected.find(':') {
                print!("{}", &selected[colon_pos + 1..]);
            }
        }
    }
}