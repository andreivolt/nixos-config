use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::Mutex;
use walkdir::WalkDir;
use simd_json::owned::Value;
use simd_json::prelude::*;
use rayon::prelude::*;
use fuzzy_matcher::FuzzyMatcher;
use fuzzy_matcher::skim::SkimMatcherV2;
use clap::Parser;
use colored::*;
use chrono::{DateTime, Utc};

#[derive(Parser)]
#[command(name = "claude-sessions")]
#[command(about = "Fuzzy search Claude Code sessions")]
struct Args {
    /// Search query
    query: Option<String>,
}

#[derive(Debug, Clone)]
struct SessionInfo {
    session_id: String,
    file_path: PathBuf,
    project_name: String,
    summary: String,
    last_cwd: String,
    message_count: usize,
    created: DateTime<Utc>,
    last_modified: DateTime<Utc>,
}

fn get_session_info(jsonl_path: &Path) -> Option<SessionInfo> {
    let file = File::open(jsonl_path).ok()?;
    let reader = BufReader::new(file);

    let mut session_id = String::new();
    let mut summary = String::new();
    let mut last_cwd = String::new();
    let mut message_count = 0;
    let mut created: Option<DateTime<Utc>> = None;
    let mut last_modified: Option<DateTime<Utc>> = None;

    // Read first and last few lines for efficiency
    let lines: Vec<_> = reader.lines().filter_map(|l| l.ok()).collect();

    if lines.is_empty() {
        return None;
    }

    // Process first few lines for metadata
    for line in lines.iter().take(10) {
        let mut line_bytes = line.clone().into_bytes();
        if let Ok(data) = simd_json::from_slice::<Value>(&mut line_bytes) {
            message_count += 1;

            // Get session ID
            if session_id.is_empty() {
                if let Some(sid) = data.get("sessionId").and_then(|v| v.as_str()) {
                    session_id = sid.to_string();
                }
            }

            // Get summary from first line
            if summary.is_empty() {
                if let Some(sum) = data.get("summary").and_then(|v| v.as_str()) {
                    summary = sum.to_string();
                }
            }

            // Get created timestamp
            if created.is_none() {
                if let Some(ts) = data.get("timestamp").and_then(|v| v.as_str()) {
                    created = DateTime::parse_from_rfc3339(ts).ok().map(|dt| dt.with_timezone(&Utc));
                }
            }

            // Get working directory
            if let Some(cwd) = data.get("cwd").and_then(|v| v.as_str()) {
                last_cwd = cwd.to_string();
            }
            if let Some(wd) = data.get("workingDirectory").and_then(|v| v.as_str()) {
                last_cwd = wd.to_string();
            }
        }
    }

    // Process last few lines for final state
    let start_idx = if lines.len() > 10 { lines.len() - 10 } else { 0 };
    for line in &lines[start_idx..] {
        let mut line_bytes = line.clone().into_bytes();
        if let Ok(data) = simd_json::from_slice::<Value>(&mut line_bytes) {
            // Get last working directory
            if let Some(cwd) = data.get("cwd").and_then(|v| v.as_str()) {
                last_cwd = cwd.to_string();
            }
            if let Some(wd) = data.get("workingDirectory").and_then(|v| v.as_str()) {
                last_cwd = wd.to_string();
            }

            // Get last modified timestamp
            if let Some(ts) = data.get("timestamp").and_then(|v| v.as_str()) {
                last_modified = DateTime::parse_from_rfc3339(ts).ok().map(|dt| dt.with_timezone(&Utc));
            }
        }
    }

    message_count = lines.len();

    // Use file modification time if no timestamp found
    let file_modified = jsonl_path.metadata().ok()
        .and_then(|meta| meta.modified().ok())
        .map(|time| DateTime::<Utc>::from(time));

    let project_name = jsonl_path.parent()
        .and_then(|p| p.file_name())
        .map(|n| {
            let name = n.to_string_lossy();
            // Remove the claude projects path prefix if it starts with it
            if name.starts_with("-Users-") {
                name.strip_prefix("-Users-").unwrap_or(&name).to_string()
            } else {
                name.to_string()
            }
        })
        .unwrap_or_else(|| "unknown".to_string());

    Some(SessionInfo {
        session_id: jsonl_path.file_stem()?.to_string_lossy().to_string(),
        file_path: jsonl_path.to_path_buf(),
        project_name,
        summary: if summary.is_empty() {
            "No summary".to_string()
        } else {
            summary
        },
        last_cwd: if last_cwd.is_empty() {
            "Unknown".to_string()
        } else {
            last_cwd
        },
        message_count,
        created: created.or(file_modified).unwrap_or_else(|| Utc::now()),
        last_modified: last_modified.or(file_modified).unwrap_or_else(|| Utc::now()),
    })
}

