
use clap::{Parser, ValueEnum};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};
use chrono::NaiveDate;
use html_escape::decode_html_entities;
use console::{style, Term};
use anyhow::Result;
use derive_more::{Constructor, Display, From};

#[derive(Debug, Display, From)]
enum SearchError {
    #[display(fmt = "API Error: {}", _0)]
    Api(String),
    #[display(fmt = "Request failed: {}", _0)]
    #[from]
    Request(reqwest::Error),
    #[display(fmt = "JSON parsing failed: {}", _0)]
    #[from]
    Json(serde_json::Error),
    #[display(fmt = "Date parsing failed: {}", _0)]
    Date(String),
}

// Helper type for cleaner code
#[derive(Constructor)]
struct PaginationParams {
    page: u32,
    hits_per_page: u32,
}

#[derive(Parser, Clone)]
#[command(name = "hn-search")]
#[command(about = "Search Hacker News stories and comments using Algolia API")]
struct Args {
    /// Search query (optional if using filters)
    query: Option<String>,

    /// Sort by relevance or date
    #[arg(long, value_enum, default_value = "relevance")]
    sort: SortBy,

    /// Filter by tags (story, comment, show_hn, ask_hn, poll)
    #[arg(long)]
    tags: Option<String>,

    /// Filter by author username
    #[arg(long)]
    author: Option<String>,

    /// Max results to fetch (uses optimal pagination automatically)
    #[arg(short, long, default_value = "20")]
    limit: u32,

    /// Minimum points filter
    #[arg(long)]
    points: Option<u32>,

    /// Minimum comments filter
    #[arg(long)]
    num_comments: Option<u32>,

    /// Filter before date (YYYY-MM-DD)
    #[arg(long)]
    before: Option<String>,

    /// Filter after date (YYYY-MM-DD)
    #[arg(long)]
    after: Option<String>,

    /// Time range shortcut
    #[arg(long, value_enum)]
    time_range: Option<TimeRange>,

    /// Output raw JSON response
    #[arg(long)]
    raw: bool,

    /// Formatted output
    #[arg(long)]
    pretty: bool,

}

#[derive(Clone, ValueEnum, Display)]
enum SortBy {
    #[display(fmt = "relevance")]
    Relevance,
    #[display(fmt = "date")]
    Date,
}

#[derive(Clone, ValueEnum, Display)]
enum TimeRange {
    #[value(name = "24h")]
    #[display(fmt = "24h")]
    Day,
    #[display(fmt = "week")]
    Week,
    #[display(fmt = "month")]
    Month,
    #[display(fmt = "year")]
    Year,
}

#[derive(Deserialize, Serialize, Constructor)]
struct SearchResponse {
    hits: Vec<Hit>,
    #[serde(rename = "nbHits")]
    nb_hits: u32,
    page: u32,
    #[serde(rename = "nbPages")]
    nb_pages: u32,
}

#[derive(Deserialize, Serialize, Clone)]
struct Hit {
    #[serde(rename = "objectID")]
    object_id: String,
    title: Option<String>,
    url: Option<String>,
    author: Option<String>,
    points: Option<u32>,
    #[serde(rename = "num_comments")]
    num_comments: Option<u32>,
    #[serde(rename = "created_at")]
    created_at: Option<String>,
    #[serde(rename = "story_title")]
    story_title: Option<String>,
    #[serde(rename = "comment_text")]
    comment_text: Option<String>,
    #[serde(rename = "story_text")]
    story_text: Option<String>,
}

fn date_to_timestamp(date_str: &str) -> Result<u64> {
    let date = NaiveDate::parse_from_str(date_str, "%Y-%m-%d")
        .map_err(|_| anyhow::anyhow!("Invalid date format '{}'. Use YYYY-MM-DD", date_str))?;
    Ok(date.and_hms_opt(0, 0, 0).unwrap().and_utc().timestamp() as u64)
}

