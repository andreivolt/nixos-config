use anyhow::{Context, Result};
use aws_credential_types::provider::ProvideCredentials;
use aws_sdk_s3::config::Credentials;
use aws_sdk_s3::presigning::PresigningConfig;
use aws_sdk_s3::{Client, Config};
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use mime_guess::MimeGuess;
use std::env;
use std::io::{self, Read};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::Duration;

#[derive(Parser)]
#[command(name = "with-url")]
#[command(about = "Upload file to cloud storage and execute command with uploaded file URL")]
struct Args {
    #[arg(short, long, help = "File to upload")]
    file: Option<PathBuf>,

    #[arg(help = "Command to execute with URL", trailing_var_arg = true)]
    command: Vec<String>,
}


struct UploadedFile {
    client: Client,
    bucket: String,
    key: String,
}

impl UploadedFile {
    fn new(client: Client, bucket: String, key: String) -> Self {
        Self { client, bucket, key }
    }
}

impl Drop for UploadedFile {
    fn drop(&mut self) {
        let client = self.client.clone();
        let bucket = self.bucket.clone();
        let key = self.key.clone();

        tokio::spawn(async move {
            let _ = client
                .delete_object()
                .bucket(&bucket)
                .key(&key)
                .send()
                .await;
        });
    }
}

async fn create_s3_client() -> Result<Client> {
    // Get credentials from AWS profile (same as Python version)
    let profile_name = "backblaze";
    let shared_config = aws_config::defaults(aws_config::BehaviorVersion::latest())
        .profile_name(profile_name)
        .load()
        .await;

    let credentials = shared_config.credentials_provider()
        .context("No credentials provider found")?
        .provide_credentials()
        .await
        .context("Failed to load credentials from AWS profile")?;

    // Configure S3 client for Backblaze B2 S3-compatible API
    let config = Config::builder()
        .credentials_provider(Credentials::new(
            credentials.access_key_id(),
            credentials.secret_access_key(),
            credentials.session_token().map(|t| t.to_string()),
            None,
            "backblaze-profile",
        ))
        .region(aws_config::Region::new("us-east-005"))
        .endpoint_url("https://s3.us-east-005.backblazeb2.com")
        .force_path_style(true)
        .build();

    Ok(Client::from_conf(config))
}

async fn upload_file(client: &Client, bucket: &str, data: Vec<u8>, filename: &str) -> Result<String> {
    let mime_type = MimeGuess::from_path(filename)
        .first_or_octet_stream()
        .to_string();

    let file_size = data.len() as u64;

    // Always show progress
    let pb = ProgressBar::new(file_size);
    pb.set_style(
        ProgressStyle::default_bar()
            .template("{spinner:.green} [{elapsed_precise}] [{wide_bar:.cyan/blue}] {bytes}/{total_bytes} ({bytes_per_sec}, {eta})")
            .unwrap()
            .progress_chars("#>-")
    );

    pb.set_message(format!("Uploading {}", filename));

    if file_size < 100 * 1024 { // Files smaller than 100KB use simple upload
        client
            .put_object()
            .bucket(bucket)
            .key(filename)
            .body(data.into())
            .content_type(&mime_type)
            .send()
            .await
            .context("Failed to upload file")?;

        pb.set_position(file_size);
        pb.finish_with_message(format!("✓ Uploaded {}", filename));
    } else {
        // Use multipart upload for real progress tracking
        let upload_id = client
            .create_multipart_upload()
            .bucket(bucket)
            .key(filename)
            .content_type(&mime_type)
            .send()
            .await
            .context("Failed to create multipart upload")?
            .upload_id()
            .unwrap()
            .to_string();

        let chunk_size = 5 * 1024 * 1024; // S3 minimum
        let mut completed_parts = Vec::new();

        let total_parts = (data.len() + chunk_size - 1) / chunk_size;

        for (part_number, chunk) in data.chunks(chunk_size).enumerate() {
            let part_number = (part_number + 1) as i32;

            pb.set_message(format!("Uploading {} (part {}/{})", filename, part_number, total_parts));

            let upload_part_output = client
                .upload_part()
                .bucket(bucket)
                .key(filename)
                .upload_id(&upload_id)
                .part_number(part_number)
                .body(chunk.to_vec().into())
                .send()
                .await
                .context("Failed to upload part")?;

            pb.inc(chunk.len() as u64);

            completed_parts.push(
                aws_sdk_s3::types::CompletedPart::builder()
                    .part_number(part_number)
                    .e_tag(upload_part_output.e_tag().unwrap())
                    .build(),
            );
        }

        client
            .complete_multipart_upload()
            .bucket(bucket)
            .key(filename)
            .upload_id(&upload_id)
            .multipart_upload(
                aws_sdk_s3::types::CompletedMultipartUpload::builder()
                    .set_parts(Some(completed_parts))
                    .build(),
            )
            .send()
            .await
            .context("Failed to complete multipart upload")?;

        pb.finish_with_message(format!("✓ Uploaded {}", filename));
    }

    Ok(filename.to_string())
}

