use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use directories::ProjectDirs;
use rand::seq::SliceRandom;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;
use std::process::Stdio;
use tabled::{settings::{Style, Disable, object::Rows}, Table, Tabled};
use tokio::fs;
use tokio::io::AsyncWriteExt;
use tokio::process::Command;

fn get_tailscale_command() -> &'static str {
    if cfg!(target_os = "macos") {
        // On macOS, prefer the app bundle path if available, otherwise fall back to PATH
        if std::path::Path::new("/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale").exists() {
            "/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale"
        } else {
            "tailscale"
        }
    } else {
        // On Linux and other platforms, use the command from PATH
        "tailscale"
    }
}

#[derive(Parser)]
#[command(name = "tailscale-exit-node")]
#[command(about = "Manage Tailscale exit nodes with interactive selection")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Set exit node (by hostname or country)
    Set { target: Option<String> },
    /// Clear/disable exit node
    Clear,
    /// List available exit nodes
    List { filter: Option<String> },
    /// Select a random exit node
    Random { filter: Option<String> },
}

#[derive(Debug, Clone, Tabled, Serialize, Deserialize)]
struct ExitNode {
    hostname: String,
    country: String,
    city: String,
}


#[derive(Deserialize)]
struct MullvadRelay {
    hostname: String,
    country_name: String,
    city_name: String,
    active: bool,
    #[serde(rename = "type")]
    relay_type: String,
}

fn get_cache_path() -> Result<PathBuf> {
    let proj_dirs = ProjectDirs::from("", "", "tailscale-exit-node")
        .context("Failed to get project directories")?;
    let cache_dir = proj_dirs.cache_dir();
    Ok(cache_dir.join("nodes.json"))
}

async fn get_mullvad_nodes() -> Result<Vec<ExitNode>> {
    // Try to load from cache first
    let cache_path = get_cache_path()?;
    if cache_path.exists() {
        if let Ok(content) = fs::read_to_string(&cache_path).await {
            if let Ok(nodes) = serde_json::from_str::<Vec<ExitNode>>(&content) {
                return Ok(nodes);
            }
        }
    }

    // Fetch from API if cache doesn't exist or is invalid
    let client = reqwest::Client::new();
    let relays: Vec<MullvadRelay> = client
        .get("https://api.mullvad.net/www/relays/all/")
        .send()
        .await?
        .json()
        .await?;

    let mut nodes: Vec<ExitNode> = relays
        .into_iter()
        .filter(|r| r.active && r.relay_type == "wireguard")
        .map(|r| ExitNode {
            hostname: format!("{}.mullvad.ts.net", r.hostname),
            country: r.country_name,
            city: r.city_name,
        })
        .collect();

    nodes.sort_by(|a, b| a.country.cmp(&b.country).then_with(|| a.city.cmp(&b.city)));

    if let Some(parent) = cache_path.parent() {
        let _ = fs::create_dir_all(parent).await;
    }
    let _ = fs::write(&cache_path, serde_json::to_string_pretty(&nodes)?).await;

    Ok(nodes)
}

fn filter_by_country(nodes: &[ExitNode], country: &str) -> Vec<ExitNode> {
    let country_lower = country.to_lowercase();
    nodes.iter()
        .filter(|node| node.country.to_lowercase().contains(&country_lower))
        .cloned()
        .collect()
}

async fn set_exit_node(hostname: &str) -> Result<()> {
    let output = Command::new(get_tailscale_command())
        .args(["set", "--exit-node", hostname])
        .output()
        .await
        .context("Failed to set exit node")?;

    if !output.status.success() {
        anyhow::bail!("Failed to set exit node: {}", String::from_utf8_lossy(&output.stderr));
    }

    Ok(())
}

async fn interactive_select() -> Result<()> {
    let nodes = get_mullvad_nodes().await?;

    if nodes.is_empty() {
        println!("No exit nodes found");
        return Ok(());
    }

    // Group nodes by country
    let mut countries_map: HashMap<String, Vec<ExitNode>> = HashMap::new();
    for node in nodes {
        countries_map.entry(node.country.clone()).or_insert_with(Vec::new).push(node);
    }

    // Get sorted list of unique countries
    let mut countries: Vec<String> = countries_map.keys().cloned().collect();
    countries.sort();

    // Show countries in fzf
    let country_list = countries.join("\n");

    let mut fzf = Command::new("fzf")
        .arg("--prompt=Select Country> ")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("Failed to start fzf")?;

    let mut stdin = fzf.stdin.take().unwrap();
    stdin.write_all(country_list.as_bytes()).await?;
    stdin.shutdown().await?;

    let output = fzf.wait_with_output().await?;

    if output.status.success() {
        let selected_country = String::from_utf8(output.stdout)?.trim().to_string();
        if !selected_country.is_empty() {
            // Pick a random node from the selected country
            if let Some(country_nodes) = countries_map.get(&selected_country) {
                let mut rng = rand::thread_rng();
                let selected = country_nodes.choose(&mut rng).unwrap();

                set_exit_node(&selected.hostname).await?;
                println!("Exit node set to: {}", selected.hostname);
            }
        } else {
            println!("No country selected");
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        None => interactive_select().await?,

        Some(Commands::Set { target: None }) => {
            interactive_select().await?;
        }

        Some(Commands::Set { target: Some(target) }) => {
            let nodes = get_mullvad_nodes().await?;

            // Try exact hostname match first
            if let Some(node) = nodes.iter().find(|n| n.hostname == target) {
                set_exit_node(&node.hostname).await?;
                println!("Exit node set to: {}", node.hostname);
            } else {
                // Try country-based selection
                let country_nodes = filter_by_country(&nodes, &target);

                if !country_nodes.is_empty() {
                    let mut rng = rand::thread_rng();
                    let selected = country_nodes.choose(&mut rng).unwrap();

                    set_exit_node(&selected.hostname).await?;
                    println!("Exit node set to: {}", selected.hostname);
                } else {
                    println!("No exit nodes found matching hostname or country: {}", target);
                    std::process::exit(1);
                }
            }
        }

        Some(Commands::Clear) => {
            set_exit_node("").await?;
            println!("Exit node cleared");
        }

        Some(Commands::List { filter }) => {
            let nodes = get_mullvad_nodes().await?;
            let filtered_nodes = if let Some(ref f) = filter {
                filter_by_country(&nodes, f)
            } else {
                nodes
            };

            let table = Table::new(&filtered_nodes)
                .with(Style::blank())
                .with(Disable::row(Rows::first()))
                .to_string();

            print!("{}", table);
        }

        Some(Commands::Random { filter }) => {
            let nodes = get_mullvad_nodes().await?;
            let filtered_nodes = if let Some(ref f) = filter {
                filter_by_country(&nodes, f)
            } else {
                nodes
            };

            if filtered_nodes.is_empty() {
                println!("No exit nodes found{}",
                         filter.map(|f| format!(" matching filter: {}", f)).unwrap_or_default());
                return Ok(());
            }

            let mut rng = rand::thread_rng();
            let selected = filtered_nodes.choose(&mut rng).unwrap();

            set_exit_node(&selected.hostname).await?;
            println!("Exit node set to: {}", selected.hostname);
        }
    }

    Ok(())
}