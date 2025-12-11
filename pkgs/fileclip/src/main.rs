#[macro_use]
extern crate objc;

use cocoa::appkit::NSPasteboard;
use cocoa::base::{id, nil};
use cocoa::foundation::{NSArray, NSString, NSURL};
use std::env;
use std::fs;
use std::path::Path;
use std::process;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() != 2 {
        eprintln!("Usage: {} <file_path>", args[0]);
        process::exit(1);
    }

    let file_path = &args[1];

    // Check if file exists
    if !Path::new(file_path).exists() {
        eprintln!("Error: File '{}' does not exist", file_path);
        process::exit(1);
    }

    // Convert to absolute path
    let abs_path = match fs::canonicalize(file_path) {
        Ok(path) => path,
        Err(e) => {
            eprintln!("Error getting absolute path: {}", e);
            process::exit(1);
        }
    };

    // Copy to clipboard
    match copy_file_to_clipboard(&abs_path.to_string_lossy()) {
        Ok(_) => println!("File copied to clipboard: {}", abs_path.display()),
        Err(e) => {
            eprintln!("Error copying to clipboard: {}", e);
            process::exit(1);
        }
    }
}

fn copy_file_to_clipboard(file_path: &str) -> Result<(), String> {
    unsafe {
        // Get the general pasteboard
        let pasteboard: id = NSPasteboard::generalPasteboard(nil);

        // Clear the pasteboard
        let _: () = msg_send![pasteboard, clearContents];

        // Create NSURL from file path
        let file_url_string = format!("file://{}", file_path);
        let ns_string = NSString::alloc(nil).init_str(&file_url_string);
        let file_url: id = NSURL::URLWithString_(nil, ns_string);

        if file_url == nil {
            return Err("Failed to create NSURL".to_string());
        }

        // Create array with the file URL
        let urls_array = NSArray::arrayWithObject(nil, file_url);

        // Write to pasteboard - this copies the file as a file object
        let success: bool = msg_send![pasteboard, writeObjects: urls_array];

        if success {
            Ok(())
        } else {
            Err("Failed to write to pasteboard".to_string())
        }
    }
}
