use crate::error::{Error, Result};
use reqwest::blocking::{multipart, Client};
use serde::{Deserialize, Serialize};
use std::env;
use std::fs::File;
use std::io::Read;
use std::path::Path;

const API_BASE: &str = "https://api.pushover.net/1";

#[derive(Debug, Clone)]
pub struct Credentials {
    pub token: String,
    pub user: String,
}

impl Credentials {
    pub fn from_env() -> Result<Self> {
        let token = env::var("PUSHOVER_TOKEN")
            .or_else(|_| env::var("pushover_token"))
            .map_err(|_| Error::MissingEnv("PUSHOVER_TOKEN"))?;
        let user = env::var("PUSHOVER_USER")
            .or_else(|_| env::var("pushover_user"))
            .map_err(|_| Error::MissingEnv("PUSHOVER_USER"))?;
        Ok(Self { token, user })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Priority {
    Lowest = -2,
    Low = -1,
    Normal = 0,
    High = 1,
    Emergency = 2,
}

impl Priority {
    pub fn from_str(s: &str) -> Result<Self> {
        match s.to_lowercase().as_str() {
            "lowest" | "-2" => Ok(Self::Lowest),
            "low" | "-1" => Ok(Self::Low),
            "normal" | "0" => Ok(Self::Normal),
            "high" | "1" => Ok(Self::High),
            "emergency" | "2" => Ok(Self::Emergency),
            _ => Err(Error::InvalidPriority(s.to_string())),
        }
    }

    pub fn as_i8(self) -> i8 {
        self as i8
    }
}

#[derive(Debug, Default)]
pub struct Message {
    pub message: String,
    pub title: Option<String>,
    pub priority: Option<Priority>,
    pub sound: Option<String>,
    pub device: Option<String>,
    pub url: Option<String>,
    pub url_title: Option<String>,
    pub html: bool,
    pub monospace: bool,
    pub timestamp: Option<i64>,
    pub ttl: Option<u32>,
    pub attachment: Option<String>,
    // Emergency priority options
    pub retry: Option<u32>,
    pub expire: Option<u32>,
    pub callback: Option<String>,
    pub tags: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ApiResponse {
    pub status: i32,
    pub request: String,
    #[serde(default)]
    pub errors: Vec<String>,
    pub receipt: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ReceiptResponse {
    pub status: i32,
    pub acknowledged: i32,
    #[serde(default)]
    pub acknowledged_at: i64,
    #[serde(default)]
    pub acknowledged_by: String,
    #[serde(default)]
    pub acknowledged_by_device: String,
    pub last_delivered_at: Option<i64>,
    pub expired: i32,
    pub expires_at: i64,
    pub called_back: i32,
    #[serde(default)]
    pub called_back_at: i64,
}

#[derive(Debug, Default)]
pub struct Glance {
    pub title: Option<String>,
    pub text: Option<String>,
    pub subtext: Option<String>,
    pub count: Option<i32>,
    pub percent: Option<u8>,
    pub device: Option<String>,
}

pub struct PushoverClient {
    client: Client,
    creds: Credentials,
}

impl PushoverClient {
    pub fn new() -> Result<Self> {
        let creds = Credentials::from_env()?;
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()?;
        Ok(Self { client, creds })
    }

    pub fn send(&self, msg: &Message) -> Result<ApiResponse> {
        let url = format!("{}/messages.json", API_BASE);

        // If there's an attachment, use multipart form
        if let Some(ref attachment_path) = msg.attachment {
            return self.send_with_attachment(msg, attachment_path);
        }

        let mut form: Vec<(&str, String)> = vec![
            ("token", self.creds.token.clone()),
            ("user", self.creds.user.clone()),
            ("message", msg.message.clone()),
        ];

        if let Some(ref title) = msg.title {
            form.push(("title", title.clone()));
        }
        if let Some(priority) = msg.priority {
            form.push(("priority", priority.as_i8().to_string()));

            if priority == Priority::Emergency {
                form.push(("retry", msg.retry.unwrap_or(60).to_string()));
                form.push(("expire", msg.expire.unwrap_or(3600).to_string()));
                if let Some(ref callback) = msg.callback {
                    form.push(("callback", callback.clone()));
                }
                if let Some(ref tags) = msg.tags {
                    form.push(("tags", tags.clone()));
                }
            }
        }
        if let Some(ref sound) = msg.sound {
            form.push(("sound", sound.clone()));
        }
        if let Some(ref device) = msg.device {
            form.push(("device", device.clone()));
        }
        if let Some(ref url) = msg.url {
            form.push(("url", url.clone()));
        }
        if let Some(ref url_title) = msg.url_title {
            form.push(("url_title", url_title.clone()));
        }
        if msg.html {
            form.push(("html", "1".to_string()));
        }
        if msg.monospace {
            form.push(("monospace", "1".to_string()));
        }
        if let Some(timestamp) = msg.timestamp {
            form.push(("timestamp", timestamp.to_string()));
        }
        if let Some(ttl) = msg.ttl {
            form.push(("ttl", ttl.to_string()));
        }

        let response: ApiResponse = self.client.post(&url).form(&form).send()?.json()?;

        if response.status != 1 {
            return Err(Error::Api(response.errors.join(", ")));
        }
        Ok(response)
    }

    fn send_with_attachment(&self, msg: &Message, attachment_path: &str) -> Result<ApiResponse> {
        let url = format!("{}/messages.json", API_BASE);
        let path = Path::new(attachment_path);

        let mut file = File::open(path)?;
        let mut buffer = Vec::new();
        file.read_to_end(&mut buffer)?;

        let filename = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("attachment");

        let mime_type = match path.extension().and_then(|e| e.to_str()) {
            Some("png") => "image/png",
            Some("jpg") | Some("jpeg") => "image/jpeg",
            Some("gif") => "image/gif",
            Some("webp") => "image/webp",
            _ => "application/octet-stream",
        };

        let attachment_part = multipart::Part::bytes(buffer)
            .file_name(filename.to_string())
            .mime_str(mime_type)?;

        let mut form = multipart::Form::new()
            .text("token", self.creds.token.clone())
            .text("user", self.creds.user.clone())
            .text("message", msg.message.clone())
            .part("attachment", attachment_part);

        if let Some(ref title) = msg.title {
            form = form.text("title", title.clone());
        }
        if let Some(priority) = msg.priority {
            form = form.text("priority", priority.as_i8().to_string());

            if priority == Priority::Emergency {
                form = form.text("retry", msg.retry.unwrap_or(60).to_string());
                form = form.text("expire", msg.expire.unwrap_or(3600).to_string());
                if let Some(ref callback) = msg.callback {
                    form = form.text("callback", callback.clone());
                }
                if let Some(ref tags) = msg.tags {
                    form = form.text("tags", tags.clone());
                }
            }
        }
        if let Some(ref sound) = msg.sound {
            form = form.text("sound", sound.clone());
        }
        if let Some(ref device) = msg.device {
            form = form.text("device", device.clone());
        }
        if let Some(ref url) = msg.url {
            form = form.text("url", url.clone());
        }
        if let Some(ref url_title) = msg.url_title {
            form = form.text("url_title", url_title.clone());
        }
        if msg.html {
            form = form.text("html", "1");
        }
        if msg.monospace {
            form = form.text("monospace", "1");
        }
        if let Some(timestamp) = msg.timestamp {
            form = form.text("timestamp", timestamp.to_string());
        }
        if let Some(ttl) = msg.ttl {
            form = form.text("ttl", ttl.to_string());
        }

        let response: ApiResponse = self.client.post(&url).multipart(form).send()?.json()?;

        if response.status != 1 {
            return Err(Error::Api(response.errors.join(", ")));
        }
        Ok(response)
    }

    pub fn get_receipt(&self, receipt_id: &str) -> Result<ReceiptResponse> {
        let url = format!(
            "{}/receipts/{}.json?token={}",
            API_BASE, receipt_id, self.creds.token
        );
        let text = self.client.get(&url).send()?.text()?;

        // First check if it's an error response
        if let Ok(err_response) = serde_json::from_str::<ApiResponse>(&text) {
            if err_response.status != 1 {
                return Err(Error::Api(err_response.errors.join(", ")));
            }
        }

        let response: ReceiptResponse = serde_json::from_str(&text)
            .map_err(|e| Error::Api(format!("Failed to parse response: {}", e)))?;
        Ok(response)
    }

    pub fn cancel_receipt(&self, receipt_id: &str) -> Result<ApiResponse> {
        let url = format!("{}/receipts/{}/cancel.json", API_BASE, receipt_id);
        let form = [("token", self.creds.token.as_str())];
        let response: ApiResponse = self.client.post(&url).form(&form).send()?.json()?;

        if response.status != 1 {
            return Err(Error::Api(response.errors.join(", ")));
        }
        Ok(response)
    }

    pub fn send_glance(&self, glance: &Glance) -> Result<ApiResponse> {
        let url = format!("{}/glances.json", API_BASE);

        let mut form: Vec<(&str, String)> = vec![
            ("token", self.creds.token.clone()),
            ("user", self.creds.user.clone()),
        ];

        if let Some(ref title) = glance.title {
            form.push(("title", title.clone()));
        }
        if let Some(ref text) = glance.text {
            form.push(("text", text.clone()));
        }
        if let Some(ref subtext) = glance.subtext {
            form.push(("subtext", subtext.clone()));
        }
        if let Some(count) = glance.count {
            form.push(("count", count.to_string()));
        }
        if let Some(percent) = glance.percent {
            form.push(("percent", percent.to_string()));
        }
        if let Some(ref device) = glance.device {
            form.push(("device", device.clone()));
        }

        let response: ApiResponse = self.client.post(&url).form(&form).send()?.json()?;

        if response.status != 1 {
            return Err(Error::Api(response.errors.join(", ")));
        }
        Ok(response)
    }
}