fn collect_all_sessions() -> Vec<SessionInfo> {
    let claude_base = dirs::home_dir()
        .map(|h| h.join(".claude/projects"))
        .unwrap_or_else(|| Path::new(".").to_path_buf());

    let sessions = Mutex::new(Vec::new());

    // Find all JSONL files
    let jsonl_files: Vec<_> = WalkDir::new(&claude_base)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().map_or(false, |ext| ext == "jsonl"))
        .collect();

    jsonl_files.par_iter().for_each(|entry| {
        if let Some(session_info) = get_session_info(entry.path()) {
            sessions.lock().unwrap().push(session_info);
        }
    });

    let mut sessions = sessions.into_inner().unwrap();
    // Sort by last modified (most recent first)
    sessions.sort_by(|a, b| b.last_modified.cmp(&a.last_modified));
    sessions
}

fn fuzzy_search<'a>(sessions: &'a [SessionInfo], query: &str) -> Vec<(usize, &'a SessionInfo)> {
    let matcher = SkimMatcherV2::default();
    let mut matches = Vec::new();

    for (index, session) in sessions.iter().enumerate() {
        // Create searchable text combining multiple fields
        let searchable = format!(
            "{} {} {} {} {}",
            session.summary,
            session.last_cwd,
            session.project_name,
            session.session_id,
            session.file_path.file_stem().unwrap_or_default().to_string_lossy()
        );

        if let Some(score) = matcher.fuzzy_match(&searchable, query) {
            matches.push((score, index, session));
        }
    }

    // Sort by fuzzy match score (highest first)
    matches.sort_by(|a, b| b.0.cmp(&a.0));

    matches.into_iter().map(|(_, index, session)| (index, session)).collect()
}

