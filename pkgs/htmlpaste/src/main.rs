use clipboard_rs::{Clipboard, ClipboardContext};
use std::process;

fn main() {
    let ctx = ClipboardContext::new().unwrap();

    match ctx.get_html() {
        Ok(html) => {
            println!("{}", html);
        }
        Err(_) => {
            eprintln!("Could not find HTML data on the system clipboard");
            process::exit(1);
        }
    }
}