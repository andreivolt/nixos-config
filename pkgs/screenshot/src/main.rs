use anyhow::{Result, bail};
use chrono::Utc;
use clap::{Parser, ValueEnum};
use is_terminal::IsTerminal;
use std::{fs, io::{self, Write}, process::Command};
use tempfile;

#[derive(Parser)]
#[command(about = "Cross-platform screenshot tool")]
struct Args {
    #[arg(value_enum, default_value = "selection")]
    target: Target,

    #[arg(help = "Output filename (must end with .png)")]
    filename: Option<String>,
}

#[derive(Clone, ValueEnum)]
enum Target {
    Selection,
    Window,
    Full,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let filename = args.filename.filter(|f| f.ends_with(".png"));
    let (output_mode, auto_filename) = match (filename.as_ref(), io::stdout().is_terminal()) {
        (Some(_), _) => (OutputMode::File, None),
        (None, true) => {
            let timestamp = Utc::now().format("%Y-%m-%d_%H-%M-%S");
            let auto_name = format!("screenshot_{}.png", timestamp);
            (OutputMode::File, Some(auto_name))
        },
        (None, false) => (OutputMode::Stdout, None),
    };

    let (cmd, opt) = match (args.target, cfg!(target_os = "macos"), cfg!(target_os = "linux")) {
        (Target::Selection, true, _) => ("screencapture", "-i"),
        (Target::Window, true, _) => ("screencapture", "-Wo"),
        (Target::Full, true, _) => ("screencapture", ""),
        (Target::Selection, _, true) => ("grimshot", "save area"),
        (Target::Window, _, true) => ("grimshot", "save window"),
        (Target::Full, _, true) => ("grimshot", "save screen"),
        _ => bail!("Unsupported OS"),
    };

    let (file_path, _temp) = {
        let temp = tempfile::Builder::new()
            .prefix("screenshot-")
            .suffix(".png")
            .tempfile()?;
        let path = temp.path().to_path_buf();

        let capture_cmd = if cfg!(target_os = "macos") {
            format!("{cmd} {opt} {}", path.display())
        } else {
            format!("{cmd} {opt} {}", path.display())
        };

        Command::new("sh").arg("-c").arg(&capture_cmd).status()?;

        let result = match output_mode {
            OutputMode::Stdout => {
                io::stdout().write_all(&fs::read(&path)?)?;
                (None, Some(temp))
            }
            OutputMode::File => {
                let dest = filename.or(auto_filename).unwrap();
                fs::copy(&path, &dest)?;
                (Some(fs::canonicalize(&dest)?), Some(temp))
            }
        };

        result
    };

    if !matches!(output_mode, OutputMode::Stdout) {
        if let Some(path) = &file_path {
            println!("Screenshot saved to: {}", path.display());
        }

        let notify_cmd = if cfg!(target_os = "macos") {
            file_path.as_ref().map(|p| format!(
                "terminal-notifier -title 'Screenshot' -message 'Screenshot taken' -open 'file://{}' -contentImage '{}'",
                p.display(), p.display()
            ))
        } else {
            Some("notify-send 'Screenshot' 'Screenshot taken'".to_string())
        };

        if let Some(cmd) = notify_cmd {
            Command::new("sh").arg("-c").arg(&cmd).status()?;
        }
    }

    Ok(())
}

enum OutputMode {
    File,
    Stdout,
}