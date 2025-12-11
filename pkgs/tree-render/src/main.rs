
use std::env;
use std::io::{self, Read};
use std::process;

use clap::Parser;
use crossterm::style::{Color, SetBackgroundColor, SetForegroundColor, ResetColor, Stylize};
use serde_json::Value;
use terminal_size::{Width, terminal_size};
use textwrap::wrap;

#[derive(Parser, Debug)]
#[command(about = "Render tree-structured data in terminal")]
struct Args {
    #[arg(long, default_value = "user", help = "Field name for comment author")]
    author: String,

    #[arg(long, default_value = "timeAgo", help = "Field name for comment timestamp")]
    timestamp: String,

    #[arg(long, default_value = "text", help = "Field name for comment content")]
    content: String,

    #[arg(long, default_value = "children", help = "Field name for comment replies")]
    replies: String,

    #[arg(long, help = "Field name for header/story data")]
    header: Option<String>,

    #[arg(long, help = "Read JSONL input (one JSON object per line)")]
    jsonl: bool,
}

#[derive(Debug, Clone)]
struct FieldMap {
    author: String,
    timestamp: String,
    content: String,
    replies: String,
}

impl FieldMap {
    fn new(args: &Args) -> Self {
        Self {
            author: args.author.clone(),
            timestamp: args.timestamp.clone(),
            content: args.content.clone(),
            replies: args.replies.clone(),
        }
    }
}

#[derive(Debug, Clone)]
struct Comment {
    data: Value,
}

impl Comment {
    fn new(data: Value) -> Self {
        Self { data }
    }

    fn get_field(&self, field_map: &FieldMap, field_type: &str) -> String {
        let field_name = match field_type {
            "author" => &field_map.author,
            "timestamp" => &field_map.timestamp,
            "content" => &field_map.content,
            "replies" => &field_map.replies,
            _ => field_type,
        };

        self.data.get(field_name)
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string()
    }

    fn get_children(&self, field_map: &FieldMap) -> Vec<Comment> {
        let replies_field = &field_map.replies;
        let empty_vec = vec![];
        let children_data = self.data.get(replies_field)
            .or_else(|| self.data.get("children"))
            .and_then(|v| v.as_array())
            .unwrap_or(&empty_vec);

        children_data.iter()
            .map(|child| Comment::new(child.clone()))
            .collect()
    }
}

struct ColorManager {
    colors: Vec<Color>,
    no_color: bool,
    is_tty: bool,
}

impl ColorManager {
    fn new() -> Self {
        let no_color = env::var("NO_COLOR").is_ok();
        let is_tty = crossterm::tty::IsTty::is_tty(&io::stdout());

        let colors = vec![
            Color::Rgb { r: 139, g: 0, b: 0 },    // Dark red
            Color::Rgb { r: 0, g: 100, b: 0 },    // Dark green
            Color::Rgb { r: 0, g: 0, b: 139 },    // Dark blue
            Color::Rgb { r: 128, g: 0, b: 128 },  // Purple
            Color::Rgb { r: 255, g: 140, b: 0 },  // Dark orange
            Color::Rgb { r: 220, g: 20, b: 60 },  // Crimson
            Color::Rgb { r: 25, g: 25, b: 112 },  // Midnight blue
            Color::Rgb { r: 128, g: 128, b: 0 },  // Olive
            Color::Rgb { r: 75, g: 0, b: 130 },   // Indigo
            Color::Rgb { r: 0, g: 128, b: 128 },  // Teal
            Color::Rgb { r: 165, g: 42, b: 42 },  // Brown
            Color::Rgb { r: 72, g: 61, b: 139 },  // Dark slate blue
        ];

        Self { colors, no_color, is_tty }
    }

    fn get_author_color(&self, author: &str) -> Option<Color> {
        if !self.is_tty || self.no_color {
            return None;
        }

        let digest = md5::compute(author.as_bytes());
        let hash = u128::from_be_bytes(digest.0);
        let color_index = (hash as usize) % self.colors.len();
        Some(self.colors[color_index])
    }

    fn format_author(&self, author: &str, timestamp: &str) -> String {
        if let Some(color) = self.get_author_color(author) {
            format!("{}{}{} ({}){}",
                SetBackgroundColor(color),
                SetForegroundColor(Color::White),
                author,
                timestamp,
                ResetColor
            )
        } else {
            format!("{} ({})", author, timestamp)
        }
    }
}

struct MarkdownRenderer {
    width: usize,
    no_color: bool,
}

impl MarkdownRenderer {
    fn new(width: usize) -> Self {
        let no_color = env::var("NO_COLOR").is_ok() || !crossterm::tty::IsTty::is_tty(&io::stdout());
        Self { width, no_color }
    }

    fn render(&self, text: &str) -> String {
        // Just wrap text to specified width - no markdown/HTML processing
        let wrapped_lines: Vec<String> = text.lines()
            .flat_map(|line| {
                if line.trim().is_empty() {
                    vec![String::new()]
                } else {
                    wrap(line, self.width).into_iter().map(|s| s.to_string()).collect()
                }
            })
            .collect();

        wrapped_lines.join("\n")
    }
}

