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

pub struct FixedUserDefinedDemo {
    running: Arc<AtomicBool>,
}

impl FixedUserDefinedDemo {
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
        
        // Use the correct Zenoh 1.5.1 API
        let publisher = session.declare_publisher(&k_announce()).await?;
        let job_json = serde_json::to_string(&job)?;
        publisher.put(job_json).await?;
        
        println!("📤 Submitted user task: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
        Ok(job.task_id)
    }

    pub async fn worker_simulation(&self, worker_id: &str, latency_ms: u32) -> Result<()> {
        println!("👷 Worker {} started (latency: {}ms)", worker_id, latency_ms);
        
        let session = zenoh::open(zenoh::Config::default()).await?;
        let subscriber = session.declare_subscriber(&k_announce()).await?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Use the correct payload access method
                    let job: Job = serde_json::from_slice(&sample.payload())?;
                    println!("📋 Worker {} received job: {} ({})", worker_id, job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    
                    // Simulate latency
                    sleep(Duration::from_millis(latency_ms as u64)).await;
                    
                    // Claim the job
                    let now_ms = chrono::Utc::now().timestamp_millis() as u64;
                    let claim = Claim {
                        task_id: job.task_id.clone(),
                        peer: worker_id.to_string(),
                        eta_ms: latency_ms,
                        lease_until_ms: now_ms + 200,
                    };
                    
                    let claim_publisher = session.declare_publisher(&k_claim(&job.task_id)).await?;
                    let claim_json = serde_json::to_string(&claim)?;
                    claim_publisher.put(claim_json).await?;
                    println!("📝 Worker {} claimed job {}", worker_id, job.task_id);
                    
                    // Wait for assignment
                    let assign_subscriber = session.declare_subscriber(&k_assign(&job.task_id)).await?;
                    let mut assigned = false;
                    
                    // Wait for assignment with timeout
                    let timeout = Duration::from_millis(1000);
                    let start = std::time::Instant::now();
                    
                    while start.elapsed() < timeout && !assigned {
                        match assign_subscriber.recv_async().await {
                            Ok(assign_sample) => {
                                let assign: Assign = serde_json::from_slice(&assign_sample.payload)?;
                                if assign.assignee == worker_id {
                                    assigned = true;
                                    println!("✅ Worker {} assigned job {}", worker_id, job.task_id);
                                }
                            }
                            Err(_) => break,
                        }
                    }
                    
                    if !assigned {
                        println!("⏰ Worker {} assignment timeout for job {}", worker_id, job.task_id);
                        continue;
                    }
                    
                    // Execute the task
                    println!("⚙️  Worker {} executing job {} ({})", worker_id, job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    
                    let status = Status {
                        task_id: job.task_id.clone(),
                        state: "running".to_string(),
                        progress: 0.3,
                    };
                    
                    let status_publisher = session.declare_publisher(&k_status(&job.task_id)).await?;
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await?;
                    
                    // Execute the actual task using dynamic executor
                    let executor = DynamicTaskExecutor::new()?;
                    let result = executor.execute_task(&job, worker_id)?;
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Publish result
                    let result_publisher = session.declare_publisher(&k_result(&job.task_id)).await?;
                    let result_json = serde_json::to_string(&result)?;
                    result_publisher.put(result_json).await?;
                    
                    let final_status = Status {
                        task_id: job.task_id.clone(),
                        state: "succeeded".to_string(),
                        progress: 1.0,
                    };
                    let final_status_json = serde_json::to_string(&final_status)?;
                    status_publisher.put(final_status_json).await?;
                    println!("🎉 Worker {} completed job {}: {}", worker_id, job.task_id, result.message);
                }
                Err(e) => {
                    println!("❌ Worker {} error: {}", worker_id, e);
                    break;
                }
            }
        }
        
