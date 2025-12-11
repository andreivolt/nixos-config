use objc::runtime::{Class, BOOL, NO};
use objc::{msg_send, sel, sel_impl};
use cocoa::foundation::{NSString, NSArray, NSData, NSURL, NSDictionary};
use cocoa::base::{id, nil};
use clap::Parser;
use std::ffi::CStr;
use std::io::{self, Read};
use std::fs;
use std::path::Path;
use std::process::Command;
use tempfile::NamedTempFile;

#[derive(Parser)]
#[command(about = "Extract text from images using macOS Vision framework")]
struct Args {
    /// Path to image file (use - for stdin)
    image_path: Option<String>,

    /// Copy text to clipboard
    #[arg(short, long)]
    copy: bool,
}

#[link(name = "Vision", kind = "framework")]
extern "C" {}

#[link(name = "CoreImage", kind = "framework")]
extern "C" {}

struct VisionResult {
    text: String,
    #[allow(dead_code)]
    confidence: f64,
}

fn create_ci_image_from_path(path: &str) -> Result<id, String> {
    unsafe {
        let ci_image_class = Class::get("CIImage").ok_or("Failed to get CIImage class")?;
        let ns_path = NSString::alloc(nil).init_str(path);
        let nsurl = NSURL::fileURLWithPath_(nil, ns_path);

        let ci_image: id = msg_send![ci_image_class, imageWithContentsOfURL: nsurl];
        if ci_image == nil {
            return Err("Failed to create CIImage from path".to_string());
        }

        Ok(ci_image)
    }
}

fn create_ci_image_from_data(data: &[u8]) -> Result<id, String> {
    unsafe {
        let ci_image_class = Class::get("CIImage").ok_or("Failed to get CIImage class")?;
        let ns_data = NSData::dataWithBytes_length_(nil, data.as_ptr() as *const _, data.len() as u64);

        let ci_image: id = msg_send![ci_image_class, imageWithData: ns_data];
        if ci_image == nil {
            return Err("Failed to create CIImage from data".to_string());
        }

        Ok(ci_image)
    }
}

fn extract_text_from_image(ci_image: id) -> Result<Vec<VisionResult>, String> {
    unsafe {
        // Create Vision request handler
        let vision_handler_class = Class::get("VNImageRequestHandler").ok_or("Failed to get VNImageRequestHandler class")?;
        let options = NSDictionary::dictionary(nil);
        let handler: id = msg_send![vision_handler_class, alloc];
        let handler: id = msg_send![handler, initWithCIImage: ci_image options: options];

        // Create text recognition request
        let text_request_class = Class::get("VNRecognizeTextRequest").ok_or("Failed to get VNRecognizeTextRequest class")?;
        let request: id = msg_send![text_request_class, alloc];
        let request: id = msg_send![request, init];

        // Create request array
        let requests = NSArray::arrayWithObject(nil, request);

        // Perform request
        let mut error: id = nil;
        let success: BOOL = msg_send![handler, performRequests: requests error: &mut error];

        if success == NO {
            return Err("Vision request failed".to_string());
        }

        // Get results
        let results: id = msg_send![request, results];
        let count: u64 = msg_send![results, count];

        let mut vision_results = Vec::new();

        for i in 0..count {
            let observation: id = msg_send![results, objectAtIndex: i];
            let candidates: id = msg_send![observation, topCandidates: 1u64];

            let candidates_count: u64 = msg_send![candidates, count];
            if candidates_count > 0 {
                let top_candidate: id = msg_send![candidates, objectAtIndex: 0u64];
                let text_string: id = msg_send![top_candidate, string];
                let text_ptr: *const i8 = msg_send![text_string, UTF8String];
                let confidence: f64 = msg_send![top_candidate, confidence];

                if !text_ptr.is_null() {
                    let text = CStr::from_ptr(text_ptr).to_string_lossy().to_string();
                    vision_results.push(VisionResult { text, confidence });
                }
            }
        }

        Ok(vision_results)
    }
}

fn capture_screenshot() -> Result<Vec<u8>, String> {
    let temp_file = NamedTempFile::with_suffix(".png")
        .map_err(|e| format!("Failed to create temp file: {}", e))?;
    let temp_path = temp_file.path().to_path_buf();

    let output = Command::new("screenshot")
        .arg("selection")
        .arg(&temp_path)
        .output()
        .map_err(|e| format!("Failed to run screenshot: {}", e))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("Screenshot capture failed: {}", stderr));
    }

    // Check if file was created and has content
    if !temp_path.exists() || temp_path.metadata().unwrap().len() == 0 {
        return Err("Screenshot capture failed or was cancelled".to_string());
    }

    let data = fs::read(&temp_path)
        .map_err(|e| format!("Failed to read screenshot: {}", e))?;

    // Keep the file alive by forgetting the NamedTempFile
    std::mem::forget(temp_file);
    Ok(data)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let results = match args.image_path.as_deref() {
        Some("-") => {
            // Read from stdin
            let mut buffer = Vec::new();
            io::stdin().read_to_end(&mut buffer)?;
            let ci_image = create_ci_image_from_data(&buffer)?;
            extract_text_from_image(ci_image)?
        }
        Some(path) => {
            // Read from file path
            if !Path::new(path).is_file() {
                return Err("Invalid image path".into());
            }
            let ci_image = create_ci_image_from_path(path)?;
            extract_text_from_image(ci_image)?
        }
        None => {
            // Check if stdin has data
            if atty::is(atty::Stream::Stdin) {
                // No stdin data, capture screenshot
                let screenshot_data = capture_screenshot()?;
                let ci_image = create_ci_image_from_data(&screenshot_data)?;
                extract_text_from_image(ci_image)?
            } else {
                // Read from stdin
                let mut buffer = Vec::new();
                io::stdin().read_to_end(&mut buffer)?;
                let ci_image = create_ci_image_from_data(&buffer)?;
                extract_text_from_image(ci_image)?
            }
        }
    };

    let output_text = results.iter()
        .map(|r| r.text.as_str())
        .collect::<Vec<_>>()
        .join("\n");

    if args.copy {
        use clipboard::ClipboardProvider;
        let mut ctx: clipboard::ClipboardContext = ClipboardProvider::new()
            .map_err(|e| format!("Failed to create clipboard context: {}", e))?;
        ctx.set_contents(output_text)
            .map_err(|e| format!("Failed to copy to clipboard: {}", e))?;
        println!("Text copied to clipboard");
    } else {
        println!("{}", output_text);
    }

    Ok(())
}
