use anyhow::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use serde_json;
use crate::schema::*;
use crate::dynamic_executor::DynamicTaskExecutor;

const NS: &str = "comp";
const QUEUE: &str = "user_tasks";

// Keyspace helpers
fn k_announce() -> String {
    format!("{}/queues/{}/announce", NS, QUEUE)
}

fn k_task(task_id: &str) -> String {
    format!("{}/tasks/{}", NS, task_id)
}

fn k_claim(task_id: &str) -> String {
    format!("{}/claim", k_task(task_id))
}

fn k_assign(task_id: &str) -> String {
    format!("{}/assign", k_task(task_id))
}

fn k_status(task_id: &str) -> String {
    format!("{}/status", k_task(task_id))
}

fn k_result(task_id: &str) -> String {
    format!("{}/result", k_task(task_id))
}

pub struct SimpleUserDefinedDemo {
    running: Arc<AtomicBool>,
}

impl SimpleUserDefinedDemo {
    pub fn new() -> Self {
        Self {
            running: Arc::new(AtomicBool::new(true)),
        }
    }

    pub async fn create_factorial_task_definition(number: u64) -> TaskDefinition {
        TaskDefinition {
            name: "factorial_computation".to_string(),
            version: "1.0".to_string(),
            description: format!("Compute factorial of {}", number),
            inputs: vec![
                serde_json::json!({
                    "name": "number",
                    "type": "integer",
                    "required": true,
                    "default": number,
                    "description": "Number to compute factorial for"
                })
            ],
            outputs: vec![
                serde_json::json!({
                    "name": "result",
                    "type": "integer",
                    "description": "The computed factorial"
                })
            ],
            compute_logic: ComputeLogic {
                logic_type: "expression".to_string(),
                language: "rust".to_string(),
                code: Some(format!(
                    r#"
use std::time::Instant;

let start_time = Instant::now();
let number = inputs["number"].as_u64().unwrap_or({});
let factorial = (1..=number).product::<u64>();
let end_time = Instant::now();
let computation_time = start_time.duration_since(start_time).as_millis();

let result = serde_json::json!({{
    "factorial": factorial,
    "computation_time_ms": computation_time,
    "input_number": number
}});
"#,
                    number
                )),
                code_source: None,
                timeout_seconds: 30,
            },
            validation: vec![
                serde_json::json!({
                    "field": "number",
                    "min": 0,
                    "max": 20,
                    "message": "Number must be between 0 and 20 for performance"
                })
            ],
            metadata: serde_json::json!({
                "estimated_duration_ms": 100,
                "memory_requirement_mb": 10,
                "cpu_intensive": true
            }),
        }
    }

    pub async fn create_fibonacci_task_definition(terms: u64) -> TaskDefinition {
        TaskDefinition {
            name: "fibonacci_sequence".to_string(),
            version: "1.0".to_string(),
            description: format!("Generate Fibonacci sequence up to {} terms", terms),
            inputs: vec![
                serde_json::json!({
                    "name": "terms",
                    "type": "integer",
                    "required": true,
                    "default": terms,
                    "description": "Number of terms to generate"
                })
            ],
            outputs: vec![
                serde_json::json!({
                    "name": "sequence",
                    "type": "array",
                    "description": "The Fibonacci sequence"
                })
            ],
            compute_logic: ComputeLogic {
                logic_type: "expression".to_string(),
                language: "rust".to_string(),
                code: Some(format!(
                    r#"
fn fibonacci(n: u64) -> Vec<u64> {{
    if n == 0 {{
        return vec![];
    }} else if n == 1 {{
        return vec![0];
    }} else if n == 2 {{
        return vec![0, 1];
    }}
    
    let mut sequence = vec![0, 1];
    for i in 2..n {{
        sequence.push(sequence[i as usize - 1] + sequence[i as usize - 2]);
    }}
    sequence
}}

let terms = inputs["terms"].as_u64().unwrap_or({});
let sequence = fibonacci(terms);

let result = serde_json::json!({{
    "sequence": sequence,
    "terms": sequence.len(),
    "last_term": sequence.last().copied()
}});
"#,
                    terms
                )),
                code_source: None,
                timeout_seconds: 30,
            },
            validation: vec![
                serde_json::json!({
                    "field": "terms",
                    "min": 1,
                    "max": 50,
                    "message": "Terms must be between 1 and 50"
                })
            ],
            metadata: serde_json::json!({
                "estimated_duration_ms": 50,
                "memory_requirement_mb": 5,
                "cpu_intensive": false
            }),
        }
    }

    pub async fn run_simple_demo(&self) -> Result<()> {
        println!("🚀 Zenoh User-Defined Compute Tasks Demo (Rust - Simplified)");
        println!("=============================================================");
        println!("Note: This is a simplified demo that simulates task execution");
        println!("without actual Zenoh messaging due to API compatibility issues.");
        println!();

        // Simulate task execution
        println!("📋 Creating and executing user-defined tasks...");

        // Example 1: Factorial task
        let factorial_def = Self::create_factorial_task_definition(10).await;
        let factorial_job = Job::new_user_task(QUEUE.to_string(), factorial_def, serde_json::json!({"number": 10}));
        
        println!("📤 Created factorial task: {} ({})", factorial_job.task_id, factorial_job.task_definition.as_ref().unwrap().name);
        
        // Simulate execution
        let executor = DynamicTaskExecutor::new()?;
        let result = executor.execute_task(&factorial_job, "worker-1")?;
        
        println!("📊 RESULT: {} - {}", result.task_id, if result.ok { "✅ SUCCESS" } else { "❌ FAILED" });
        if !result.artifacts.is_empty() {
            for (artifact_name, artifact_content) in &result.artifacts {
                if let Ok(result_data) = serde_json::from_str::<serde_json::Value>(artifact_content) {
                    println!("   {}: {}", artifact_name, result_data);
                }
            }
        }

        // Example 2: Fibonacci task
        let fibonacci_def = Self::create_fibonacci_task_definition(15).await;
        let fibonacci_job = Job::new_user_task(QUEUE.to_string(), fibonacci_def, serde_json::json!({"terms": 15}));
        
        println!("\n📤 Created Fibonacci task: {} ({})", fibonacci_job.task_id, fibonacci_job.task_definition.as_ref().unwrap().name);
        
        // Simulate execution
        let result2 = executor.execute_task(&fibonacci_job, "worker-2")?;
        
        println!("📊 RESULT: {} - {}", result2.task_id, if result2.ok { "✅ SUCCESS" } else { "❌ FAILED" });
        if !result2.artifacts.is_empty() {
            for (artifact_name, artifact_content) in &result2.artifacts {
                if let Ok(result_data) = serde_json::from_str::<serde_json::Value>(artifact_content) {
                    println!("   {}: {}", artifact_name, result_data);
                }
            }
        }

        println!("\n✅ Demo completed!");
        println!("\nNote: For full Zenoh integration, the API compatibility issues need to be resolved.");
        println!("The Python implementation provides a fully working example with actual Zenoh messaging.");
        
        Ok(())
    }
}
