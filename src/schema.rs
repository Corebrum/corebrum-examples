use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskDefinition {
    pub name: String,
    pub description: Option<String>,
    pub language: String,
    pub source: TaskSource,
    pub inputs: Vec<TaskInput>,
    pub outputs: Vec<TaskOutput>,
    pub requirements: Option<TaskRequirements>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskSource {
    Inline { code: String },
    Url { url: String },
    Git { repo: String, path: String, branch: Option<String> },
    Gist { id: String, filename: String },
    Wasm { wasm_bytes: Vec<u8> },
    Docker { image: String, command: Vec<String> },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskInput {
    pub name: String,
    pub description: Option<String>,
    pub required: bool,
    pub default_value: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskOutput {
    pub name: String,
    pub description: Option<String>,
    pub data_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskRequirements {
    pub memory_mb: Option<u64>,
    pub cpu_cores: Option<u32>,
    pub timeout_seconds: Option<u64>,
    pub dependencies: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Job {
    pub task_id: String,
    pub queue: String,
    pub task_definition: Option<TaskDefinition>,
    pub inputs: serde_json::Value,
    pub priority: Option<i32>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub timeout_seconds: Option<u64>,
}

impl Job {
    pub fn new_user_task(queue: String, task_definition: TaskDefinition, inputs: serde_json::Value) -> Self {
        Self {
            task_id: uuid::Uuid::new_v4().to_string(),
            queue,
            task_definition: Some(task_definition),
            inputs,
            priority: Some(0),
            created_at: chrono::Utc::now(),
            timeout_seconds: Some(300), // 5 minutes default
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claim {
    pub task_id: String,
    pub worker_id: String,
    pub claimed_at: chrono::DateTime<chrono::Utc>,
    pub estimated_duration_seconds: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Assign {
    pub task_id: String,
    pub worker_id: String,
    pub assigned_at: chrono::DateTime<chrono::Utc>,
    pub task_definition: TaskDefinition,
    pub inputs: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Status {
    pub task_id: String,
    pub worker_id: String,
    pub status: TaskStatus,
    pub message: Option<String>,
    pub progress: Option<f64>,
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskStatus {
    Pending,
    Claimed,
    Assigned,
    Running,
    Completed,
    Failed,
    Timeout,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Result {
    pub task_id: String,
    pub worker_id: String,
    pub status: TaskStatus,
    pub outputs: HashMap<String, serde_json::Value>,
    pub error: Option<String>,
    pub execution_time_seconds: Option<f64>,
    pub completed_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkerInfo {
    pub worker_id: String,
    pub capabilities: Vec<String>,
    pub status: WorkerStatus,
    pub last_heartbeat: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum WorkerStatus {
    Available,
    Busy,
    Offline,
}
