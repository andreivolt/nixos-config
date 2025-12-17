use crate::api::{Message, Priority, PushoverClient};
use crate::error::Result;
use clap::Args;
use std::io::{self, Read};

const SOUNDS_HELP: &str = "Notification sound [alien, bike, bugle, cashregister, classical, \
climb, cosmic, echo, falling, gamelan, incoming, intermission, magic, mechanical, none, \
persistent, pianobar, pushover, siren, spacealarm, tugboat, updown, vibrate]";

#[derive(Args, Debug)]
pub struct SendArgs {
    /// Message text (or second positional arg if title is first)
    #[arg(value_name = "MESSAGE")]
    pub first: Option<String>,

    /// Message text when first arg is title
    #[arg(value_name = "MESSAGE")]
    pub second: Option<String>,

    /// Message title (alternative to positional)
    #[arg(short, long)]
    pub title: Option<String>,

    /// Priority level
    #[arg(short, long, value_name = "PRIORITY")]
    pub priority: Option<String>,

    #[arg(short, long, help = SOUNDS_HELP)]
    pub sound: Option<String>,

    /// Target device(s), comma-separated
    #[arg(short, long)]
    pub device: Option<String>,

    /// Supplementary URL
    #[arg(short, long)]
    pub url: Option<String>,

    /// Title for supplementary URL
    #[arg(long)]
    pub url_title: Option<String>,

    /// Enable HTML formatting
    #[arg(long)]
    pub html: bool,

    /// Use monospace font
    #[arg(long)]
    pub mono: bool,

    /// Unix timestamp for message
    #[arg(long)]
    pub timestamp: Option<i64>,

    /// Seconds until message auto-deletes
    #[arg(long)]
    pub ttl: Option<u32>,

    /// Image file to attach
    #[arg(short, long)]
    pub attachment: Option<String>,

    /// Emergency: retry interval in seconds (min 30)
    #[arg(long, default_value = "60")]
    pub retry: u32,

    /// Emergency: expiration in seconds (max 10800)
    #[arg(long, default_value = "3600")]
    pub expire: u32,

    /// Emergency: callback URL when acknowledged
    #[arg(long)]
    pub callback: Option<String>,

    /// Emergency: receipt tags
    #[arg(long)]
    pub tags: Option<String>,

    /// Show verbose output
    #[arg(short, long)]
    pub verbose: bool,

    /// Output as JSON
    #[arg(long)]
    pub json: bool,
}

impl SendArgs {
    /// Resolve message and title from positional args
    /// - "msg" -> message only
    /// - "title" "msg" -> title and message
    /// - stdin if no positional args
    pub fn resolve_message_and_title(&self) -> Result<(String, Option<String>)> {
        match (&self.first, &self.second, &self.title) {
            // Two positional args: first is title, second is message
            (Some(first), Some(second), None) => Ok((second.clone(), Some(first.clone()))),
            // Two positional + explicit title: explicit title wins, both positional are message
            (Some(first), Some(second), Some(title)) => {
                Ok((format!("{} {}", first, second), Some(title.clone())))
            }
            // One positional + explicit title
            (Some(msg), None, Some(title)) => Ok((msg.clone(), Some(title.clone()))),
            // One positional, no title
            (Some(msg), None, None) => Ok((msg.clone(), None)),
            // No positional args, read from stdin
            (None, None, title) => {
                let mut buffer = String::new();
                io::stdin().read_to_string(&mut buffer)?;
                let msg = buffer.trim().to_string();
                if msg.is_empty() {
                    return Err(crate::error::Error::Api(
                        "No message provided (use positional arg or stdin)".to_string(),
                    ));
                }
                Ok((msg, title.clone()))
            }
            // Edge case: second without first (shouldn't happen with clap)
            (None, Some(_), _) => Err(crate::error::Error::Api(
                "Invalid argument combination".to_string(),
            )),
        }
    }
}

pub fn run(args: &SendArgs) -> Result<()> {
    let client = PushoverClient::new()?;
    let (message, title) = args.resolve_message_and_title()?;

    let priority = args
        .priority
        .as_ref()
        .map(|p| Priority::from_str(p))
        .transpose()?;

    let msg = Message {
        message,
        title,
        priority,
        sound: args.sound.clone(),
        device: args.device.clone(),
        url: args.url.clone(),
        url_title: args.url_title.clone(),
        html: args.html,
        monospace: args.mono,
        timestamp: args.timestamp,
        ttl: args.ttl,
        attachment: args.attachment.clone(),
        retry: Some(args.retry),
        expire: Some(args.expire),
        callback: args.callback.clone(),
        tags: args.tags.clone(),
    };

    let response = client.send(&msg)?;

    if args.json {
        println!("{}", serde_json::to_string_pretty(&response).unwrap());
    } else if args.verbose {
        println!("Sent (request: {})", response.request);
        if let Some(ref receipt) = response.receipt {
            println!("Receipt: {}", receipt);
        }
    } else {
        // Minimal output on success
        if let Some(ref receipt) = response.receipt {
            println!("{}", receipt);
        }
    }

    Ok(())
}
