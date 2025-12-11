use anyhow::{anyhow, Result};
use chrono::{DateTime, Local, TimeZone, Utc};
use clap::Parser;
use html2text::from_read;
use html_escape;
use regex::Regex;
use roux::Subreddit;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use url::Url;

#[derive(Parser)]
#[command(about = "Fetch and display Reddit comments in a formatted view")]
struct Args {
    /// The Reddit submission or comment URL
    url: Option<String>,

    /// Output the comment tree in JSON format
    #[arg(long)]
    json: bool,

    /// Clear the cache and exit
    #[arg(long)]
    clear_cache: bool,

    /// Skip cache and fetch fresh data
    #[arg(short = 'x')]
    skip_cache: bool,
}

#[derive(Serialize)]
struct CommentTree {
    id: String,
    author: String,
    time: String,
    text: String,
    children: Vec<CommentTree>,
}

#[derive(Serialize)]
struct CommentJson {
    author: String,
    body: String,
    created_utc: String,
    score: i64,
    replies: Vec<CommentJson>,
}

#[derive(Serialize, Deserialize)]
struct CacheEntry {
    data: Value,
    timestamp: i64,
}

fn get_cache_dir() -> Result<PathBuf> {
    let cache_dir = dirs::cache_dir()
        .ok_or_else(|| anyhow!("Could not determine cache directory"))?
        .join("reddit-comments");

    if !cache_dir.exists() {
        fs::create_dir_all(&cache_dir)?;
    }

    Ok(cache_dir)
}

fn get_cache_key(submission_id: &str, comment_id: Option<&str>) -> String {
    let mut hasher = Sha256::new();
    hasher.update(submission_id.as_bytes());
    if let Some(cid) = comment_id {
        hasher.update(cid.as_bytes());
    }
    hex::encode(hasher.finalize())
}

fn get_cached_data(submission_id: &str, comment_id: Option<&str>) -> Result<Option<Value>> {
    let cache_dir = get_cache_dir()?;
    let cache_key = get_cache_key(submission_id, comment_id);
    let cache_file = cache_dir.join(format!("{}.json", cache_key));

    if !cache_file.exists() {
        return Ok(None);
    }

    let cache_content = fs::read_to_string(&cache_file)?;
    let cache_entry: CacheEntry = serde_json::from_str(&cache_content)?;

    // Check if cache is less than 1 hour old
    let now = chrono::Utc::now().timestamp();
    if now - cache_entry.timestamp < 3600 {
        Ok(Some(cache_entry.data))
    } else {
        // Cache expired, remove it
        let _ = fs::remove_file(&cache_file);
        Ok(None)
    }
}

fn save_to_cache(submission_id: &str, comment_id: Option<&str>, data: &Value) -> Result<()> {
    let cache_dir = get_cache_dir()?;
    let cache_key = get_cache_key(submission_id, comment_id);
    let cache_file = cache_dir.join(format!("{}.json", cache_key));

    let cache_entry = CacheEntry {
        data: data.clone(),
        timestamp: chrono::Utc::now().timestamp(),
    };

    let cache_content = serde_json::to_string(&cache_entry)?;
    fs::write(&cache_file, cache_content)?;

    Ok(())
}

fn clear_cache() -> Result<()> {
    let cache_dir = get_cache_dir()?;

    if cache_dir.exists() {
        for entry in fs::read_dir(&cache_dir)? {
            let entry = entry?;
            if entry.path().extension().map(|s| s == "json").unwrap_or(false) {
                fs::remove_file(entry.path())?;
            }
        }
        println!("Cache cleared successfully");
    } else {
        println!("No cache directory found");
    }

    Ok(())
}

