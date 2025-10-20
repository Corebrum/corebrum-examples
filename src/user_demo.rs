use anyhow::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use serde_json;
use corebrum_examples::schema::*;
use corebrum_examples::dynamic_executor::DynamicTaskExecutor;

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

pub struct UserDefinedDemo {
    running: Arc<AtomicBool>,
}

impl UserDefinedDemo {
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
                code: format!(
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
                ),
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
                code: format!(
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
                ),
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

    pub async fn submit_task(&self, session: &zenoh::Session, task_definition: TaskDefinition, inputs: serde_json::Value) -> Result<String> {
        let job = Job::new_user_task(QUEUE.to_string(), task_definition, inputs);
        
        let publisher = session.declare_publisher(&k_announce()).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
        let job_json = serde_json::to_string(&job)?;
        publisher.put(job_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
        
        println!("📤 Submitted user task: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
        Ok(job.task_id)
    }

    pub async fn worker_simulation(&self, worker_id: &str, latency_ms: u32) -> Result<()> {
        println!("👷 Worker {} started (latency: {}ms)", worker_id, latency_ms);
        
        let session = zenoh::open(zenoh::Config::default()).await.map_err(|e| anyhow::anyhow!("Failed to open Zenoh session: {}", e))?;
        let subscriber = session.declare_subscriber(&k_announce()).await.map_err(|e| anyhow::anyhow!("Failed to declare subscriber: {}", e))?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    let payload = sample.payload().deserialize::<String>()?;
                    let job: Job = serde_json::from_str(&payload)?;
                    println!("🔍 Worker {} sees job: {} ({})", worker_id, job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    
                    // Submit claim
                    let now_ms = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)?
                        .as_millis() as u64;
                    
                    let claim = Claim {
                        task_id: job.task_id.clone(),
                        worker_id: worker_id.to_string(),
                        claimed_at: chrono::Utc::now(),
                        estimated_duration_seconds: Some(5),
                    };
                    
                    let claim_publisher = session.declare_publisher(&k_claim(&job.task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
                    let claim_json = serde_json::to_string(&claim)?;
                    claim_publisher.put(claim_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    println!("📝 Worker {} claimed job {}", worker_id, job.task_id);
                    
                    // Wait for assignment
                    let assign_subscriber = session.declare_subscriber(&k_assign(&job.task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare subscriber: {}", e))?;
                    let mut assigned = false;
                    let start_time = std::time::SystemTime::now();
                    
                    while std::time::SystemTime::now().duration_since(start_time)? < Duration::from_secs(1) && self.running.load(Ordering::Relaxed) {
                        match assign_subscriber.recv_async().await {
                            Ok(assign_sample) => {
                                if !self.running.load(Ordering::Relaxed) {
                                    break;
                                }
                                let payload = assign_sample.payload().deserialize::<String>()?;
                    let assign: Assign = serde_json::from_str(&payload)?;
                                if assign.worker_id == worker_id {
                                    assigned = true;
                                    break;
                                }
                            }
                            Err(_) => {
                                sleep(Duration::from_millis(10)).await;
                            }
                        }
                    }
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    if !assigned {
                        println!("❌ Worker {} not assigned job {}", worker_id, job.task_id);
                        continue;
                    }
                    
                    // Execute task using dynamic executor
                    println!("⚙️  Worker {} executing job {} ({})", worker_id, job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    let status_publisher = session.declare_publisher(&k_status(&job.task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
                    
                    let status = Status {
                        task_id: job.task_id.clone(),
                        worker_id: worker_id.to_string(),
                        status: crate::schema::TaskStatus::Running,
                        message: Some("Task is running".to_string()),
                        progress: Some(0.3),
                        timestamp: chrono::Utc::now(),
                    };
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    
                    // Execute the actual task using dynamic executor
                    let mut executor = DynamicTaskExecutor::new();
                    let task_def = job.task_definition.as_ref().ok_or_else(|| anyhow::anyhow!("No task definition found"))?;
                    let result = executor.execute_task(task_def, job.inputs.clone()).await?;
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Publish result
                    let result_publisher = session.declare_publisher(&k_result(&job.task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
                    let result_json = serde_json::to_string(&result)?;
                    result_publisher.put(result_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    
                    let status = Status {
                        task_id: job.task_id.clone(),
                        worker_id: worker_id.to_string(),
                        status: crate::schema::TaskStatus::Completed,
                        message: Some("Task completed successfully".to_string()),
                        progress: Some(1.0),
                        timestamp: chrono::Utc::now(),
                    };
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    
                    println!("🎉 Worker {} completed job {}: {:?}", worker_id, job.task_id, result.status);
                }
                Err(_) => {
                    if self.running.load(Ordering::Relaxed) {
                        sleep(Duration::from_millis(10)).await;
                    }
                }
            }
        }
        
        println!("👷 Worker {} stopped", worker_id);
        Ok(())
    }

    pub async fn assigner_simulation(&self) -> Result<()> {
        println!("🤖 Assigner started");
        
        let session = zenoh::open(zenoh::Config::default()).await.map_err(|e| anyhow::anyhow!("Failed to open Zenoh session: {}", e))?;
        let job_subscriber = session.declare_subscriber(&k_announce()).await.map_err(|e| anyhow::anyhow!("Failed to declare subscriber: {}", e))?;
        let claim_subscriber = session.declare_subscriber(&format!("{}/tasks/*/claim", NS)).await.map_err(|e| anyhow::anyhow!("Failed to declare subscriber: {}", e))?;
        
        let mut pending_jobs: HashMap<String, (Job, Vec<Claim>, std::time::SystemTime)> = HashMap::new();
        
        loop {
            if !self.running.load(Ordering::Relaxed) {
                break;
            }
            
            // Check for new jobs
            match job_subscriber.try_recv() {
                Ok(sample) => {
                    let payload = sample.payload().deserialize::<String>()?;
                    let job: Job = serde_json::from_str(&payload)?;
                    println!("📋 Assigner received job: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    pending_jobs.insert(job.task_id.clone(), (job, Vec::new(), std::time::SystemTime::now()));
                }
                Err(_) => {}
            }
            
            // Check for claims
            match claim_subscriber.try_recv() {
                Ok(claim_sample) => {
                    let payload = claim_sample.payload().deserialize::<String>()?;
                    let claim: Claim = serde_json::from_str(&payload)?;
                    if let Some((_, claims, _)) = pending_jobs.get_mut(&claim.task_id) {
                        claims.push(claim.clone());
                        println!("📝 Assigner received claim for {} from {}", claim.task_id, claim.worker_id);
                    }
                }
                Err(_) => {}
            }
            
            // Process pending jobs that have been waiting long enough
            let current_time = std::time::SystemTime::now();
            let mut to_process = Vec::new();
            
            for (task_id, (job, claims, start_time)) in &pending_jobs {
                if current_time.duration_since(*start_time).unwrap_or(Duration::ZERO) > Duration::from_millis(100) {
                    to_process.push((task_id.clone(), job.clone(), claims.clone()));
                }
            }
            
            for (task_id, job, claims) in to_process {
                pending_jobs.remove(&task_id);
                
                if !claims.is_empty() {
                    // Pick best worker (lowest ETA)
                    let best = claims.iter().min_by_key(|c| c.estimated_duration_seconds).unwrap();
                    let assign = Assign {
                        task_id: task_id.clone(),
                        worker_id: best.worker_id.clone(),
                        assigned_at: chrono::Utc::now(),
                        task_definition: job.0.clone(),
                        inputs: job.1.clone(),
                    };
                    
                    let assign_publisher = session.declare_publisher(&k_assign(&task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
                    let assign_json = serde_json::to_string(&assign)?;
                    assign_publisher.put(assign_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    
                    let status = Status {
                        task_id: task_id.clone(),
                        worker_id: best.worker_id.clone(),
                        status: crate::schema::TaskStatus::Assigned,
                        message: Some("Task assigned to worker".to_string()),
                        progress: Some(0.0),
                        timestamp: chrono::Utc::now(),
                    };
                    let status_publisher = session.declare_publisher(&k_status(&task_id)).await.map_err(|e| anyhow::anyhow!("Failed to declare publisher: {}", e))?;
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await.map_err(|e| anyhow::anyhow!("Failed to put data: {}", e))?;
                    
                    println!("✅ Assigned job {} to {} (ETA: {}s)", task_id, best.worker_id, best.estimated_duration_seconds.unwrap_or(0));
                } else {
                    println!("❌ No claims for job {}", task_id);
                }
            }
            
            sleep(Duration::from_millis(10)).await;
        }
        
        println!("🤖 Assigner stopped");
        Ok(())
    }

    pub async fn result_listener(&self) -> Result<()> {
        println!("👂 Result listener started...");
        let session = zenoh::open(zenoh::Config::default()).await.map_err(|e| anyhow::anyhow!("Failed to open Zenoh session: {}", e))?;
        let subscriber = session.declare_subscriber(&format!("{}/tasks/*/result", NS)).await.map_err(|e| anyhow::anyhow!("Failed to declare subscriber: {}", e))?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    let payload = sample.payload().deserialize::<String>()?;
                    let result: crate::schema::Result = serde_json::from_str(&payload)?;
                    println!("📊 RESULT: {} - {:?}", result.task_id, result.status);
                    if !result.outputs.is_empty() {
                        println!("   Outputs: {:?}", result.outputs.keys().collect::<Vec<_>>());
                        // Print the actual result content
                        for (output_name, output_value) in &result.outputs {
                            println!("   {}: {}", output_name, output_value);
                        }
                    }
                }
                Err(_) => {
                    if self.running.load(Ordering::Relaxed) {
                        sleep(Duration::from_millis(10)).await;
                    }
                }
            }
        }
        
        println!("👂 Result listener stopped");
        Ok(())
    }

    pub async fn run_demo(&self) -> Result<()> {
        println!("🚀 Zenoh User-Defined Compute Tasks Demo (Rust)");
        println!("================================================");
        
        let session = zenoh::open(zenoh::Config::default()).await.map_err(|e| anyhow::anyhow!("Failed to open Zenoh session: {}", e))?;
        
        // Start components
        let assigner_handle = {
            let running = self.running.clone();
            let demo = UserDefinedDemo { running };
            tokio::spawn(async move { demo.assigner_simulation().await })
        };
        
        let worker1_handle = {
            let running = self.running.clone();
            let demo = UserDefinedDemo { running };
            tokio::spawn(async move { demo.worker_simulation("worker-1", 100).await })
        };
        
        let worker2_handle = {
            let running = self.running.clone();
            let demo = UserDefinedDemo { running };
            tokio::spawn(async move { demo.worker_simulation("worker-2", 150).await })
        };
        
        let listener_handle = {
            let running = self.running.clone();
            let demo = UserDefinedDemo { running };
            tokio::spawn(async move { demo.result_listener().await })
        };
        
        // Wait for components to start
        sleep(Duration::from_secs(1)).await;
        
        // Submit user-defined tasks
        println!("\n📋 Submitting user-defined tasks...");
        
        // Example 1: Submit factorial task
        let factorial_def = UserDefinedDemo::create_factorial_task_definition(10).await;
        self.submit_task(&session, factorial_def, serde_json::json!({"number": 10})).await?;
        sleep(Duration::from_millis(500)).await;
        
        // Example 2: Submit Fibonacci task
        let fibonacci_def = UserDefinedDemo::create_fibonacci_task_definition(15).await;
        self.submit_task(&session, fibonacci_def, serde_json::json!({"terms": 15})).await?;
        sleep(Duration::from_millis(500)).await;
        
        // Example 3: Submit another factorial task
        let factorial_def2 = UserDefinedDemo::create_factorial_task_definition(12).await;
        self.submit_task(&session, factorial_def2, serde_json::json!({"number": 12})).await?;
        sleep(Duration::from_millis(500)).await;
        
        // Example 4: Submit another Fibonacci task
        let fibonacci_def2 = UserDefinedDemo::create_fibonacci_task_definition(20).await;
        self.submit_task(&session, fibonacci_def2, serde_json::json!({"terms": 20})).await?;
        
        // Let the demo run
        sleep(Duration::from_secs(10)).await;
        
        // Stop demo
        println!("\n🛑 Stopping demo...");
        self.running.store(false, Ordering::Relaxed);
        
        // Wait for tasks to complete
        let _ = tokio::join!(
            assigner_handle,
            worker1_handle,
            worker2_handle,
            listener_handle
        );
        
        println!("✅ Demo completed!");
        Ok(())
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let demo = UserDefinedDemo::new();
    demo.run_demo().await
}
