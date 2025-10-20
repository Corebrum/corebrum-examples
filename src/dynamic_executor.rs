use anyhow::{Result, Context};
use crate::schema::{TaskDefinition, TaskSource, TaskStatus, Result as TaskResult};
use std::collections::HashMap;
use std::process::Command;
use std::fs;
use tempfile::TempDir;
use serde_json;

pub struct DynamicTaskExecutor {
    temp_dir: Option<TempDir>,
}

impl DynamicTaskExecutor {
    pub fn new() -> Self {
        Self {
            temp_dir: None,
        }
    }

    pub async fn execute_task(
        &mut self,
        task_definition: &TaskDefinition,
        inputs: serde_json::Value,
    ) -> Result<TaskResult> {
        let start_time = std::time::Instant::now();
        
        // Create temporary directory for execution
        let temp_dir = TempDir::new().context("Failed to create temporary directory")?;
        self.temp_dir = Some(temp_dir);
        
        let result = match &task_definition.source {
            TaskSource::Inline { code } => {
                self.execute_inline_code(&task_definition.language, code, inputs).await
            }
            TaskSource::Url { url } => {
                self.execute_from_url(url, inputs).await
            }
            TaskSource::Git { repo, path, branch } => {
                self.execute_from_git(repo, path, branch.as_deref(), inputs).await
            }
            TaskSource::Gist { id, filename } => {
                self.execute_from_gist(id, filename, inputs).await
            }
            TaskSource::Wasm { wasm_bytes } => {
                self.execute_wasm(wasm_bytes, inputs).await
            }
            TaskSource::Docker { image, command } => {
                self.execute_docker(image, command, inputs).await
            }
        };

        let execution_time = start_time.elapsed().as_secs_f64();
        
        match result {
            Ok(outputs) => Ok(TaskResult {
                task_id: uuid::Uuid::new_v4().to_string(),
                worker_id: "dynamic_executor".to_string(),
                status: TaskStatus::Completed,
                outputs,
                error: None,
                execution_time_seconds: Some(execution_time),
                completed_at: chrono::Utc::now(),
            }),
            Err(e) => Ok(TaskResult {
                task_id: uuid::Uuid::new_v4().to_string(),
                worker_id: "dynamic_executor".to_string(),
                status: TaskStatus::Failed,
                outputs: HashMap::new(),
                error: Some(e.to_string()),
                execution_time_seconds: Some(execution_time),
                completed_at: chrono::Utc::now(),
            }),
        }
    }

    async fn execute_inline_code(
        &self,
        language: &str,
        code: &str,
        inputs: serde_json::Value,
    ) -> Result<HashMap<String, serde_json::Value>> {
        let temp_dir = self.temp_dir.as_ref().unwrap();
        
        match language {
            "python" => {
                let script_path = temp_dir.path().join("script.py");
                fs::write(&script_path, code)?;
                
                // Write inputs to a JSON file
                let inputs_path = temp_dir.path().join("inputs.json");
                fs::write(&inputs_path, serde_json::to_string(&inputs)?)?;
                
                let output = Command::new("python3")
                    .arg(&script_path)
                    .arg(&inputs_path)
                    .current_dir(temp_dir.path())
                    .output()?;
                
                if !output.status.success() {
                    anyhow::bail!("Python execution failed: {}", String::from_utf8_lossy(&output.stderr));
                }
                
                let result_str = String::from_utf8(output.stdout)?;
                let result: HashMap<String, serde_json::Value> = serde_json::from_str(&result_str)?;
                Ok(result)
            }
            "javascript" | "js" => {
                let script_path = temp_dir.path().join("script.js");
                fs::write(&script_path, code)?;
                
                let inputs_path = temp_dir.path().join("inputs.json");
                fs::write(&inputs_path, serde_json::to_string(&inputs)?)?;
                
                let output = Command::new("node")
                    .arg(&script_path)
                    .arg(&inputs_path)
                    .current_dir(temp_dir.path())
                    .output()?;
                
                if !output.status.success() {
                    anyhow::bail!("JavaScript execution failed: {}", String::from_utf8_lossy(&output.stderr));
                }
                
                let result_str = String::from_utf8(output.stdout)?;
                let result: HashMap<String, serde_json::Value> = serde_json::from_str(&result_str)?;
                Ok(result)
            }
            _ => anyhow::bail!("Unsupported language: {}", language),
        }
    }

    async fn execute_from_url(&self, url: &str, inputs: serde_json::Value) -> Result<HashMap<String, serde_json::Value>> {
        // Download and execute code from URL
        let response = reqwest::get(url).await?;
        let code = response.text().await?;
        
        // Determine language from URL or content
        let language = if url.ends_with(".py") {
            "python"
        } else if url.ends_with(".js") {
            "javascript"
        } else {
            "python" // default
        };
        
        self.execute_inline_code(language, &code, inputs).await
    }

    async fn execute_from_git(&self, repo: &str, path: &str, branch: Option<&str>, inputs: serde_json::Value) -> Result<HashMap<String, serde_json::Value>> {
        let temp_dir = self.temp_dir.as_ref().unwrap();
        
        // Clone repository
        let mut git_cmd = Command::new("git");
        git_cmd.arg("clone");
        if let Some(branch) = branch {
            git_cmd.arg("-b").arg(branch);
        }
        git_cmd.arg(repo).arg(temp_dir.path().join("repo"));
        
        let output = git_cmd.output()?;
        if !output.status.success() {
            anyhow::bail!("Git clone failed: {}", String::from_utf8_lossy(&output.stderr));
        }
        
        // Execute the file
        let file_path = temp_dir.path().join("repo").join(path);
        let code = fs::read_to_string(&file_path)?;
        
        let language = if path.ends_with(".py") {
            "python"
        } else if path.ends_with(".js") {
            "javascript"
        } else {
            "python" // default
        };
        
        self.execute_inline_code(language, &code, inputs).await
    }

    async fn execute_from_gist(&self, id: &str, filename: &str, inputs: serde_json::Value) -> Result<HashMap<String, serde_json::Value>> {
        let url = format!("https://gist.githubusercontent.com/{}/raw/{}", id, filename);
        self.execute_from_url(&url, inputs).await
    }

    async fn execute_wasm(&self, wasm_bytes: &[u8], inputs: serde_json::Value) -> Result<HashMap<String, serde_json::Value>> {
        // WASM execution would require wasmtime runtime
        // This is a simplified implementation
        anyhow::bail!("WASM execution not yet implemented")
    }

    async fn execute_docker(&self, image: &str, command: &[String], inputs: serde_json::Value) -> Result<HashMap<String, serde_json::Value>> {
        // Docker execution would require docker daemon
        // This is a simplified implementation
        anyhow::bail!("Docker execution not yet implemented")
    }
}

impl Drop for DynamicTaskExecutor {
    fn drop(&mut self) {
        // Cleanup is handled automatically by TempDir
    }
}