fn clean_comment_text(text: &str) -> String {
    // First unescape HTML entities, then convert HTML to plain text
    let unescaped = html_escape::decode_html_entities(text);
    let converted = from_read(unescaped.as_bytes(), 120);

    // Replace blockquotes
    let mut result = converted.replace("> ", "│ ");

    // Remove markdown reference links
    let re_refs = Regex::new(r"\n\n\[\d+\]:.*").unwrap();
    result = re_refs.replace_all(&result, "").to_string();

    // Convert markdown links to plain text
    // [text][num] -> text
    let re_ref_links = Regex::new(r"\[([^\]]+)\]\[\d+\]").unwrap();
    result = re_ref_links.replace_all(&result, "$1").to_string();

    // [text](url) -> text
    let re_inline_links = Regex::new(r"\[([^\]]+)\]\([^)]+\)").unwrap();
    result = re_inline_links.replace_all(&result, "$1").to_string();

    // Convert numbered lists to avoid tree-render converting them back to HTML
    let re_numbered = Regex::new(r"^(\d+)\. ").unwrap();
    let mut lines = Vec::new();
    for line in result.lines() {
        lines.push(re_numbered.replace(line, "[$1] ").to_string());
    }

    let mut final_result = lines.join("\n");

    // Remove any remaining HTML tags that might slip through
    let re_html = Regex::new(r"<[^>]*>").unwrap();
    final_result = re_html.replace_all(&final_result, "").to_string();

    // Keep beautiful unicode table characters now that tree-render is fixed

    final_result
}


fn get_submission_and_comment_id(url: &str) -> Result<(String, Option<String>)> {
    let parsed = Url::parse(url)?;

    if let Some(host) = parsed.host_str() {
        if host.contains("reddit.com") || host.contains("old.reddit.com") {
            let segments: Vec<&str> = parsed.path_segments()
                .ok_or_else(|| anyhow!("Invalid URL path"))?
                .collect();

            // Handle /r/subreddit/comments/submission_id/title/comment_id format
            if segments.len() >= 5 && segments[0] == "r" && segments[2] == "comments" {
                let submission_id = segments[3].to_string();
                let comment_id = if segments.len() >= 6 && !segments[5].is_empty() {
                    Some(segments[5].to_string())
                } else {
                    None
                };
                return Ok((submission_id, comment_id));
            }
        }
    }

    Err(anyhow!("Invalid Reddit URL"))
}

