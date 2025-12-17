use crate::api::PushoverClient;
use crate::error::Result;
use clap::Args;

#[derive(Args, Debug)]
pub struct ReceiptArgs {
    /// Receipt ID from emergency notification
    pub receipt_id: String,

    /// Output as JSON
    #[arg(long)]
    pub json: bool,
}

#[derive(Args, Debug)]
pub struct CancelArgs {
    /// Receipt ID to cancel
    pub receipt_id: String,

    /// Show verbose output
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn get_receipt(args: &ReceiptArgs) -> Result<()> {
    let client = PushoverClient::new()?;
    let receipt = client.get_receipt(&args.receipt_id)?;

    if args.json {
        println!("{}", serde_json::to_string_pretty(&receipt).unwrap());
    } else {
        let ack_status = if receipt.acknowledged == 1 {
            format!(
                "acknowledged at {} by {}",
                format_timestamp(receipt.acknowledged_at),
                if receipt.acknowledged_by_device.is_empty() {
                    &receipt.acknowledged_by
                } else {
                    &receipt.acknowledged_by_device
                }
            )
        } else {
            "not acknowledged".to_string()
        };

        let expired_status = if receipt.expired == 1 {
            "expired"
        } else {
            "active"
        };

        println!("Status: {}", ack_status);
        println!("Expired: {} (at {})", expired_status, format_timestamp(receipt.expires_at));
        if let Some(last) = receipt.last_delivered_at {
            println!("Last delivered: {}", format_timestamp(last));
        }
        if receipt.called_back == 1 {
            println!("Callback: triggered at {}", format_timestamp(receipt.called_back_at));
        }
    }

    Ok(())
}

pub fn cancel(args: &CancelArgs) -> Result<()> {
    let client = PushoverClient::new()?;
    let response = client.cancel_receipt(&args.receipt_id)?;

    if args.verbose {
        println!("Cancelled (request: {})", response.request);
    }

    Ok(())
}

fn format_timestamp(ts: i64) -> String {
    if ts == 0 {
        return "N/A".to_string();
    }
    // Simple timestamp formatting - just show the unix time for now
    // Could use chrono for proper formatting but keeping deps minimal
    ts.to_string()
}
