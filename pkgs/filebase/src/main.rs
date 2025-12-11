use aws_config::BehaviorVersion;
use aws_sdk_s3::Client;
use aws_sdk_s3::primitives::ByteStream;
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use mime_guess::MimeGuess;
use rand::Rng;
use std::io::{self, Read};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(about = "Upload files to Filebase storage service")]
struct Args {
    /// File to upload
    file: Option<PathBuf>,

    /// Copy URL to clipboard (macOS only)
    #[arg(short, long)]
    copy: bool,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Initialize S3 client with filebase profile
    let config = aws_config::defaults(BehaviorVersion::latest())
        .profile_name("filebase")
        .load()
        .await;
    let client = Client::new(&config);
    let bucket = "andreiv";

    let (content, file_name, content_type) = if let Some(file_path) = args.file {
        // Read file from path
        let content = std::fs::read(&file_path)?;
        let file_name = file_path
            .file_name()
            .ok_or("Invalid file name")?
            .to_string_lossy()
            .to_string();

        // Get MIME type
        let mime_type = MimeGuess::from_path(&file_path)
            .first_raw()
            .unwrap_or("application/octet-stream");

        (content, file_name, mime_type.to_string())
    } else {
        // Read from stdin
        let mut content = Vec::new();
        io::stdin().read_to_end(&mut content)?;

        // Detect content type and extension using infer crate
        let (content_type, ext) = if let Some(kind) = infer::get(&content) {
            (kind.mime_type().to_string(), kind.extension().to_string())
        } else {
            return Err("Unable to determine file type".into());
        };

        // Generate random filename
        let random_hex: String = (0..8)
            .map(|_| format!("{:02x}", rand::thread_rng().gen::<u8>()))
            .collect();
        let file_name = format!("{}.{}", random_hex, ext);

        (content, file_name, content_type)
    };

    // Upload to S3 with progress using multipart for large files
    let content_length = content.len() as u64;
    let pb = ProgressBar::new(content_length);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({bytes_per_sec}) ({eta})")?
        .progress_chars("#>-"));

    pb.set_message("Uploading");

    const CHUNK_SIZE: usize = 5 * 1024 * 1024; // 5MB chunks
    const MIN_MULTIPART_SIZE: usize = 5 * 1024 * 1024; // Use multipart for files >= 5MB

    if content.len() >= MIN_MULTIPART_SIZE {
        // Use multipart upload for large files
        let multipart_upload = client
            .create_multipart_upload()
            .bucket(bucket)
            .key(&file_name)
            .content_type(&content_type)
            .metadata("Content-Type", &content_type)
            .send()
            .await?;

        let upload_id = multipart_upload.upload_id().unwrap();
        let mut completed_parts = Vec::new();

        for (part_number, chunk) in content.chunks(CHUNK_SIZE).enumerate() {
            let part_num = (part_number + 1) as i32;
            let part_result = client
                .upload_part()
                .bucket(bucket)
                .key(&file_name)
                .upload_id(upload_id)
                .part_number(part_num)
                .body(ByteStream::from(chunk.to_vec()))
                .send()
                .await?;

            completed_parts.push(
                aws_sdk_s3::types::CompletedPart::builder()
                    .part_number(part_num)
                    .e_tag(part_result.e_tag().unwrap())
                    .build(),
            );

            pb.inc(chunk.len() as u64);
        }

        client
            .complete_multipart_upload()
            .bucket(bucket)
            .key(&file_name)
            .upload_id(upload_id)
            .multipart_upload(
                aws_sdk_s3::types::CompletedMultipartUpload::builder()
                    .set_parts(Some(completed_parts))
                    .build(),
            )
            .send()
            .await?;
    } else {
        // Use single part upload for small files
        let body = ByteStream::from(content);
        client
            .put_object()
            .bucket(bucket)
            .key(&file_name)
            .body(body)
            .content_type(&content_type)
            .metadata("Content-Type", &content_type)
            .send()
            .await?;

        pb.inc(content_length);
    }

    pb.finish_with_message("Upload complete");

    // Get object metadata to retrieve CID
    let head_response = client
        .head_object()
        .bucket(bucket)
        .key(&file_name)
        .send()
        .await?;

    let cid = head_response
        .metadata()
        .and_then(|m| m.get("cid"))
        .ok_or("CID not found in metadata")?;

    let ipfs_url = format!("https://ipfs.filebase.io/ipfs/{}", cid);

    if args.copy {
        #[cfg(target_os = "macos")]
        {
            use clipboard::{ClipboardContext, ClipboardProvider};
            let mut ctx: ClipboardContext = ClipboardProvider::new()?;
            ctx.set_contents(ipfs_url)?;
            println!("URL copied to clipboard");
        }
        #[cfg(not(target_os = "macos"))]
        {
            eprintln!("Clipboard support is only available on macOS");
            println!("{}", ipfs_url);
        }
    } else {
        println!("{}", ipfs_url);
    }

    Ok(())
}