
use clap::Parser;
use regex::Regex;
use serde_json::Value;
use std::io::{self, Read};
use std::fs;

#[derive(Parser, Debug)]
#[command(author, version, about = "Convert JSON to Nix format", long_about = None)]
struct Args {
    /// Input JSON file (read from stdin if not provided)
    file: Option<String>,

    /// Flatten nested objects into dot notation
    #[arg(long)]
    flatten: bool,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Read input
    let input = if let Some(file) = args.file {
        fs::read_to_string(file)?
    } else {
        let mut buffer = String::new();
        io::stdin().read_to_string(&mut buffer)?;
        buffer
    };

    // Strip comments
    let json_str = strip_comments(&input);

    // Parse JSON
    let value: Value = serde_json::from_str(&json_str)?;

    // Convert to Nix
    let nix_str = if args.flatten && value.is_object() {
        flatten_object(&value)
    } else {
        fmt_any(&value, 0)
    };

    println!("{}", nix_str);

    Ok(())
}

fn strip_comments(text: &str) -> String {
    // Remove // comments while preserving them in quoted strings
    let comment_re = Regex::new(r#"("(?:[^"\\]|\\.)*")|//.*$"#).unwrap();

    text.lines()
        .map(|line| {
            let mut result = String::new();
            let mut last_end = 0;

            for cap in comment_re.captures_iter(line) {
                let m = cap.get(0).unwrap();
                result.push_str(&line[last_end..m.start()]);

                if let Some(quoted) = cap.get(1) {
                    // It's a quoted string, keep it
                    result.push_str(quoted.as_str());
                }
                // If it's a comment (no group 1), skip it

                last_end = m.end();
            }
            result.push_str(&line[last_end..]);
            result
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn nix_stringify(s: &str) -> String {
    // Check if string contains newlines
    if s.contains('\n') {
        // Use multiline string syntax
        format!("''{}''", s)
    } else {
        // Escape ${ to prevent Nix interpolation
        let escaped = s.replace("${", "\\${");
        format!("\"{}\"", escaped)
    }
}

fn sanitize_key(key: &str) -> String {
    // Check if key is a valid Nix identifier
    let identifier_re = Regex::new(r"^[a-zA-Z_][a-zA-Z0-9_-]*$").unwrap();

    if identifier_re.is_match(key) {
        key.to_string()
    } else {
        nix_stringify(key)
    }
}

fn indent(level: usize) -> String {
    "  ".repeat(level)
}

fn fmt_any(value: &Value, level: usize) -> String {
    match value {
        Value::Null => "null".to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Number(n) => n.to_string(),
        Value::String(s) => nix_stringify(s),
        Value::Array(arr) => fmt_array(arr, level),
        Value::Object(obj) => fmt_object(obj, level),
    }
}

fn fmt_array(arr: &Vec<Value>, level: usize) -> String {
    if arr.is_empty() {
        return "[ ]".to_string();
    }

    let mut result = String::from("[\n");
    for (i, item) in arr.iter().enumerate() {
        result.push_str(&indent(level + 1));
        result.push_str(&fmt_any(item, level + 1));
        if i < arr.len() - 1 {
            result.push('\n');
        }
    }
    result.push('\n');
    result.push_str(&indent(level));
    result.push(']');
    result
}

fn fmt_object(obj: &serde_json::Map<String, Value>, level: usize) -> String {
    if obj.is_empty() {
        return "{ }".to_string();
    }

    let entries = obj
        .iter()
        .map(|(key, value)| {
            format!(
                "{}{} = {};",
                indent(level + 1),
                sanitize_key(key),
                fmt_any(value, level + 1)
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    format!("{{\n{}\n{}}}", entries, indent(level))
}

fn flatten_object(value: &Value) -> String {
    if let Value::Object(obj) = value {
        let entries = flatten_obj_items(obj, "")
            .iter()
            .map(|(key, val)| {
                format!("  {} = {};", sanitize_key(key), fmt_any(val, 1))
            })
            .collect::<Vec<_>>()
            .join("\n");

        format!("{{\n{}\n}}", entries)
    } else {
        "{ }".to_string()
    }
}

fn flatten_obj_items(obj: &serde_json::Map<String, Value>, prefix: &str) -> Vec<(String, Value)> {
    let mut result = Vec::new();

    for (key, value) in obj {
        let new_key = if prefix.is_empty() {
            key.clone()
        } else {
            format!("{}.{}", prefix, key)
        };

        match value {
            Value::Object(nested_obj) => {
                result.extend(flatten_obj_items(nested_obj, &new_key));
            }
            _ => {
                result.push((new_key, value.clone()));
            }
        }
    }

    result
}