fn parse_comment_to_tree(comment: &Value) -> Option<CommentTree> {
    let data = comment.get("data")?;

    // Skip deleted/removed/empty comments
    let author = data.get("author")?.as_str()?;
    if author == "[deleted]" || author == "None" {
        return None;
    }

    // Use body_html field which contains HTML that we can convert to text
    let body = data.get("body_html")?.as_str()?.to_string();

    if body.is_empty() || body == "[deleted]" || body == "[removed]" {
        return None;
    }

    let id = data.get("id")?.as_str()?;
    let created_utc = data.get("created_utc")?.as_f64()?;
    let timestamp = Utc.timestamp_opt(created_utc as i64, 0).single()?;
    let local_time = DateTime::<Local>::from(timestamp);

    let mut children = Vec::new();
    if let Some(replies) = data.get("replies") {
        if let Some(replies_obj) = replies.as_object() {
            if let Some(listing_data) = replies_obj.get("data") {
                if let Some(listing_children) = listing_data.get("children") {
                    if let Some(listing_array) = listing_children.as_array() {
                        for reply in listing_array {
                            if reply.get("kind").and_then(|k| k.as_str()) == Some("t1") {
                                if let Some(child) = parse_comment_to_tree(reply) {
                                    children.push(child);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let cleaned_text = clean_comment_text(&body);


    Some(CommentTree {
        id: id.to_string(),
        author: author.to_string(),
        time: local_time.format("%Y-%m-%d %H:%M").to_string(),
        text: cleaned_text,
        children,
    })
}

fn parse_comment_to_json(comment: &Value) -> CommentJson {
    let data = &comment["data"];

    let author = data.get("author")
        .and_then(|a| a.as_str())
        .unwrap_or("[deleted]")
        .to_string();
    // Use body_html field which contains HTML that we can convert to text
    let body = data.get("body_html")
        .and_then(|b| b.as_str())
        .unwrap_or("")
        .to_string();
    let score = data.get("score")
        .and_then(|s| s.as_i64())
        .unwrap_or(0);
    let created_utc = data.get("created_utc")
        .and_then(|c| c.as_f64())
        .unwrap_or(0.0);
    let timestamp = Utc.timestamp_opt(created_utc as i64, 0).single()
        .unwrap_or_else(Utc::now);

    let mut replies = Vec::new();
    if let Some(replies_val) = data.get("replies") {
        if let Some(replies_obj) = replies_val.as_object() {
            if let Some(listing_data) = replies_obj.get("data") {
                if let Some(listing_children) = listing_data.get("children") {
                    if let Some(listing_array) = listing_children.as_array() {
                        for reply in listing_array {
                            if reply.get("kind").and_then(|k| k.as_str()) == Some("t1") {
                                replies.push(parse_comment_to_json(reply));
                            }
                        }
                    }
                }
            }
        }
    }

    CommentJson {
        author,
        body: clean_comment_text(&body),
        created_utc: timestamp.to_rfc3339(),
        score,
        replies,
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Handle clear cache command
    if args.clear_cache {
        return clear_cache();
    }

    let url = args.url.ok_or_else(|| anyhow!("URL is required"))?;
    let (submission_id, comment_id) = get_submission_and_comment_id(&url)?;

    // Try to get from cache first (unless skip_cache is set)
    let comments_value = if args.skip_cache {
        None
    } else {
        get_cached_data(&submission_id, comment_id.as_deref())?
    };

    let comments_value = if let Some(cached_data) = comments_value {
        cached_data
    } else {
        // Fetch fresh data
        let subreddit = Subreddit::new("all");
        let comments_response = subreddit.article_comments(&submission_id, None, Some(500)).await?;
        let comments_value: Value = serde_json::to_value(&comments_response)?;

        // Save to cache
        if let Err(e) = save_to_cache(&submission_id, comment_id.as_deref(), &comments_value) {
            eprintln!("Warning: Failed to save to cache: {}", e);
        }

        comments_value
    };

    // The roux response structure is: { data: { children: [...] } }
    let comments = if let Some(cid) = comment_id {
        // Find specific comment in the tree
        let mut found_comments = Vec::new();

        // Check if comments_value has the expected structure
        if let Some(data) = comments_value.get("data") {
            if let Some(children) = data.get("children").and_then(|c| c.as_array()) {
                for comment in children {
                    if comment.get("data").and_then(|d| d.get("id")).and_then(|id| id.as_str()) == Some(&cid) {
                        found_comments.push(comment.clone());
                        break;
                    }
                }
            }
        }

        if found_comments.is_empty() {
            return Err(anyhow!("Comment not found"));
        }
        found_comments
    } else {
        // Get all comments - handle roux response structure
        if let Some(data) = comments_value.get("data") {
            if let Some(children) = data.get("children").and_then(|c| c.as_array()) {
                children.iter()
                    .filter(|c| c.get("kind").and_then(|k| k.as_str()) == Some("t1"))
                    .cloned()
                    .collect()
            } else {
                Vec::new()
            }
        } else {
            Vec::new()
        }
    };

    if args.json {
        let comment_tree: Vec<CommentJson> = comments.iter()
            .map(parse_comment_to_json)
            .collect();
        println!("{}", serde_json::to_string(&comment_tree)?);
    } else {
        let tree_comments: Vec<CommentTree> = comments.iter()
            .filter_map(parse_comment_to_tree)
            .collect();

        let json_input = serde_json::to_string(&tree_comments)?;

        let mut child = Command::new("tree-render")
            .arg("--author=author")
            .arg("--timestamp=time")
            .arg("--content=text")
            .arg("--replies=children")
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .spawn()?;

        if let Some(mut stdin) = child.stdin.take() {
            use std::io::Write;
            stdin.write_all(json_input.as_bytes())?;
        }

        child.wait()?;
    }

    Ok(())
}