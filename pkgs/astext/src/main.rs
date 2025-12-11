use anyhow::Result;
use clap::Parser;
use mime_guess::mime;
use sha2::{Sha256, Digest};
use std::{fs, io::{self, Read}, path::Path, process::{Command, Stdio}};

#[derive(Parser)]
#[command(about = "Convert files to plain text")]
struct Args {
    #[arg(help = "Input files (reads from stdin if not provided)")]
    files: Vec<String>,

    #[arg(short = 'o', long = "output", help = "Output file (default: stdout)")]
    output: Option<String>,

    #[arg(short = 'n', long = "no-cache", help = "Disable caching")]
    no_cache: bool,
}

fn pandoc_convert(path: &Path, from: &str) -> Result<String> {
    let output = Command::new("pandoc")
        .args(["-f", from, "-t", "plain", "--wrap=none"])
        .arg(path)
        .output()?;

    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

fn soffice_convert(path: &Path) -> Result<String> {
    let temp_dir = std::env::temp_dir();
    let stem = path.file_stem().unwrap().to_str().unwrap();
    let html_path = temp_dir.join(format!("{}.html", stem));

    let output = Command::new("soffice")
        .args(["--headless", "--convert-to", "html", "--outdir"])
        .arg(&temp_dir)
        .arg(path)
        .output()?;

    if !output.status.success() {
        anyhow::bail!("soffice failed: {}", String::from_utf8_lossy(&output.stderr));
    }

    if !html_path.exists() {
        anyhow::bail!("HTML file not created: {}", html_path.display());
    }

    let result = pandoc_convert(&html_path, "html");
    let _ = fs::remove_file(&html_path);
    result
}


fn file_hash(path: &Path) -> Result<String> {
    let content = fs::read(path)?;
    let hash = Sha256::digest(&content);
    Ok(format!("{:x}", hash))
}

fn get_cache_dir() -> Result<std::path::PathBuf> {
    let cache_dir = dirs::cache_dir()
        .ok_or_else(|| anyhow::anyhow!("Could not determine cache directory"))?
        .join("2text");

    // Create cache directory if it doesn't exist
    fs::create_dir_all(&cache_dir)?;
    Ok(cache_dir)
}

fn get_cache_path(file_path: &Path, hash: &str) -> Result<std::path::PathBuf> {
    let cache_dir = get_cache_dir()?;

    // Create a cache filename that includes the original filename and hash
    let filename = file_path.file_name()
        .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?
        .to_str()
        .ok_or_else(|| anyhow::anyhow!("Invalid filename"))?;

    let cache_filename = format!("{}-{}.txt", filename, &hash[..8]);
    Ok(cache_dir.join(cache_filename))
}

fn convert(path: &Path, use_cache: bool) -> Result<String> {
    if !use_cache {
        return convert_impl(path);
    }

    let hash = file_hash(path)?;
    let cache_path = get_cache_path(path, &hash)?;

    // Check if cache exists
    if cache_path.exists() {
        if let Ok(cached) = fs::read_to_string(&cache_path) {
            return Ok(cached);
        }
    }

    // Not cached, convert and save
    let result = convert_impl(path)?;
    let _ = fs::write(&cache_path, &result);
    Ok(result)
}

fn convert_impl(path: &Path) -> Result<String> {
    let mime = mime_guess::from_path(path).first_or_text_plain();

    match (mime.type_(), mime.subtype().as_str()) {
        (mime::TEXT, "html") => pandoc_convert(path, "html"),
        (mime::TEXT, _) => Ok(fs::read_to_string(path)?),
        (mime::APPLICATION, "pdf") => Command::new("pdftotext")
            .args(["-layout", path.to_str().unwrap(), "-"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).into_owned())
            .map_err(Into::into),
        (mime::APPLICATION, s) if s.contains("word") => soffice_convert(path),
        (mime::APPLICATION, s) if s.contains("opendocument") => soffice_convert(path),
        (mime::APPLICATION, "rtf") => soffice_convert(path),
        (mime::APPLICATION, s) if s.contains("excel") => soffice_convert(path),
        (mime::APPLICATION, s) if s.contains("powerpoint") => soffice_convert(path),
        (mime::APPLICATION, s) if s.contains("epub") => pandoc_convert(path, "epub"),
        (mime::IMAGE, _) => Command::new("tesseract")
            .args([path.to_str().unwrap(), "stdout"])
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).into_owned())
            .map_err(Into::into),
        _ => anyhow::bail!("Unsupported: {}", mime),
    }
}

fn convert_stdin() -> Result<String> {
    let mut stdin = io::stdin();
    let mut buffer = Vec::new();
    stdin.read_to_end(&mut buffer)?;

    // Try pdftotext with stdin first (it can handle PDF from stdin)
    let mut child = Command::new("pdftotext")
        .args(["-layout", "-", "-"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        use std::io::Write;
        stdin.write_all(&buffer)?;
    }

    let output = child.wait_with_output()?;

    if output.status.success() && !output.stdout.is_empty() {
        Ok(String::from_utf8_lossy(&output.stdout).into_owned())
    } else {
        // Fallback: write to temp file and try to detect type
        let temp_path = std::env::temp_dir().join(format!("2text_stdin_{}.tmp", std::process::id()));
        fs::write(&temp_path, &buffer)?;
        let result = convert_impl(&temp_path);
        let _ = fs::remove_file(&temp_path);
        result
    }
}

fn main() -> Result<()> {
    let args = Args::parse();

    if args.files.is_empty() {
        // Read from stdin
        let result = convert_stdin()?;
        match args.output {
            Some(output_path) => fs::write(output_path, result)?,
            None => print!("{}", result),
        }
    } else {
        let paths: Vec<_> = args.files.iter().map(Path::new).collect();
        let use_cache = !args.no_cache;

        match args.output {
            Some(output_path) => {
                let mut output = String::new();
                for path in &paths {
                    output.push_str(&convert(path, use_cache)?);
                }
                fs::write(output_path, output)?;
            },
            None => {
                for path in &paths {
                    print!("{}", convert(path, use_cache)?);
                }
            },
        }
    }

    Ok(())
}
