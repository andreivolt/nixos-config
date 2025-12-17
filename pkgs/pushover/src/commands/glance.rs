use crate::api::{Glance, PushoverClient};
use crate::error::Result;
use clap::Args;

#[derive(Args, Debug)]
pub struct GlanceArgs {
    /// Glance title (max 100 chars)
    #[arg(long)]
    pub title: Option<String>,

    /// Main text line (max 100 chars)
    #[arg(long)]
    pub text: Option<String>,

    /// Secondary text line (max 100 chars)
    #[arg(long)]
    pub subtext: Option<String>,

    /// Numeric count to display
    #[arg(long)]
    pub count: Option<i32>,

    /// Percentage (0-100)
    #[arg(long, value_parser = clap::value_parser!(u8).range(0..=100))]
    pub percent: Option<u8>,

    /// Target device
    #[arg(short, long)]
    pub device: Option<String>,

    /// Show verbose output
    #[arg(short, long)]
    pub verbose: bool,

    /// Output as JSON
    #[arg(long)]
    pub json: bool,
}

pub fn run(args: &GlanceArgs) -> Result<()> {
    // At least one data field required
    if args.title.is_none()
        && args.text.is_none()
        && args.subtext.is_none()
        && args.count.is_none()
        && args.percent.is_none()
    {
        return Err(crate::error::Error::Api(
            "At least one of --title, --text, --subtext, --count, or --percent required".to_string(),
        ));
    }

    let client = PushoverClient::new()?;

    let glance = Glance {
        title: args.title.clone(),
        text: args.text.clone(),
        subtext: args.subtext.clone(),
        count: args.count,
        percent: args.percent,
        device: args.device.clone(),
    };

    let response = client.send_glance(&glance)?;

    if args.json {
        println!("{}", serde_json::to_string_pretty(&response).unwrap());
    } else if args.verbose {
        println!("Glance sent (request: {})", response.request);
    }

    Ok(())
}
