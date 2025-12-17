use std::process;

#[cfg(target_os = "linux")]
fn get_html() -> Result<String, String> {
    use std::io::Read;
    use wl_clipboard_rs::paste::{get_contents, ClipboardType, MimeType, Seat};

    let result = get_contents(ClipboardType::Regular, Seat::Unspecified, MimeType::Specific("text/html"));

    match result {
        Ok((mut pipe, _)) => {
            let mut contents = String::new();
            pipe.read_to_string(&mut contents)
                .map_err(|e| format!("Failed to read clipboard: {}", e))?;
            Ok(contents)
        }
        Err(_) => Err("Could not find HTML data on the system clipboard".to_string()),
    }
}

#[cfg(not(target_os = "linux"))]
fn get_html() -> Result<String, String> {
    use clipboard_rs::{Clipboard, ClipboardContext};
    let ctx = ClipboardContext::new().map_err(|e| e.to_string())?;
    ctx.get_html().map_err(|_| "Could not find HTML data on the system clipboard".to_string())
}

fn main() {
    match get_html() {
        Ok(html) => {
            print!("{}", html);
        }
        Err(e) => {
            eprintln!("{}", e);
            process::exit(1);
        }
    }
}