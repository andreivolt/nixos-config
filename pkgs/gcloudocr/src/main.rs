
use clap::Parser;
use google_cloud_vision_v1::client::ImageAnnotator;
use google_cloud_vision_v1::model::{
    AnnotateImageRequest, Feature, Image, TextAnnotation,
    feature::Type
};
use std::io::{self, Read};
use std::process::Command;
use anyhow::{Result, Context};
use arboard::Clipboard;
use bytes::Bytes;

#[derive(Parser)]
#[command(about = "OCR tool using Google Cloud Vision API")]
struct Args {
    /// Input file (reads from stdin if not provided)
    file: Option<String>,

    /// Take screenshot
    #[arg(short, long)]
    screenshot: bool,

    /// Preserve layout using document detection
    #[arg(short, long)]
    layout: bool,

    /// Copy text to clipboard
    #[arg(short, long)]
    copy: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let image_data = if args.screenshot {
        let output = Command::new("screenshot")
            .output()
            .context("Failed to take screenshot")?;

        if !output.status.success() {
            return Err(anyhow::anyhow!("Screenshot failed: {}", String::from_utf8_lossy(&output.stderr)));
        }

        output.stdout
    } else if let Some(file) = args.file {
        std::fs::read(&file)?
    } else {
        let mut buffer = Vec::new();
        io::stdin().read_to_end(&mut buffer)?;
        buffer
    };

    let result = detect_text(image_data, args.layout).await?;

    if args.copy {
        let mut clipboard = Clipboard::new()?;
        clipboard.set_text(&result)?;
        println!("Text copied to clipboard");
    } else {
        println!("{}", result);
    }

    Ok(())
}

async fn detect_text(image_data: Vec<u8>, use_layout: bool) -> Result<String> {
    if image_data.is_empty() {
        return Err(anyhow::anyhow!("No image data provided"));
    }

    let client = ImageAnnotator::builder().build().await?;

    let image = Image::new()
        .set_content(Bytes::from(image_data));

    let feature = Feature::new()
        .set_type(if use_layout {
            Type::DocumentTextDetection
        } else {
            Type::TextDetection
        })
        .set_max_results(1)
        .set_model("builtin/stable".to_string());

    let annotate_request = AnnotateImageRequest::new()
        .set_image(image)
        .set_features(vec![feature]);

    let response = client
        .batch_annotate_images()
        .set_requests(vec![annotate_request])
        .send()
        .await?;

    if let Some(resp) = response.responses.first() {
        if use_layout {
            if let Some(annotation) = &resp.full_text_annotation {
                return Ok(format_with_layout(annotation));
            }
        }

        if let Some(annotation) = &resp.full_text_annotation {
            return Ok(annotation.text.clone());
        }

        if let Some(first) = resp.text_annotations.first() {
            return Ok(first.description.clone());
        }
    }

    Ok("No text detected".to_string())
}

fn format_with_layout(annotation: &TextAnnotation) -> String {
    if annotation.pages.is_empty() {
        return annotation.text.clone();
    }

    let mut positioned_words: Vec<_> = annotation.pages.iter()
        .flat_map(|page| &page.blocks)
        .flat_map(|block| &block.paragraphs)
        .flat_map(|paragraph| &paragraph.words)
        .filter_map(|word| {
            let word_text: String = word.symbols.iter()
                .map(|s| s.text.as_str())
                .collect();

            if word_text.trim().is_empty() {
                return None;
            }

            word.bounding_box.as_ref().map(|bbox| {
                let x = bbox.vertices.iter().map(|v| v.x).min().unwrap_or(0);
                let y = bbox.vertices.iter().map(|v| v.y).min().unwrap_or(0);
                (word_text, x, y)
            })
        })
        .collect();

    positioned_words.sort_by_key(|&(_, x, y)| (y, x));

    let mut lines = Vec::new();
    let mut current_line = Vec::new();
    let mut current_y: Option<i32> = None;
    let line_threshold = 10;

    for (text, x, y) in positioned_words {
        if current_y.map_or(true, |cy| (y - cy).abs() <= line_threshold) {
            current_line.push((text, x));
            current_y = current_y.or(Some(y));
        } else {
            current_line.sort_by_key(|&(_, x): &(String, i32)| x);
            lines.push(current_line.iter().map(|(t, _)| t.as_str()).collect::<Vec<_>>().join(" "));
            current_line = vec![(text, x)];
            current_y = Some(y);
        }
    }

    if !current_line.is_empty() {
        current_line.sort_by_key(|&(_, x): &(String, i32)| x);
        lines.push(current_line.iter().map(|(t, _)| t.as_str()).collect::<Vec<_>>().join(" "));
    }

    lines.join("\n")
}