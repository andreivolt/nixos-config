use arboard::Clipboard;
use image::{ImageFormat, DynamicImage, RgbaImage};
use std::io::{self, Write, Cursor};
use std::process;

fn main() {
    let mut clipboard = match Clipboard::new() {
        Ok(cb) => cb,
        Err(e) => {
            eprintln!("Failed to access clipboard: {}", e);
            process::exit(1);
        }
    };

    let image_data = match clipboard.get_image() {
        Ok(img) => img,
        Err(e) => {
            eprintln!("Failed to get image from clipboard: {}", e);
            process::exit(1);
        }
    };

    // Convert raw RGBA data to PNG
    let rgba_image = RgbaImage::from_raw(
        image_data.width as u32,
        image_data.height as u32,
        image_data.bytes.to_vec(),
    ).expect("Failed to create RGBA image");

    let dynamic_image = DynamicImage::ImageRgba8(rgba_image);

    let mut png_data = Vec::new();
    let mut cursor = Cursor::new(&mut png_data);

    match dynamic_image.write_to(&mut cursor, ImageFormat::Png) {
        Ok(_) => {},
        Err(e) => {
            eprintln!("Failed to encode PNG: {}", e);
            process::exit(1);
        }
    }

    match io::stdout().write_all(&png_data) {
        Ok(_) => {},
        Err(e) => {
            eprintln!("Failed to write PNG data: {}", e);
            process::exit(1);
        }
    }
}