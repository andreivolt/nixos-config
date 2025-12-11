
use clap::Parser;
use rayon::prelude::*;
use std::fs;
use std::io::{self, Read, Write};
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};
use walkdir::WalkDir;

/// Whitespace trimming tool that handles trailing whitespace and empty lines
#[derive(Parser)]
#[command(about = "Trim trailing whitespace and empty lines from files", long_about = None)]
struct Args {
    /// Files or directories to process (reads from stdin if no paths provided)
    paths: Vec<String>,

    /// Edit files in place (required for files, optional confirmation for directories)
    #[arg(short, long)]
    in_place: bool,

    /// Skip confirmation prompts
    #[arg(short = 'f', long)]
    force: bool,
}

fn trim_whitespace(s: &str) -> String {
    let had_final_newline = s.ends_with('\n');
    let mut result = s.lines()
        .map(|line| line.trim_end())  // This handles both cases!
        .collect::<Vec<_>>()
        .join("\n");

    if had_final_newline {
        result.push('\n');
    }

    result
}

fn prompt_for_confirmation(dir: &Path) -> io::Result<bool> {
    print!("Process directory {} and all its files? [y/N] ", dir.display());
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;

    let input = input.trim().to_lowercase();
    Ok(input == "y" || input == "yes")
}

fn process_file<P: AsRef<Path>>(path: P, in_place: bool) -> io::Result<String> {
    let content = fs::read_to_string(&path)?;
    let trimmed = trim_whitespace(&content);

    if content == trimmed {
        return Ok("unchanged".to_string());
    }

    if in_place {
        fs::write(&path, &trimmed)?;
        Ok("trimmed".to_string())
    } else {
        Ok(trimmed)
    }
}

fn process_directory<P: AsRef<Path>>(path: P) -> io::Result<()> {
    let files: Vec<_> = WalkDir::new(path.as_ref())
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().is_file())
        .map(|e| e.path().to_owned())
        .collect();

    let count = AtomicUsize::new(0);
    let total = files.len();

    println!("Processing {} files in {}...", total, path.as_ref().display());

    files.par_iter().for_each(|file| {
        match process_file(file, true) {
            Ok(status) => {
                if status == "trimmed" {
                    let processed = count.fetch_add(1, Ordering::Relaxed) + 1;
                    println!("Trimmed: {}", file.display());
                    if processed % 100 == 0 {
                        println!("Processed {}/{} files", processed, total);
                    }
                }
            },
            Err(e) => eprintln!("Error processing {}: {}", file.display(), e)
        }
    });

    let trimmed_count = count.load(Ordering::Relaxed);
    if trimmed_count > 0 {
        println!("Trimmed whitespace from {} files", trimmed_count);
    } else {
        println!("No files needed trimming");
    }

    Ok(())
}

fn main() -> io::Result<()> {
    let args = Args::parse();

    if args.paths.is_empty() {
        // Process stdin
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        let trimmed = trim_whitespace(&buffer);
        io::stdout().write_all(trimmed.as_bytes())?;
    } else {
        // Process each argument
        for arg in &args.paths {
            let path = Path::new(arg);

            if path.is_dir() {
                if args.force || prompt_for_confirmation(path)? {
                    process_directory(path)?;
                } else {
                    println!("Skipping directory: {}", path.display());
                }
            } else if path.is_file() {
                if args.in_place {
                    match process_file(path, true)? {
                        status if status == "trimmed" => println!("Trimmed: {}", path.display()),
                        _ => println!("No changes needed for: {}", path.display())
                    }
                } else {
                    let output = process_file(path, false)?;
                    if output != "unchanged" {
                        println!("{}", output);
                    } else {
                        // This was a status message
                        println!("No changes needed for: {}", path.display());
                    }
                }
            } else {
                eprintln!("Error: '{}' is not a file or directory", arg);
            }
        }
    }

    Ok(())
}