#[derive(Debug)]
struct ConversationMessage {
    author: String,
    timestamp: String,
    text: String,
}

struct ConversationDetector;

impl ConversationDetector {
    fn extract_conversation(comment: &Comment, field_map: &FieldMap, is_root: bool) -> (Vec<ConversationMessage>, Vec<Comment>) {
        let mut conversation = Vec::new();
        let mut current = comment.clone();
        let mut remaining_children = Vec::new();

        loop {
            let author = current.get_field(field_map, "author");
            let author = if author.is_empty() { "[deleted]".to_string() } else { author };

            conversation.push(ConversationMessage {
                author: author.clone(),
                timestamp: current.get_field(field_map, "timestamp"),
                text: current.get_field(field_map, "content"),
            });

            let children = current.get_children(field_map);
            if children.is_empty() {
                break;
            } else if is_root {
                // For root comments, don't merge with children - just treat them as separate comments
                remaining_children = children;
                break;
            } else if children.len() == 1 {
                let child = &children[0];
                let child_author = child.get_field(field_map, "author");
                let child_author = if child_author.is_empty() { "[deleted]".to_string() } else { child_author };

                if child_author != author {
                    current = child.clone();
                } else {
                    remaining_children = children;
                    break;
                }
            } else {
                // Multiple children - check if they're all from same author
                let authors: std::collections::HashSet<String> = children.iter()
                    .map(|child| {
                        let a = child.get_field(field_map, "author");
                        if a.is_empty() { "[deleted]".to_string() } else { a }
                    })
                    .collect();

                if authors.len() == 1 {
                    let next_author = authors.iter().next().unwrap();
                    if next_author != &author {
                        // Merge all children into one
                        let mut texts = Vec::new();
                        let mut all_grandchildren = Vec::new();

                        for child in &children {
                            let child_text = child.get_field(field_map, "content");
                            if !child_text.is_empty() {
                                texts.push(child_text);
                            }
                            all_grandchildren.extend(child.get_children(field_map));
                        }

                        // Create merged child (simplified - using first child as base)
                        let mut merged_data = children[0].data.clone();
                        if let Some(obj) = merged_data.as_object_mut() {
                            obj.insert(field_map.content.clone(), Value::String(texts.join("\n\n")));
                            obj.insert(field_map.replies.clone(), serde_json::to_value(&all_grandchildren.iter().map(|c| &c.data).collect::<Vec<_>>()).unwrap_or(Value::Array(vec![])));
                        }
                        current = Comment::new(merged_data);
                    } else {
                        remaining_children = children;
                        break;
                    }
                } else {
                    remaining_children = children;
                    break;
                }
            }
        }

        (conversation, remaining_children)
    }

    fn is_alternating_conversation(conversation: &[ConversationMessage]) -> bool {
        if conversation.len() < 3 {
            return false;
        }

        for i in 1..conversation.len() {
            if conversation[i].author == conversation[i-1].author {
                return false;
            }
        }
        true
    }
}

struct TreeRenderer {
    field_map: FieldMap,
    color_manager: ColorManager,
    terminal_width: usize,
}

impl TreeRenderer {
    fn new(field_map: FieldMap) -> Self {
        let terminal_width = terminal_size()
            .map(|(Width(w), _)| w as usize)
            .unwrap_or(80);

        Self {
            field_map,
            color_manager: ColorManager::new(),
            terminal_width,
        }
    }

    fn render_header(&self, data: &Value, header_key: &str) {
        if let Some(story) = data.get(header_key) {
            let title = story.get("title").and_then(|v| v.as_str()).unwrap_or("No title");
            if self.color_manager.no_color {
                println!("{}", title);
            } else {
                println!("{}", crossterm::style::style(title).bold());
            }

            if let Some(url) = story.get("url").and_then(|v| v.as_str()) {
                if self.color_manager.no_color {
                    println!("{}", url);
                } else {
                    println!("{}", crossterm::style::style(url).dim());
                }
            }

            let points = story.get("points").and_then(|v| v.as_u64()).unwrap_or(0);
            let user = story.get("user").and_then(|v| v.as_str()).unwrap_or("unknown");
            if self.color_manager.no_color {
                println!("{} points by {}", points, user);
            } else {
                println!("{} points by {}",
                    crossterm::style::style(points).with(crossterm::style::Color::Green),
                    crossterm::style::style(user).with(crossterm::style::Color::Blue)
                );
            }
            println!();
        }
    }

    fn render_comment_tree(&self, comments: &[Comment]) {
        for (i, comment) in comments.iter().enumerate() {
            let is_last = i == comments.len() - 1;
            self.print_comment(comment, "", is_last, true);
        }
    }

