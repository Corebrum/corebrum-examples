use anyhow::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use serde_json;
use crate::schema::*;
use crate::dynamic_executor::DynamicTaskExecutor;
use crate::zenoh_utils::*;

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

pub struct FixedZenohDemo {
    running: Arc<AtomicBool>,
}

impl FixedZenohDemo {
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

    pub async fn submit_task(&self, session: &zenoh::Session, task_definition: TaskDefinition, inputs: serde_json::Value) -> Result<String> {
        let job = Job::new_user_task(QUEUE.to_string(), task_definition, inputs);
        
        // Use the fixed error handling
        let key = k_announce();
        let publisher = session.declare_publisher(&key).await.into_anyhow()?;
        let job_json = serde_json::to_string(&job)?;
        publisher.put(job_json).await.into_anyhow()?;
        
        println!("📤 Submitted user task: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
        Ok(job.task_id)
    }

    pub async fn worker_simulation(&self, worker_id: &str, latency_ms: u32) -> Result<()> {
        println!("👷 Worker {} started (latency: {}ms)", worker_id, latency_ms);
        
        // Use the fixed error handling
        let session = zenoh::open(zenoh::Config::default()).await.into_anyhow()?;
        let key = k_announce();
        let subscriber = session.declare_subscriber(&key).await.into_anyhow()?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Use the fixed payload deserialization
                    let job: Job = deserialize_from_sample_with_context(&sample, "job")?;
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
                    
                    let claim_key = k_claim(&job.task_id);
                    let claim_publisher = session.declare_publisher(&claim_key).await.into_anyhow()?;
                    let claim_json = serde_json::to_string(&claim)?;
                    claim_publisher.put(claim_json).await.into_anyhow()?;
                    println!("📝 Worker {} claimed job {}", worker_id, job.task_id);
                    
                    // Wait for assignment
                    let assign_key = k_assign(&job.task_id);
                    println!("🔑 Worker {} subscribing to assignment key: {}", worker_id, assign_key);
                    let assign_subscriber = session.declare_subscriber(&assign_key).await.into_anyhow()?;
                    let mut assigned = false;
                    
                    // Small delay to ensure subscriber is ready
                    sleep(Duration::from_millis(100)).await;
                    
                    // Wait for assignment with timeout
                    let timeout = Duration::from_millis(2000); // Increased timeout
                    let start = std::time::Instant::now();
                    
                    println!("⏳ Worker {} waiting for assignment for job {} on key {}...", worker_id, job.task_id, assign_key);
                    
                    while start.elapsed() < timeout && !assigned {
                        match tokio::time::timeout(Duration::from_millis(100), assign_subscriber.recv_async()).await {
                            Ok(Ok(assign_sample)) => {
                                if let Ok(assign) = deserialize_from_sample_with_context::<Assign>(&assign_sample, "assign") {
                                    if assign.assignee == worker_id {
                                        assigned = true;
                                        println!("✅ Worker {} assigned job {}", worker_id, job.task_id);
                                    } else {
                                        println!("🔄 Worker {} received assignment for different worker: {}", worker_id, assign.assignee);
                                    }
                                }
                            }
                            Ok(Err(e)) => {
                                println!("❌ Worker {} assignment receive error: {}", worker_id, e);
                                break;
                            }
                            Err(_) => {
                                // Timeout - continue waiting
                                if start.elapsed().as_millis() % 500 == 0 {
                                    println!("⏳ Worker {} still waiting for assignment... ({}ms elapsed)", worker_id, start.elapsed().as_millis());
                                }
                            }
                        }
                    }
                    
                    if !assigned {
                        println!("⏰ Worker {} assignment timeout for job {} - job may have been assigned to another worker", worker_id, job.task_id);
                        continue;
                    }
                    
                    // Execute the task
                    println!("⚙️  Worker {} executing job {} ({})", worker_id, job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
                    
                    let status = Status {
                        task_id: job.task_id.clone(),
                        state: "running".to_string(),
                        progress: 0.3,
                    };
                    
                    let status_key = k_status(&job.task_id);
                    let status_publisher = session.declare_publisher(&status_key).await.into_anyhow()?;
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await.into_anyhow()?;
                    
                    // Execute the actual task using dynamic executor
                    let executor = DynamicTaskExecutor::new()?;
                    let result = executor.execute_task(&job, worker_id)?;
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Publish result
                    let result_key = k_result(&job.task_id);
                    let result_publisher = session.declare_publisher(&result_key).await.into_anyhow()?;
                    let result_json = serde_json::to_string(&result)?;
                    result_publisher.put(result_json).await.into_anyhow()?;
                    
                    let final_status = Status {
                        task_id: job.task_id.clone(),
                        state: "succeeded".to_string(),
                        progress: 1.0,
                    };
                    let final_status_json = serde_json::to_string(&final_status)?;
                    status_publisher.put(final_status_json).await.into_anyhow()?;
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
        
        let session = zenoh::open(zenoh::Config::default()).await.into_anyhow()?;
        let announce_key = k_announce();
        let job_subscriber = session.declare_subscriber(&announce_key).await.into_anyhow()?;
        let claim_key = format!("{}/tasks/*/claim", NS);
        let claim_subscriber = session.declare_subscriber(&claim_key).await.into_anyhow()?;
        
        let mut pending_jobs: HashMap<String, Job> = HashMap::new();
        let mut claims: HashMap<String, Vec<Claim>> = HashMap::new();
        
        loop {
            tokio::select! {
                // Handle new job announcements
                job_result = job_subscriber.recv_async() => {
                    match job_result {
                        Ok(sample) => {
                            let job: Job = deserialize_from_sample_with_context(&sample, "job")?;
                            let job_id = job.task_id.clone();
                            let job_name = job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown").to_string();
                            pending_jobs.insert(job_id.clone(), job);
                            println!("📋 Assigner received job: {} ({})", job_id, job_name);
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
                            let claim: Claim = deserialize_from_sample_with_context(&claim_sample, "claim")?;
                            let claim_task_id = claim.task_id.clone();
                            let claim_peer = claim.peer.clone();
                            claims.entry(claim_task_id.clone()).or_insert_with(Vec::new).push(claim);
                            println!("📝 Assigner received claim from {} for job {}", claim_peer, claim_task_id);
                            
                            // Assign job to the first available worker
                            if let Some(_job) = pending_jobs.remove(&claim_task_id) {
                                // Delay to ensure worker subscriber is ready
                                sleep(Duration::from_millis(200)).await;
                                
                                let assign = Assign {
                                    task_id: claim_task_id.clone(),
                                    assignee: claim_peer.clone(),
                                    deadline_s: 30, // 30 seconds deadline
                                };
                                
                                let assign_key = k_assign(&claim_task_id);
                                println!("🔑 Assigner publishing assignment to key: {}", assign_key);
                                match session.declare_publisher(&assign_key).await {
                                    Ok(assign_publisher) => {
                                        match serde_json::to_string(&assign) {
                                            Ok(assign_json) => {
                                                match assign_publisher.put(assign_json).await {
                                                    Ok(_) => println!("📤 Assigner sent assignment for job {} to worker {}", claim_task_id, claim_peer),
                                                    Err(e) => println!("❌ Assigner failed to send assignment: {}", e),
                                                }
                                            }
                                            Err(e) => println!("❌ Assigner failed to serialize assignment: {}", e),
                                        }
                                    }
                                    Err(e) => println!("❌ Assigner failed to create assignment publisher: {}", e),
                                }
                                
                                let status = Status {
                                    task_id: claim_task_id.clone(),
                                    state: "assigned".to_string(),
                                    progress: 0.1,
                                };
                                
                                let status_key = k_status(&claim_task_id);
                                match session.declare_publisher(&status_key).await {
                                    Ok(status_publisher) => {
                                        match serde_json::to_string(&status) {
                                            Ok(status_json) => {
                                                match status_publisher.put(status_json).await {
                                                    Ok(_) => println!("📤 Assigner sent status for job {}", claim_task_id),
                                                    Err(e) => println!("❌ Assigner failed to send status: {}", e),
                                                }
                                            }
                                            Err(e) => println!("❌ Assigner failed to serialize status: {}", e),
                                        }
                                    }
                                    Err(e) => println!("❌ Assigner failed to create status publisher: {}", e),
                                }
                                
                                println!("✅ Assigner assigned job {} to worker {}", claim_task_id, claim_peer);
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
        
        let session = zenoh::open(zenoh::Config::default()).await.into_anyhow()?;
        let result_key = format!("{}/tasks/*/result", NS);
        let subscriber = session.declare_subscriber(&result_key).await.into_anyhow()?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    let result: crate::schema::Result = deserialize_from_sample_with_context(&sample, "result")?;
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

    pub async fn run_fixed_zenoh_demo(&self) -> Result<()> {
        println!("🚀 Zenoh User-Defined Compute Tasks Demo (Rust - Fixed API)");
        println!("============================================================");
        println!("Using Zenoh 1.5.1 API with proper error handling and payload access");
        println!();

        // Start assigner
        let assigner_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = FixedZenohDemo { running };
                if let Err(e) = demo.assigner_simulation().await {
                    println!("❌ Assigner error: {}", e);
                }
            })
        };

        // Start result listener
        let listener_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = FixedZenohDemo { running };
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
                    let demo = FixedZenohDemo { running };
                    if let Err(e) = demo.worker_simulation(&worker_id, latency_ms).await {
                        println!("❌ Worker {} error: {}", worker_id, e);
                    }
                })
            })
            .collect();

        // Wait a bit for components to start
        sleep(Duration::from_millis(1000)).await;

        // Submit tasks
        let session = zenoh::open(zenoh::Config::default()).await.into_anyhow()?;
        
        // Submit factorial task
        let factorial_def = Self::create_factorial_task_definition(10).await;
        let factorial_inputs = serde_json::json!({"number": 10});
        self.submit_task(&session, factorial_def, factorial_inputs).await?;
        
        sleep(Duration::from_millis(500)).await;
        
        // Submit another factorial task
        let factorial_def2 = Self::create_factorial_task_definition(8).await;
        let factorial_inputs2 = serde_json::json!({"number": 8});
        self.submit_task(&session, factorial_def2, factorial_inputs2).await?;

        // Wait for tasks to complete
        sleep(Duration::from_millis(5000)).await;

        // Stop all components
        self.running.store(false, Ordering::Relaxed);
        
        // Wait for all tasks to complete with timeout
        println!("🛑 Stopping demo components...");
        let shutdown_timeout = Duration::from_millis(3000);
        
        match tokio::time::timeout(shutdown_timeout, async {
            tokio::join!(assigner_handle, listener_handle)
        }).await {
            Ok(_) => println!("✅ Assigner and result listener stopped gracefully"),
            Err(_) => println!("⏰ Assigner and result listener shutdown timeout"),
        }
        
        for (i, handle) in worker_handles.into_iter().enumerate() {
            let worker_id = format!("worker-{}", i + 1);
            match tokio::time::timeout(Duration::from_millis(1000), handle).await {
                Ok(_) => println!("✅ Worker {} stopped gracefully", worker_id),
                Err(_) => println!("⏰ Worker {} shutdown timeout", worker_id),
            }
        }

        println!("\n✅ Fixed Zenoh demo completed!");
        println!("This demo uses the correct Zenoh 1.5.1 API patterns:");
        println!("- Proper error handling with .into_anyhow()");
        println!("- Correct sample payload access with deserialize_from_sample()");
        println!("- Updated API method calls");
        
        Ok(())
    }
}
