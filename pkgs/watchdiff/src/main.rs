use notify::{Config, Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::Mutex;
use clap::{Arg, Command};
use anyhow::{Context, Result};
use similar::{ChangeTag, TextDiff};
use syntect::easy::HighlightLines;
use syntect::highlighting::ThemeSet;
use syntect::parsing::SyntaxSet;
use syntect::util::as_24_bit_terminal_escaped;
use crossterm::{
    style::{Color, ResetColor, SetBackgroundColor},
    ExecutableCommand,
};
use std::io::{self, Write};
use console::Term;

type FileContents = Arc<Mutex<HashMap<PathBuf, String>>>;

fn is_binary_file(path: &Path) -> bool {
    if let Ok(content) = fs::read(path) {
        // Check first 8192 bytes for null bytes (common binary indicator)
        content.iter().take(8192).any(|&byte| byte == 0)
    } else {
        false
    }
}

fn get_file_extension(path: &Path) -> Option<&str> {
    path.extension().and_then(|ext| ext.to_str())
}

fn highlight_diff(old_content: &str, new_content: &str, file_path: &Path) -> Result<()> {
    let syntax_set = SyntaxSet::load_defaults_newlines();
    let theme_set = ThemeSet::load_defaults();
    let theme = &theme_set.themes["base16-ocean.dark"];

    let extension = get_file_extension(file_path).unwrap_or("txt");
    let syntax = syntax_set
        .find_syntax_by_extension(extension)
        .or_else(|| {
            // Try some fallbacks for common extensions
            match extension {
                "kt" | "kts" => syntax_set.find_syntax_by_extension("java"), // Use Java syntax for Kotlin
                "tsx" | "jsx" => syntax_set.find_syntax_by_extension("js"),
                "vue" => syntax_set.find_syntax_by_extension("html"),
                _ => None
            }
        })
        .unwrap_or_else(|| syntax_set.find_syntax_plain_text());


    let diff = TextDiff::from_lines(old_content, new_content);

    println!("\n{}", "=".repeat(80));
    println!("📁 File: {}", file_path.display());
    println!("{}", "=".repeat(80));

    let mut stdout = io::stdout();
    let term = Term::stdout();
    let _term_width = term.size().1 as usize;

    const CONTEXT_LINES: usize = 3;
    let changes: Vec<_> = diff.iter_all_changes().collect();
    let mut i = 0;

    while i < changes.len() {
        // Find the next change (non-equal)
        let change_start = changes[i..]
            .iter()
            .position(|c| c.tag() != ChangeTag::Equal)
            .map(|pos| i + pos);

        if let Some(start) = change_start {
            // Find where this group of changes ends
            let change_end = changes[start..]
                .iter()
                .position(|c| c.tag() == ChangeTag::Equal)
                .map(|pos| start + pos)
                .unwrap_or(changes.len());

            // Show context before changes
            let context_start = start.saturating_sub(CONTEXT_LINES);
            for j in context_start..start {
                let change = &changes[j];
                let line = change.value();
                let mut highlighter = HighlightLines::new(syntax, theme);
                let highlighted = highlighter.highlight_line(line, &syntax_set)
                    .context("Failed to highlight line")?;

                print!("  ");
                for (style, text) in highlighted.iter() {
                    print!("{}", as_24_bit_terminal_escaped(&[(style.clone(), text)], false));
                }
            }

            // Show the actual changes
            for j in start..change_end {
                let change = &changes[j];
                let line = change.value();
                let mut highlighter = HighlightLines::new(syntax, theme);
                let highlighted = highlighter.highlight_line(line, &syntax_set)
                    .context("Failed to highlight line")?;

                match change.tag() {
                    ChangeTag::Delete => {
                        stdout.execute(SetBackgroundColor(Color::Rgb { r: 64, g: 0, b: 0 }))?; // Dark red background
                        print!("- ");
                        for (style, text) in highlighted.iter() {
                            print!("{}", as_24_bit_terminal_escaped(&[(style.clone(), text)], false));
                        }
                        stdout.execute(ResetColor)?;
                        if !line.ends_with('\n') {
                            println!();
                        }
                    }
                    ChangeTag::Insert => {
                        stdout.execute(SetBackgroundColor(Color::Rgb { r: 0, g: 64, b: 0 }))?; // Dark green background
                        print!("+ ");
                        for (style, text) in highlighted.iter() {
                            print!("{}", as_24_bit_terminal_escaped(&[(style.clone(), text)], false));
                        }
                        stdout.execute(ResetColor)?;
                        if !line.ends_with('\n') {
                            println!();
                        }
                    }
                    ChangeTag::Equal => {
                        print!("  ");
                        for (style, text) in highlighted.iter() {
                            print!("{}", as_24_bit_terminal_escaped(&[(style.clone(), text)], false));
                        }
                    }
                }
            }

            // Show context after changes
            let context_end = (change_end + CONTEXT_LINES).min(changes.len());
            for j in change_end..context_end {
                let change = &changes[j];
                let line = change.value();
                let mut highlighter = HighlightLines::new(syntax, theme);
                let highlighted = highlighter.highlight_line(line, &syntax_set)
                    .context("Failed to highlight line")?;

                print!("  ");
                for (style, text) in highlighted.iter() {
                    print!("{}", as_24_bit_terminal_escaped(&[(style.clone(), text)], false));
                }
            }

            // Skip to after the context
            i = context_end;

            // Add separator if there are more changes
            if i < changes.len() && changes[i..].iter().any(|c| c.tag() != ChangeTag::Equal) {
                println!("...");
            }
        } else {
            break;
        }
    }

    stdout.flush()?;
    Ok(())
}

async fn handle_file_event(
    event: Event,
    file_contents: FileContents,
) -> Result<()> {
    if let EventKind::Modify(_) = event.kind {
        for path in event.paths {
            if path.is_file() && !is_binary_file(&path) {
                // Add small delay to ensure file is fully written
                tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

                if let Ok(new_content) = fs::read_to_string(&path) {
                    let mut contents = file_contents.lock().await;

                    if let Some(old_content) = contents.get(&path) {
                        if old_content != &new_content {
                            if let Err(e) = highlight_diff(old_content, &new_content, &path) {
                                eprintln!("Error highlighting diff: {}", e);
                            }
                        }
                    }

                    contents.insert(path.clone(), new_content);
                }
            }
        }
    }
    Ok(())
}

async fn initialize_file_contents(
    dir: &Path,
    file_contents: FileContents,
) -> Result<()> {
    fn visit_dir(dir: &Path, contents: &mut HashMap<PathBuf, String>) -> Result<()> {
        if dir.is_dir() {
            for entry in fs::read_dir(dir)? {
                let entry = entry?;
                let path = entry.path();

                if path.is_dir() {
                    visit_dir(&path, contents)?;
                } else if path.is_file() && !is_binary_file(&path) {
                    if let Ok(content) = fs::read_to_string(&path) {
                        contents.insert(path, content);
                    }
                }
            }
        }
        Ok(())
    }

    let mut contents = file_contents.lock().await;
    visit_dir(dir, &mut contents)?;
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let matches = Command::new("Directory Monitor")
        .version("1.0")
        .about("Monitors a directory for file changes and shows syntax-highlighted diffs")
        .arg(
            Arg::new("directory")
                .help("Directory to monitor")
                .value_name("DIR")
                .default_value(".")
                .index(1),
        )
        .get_matches();

    let watch_path = matches.get_one::<String>("directory").unwrap();
    let watch_path = Path::new(watch_path);

    if !watch_path.exists() {
        anyhow::bail!("Directory does not exist: {}", watch_path.display());
    }

    println!("🔍 Monitoring directory: {}", watch_path.display());
    println!("📝 Watching for changes...");
    println!("Press Ctrl+C to stop\n");

    let file_contents: FileContents = Arc::new(Mutex::new(HashMap::new()));

    // Initialize with current file contents
    initialize_file_contents(watch_path, file_contents.clone()).await?;

    let (tx, mut rx) = tokio::sync::mpsc::channel(100);
    let file_contents_clone = file_contents.clone();

    // Set up file watcher
    let mut watcher = RecommendedWatcher::new(
        move |result: Result<Event, notify::Error>| {
            if let Ok(event) = result {
                let _ = tx.blocking_send(event);
            }
        },
        Config::default(),
    )?;

    watcher.watch(watch_path, RecursiveMode::Recursive)?;

    // Handle events
    while let Some(event) = rx.recv().await {
        if let Err(e) = handle_file_event(event, file_contents_clone.clone()).await {
            eprintln!("Error handling file event: {}", e);
        }
    }

    Ok(())
}