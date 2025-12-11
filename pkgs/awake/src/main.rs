use anyhow::{Context, Result};
use clap::Parser;
use duct::cmd;
use signal_hook::{consts::{SIGINT, SIGTERM}, iterator::Signals};
use std::process;
use std::thread;

#[derive(Parser)]
#[command(about = "Control KeepingYouAwake on macOS")]
struct Cli {
    /// Action: on, off, or minutes (number implies on)
    action: Option<String>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let (action, minutes, should_wait) = if let Some(arg) = cli.action {
        if let Ok(mins) = arg.parse::<u32>() {
            ("activate", Some(mins), false)
        } else {
            match arg.as_str() {
                "on" => ("activate", None, false),
                "off" => ("deactivate", None, false),
                _ => {
                    eprintln!("Invalid action: {}. Use 'on', 'off', or a number of minutes.", arg);
                    process::exit(1);
                }
            }
        }
    } else {
        ("activate", None, true)
    };

    let url = format!("keepingyouawake:///{action}{}",
        minutes.map_or(String::new(), |m| format!("?minutes={m}")));


    // Check if caffeinate is already running
    let is_running = cmd!("pgrep", "-f", "caffeinate")
        .stdout_null()
        .stderr_null()
        .run()
        .is_ok();

    if action == "activate" {
        if is_running {
            if !should_wait && minutes.is_none() {
                // For "awake on", just return if already running
                return Ok(());
            } else {
                // For "awake" (interactive) or "awake <minutes>", deactivate first to replace
                let _ = cmd!("open", "--background", "keepingyouawake:///deactivate").run();
                std::thread::sleep(std::time::Duration::from_millis(100));
            }
        }
    }

    cmd!("open", "--background", &url)
        .run()
        .context("Failed to open KeepingYouAwake URL")?;

    if action == "activate" && minutes.is_none() && should_wait {
        println!("☕ Staying awake indefinitely. Press Ctrl+C to stop.");

        // Handle both SIGINT (Ctrl+C) and SIGTERM (timeout)
        thread::spawn(move || {
            let mut signals = Signals::new(&[SIGINT, SIGTERM]).unwrap();
            for _ in signals.forever() {
                println!("\n😴 Stopping awake mode...");
                let _ = cmd!("open", "--background", "keepingyouawake:///deactivate").run();
                process::exit(0);
            }
        });

        loop {
            std::thread::sleep(std::time::Duration::from_secs(1));
        }
    }

    Ok(())
}