fn run_fzf(sessions: &[SessionInfo]) -> Option<&SessionInfo> {
    // Prepare fzf input
    let fzf_input: Vec<String> = sessions
        .iter()
        .enumerate()
        .map(|(_i, session)| {
            let created_str = session.created.format("%Y-%m-%d").to_string();
            let modified_str = session.last_modified.format("%Y-%m-%d %H:%M").to_string();
            let project_short = if session.project_name.len() > 30 {
                format!("{}...", &session.project_name[..27])
            } else {
                session.project_name.clone()
            };
            let summary_short = if session.summary.len() > 40 {
                format!("{}...", &session.summary[..37])
            } else {
                session.summary.clone()
            };

            format!(
                "{:<12} │ {:<16} │ {:>4} msgs │ {}",
                created_str,
                modified_str,
                session.message_count,
                summary_short
            )
        })
        .collect();

    let mut fzf = Command::new("fzf")
        .args(&[
            "--prompt=Select Claude session: ",
            "--header=CREATED │ LAST_MODIFIED │ MSGS │ SUMMARY",
            "--delimiter=│",
            "--height=80%",
            "--preview-window=hidden",
            "--ansi",
            "--with-nth=1.."
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .ok()?;

    if let Some(mut stdin) = fzf.stdin.take() {
        for (i, line) in fzf_input.iter().enumerate() {
            if writeln!(stdin, "{}:{}", i, line).is_err() {
                break;
            }
        }
    }

    if let Ok(output) = fzf.wait_with_output() {
        if output.status.success() {
            let selected = String::from_utf8_lossy(&output.stdout);
            if let Some(colon_pos) = selected.find(':') {
                if let Ok(index) = selected[..colon_pos].parse::<usize>() {
                    return sessions.get(index);
                }
            }
        }
    }

    None
}

fn fix_session_cwds(session: &SessionInfo) {
    let current_dir = std::env::current_dir().unwrap();
    // Resolve symlinks to get the real path (match Claude CLI's behavior)
    let real_current_dir = std::fs::canonicalize(&current_dir).unwrap_or(current_dir);
    let current_dir_str = real_current_dir.to_string_lossy();

    // Only fix if the session's CWD is different from current directory
    if session.last_cwd == current_dir_str {
        return;
    }

    eprintln!("{} Fixing CWDs: {} → {}", "✓".green(), session.last_cwd, current_dir_str);

    // Calculate the correct project directory (match Claude CLI's behavior)
    // Claude CLI resolves symlinks and converts @ to - in email addresses
    let expected_project_name = current_dir_str
        .replace('/', "-")
        .replace('@', "-");
    let claude_base = dirs::home_dir()
        .map(|h| h.join(".claude/projects"))
        .unwrap_or_else(|| Path::new(".").to_path_buf());
    let expected_project_dir = claude_base.join(&expected_project_name);

    // Create the project directory if it doesn't exist
    if !expected_project_dir.exists() {
        eprintln!("{} Creating project directory: {}", "✓".green(), expected_project_name);
        std::fs::create_dir_all(&expected_project_dir).ok();
    }

    // Calculate new session file path
    let session_filename = session.file_path.file_name().unwrap();
    let new_session_path = expected_project_dir.join(session_filename);

    // Read all lines
    let file = match File::open(&session.file_path) {
        Ok(f) => f,
        Err(_) => return,
    };

    let reader = BufReader::new(file);
    let mut updated_lines = Vec::new();
    let mut update_count = 0;

    for line in reader.lines().filter_map(|l| l.ok()) {
        let mut line_bytes = line.clone().into_bytes();
        if let Ok(mut data) = simd_json::from_slice::<Value>(&mut line_bytes) {
            let mut updated = false;

            // Update cwd field
            if let Some(cwd) = data.get_mut("cwd") {
                if cwd.as_str() == Some(&session.last_cwd) {
                    *cwd = Value::String(current_dir_str.to_string());
                    updated = true;
                }
            }

            // Update workingDirectory field
            if let Some(wd) = data.get_mut("workingDirectory") {
                if wd.as_str() == Some(&session.last_cwd) {
                    *wd = Value::String(current_dir_str.to_string());
                    updated = true;
                }
            }

            if updated {
                update_count += 1;
                updated_lines.push(simd_json::to_string(&data).unwrap_or(line));
            } else {
                updated_lines.push(line);
            }
        } else {
            updated_lines.push(line);
        }
    }

    // Write to the correct project directory
    if let Ok(mut file) = std::fs::File::create(&new_session_path) {
        for line in updated_lines {
            writeln!(file, "{}", line).ok();
        }
    }

    // Remove the old session file if it's in a different location
    if new_session_path != session.file_path {
        std::fs::remove_file(&session.file_path).ok();
        eprintln!("{} Moved session to correct project directory", "✓".green());
    }

    if update_count > 0 {
        eprintln!("{} Updated {} CWD references", "✓".green(), update_count);
    }
}

fn main() {
    let args = Args::parse();

    println!("{}", "Collecting Claude sessions...".dimmed());
    let sessions = collect_all_sessions();

    if sessions.is_empty() {
        println!("{}", "No Claude sessions found.".yellow());
        return;
    }

    println!("{} Found {} sessions", "✓".green(), sessions.len());

    let filtered_sessions: Vec<&SessionInfo> = if let Some(query) = args.query {
        let matches = fuzzy_search(&sessions, &query);
        println!("{} Filtered to {} matches for '{}'", "✓".green(), matches.len(), query);
        matches.into_iter().map(|(_, session)| session).collect()
    } else {
        sessions.iter().collect()
    };

    // Convert to owned sessions for fzf
    let sessions_for_fzf: Vec<SessionInfo> = filtered_sessions.iter().map(|s| (*s).clone()).collect();

    if let Some(selected) = run_fzf(&sessions_for_fzf) {
        // Fix CWDs in the session file to match current directory
        fix_session_cwds(&selected);
        println!("{}", selected.session_id);
    }
}