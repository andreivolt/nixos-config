use clap::Parser;
use dialoguer::{theme::ColorfulTheme, Select};
use std::process::Command;

#[derive(Parser)]
#[command(about = "Change display resolution")]
struct Args {
    /// Set specific resolution (e.g., 1920x1080)
    resolution: Option<String>,
}

fn main() {
    let args = Args::parse();

    let (screen_id, resolutions) = get_resolutions();

    if let Some(target_res) = args.resolution {
        // Non-interactive mode
        if resolutions.iter().any(|res| res == &target_res) {
            apply_resolution(&screen_id, &target_res);
        } else {
            eprintln!("Resolution {} not available", target_res);
            eprintln!("Available: {}", resolutions.join(", "));
            std::process::exit(1);
        }
    } else {
        // Interactive mode
        if resolutions.is_empty() {
            eprintln!("No resolutions found with scaling:on");
            return;
        }

        let selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("Select a resolution:")
            .items(&resolutions)
            .default(0)
            .interact()
            .unwrap();

        apply_resolution(&screen_id, &resolutions[selection]);
    }
}

fn get_resolutions() -> (String, Vec<String>) {
    let output = Command::new("displayplacer")
        .arg("list")
        .output()
        .expect("Failed to run displayplacer");

    let content = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = content.lines().collect();

    let screen_id = lines.iter()
        .find(|line| line.starts_with("Persistent screen id:"))
        .and_then(|line| line.split(':').nth(1))
        .map(|s| s.trim().to_string())
        .unwrap_or_default();

    let mut resolutions: Vec<(u32, u32, String)> = lines.iter()
        .filter(|line| line.contains("mode ") && line.contains("scaling:on"))
        .filter_map(|line| {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if let Some(res_part) = parts.get(2) {
                if let Some(res) = res_part.split(':').nth(1) {
                    let dims: Vec<&str> = res.split('x').collect();
                    if dims.len() == 2 {
                        if let (Ok(width), Ok(height)) = (dims[0].parse::<u32>(), dims[1].parse::<u32>()) {
                            return Some((width, height, res.to_string()));
                        }
                    }
                }
            }
            None
        })
        .collect();

    // Sort by width descending, then height descending
    resolutions.sort_by(|a, b| b.0.cmp(&a.0).then(b.1.cmp(&a.1)));

    // Remove duplicates by width, keeping the one with highest height
    let mut seen_widths = std::collections::HashSet::new();
    resolutions.retain(|(width, _, _)| seen_widths.insert(*width));

    let resolution_strings: Vec<String> = resolutions.into_iter().map(|(_, _, res)| res).collect();

    (screen_id, resolution_strings)
}

fn apply_resolution(screen_id: &str, resolution: &str) {
    let command = format!(
        "displayplacer 'id:{} res:{} hz:60 enabled:true scaling:on origin:(0,0) degree:0'",
        screen_id, resolution
    );

    Command::new("sh")
        .arg("-c")
        .arg(&command)
        .status()
        .expect("Failed to apply resolution");
}
