use anyhow::{anyhow, Result};
use argh::FromArgs;
use chrono::{DateTime, Utc};
use timeago;
use duct::cmd;
use serde::Deserialize;
use std::env;

#[derive(FromArgs)]
/// Delete Tailscale devices
struct Args {
    /// device names to delete
    #[argh(positional)]
    devices: Vec<String>,
}

#[derive(Deserialize)]
struct DevicesResponse {
    devices: Vec<Device>,
}

#[derive(Deserialize, Clone)]
struct Device {
    id: String,
    name: String,
    #[serde(rename = "lastSeen")]
    last_seen: Option<DateTime<Utc>>,
}

fn get_env_vars() -> Result<(String, String)> {
    let api_key = env::var("TAILSCALE_API_KEY")
        .map_err(|_| anyhow!("TAILSCALE_API_KEY environment variable not set"))?;
    let org = env::var("TAILSCALE_ORG")
        .map_err(|_| anyhow!("TAILSCALE_ORG environment variable not set"))?;
    Ok((api_key, org))
}

fn time_ago(dt: Option<DateTime<Utc>>) -> String {
    match dt {
        Some(dt) => {
            let now = Utc::now();
            let duration = now.signed_duration_since(dt);
            timeago::Formatter::new().convert(duration.to_std().unwrap_or(std::time::Duration::ZERO))
        }
        None => "never".to_string(),
    }
}

fn get_devices(api_key: &str, org: &str) -> Result<Vec<Device>> {
    let url = format!("https://api.tailscale.com/api/v2/tailnet/{}/devices", org);

    let response = ureq::get(&url)
        .set("Authorization", &format!("Bearer {}", api_key))
        .call()
        .map_err(|e| anyhow!("API request failed: {}", e))?;

    let devices_response: DevicesResponse = response.into_json()?;
    Ok(devices_response.devices)
}

fn delete_device(api_key: &str, device_id: &str) -> Result<()> {
    let url = format!("https://api.tailscale.com/api/v2/device/{}", device_id);

    ureq::delete(&url)
        .set("Authorization", &format!("Bearer {}", api_key))
        .call()
        .map_err(|e| anyhow!("Delete request failed: {}", e))?;

    Ok(())
}

fn select_devices_with_fzf(devices: &[Device]) -> Result<Vec<Device>> {
    let max_name_len = devices.iter().map(|d| d.name.len()).max().unwrap_or(0);
    let device_list: Vec<String> = devices
        .iter()
        .map(|d| format!("{:<width$} - {}", d.name, time_ago(d.last_seen), width = max_name_len))
        .collect();

    let input = device_list.join("\n");

    let output = cmd!("fzf", "--multi", "--prompt=Select devices to delete: ", "--header=TAB to select multiple, ENTER to confirm")
        .stdin_bytes(input)
        .read()
        .map_err(|_| anyhow!("No devices selected"))?;

    let selected_names: Vec<String> = output
        .lines()
        .map(|line| line.split(" - ").next().unwrap_or("").trim().to_string())
        .collect();

    let selected_devices: Vec<Device> = devices
        .iter()
        .filter(|d| selected_names.contains(&d.name))
        .cloned()
        .collect();

    Ok(selected_devices)
}

fn main() -> Result<()> {
    let args: Args = argh::from_env();
    let (api_key, org) = get_env_vars()?;

    let devices = get_devices(&api_key, &org)?;

    if devices.is_empty() {
        println!("No devices found");
        return Ok(());
    }

    let selected_devices = if args.devices.is_empty() {
        select_devices_with_fzf(&devices)?
    } else {
        let filtered: Vec<Device> = devices
            .iter()
            .filter(|d| args.devices.contains(&d.name))
            .cloned()
            .collect();
        filtered
    };

    if selected_devices.is_empty() {
        println!("No matching devices found");
        println!("\nAvailable devices:");
        for device in &devices {
            println!("  - '{}' (last seen: {})", device.name, time_ago(device.last_seen));
        }
        println!("\nYou searched for: {:?}", args.devices);
        return Ok(());
    }

    println!("Deleting {} device(s):", selected_devices.len());
    for device in &selected_devices {
        println!("  - {}", device.name);
    }

    for device in selected_devices {
        match delete_device(&api_key, &device.id) {
            Ok(()) => println!("Deleted {}", device.name),
            Err(e) => eprintln!("Error deleting {}: {}", device.name, e),
        }
    }

    Ok(())
}