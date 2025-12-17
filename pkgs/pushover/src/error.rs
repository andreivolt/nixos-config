use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("API error: {0}")]
    Api(String),

    #[error("Missing environment variable: {0}")]
    MissingEnv(&'static str),

    #[error("HTTP error: {0}")]
    Http(#[from] reqwest::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid priority: {0} (must be -2 to 2 or lowest/low/normal/high/emergency)")]
    InvalidPriority(String),
}

pub type Result<T> = std::result::Result<T, Error>;