    fn print_comment(&self, comment: &Comment, prefix: &str, is_last: bool, is_root: bool) {
        let (conversation, remaining_children) = ConversationDetector::extract_conversation(comment, &self.field_map, is_root);

        if !is_root && conversation.len() >= 3 && ConversationDetector::is_alternating_conversation(&conversation) {
            // Render flattened conversation
            let author = if conversation[0].author.is_empty() { "[deleted]".to_string() } else { conversation[0].author.clone() };
            let name = self.color_manager.format_author(&author, &conversation[0].timestamp);

            if is_root {
                println!("{}", name);
            } else {
                let symbol = if is_last { "└── " } else { "├── " };
                println!("{}{}{}", prefix, symbol, name);
            }

            let text_prefix = if is_root {
                String::new()
            } else {
                format!("{}{}", prefix, if is_last { "    " } else { "│   " })
            };

            let available_width = self.terminal_width.saturating_sub(text_prefix.len()).max(40);
            let renderer = MarkdownRenderer::new(available_width);

            for (i, msg) in conversation.iter().enumerate() {
                if !msg.text.is_empty() {
                    if i > 0 {
                        let author_name = self.color_manager.format_author(&msg.author, &msg.timestamp);
                        println!("{}{}", text_prefix, author_name);
                    }

                    let rendered_text = renderer.render(&msg.text);
                    for line in rendered_text.lines() {
                        if !line.trim().is_empty() {
                            println!("{}{}", text_prefix, line);
                        }
                    }

                    if !rendered_text.trim().is_empty() {
                        println!("{}", text_prefix);
                    }
                }
            }
        } else {
            // Render single comment
            let author = comment.get_field(&self.field_map, "author");
            let author = if author.is_empty() { "[deleted]".to_string() } else { author };
            let timestamp = comment.get_field(&self.field_map, "timestamp");
            let name = self.color_manager.format_author(&author, &timestamp);

            if is_root {
                println!("{}", name);
            } else {
                let symbol = if is_last { "└── " } else { "├── " };
                println!("{}{}{}", prefix, symbol, name);
            }

            let comment_text = comment.get_field(&self.field_map, "content");
            if !comment_text.is_empty() {
                let text_prefix = if is_root {
                    String::new()
                } else {
                    format!("{}{}", prefix, if is_last { "    " } else { "│   " })
                };

                let available_width = self.terminal_width.saturating_sub(text_prefix.len()).max(40);
                let renderer = MarkdownRenderer::new(available_width);
                let rendered_text = renderer.render(&comment_text);

                for line in rendered_text.lines() {
                    if !line.trim().is_empty() {
                        println!("{}{}", text_prefix, line);
                    }
                }

                if !rendered_text.trim().is_empty() {
                    println!("{}", text_prefix);
                }
            }
        }

        // Print remaining children
        if !remaining_children.is_empty() {
            for (i, child) in remaining_children.iter().enumerate() {
                let child_prefix = if is_root {
                    String::new()
                } else {
                    format!("{}{}", prefix, if is_last { "    " } else { "│   " })
                };
                let child_is_last = i == remaining_children.len() - 1;
                self.print_comment(child, &child_prefix, child_is_last, false);
            }
        }
    }
}

fn main() {
    let args = Args::parse();
    let field_map = FieldMap::new(&args);

    // Read JSON from stdin
    let mut input = String::new();
    if let Err(e) = io::stdin().read_to_string(&mut input) {
        eprintln!("Error reading stdin: {}", e);
        process::exit(1);
    }

    if input.trim().is_empty() {
        eprintln!("Error: No input provided");
        process::exit(1);
    }

    // Parse JSON or JSONL
    let data: Value = if args.jsonl {
        // Parse JSONL - each line is a separate JSON object
        let mut comments = Vec::new();
        for line in input.lines() {
            let line = line.trim();
            if line.is_empty() {
                continue;
            }
            match serde_json::from_str::<Value>(line) {
                Ok(comment) => comments.push(comment),
                Err(e) => {
                    eprintln!("Error: Invalid JSON on line - {}", e);
                    process::exit(1);
                }
            }
        }
        Value::Array(comments)
    } else {
        // Parse regular JSON
        match serde_json::from_str(&input) {
            Ok(data) => data,
            Err(e) => {
                eprintln!("Error: Invalid JSON - {}", e);
                process::exit(1);
            }
        }
    };

    let renderer = TreeRenderer::new(field_map);

    // Handle header if present
    if let Some(header_key) = &args.header {
        renderer.render_header(&data, header_key);
    }

    // Get comments from data
    let comments = if let Some(comments_array) = data.get("comments").and_then(|v| v.as_array()) {
        comments_array.iter().map(|c| Comment::new(c.clone())).collect()
    } else if let Some(data_array) = data.as_array() {
        data_array.iter().map(|c| Comment::new(c.clone())).collect()
    } else {
        vec![]
    };

    if comments.is_empty() {
        println!("No comments");
        return;
    }

    renderer.render_comment_tree(&comments);
}