fn build_numeric_filters(args: &Args) -> Option<String> {
    let mut filters = Vec::new();

    if let Some(points) = args.points {
        filters.push(format!("points>={}", points));
    }

    if let Some(num_comments) = args.num_comments {
        filters.push(format!("num_comments>={}", num_comments));
    }

    if args.before.is_some() || args.after.is_some() {
        if let Some(before) = &args.before {
            match date_to_timestamp(before) {
                Ok(ts) => filters.push(format!("created_at_i<{}", ts)),
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
        if let Some(after) = &args.after {
            match date_to_timestamp(after) {
                Ok(ts) => filters.push(format!("created_at_i>{}", ts)),
                Err(e) => {
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
    } else if let Some(time_range) = &args.time_range {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let cutoff = match time_range {
            TimeRange::Day => now - 86400,
            TimeRange::Week => now - 604800,
            TimeRange::Month => now - 2592000,
            TimeRange::Year => now - 31536000,
        };

        filters.push(format!("created_at_i>{}", cutoff));
    }

    if filters.is_empty() {
        None
    } else {
        Some(filters.join(","))
    }
}

fn build_tags(args: &Args) -> Option<String> {
    let mut tags = Vec::new();

    if let Some(tag_str) = &args.tags {
        tags.extend(tag_str.split(',').map(|s| s.to_string()));
    }

    if let Some(author) = &args.author {
        tags.push(format!("author_{}", author));
    }

    if tags.is_empty() {
        None
    } else {
        Some(tags.join(","))
    }
}

fn build_query_params(args: &Args, page: u32, hits_per_page: u32) -> HashMap<String, String> {
    let mut params = HashMap::new();

    params.insert("query".to_string(), args.query.as_deref().unwrap_or("").to_string());
    params.insert("page".to_string(), page.to_string());
    params.insert("hitsPerPage".to_string(), hits_per_page.to_string());

    if let Some(tags) = build_tags(args) {
        params.insert("tags".to_string(), tags);
    }

    if let Some(filters) = build_numeric_filters(args) {
        params.insert("numericFilters".to_string(), filters);
    }

    params
}

fn strip_html_tags(text: &str) -> String {
    let mut result = text.to_string();

    // First, protect code blocks by marking them specially
    // Use (?s) flag to make . match newlines
    let re_pre = regex::Regex::new(r"(?s)<pre><code>(.*?)</code></pre>").unwrap();
    let mut code_blocks = Vec::new();
    let mut code_idx = 0;

    // Extract code blocks and replace with placeholders
    for cap in re_pre.captures_iter(&result.clone()) {
        if let Some(code) = cap.get(1) {
            let placeholder = format!("__CODE_BLOCK_{}__", code_idx);
            code_blocks.push(code.as_str().to_string());
            result = result.replace(&cap[0], &format!("\n\n{}\n\n", placeholder));
            code_idx += 1;
        }
    }

    // Handle inline code
    let re_code = regex::Regex::new(r"<code>(.*?)</code>").unwrap();
    result = re_code.replace_all(&result, "`$1`").to_string();

    // Replace paragraph and break tags with newlines
    result = result.replace("<p>", "\n\n");
    result = result.replace("</p>", "");
    result = result.replace("<br>", "\n");
    result = result.replace("<br/>", "\n");
    result = result.replace("<br />", "\n");

    // Use ammonia to safely strip remaining HTML tags
    let mut builder = ammonia::Builder::new();
    builder.tags(std::collections::HashSet::new());
    builder.clean_content_tags(std::collections::HashSet::new());

    result = builder.clean(&result).to_string();

    // Restore code blocks with proper indentation
    for (idx, code) in code_blocks.iter().enumerate() {
        let placeholder = format!("__CODE_BLOCK_{}__", idx);
        // Decode HTML entities in code blocks
        let decoded = html_escape::decode_html_entities(code);
        // Indent code blocks for readability
        let indented = decoded.lines()
            .map(|line| format!("    {}", line))
            .collect::<Vec<_>>()
            .join("\n");
        result = result.replace(&placeholder, &indented);
    }

    // Clean up excessive whitespace while preserving structure
    let lines: Vec<&str> = result.trim().split('\n').collect();
    let mut cleaned_lines = Vec::new();
    let mut prev_empty = false;

    for line in lines {
        let trimmed = line.trim_end(); // Only trim end to preserve code indentation
        if trimmed.is_empty() {
            if !prev_empty {
                cleaned_lines.push("");
                prev_empty = true;
            }
        } else {
            // Preserve leading spaces for code blocks
            if line.starts_with("    ") {
                cleaned_lines.push(line);
            } else {
                cleaned_lines.push(trimmed.trim());
            }
            prev_empty = false;
        }
    }

    cleaned_lines.join("\n")
}

fn format_hit(hit: &Hit, pretty: bool, use_color: bool) -> String {
    let hit_type = if hit.story_text.is_some() || hit.title.is_some() {
        "story"
    } else {
        "comment"
    };

    let hn_url = format!("https://news.ycombinator.com/item?id={}", hit.object_id);

    if hit_type == "story" {
        let title = hit.title.as_deref().unwrap_or("No title");
        let title = decode_html_entities(title).to_string();
        let url = hit.url.as_deref().unwrap_or("");
        let author = hit.author.as_deref().unwrap_or("unknown");
        let points = hit.points.unwrap_or(0);
        let comments = hit.num_comments.unwrap_or(0);
        let created = hit.created_at.as_deref().unwrap_or("");

        if pretty {
            let mut result = format!("📰 {}", title);
            if !url.is_empty() {
                result.push_str(&format!("\n   🔗 {}", url));
            }
            result.push_str(&format!("\n   💬 {}", hn_url));
            result.push_str(&format!("\n   👤 {} | ⭐ {} | 💬 {} | 📅 {}", author, points, comments, created));
            result
        } else {
            let story_tag = if use_color {
                style("[STORY]").blue().bright().to_string()
            } else {
                "[STORY]".to_string()
            };
            let mut result = format!("{} {} | {} | {}pts | {}cmt | {} | {}", story_tag, title, author, points, comments, created, hn_url);
            if !url.is_empty() {
                result.push_str(&format!(" | {}", url));
            }
            result
        }
    } else {
        let author = hit.author.as_deref().unwrap_or("unknown");
        let story_title = hit.story_title.as_deref().unwrap_or("Unknown story");
        let story_title = decode_html_entities(story_title).to_string();
        let comment_text = hit.comment_text.as_deref().unwrap_or("");
        let comment_text = strip_html_tags(&decode_html_entities(comment_text).to_string());
        let created = hit.created_at.as_deref().unwrap_or("");

        if pretty {
            let mut result = format!("💬 Comment by {} on: {}", author, story_title);
            if !comment_text.is_empty() {
                let indented_text = comment_text.lines()
                    .map(|line| format!("   {}", line))
                    .collect::<Vec<_>>()
                    .join("\n");
                result.push_str(&format!("\n{}", indented_text));
            }
            result.push_str(&format!("\n   🔗 {}", hn_url));
            result.push_str(&format!("\n   📅 {}", created));
            result
        } else {
            let comment_tag = if use_color {
                style("[COMMENT]").green().bright().to_string()
            } else {
                "[COMMENT]".to_string()
            };
            let mut result = format!("{} {} on \"{}\" | {} | {}", comment_tag, author, story_title, created, hn_url);
            if !comment_text.is_empty() {
                let single_line_text = comment_text.replace('\n', " ");
                result.push_str(&format!(" | {}", single_line_text));
            }
            result
        }
    }
}

async fn search_hn(args: &Args, page: u32, hits_per_page: u32) -> Result<SearchResponse> {
    let base_url = match args.sort {
        SortBy::Date => "https://hn.algolia.com/api/v1/search_by_date",
        SortBy::Relevance => "https://hn.algolia.com/api/v1/search",
    };

    let params = build_query_params(args, page, hits_per_page);
    let client = Client::new();
    let response = client.get(base_url).query(&params).send().await?;

    if !response.status().is_success() {
        return Err(anyhow::anyhow!("API Error: {}", response.status()));
    }

    let search_response: SearchResponse = response.json().await?;
    Ok(search_response)
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Calculate optimal pagination strategy
    let requested_limit = args.limit;
    let max_hits_per_page = 1000u32;

    let mut all_hits = Vec::new();
    let mut total_fetched = 0u32;
    let mut current_page = 0u32;
    let mut last_response: Option<SearchResponse> = None;

    while total_fetched < requested_limit {
        // Calculate optimal hits_per_page for this request
        let remaining = requested_limit - total_fetched;
        let hits_per_page = remaining.min(max_hits_per_page);

        let response = search_hn(&args, current_page, hits_per_page).await?;
        let hits = &response.hits;

        if hits.is_empty() {
            break;
        }

        // Take only what we need (shouldn't exceed but be safe)
        let hits_to_take = (hits.len() as u32).min(remaining);

        for hit in hits.iter().take(hits_to_take as usize) {
            all_hits.push(hit.clone());
        }
        total_fetched += hits_to_take;

        // Stop if we've got everything we need or hit API limits
        if total_fetched >= requested_limit ||
           hits.len() < hits_per_page as usize ||
           total_fetched >= response.nb_hits {
            last_response = Some(response);
            break;
        }

        current_page += 1;
        last_response = Some(response);
    }

    let results = SearchResponse::new(
        all_hits,
        last_response.as_ref().map(|r| r.nb_hits).unwrap_or(0),
        0, // Always show as page 0 since we're doing count-based
        last_response.as_ref().map(|r| r.nb_pages).unwrap_or(0),
    );

    if args.raw {
        println!("{}", serde_json::to_string_pretty(&results)?);
        return Ok(());
    }

    let hits = &results.hits;
    let nb_hits = results.nb_hits;
    let use_color = Term::stdout().features().colors_supported();

    if args.pretty {
        println!("Fetched {} of {} requested results (total available: {})",
                 hits.len(), args.limit, nb_hits);
        println!("{}", "=".repeat(80));
    }

    if hits.is_empty() {
        println!("No results found.");
        return Ok(());
    }

    if args.pretty {
        for (i, hit) in hits.iter().enumerate() {
            println!("{}. {}", i + 1, format_hit(hit, true, use_color));
            println!();
        }
    } else {
        for hit in hits {
            println!("{}", format_hit(hit, false, use_color));
        }
    }

    Ok(())
}