async fn generate_presigned_url(client: &Client, bucket: &str, key: &str) -> Result<String> {
    let presigning_config = PresigningConfig::expires_in(Duration::from_secs(3600))
        .context("Failed to create presigning config")?;

    let presigned_request = client
        .get_object()
        .bucket(bucket)
        .key(key)
        .presigned(presigning_config)
        .await
        .context("Failed to generate presigned URL")?;

    Ok(presigned_request.uri().to_string())
}

fn detect_file_extension(data: &[u8]) -> String {
    // Use infer crate to detect file type from magic bytes
    if let Some(kind) = infer::get(data) {
        return format!(".{}", kind.extension());
    }

    String::new()
}

fn execute_command(cmd_args: &[String], url: &str) -> Result<()> {
    let cmd_string = cmd_args.join(" ");

    let final_cmd = if cmd_string.contains("{}") {
        cmd_string.replace("{}", &shell_escape(url))
    } else {
        format!("{} {}", cmd_string, shell_escape(url))
    };

    let mut child = Command::new("bash")
        .arg("-c")
        .arg(&final_cmd)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .context("Failed to execute command")?;

    let exit_status = child.wait().context("Failed to wait for command")?;

    if !exit_status.success() {
        std::process::exit(exit_status.code().unwrap_or(1));
    }

    Ok(())
}

fn shell_escape(s: &str) -> String {
    format!("'{}'", s.replace('\'', "'\"'\"'"))
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let bucket = env::var("BACKBLAZE_BUCKET")
        .context("BACKBLAZE_BUCKET environment variable not set")?;

    let client = create_s3_client().await?;

    // Read file content and determine filename
    let (file_content, filename) = if let Some(file_path) = &args.file {
        let content = std::fs::read(file_path)
            .with_context(|| format!("Failed to read file: {}", file_path.display()))?;
        let filename = file_path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("upload")
            .to_string();
        (content, filename)
    } else {
        // Read from stdin
        let mut buffer = Vec::new();
        io::stdin()
            .read_to_end(&mut buffer)
            .context("Failed to read from stdin")?;

        // Detect file extension from buffer content
        let extension = detect_file_extension(&buffer);
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        let filename = format!("upload_{}{}", timestamp, extension);

        (buffer, filename)
    };

    // Upload file
    let key = upload_file(&client, &bucket, file_content, &filename).await?;

    // Create cleanup handler
    let _uploaded_file = UploadedFile::new(client.clone(), bucket.clone(), key.clone());

    // Generate presigned URL
    let url = generate_presigned_url(&client, &bucket, &key).await?;

    // Execute command or print URL
    if args.command.is_empty() {
        println!("{}", url);
    } else {
        execute_command(&args.command, &url)?;
    }

    Ok(())
}