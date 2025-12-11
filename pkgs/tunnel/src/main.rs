use anyhow::Result;
use clap::Parser;
use rand::Rng;
use std::process::Stdio;
use tokio::process::Command;
use tokio::signal;
use tokio::time::{sleep, Duration};

#[derive(Parser)]
#[command(about = "Create SSH tunnels for port forwarding")]
struct Args {
    #[arg(short, long)]
    local_port: u16,
    #[arg(short, long)]
    remote_port: u16,
    #[arg(short, long)]
    username: Option<String>,
    #[arg(short = 'H', long)]
    remote_host: String,
    #[arg(short, long)]
    identity_file: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    tokio::select! {
        _ = signal::ctrl_c() => {
            println!("\nShutting down tunnel...");
        }
        _ = async {
            loop {
                match run_tunnel(&args).await {
                    Ok(_) => {
                        println!("Tunnel disconnected. Restarting in 5s...");
                        sleep(Duration::from_secs(5)).await;
                    }
                    Err(e) => {
                        eprintln!("Error: {}. Restarting in 5s...", e);
                        sleep(Duration::from_secs(5)).await;
                    }
                }
            }
        } => {}
    }

    Ok(())
}

async fn run_tunnel(args: &Args) -> Result<()> {
    let random_port: u16 = rand::thread_rng().gen_range(30000..60000);
    let target = match &args.username {
        Some(user) => format!("{}@{}", user, args.remote_host),
        None => args.remote_host.clone(),
    };

    println!("Starting tunnel: localhost:{} -> {}:{}",
             args.local_port, target, args.remote_port);

    let reverse_arg = format!("{}:localhost:{}", random_port, args.local_port);
    let socat_cmd = format!("socat TCP-LISTEN:{},fork,reuseaddr TCP:localhost:{}",
                           args.remote_port, random_port);

    let mut ssh_args = vec!["-R", &reverse_arg, &target, &socat_cmd];

    if let Some(identity) = &args.identity_file {
        ssh_args.insert(0, identity);
        ssh_args.insert(0, "-i");
    }

    let mut child = Command::new("ssh")
        .args(&ssh_args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;

    child.wait().await?;

    Ok(())
}