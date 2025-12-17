mod api;
mod commands;
mod error;

use clap::{Parser, Subcommand};
use commands::{glance, receipt, send};

#[derive(Parser)]
#[command(name = "pushover")]
#[command(about = "CLI for Pushover notifications")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    #[command(flatten)]
    send: send::SendArgs,
}

#[derive(Subcommand)]
enum Commands {
    /// Send a notification
    Send(send::SendArgs),

    /// Check emergency notification receipt status
    Receipt(receipt::ReceiptArgs),

    /// Cancel an emergency notification
    Cancel(receipt::CancelArgs),

    /// Update watch/widget glance (Apple Watch only currently)
    Glance(glance::GlanceArgs),
}

fn main() {
    let cli = Cli::parse();

    let result = match cli.command {
        Some(Commands::Send(args)) => send::run(&args),
        Some(Commands::Receipt(args)) => receipt::get_receipt(&args),
        Some(Commands::Cancel(args)) => receipt::cancel(&args),
        Some(Commands::Glance(args)) => glance::run(&args),
        // No subcommand = default to send
        None => send::run(&cli.send),
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}
