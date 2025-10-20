use anyhow::Result;
use zenoh::Session;
use serde::{Deserialize, Serialize};

// Helper functions for Zenoh operations

pub async fn create_zenoh_session() -> Result<Session> {
    let config = zenoh::Config::default();
    let session = zenoh::open(config).await.map_err(|e| anyhow::anyhow!("Failed to open Zenoh session: {}", e))?;
    Ok(session)
}

pub fn serialize_to_string<T>(data: &T) -> Result<String>
where
    T: Serialize,
{
    let json = serde_json::to_string(data)?;
    Ok(json)
}

// Extension trait to add .into_anyhow() method for compatibility
pub trait IntoAnyhow<T> {
    fn into_anyhow(self) -> Result<T>;
}

impl<T, E> IntoAnyhow<T> for std::result::Result<T, E>
where
    E: std::error::Error + Send + Sync + 'static,
{
    fn into_anyhow(self) -> Result<T> {
        self.map_err(|e| anyhow::anyhow!(e))
    }
}

// Extension trait for Zenoh Result types
pub trait ZenohResultExt<T> {
    fn into_anyhow(self) -> Result<T>;
}

impl<T> ZenohResultExt<T> for zenoh::Result<T> {
    fn into_anyhow(self) -> Result<T> {
        self.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))
    }
}

// Utility for logging Zenoh operations
pub fn log_zenoh_operation(operation: &str, key: &str) {
    println!("🔗 Zenoh {}: {}", operation, key);
}

// Helper for error handling in Zenoh operations
pub fn handle_zenoh_error(error: zenoh::Error, operation: &str) -> anyhow::Error {
    anyhow::anyhow!("Zenoh {} failed: {}", operation, error)
}