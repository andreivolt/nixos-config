use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::fs::File;
use std::process::{Command, Stdio};
use std::thread;

#[derive(Debug, Deserialize)]
struct Event {
    #[serde(rename = "type")]
    event_type: String,
    timestamp: String,
    cwd: Option<String>,
    message: Option<Message>,
    #[serde(rename = "toolUseResult")]
    _tool_use_result: Option<Value>,
}

#[derive(Debug, Deserialize)]
struct Message {
    content: Option<Value>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FileCreation {
    path: String,
    pwd: String,
    _timestamp: String,
    session_path: PathBuf,
    content: Option<String>,
}

#[derive(Serialize, Deserialize)]
struct CachedItem {
    path: String,
    hash: String,
    session_name: String,
    filename: String,
    content: String,
}

fn find_jsonl_files() -> Vec<PathBuf> {
    let claude_dir = dirs::home_dir()
        .unwrap()
        .join(".claude/projects");

    std::fs::read_dir(&claude_dir)
        .map(|entries| {
            entries
                .flatten()
                .filter(|entry| entry.path().is_dir())
                .filter_map(|entry| std::fs::read_dir(entry.path()).ok())
                .flat_map(|entries| entries.flatten())
                .map(|entry| entry.path())
                .filter(|path| path.extension().and_then(|s| s.to_str()) == Some("jsonl"))
                .collect()
        })
        .unwrap_or_default()
}

fn extract_file_operations(content_array: &[Value]) -> Vec<(String, Option<String>)> {
    content_array
        .iter()
        .filter(|item| item.get("type").and_then(|t| t.as_str()) == Some("tool_use"))
        .filter_map(|item| {
            let tool_name = item.get("name")?.as_str()?;
            if !matches!(tool_name, "Write" | "MultiEdit" | "Edit") {
                return None;
            }

            let input = item.get("input")?;
            let file_path = input.get("file_path")?.as_str()?.to_string();
            let content = match tool_name {
                "Edit" => input.get("new_string"),
                _ => input.get("content")
            }?.as_str().map(|s| s.to_string());

            Some((file_path, content))
        })
        .collect()
}

fn extract_file_creations(jsonl_path: &Path) -> Vec<FileCreation> {
    let mut creations = Vec::new();

    if let Ok(file) = File::open(jsonl_path) {
        let reader = BufReader::new(file);
        let mut current_pwd = String::from("unknown");

        reader
            .lines()
            .flatten()
            .filter_map(|line| serde_json::from_str::<Event>(&line).ok())
            .for_each(|event| {
                if let Some(cwd) = &event.cwd {
                    current_pwd = cwd.clone();
                }

                if event.event_type == "assistant" {
                    let operations = event.message
                        .as_ref()
                        .and_then(|m| m.content.as_ref())
                        .and_then(|c| c.as_array())
                        .map(|arr| extract_file_operations(arr))
                        .unwrap_or_default();

                    creations.extend(operations.into_iter().map(|(file_path, content)| FileCreation {
                        path: file_path,
                        pwd: current_pwd.clone(),
                        _timestamp: event.timestamp.clone(),
                        session_path: jsonl_path.to_path_buf(),
                        content,
                    }));
                }
            });
    }

    creations
}

fn get_cache_path() -> PathBuf {
    std::env::temp_dir().join("claude-files-cache.json")
}

fn get_cache_timestamp() -> std::time::SystemTime {
    let cache_path = get_cache_path();
    if let Ok(metadata) = std::fs::metadata(&cache_path) {
        metadata.modified().unwrap_or(std::time::UNIX_EPOCH)
    } else {
        std::time::UNIX_EPOCH
    }
}

fn get_newest_jsonl_timestamp() -> std::time::SystemTime {
    find_jsonl_files()
        .iter()
        .filter_map(|path| std::fs::metadata(path).ok())
        .filter_map(|metadata| metadata.modified().ok())
        .max()
        .unwrap_or(std::time::UNIX_EPOCH)
}

fn load_cache() -> Option<Vec<CachedItem>> {
    let cache_path = get_cache_path();

    if let Ok(content) = std::fs::read_to_string(&cache_path) {
        serde_json::from_str(&content).ok()
    } else {
        None
    }
}

fn cache_is_stale() -> bool {
    let cache_time = get_cache_timestamp();
    let newest_jsonl_time = get_newest_jsonl_timestamp();
    cache_time <= newest_jsonl_time
}

fn build_cache_in_background() {
    thread::spawn(|| {
        let jsonl_files = find_jsonl_files();
        let mut all_creations = Vec::new();

        for jsonl_path in &jsonl_files {
            all_creations.extend(extract_file_creations(jsonl_path));
        }

        if all_creations.is_empty() {
            return;
        }

        // Sort creations: group by path, then by content size (descending)
        all_creations.sort_by(|a, b| {
            match a.path.cmp(&b.path) {
                std::cmp::Ordering::Equal => {
                    // Same file path - sort by content size (larger first)
                    let size_a = a.content.as_ref().map(|c| c.len()).unwrap_or(0);
                    let size_b = b.content.as_ref().map(|c| c.len()).unwrap_or(0);
                    size_b.cmp(&size_a)
                }
                other => other
            }
        });

        // Build cache items
        let cache_items: Vec<CachedItem> = all_creations
            .iter()
            .filter_map(|creation| {
                creation.content.as_ref().map(|content| {
                    let hash = format!("{:x}", md5::compute(content))[..6].to_string();
                    let filename = std::path::Path::new(&creation.path)
                        .file_name()
                        .and_then(|n| n.to_str())
                        .unwrap_or("unnamed")
                        .to_string();
                    let session_name = creation.session_path
                        .file_stem()
                        .and_then(|s| s.to_str())
                        .unwrap_or("unknown")
                        .to_string();

                    CachedItem {
                        path: creation.path.clone(),
                        hash,
                        session_name,
                        filename,
                        content: content.clone(),
                    }
                })
            })
            .collect();

        save_cache(&cache_items);
    });
}

fn save_cache(items: &[CachedItem]) {
    let cache_path = get_cache_path();
    if let Ok(content) = serde_json::to_string(items) {
        let _ = std::fs::write(&cache_path, content);
    }
}

fn extract_hash(s: &str) -> Option<&str> {
    s.rfind('[')
        .zip(s.rfind(']'))
        .map(|(start, end)| &s[start + 1..end])
}

fn main() {
    // Handle preview mode FIRST (before checking if piped) - use cache for efficiency
    if std::env::args().len() > 1 && std::env::args().nth(1).as_deref() == Some("--preview") {
        let preview_line = std::env::args().nth(2).unwrap_or_default();

        let hash = extract_hash(&preview_line);

        if let Some(hash) = hash {
            // Try to load from cache first
            if let Some(item) = load_cache().and_then(|items| items.into_iter().find(|item| item.hash == hash)) {
                println!("File: {}\nSession: {}\n{}\n\n{}",
                    item.filename,
                    item.session_name,
                    "-".repeat(50),
                    item.content);
                return;
            }

            // Fallback to full parsing if not in cache
            let all_creations: Vec<_> = find_jsonl_files()
                .iter()
                .flat_map(|path| extract_file_creations(path))
                .collect();

                for creation in &all_creations {
                    let content_hash = if let Some(content) = &creation.content {
                        let full_hash = format!("{:x}", md5::compute(content));
                        full_hash[..6].to_string()
                    } else {
                        "------".to_string()
                    };

                    if content_hash == hash {
                        let filename = std::path::Path::new(&creation.path)
                            .file_name()
                            .and_then(|n| n.to_str())
                            .unwrap_or("unnamed");

                        let session_name = creation.session_path
                            .file_stem()
                            .and_then(|s| s.to_str())
                            .unwrap_or("unknown");

                        if let Some(content) = &creation.content {
                            println!("File: {}\nSession: {}\n{}\n\n{}",
                                filename,
                                session_name,
                                "-".repeat(50),
                                content);
                        } else {
                            println!("(content not available)");
                        }
                        return;
                    }
                }
        }

        println!("Preview not found for: {}", preview_line);
        return;
    }

    // Try to load existing cache
    let cached_items = load_cache().unwrap_or_else(Vec::new);

    // If cache is stale or empty, start background rebuild
    if cached_items.is_empty() || cache_is_stale() {
        build_cache_in_background();
    }

    // Check if stdout is piped before using fzf
    let is_piped = !atty::is(atty::Stream::Stdout);

    if is_piped {
        // If output is piped, just output all content directly
        if cached_items.is_empty() {
            // No cache available yet when piping
            return;
        }
        for item in &cached_items {
            println!("{}", item.content);
        }
        return;
    }

    // Prepare items for fzf
    let items: Vec<String> = cached_items
        .iter()
        .map(|item| {
            format!("{} [{}]", item.path, item.hash)
        })
        .collect();

    // Run fzf with multi-select and preview
    let script_path = std::env::args().next().unwrap();
    let preview_cmd = format!("{} --preview {{}}", script_path);

    let mut fzf = Command::new("fzf")
        .args(&[
            "--multi",
            "--preview-window", "right:50%:wrap",
            "--preview", &preview_cmd,
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .expect("Failed to start fzf");

    // Send items to fzf
    {
        let stdin = fzf.stdin.as_mut().unwrap();
        for item in &items {
            writeln!(stdin, "{}", item).unwrap();
        }
    }

    // Get fzf output
    let output = fzf.wait_with_output().expect("Failed to read fzf output");

    if !output.status.success() {
        return; // User cancelled
    }

    let selected_items: Vec<String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.to_string())
        .collect();

    if selected_items.is_empty() {
        return;
    }

    // Interactive mode: save files to current directory
    selected_items
        .iter()
        .filter_map(|selected_item| extract_hash(selected_item))
        .filter_map(|hash| cached_items.iter().find(|item| item.hash == hash))
        .for_each(|item| {
            let target_path = std::path::Path::new(&item.filename);

            // Check if file exists and prompt for overwrite
            if target_path.exists() {
                eprint!("File '{}' already exists. Overwrite? [y/N] ", item.filename);
                std::io::stderr().flush().unwrap();

                let mut response = String::new();
                std::io::stdin().read_line(&mut response).unwrap();

                if !response.trim().eq_ignore_ascii_case("y") {
                    eprintln!("Skipping {}", item.filename);
                    return;
                }
            }

            // Write the file
            match std::fs::write(&target_path, &item.content) {
                Ok(_) => eprintln!("Saved: {}", item.filename),
                Err(e) => eprintln!("Error saving {}: {}", item.filename, e),
            }
        });
}