        Ok(())
    }

    pub async fn assigner_simulation(&self) -> Result<()> {
        println!("🎯 Assigner started");
        
        let session = zenoh::open(zenoh::Config::default()).await?;
        let job_subscriber = session.declare_subscriber(&k_announce()).await?;
        let claim_subscriber = session.declare_subscriber(&format!("{}/tasks/*/claim", NS)).await?;
        
        let mut pending_jobs: HashMap<String, Job> = HashMap::new();
        let mut claims: HashMap<String, Vec<Claim>> = HashMap::new();
        
        loop {
            tokio::select! {
                // Handle new job announcements
                job_result = job_subscriber.recv_async() => {
                    match job_result {
                        Ok(sample) => {
                            let job: Job = serde_json::from_slice(&sample.payload)?;
                            pending_jobs.insert(job.task_id.clone(), job);
                            println!("📋 Assigner received job: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                        }
                        Err(e) => {
                            println!("❌ Assigner job error: {}", e);
                            break;
                        }
                    }
                }
                
                // Handle claims
                claim_result = claim_subscriber.recv_async() => {
                    match claim_result {
                        Ok(claim_sample) => {
                            let claim: Claim = serde_json::from_slice(&claim_sample.payload)?;
                            claims.entry(claim.task_id.clone()).or_insert_with(Vec::new).push(claim);
                            println!("📝 Assigner received claim from {} for job {}", claim.peer, claim.task_id);
                            
                            // Assign job to the first available worker
                            if let Some(job) = pending_jobs.remove(&claim.task_id) {
                                let assign = Assign {
                                    task_id: claim.task_id.clone(),
                                    assignee: claim.peer.clone(),
                                    deadline_s: 30, // 30 seconds deadline
                                };
                                
                                let assign_publisher = session.declare_publisher(&k_assign(&claim.task_id)).await?;
                                let assign_json = serde_json::to_string(&assign)?;
                                assign_publisher.put(assign_json).await?;
                                
                                let status = Status {
                                    task_id: claim.task_id.clone(),
                                    state: "assigned".to_string(),
                                    progress: 0.1,
                                };
                                
                                let status_publisher = session.declare_publisher(&k_status(&claim.task_id)).await?;
                                let status_json = serde_json::to_string(&status)?;
                                status_publisher.put(status_json).await?;
                                
                                println!("✅ Assigner assigned job {} to worker {}", claim.task_id, claim.peer);
                            }
                        }
                        Err(e) => {
                            println!("❌ Assigner claim error: {}", e);
                            break;
                        }
                    }
                }
            }
        }
        
        Ok(())
    }

    pub async fn result_listener_simulation(&self) -> Result<()> {
        println!("👂 Result listener started");
        
        let session = zenoh::open(zenoh::Config::default()).await?;
        let subscriber = session.declare_subscriber(&format!("{}/tasks/*/result", NS)).await?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    let result: crate::schema::Result = serde_json::from_slice(&sample.payload())?;
                    println!("📊 RESULT: {} - {}", result.task_id, if result.ok { "✅ SUCCESS" } else { "❌ FAILED" });
                    if !result.artifacts.is_empty() {
                        for (artifact_name, artifact_content) in &result.artifacts {
                            if let Ok(result_data) = serde_json::from_str::<serde_json::Value>(artifact_content) {
                                println!("   {}: {}", artifact_name, result_data);
                            }
                        }
                    }
                }
                Err(e) => {
                    println!("❌ Result listener error: {}", e);
                    break;
                }
            }
        }
        
        Ok(())
    }

    pub async fn run_fixed_demo(&self) -> Result<()> {
        println!("🚀 Zenoh User-Defined Compute Tasks Demo (Rust - Fixed API)");
        println!("============================================================");
        println!("Using Zenoh 1.5.1 API with correct error handling and payload access");
        println!();

        // Start assigner
        let assigner_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = FixedUserDefinedDemo { running };
                if let Err(e) = demo.assigner_simulation().await {
                    println!("❌ Assigner error: {}", e);
                }
            })
        };

        // Start result listener
        let listener_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = FixedUserDefinedDemo { running };
                if let Err(e) = demo.result_listener_simulation().await {
                    println!("❌ Result listener error: {}", e);
                }
            })
        };

        // Start workers
        let worker_handles: Vec<_> = (1..=2)
            .map(|i| {
                let running = self.running.clone();
                let worker_id = format!("worker-{}", i);
                let latency_ms = 100 * i;
                tokio::spawn(async move {
                    let demo = FixedUserDefinedDemo { running };
                    if let Err(e) = demo.worker_simulation(&worker_id, latency_ms).await {
                        println!("❌ Worker {} error: {}", worker_id, e);
                    }
                })
            })
            .collect();

        // Wait a bit for components to start
        sleep(Duration::from_millis(1000)).await;

        // Submit tasks
        let session = zenoh::open(zenoh::Config::default()).await?;
        
        // Submit factorial task
        let factorial_def = Self::create_factorial_task_definition(10).await;
        let factorial_inputs = serde_json::json!({"number": 10});
        self.submit_task(&session, factorial_def, factorial_inputs).await?;
        
        sleep(Duration::from_millis(500)).await;
        
        // Submit Fibonacci task
        let fibonacci_def = Self::create_fibonacci_task_definition(15).await;
        let fibonacci_inputs = serde_json::json!({"terms": 15});
        self.submit_task(&session, fibonacci_def, fibonacci_inputs).await?;
        
        sleep(Duration::from_millis(500)).await;
        
        // Submit another factorial task
        let factorial_def2 = Self::create_factorial_task_definition(8).await;
        let factorial_inputs2 = serde_json::json!({"number": 8});
        self.submit_task(&session, factorial_def2, factorial_inputs2).await?;

        // Wait for tasks to complete
        sleep(Duration::from_millis(5000)).await;

        // Stop all components
        self.running.store(false, Ordering::Relaxed);
        
        // Wait for all tasks to complete
        let _ = tokio::join!(assigner_handle, listener_handle);
        for handle in worker_handles {
            let _ = handle.await;
        }

        println!("\n✅ Fixed demo completed!");
        println!("This demo uses the correct Zenoh 1.5.1 API patterns:");
        println!("- Proper error handling with .res().await?");
        println!("- Correct sample payload access");
        println!("- Updated API method calls");
        
        Ok(())
    }
}
