use anyhow::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use serde_json;
use std::fs;
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

pub struct WorkingUserZenohDemo {
    running: Arc<AtomicBool>,
}

impl WorkingUserZenohDemo {
    pub fn new() -> Self {
        Self {
            running: Arc::new(AtomicBool::new(true)),
        }
    }

    // COMMENTED OUT: Old embedded factorial task definition
    // Now using external YAML/JSON task definitions instead
    /*
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
    */

    // COMMENTED OUT: Old embedded fibonacci task definition
    // Now using external YAML/JSON task definitions instead
    /*
    pub async fn create_fibonacci_task_definition(terms: u64) -> TaskDefinition {
        TaskDefinition {
            name: "fibonacci_sequence".to_string(),
            version: "1.0".to_string(),
            description: format!("Generate Fibonacci sequence with {} terms", terms),
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
use std::time::Instant;

let start_time = Instant::now();
let terms = inputs["terms"].as_u64().unwrap_or({});
let mut sequence = vec![0, 1];
for i in 2..terms {{
    sequence.push(sequence[i as usize - 1] + sequence[i as usize - 2]);
}}
let end_time = Instant::now();
let computation_time = start_time.duration_since(start_time).as_millis();

let result = serde_json::json!({{
    "sequence": sequence,
    "terms": terms,
    "last_term": sequence.last().unwrap_or(&0),
    "computation_time_ms": computation_time
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
                    "message": "Terms must be between 1 and 50 for performance"
                })
            ],
            metadata: serde_json::json!({
                "estimated_duration_ms": 50,
                "memory_requirement_mb": 5,
                "cpu_intensive": false
            }),
        }
    }
    */

    pub async fn load_task_definition_from_yaml(&self, file_path: &str) -> Result<TaskDefinition> {
        println!("📖 Reading YAML task definition from: {}", file_path);
        let content = fs::read_to_string(file_path)?;
        
        // Parse YAML content
        let yaml_value: serde_yaml::Value = serde_yaml::from_str(&content)?;
        
        // Extract the task_definition from the YAML structure
        let task_def_value = yaml_value.get("task_definition")
            .ok_or_else(|| anyhow::anyhow!("No 'task_definition' found in YAML file"))?;
        
        // Convert to TaskDefinition
        let task_definition: TaskDefinition = serde_yaml::from_value(task_def_value.clone())?;
        
        println!("✅ Loaded task definition: {} (version: {})", task_definition.name, task_definition.version);
        Ok(task_definition)
    }

    pub async fn load_task_definition_from_json(&self, file_path: &str) -> Result<TaskDefinition> {
        println!("📖 Reading JSON task definition from: {}", file_path);
        let content = fs::read_to_string(file_path)?;
        
        // Parse JSON content
        let json_value: serde_json::Value = serde_json::from_str(&content)?;
        
        // Extract the task_definition from the JSON structure
        let task_def_value = json_value.get("task_definition")
            .ok_or_else(|| anyhow::anyhow!("No 'task_definition' found in JSON file"))?;
        
        // Convert to TaskDefinition
        let task_definition: TaskDefinition = serde_json::from_value(task_def_value.clone())?;
        
        println!("✅ Loaded task definition: {} (version: {})", task_definition.name, task_definition.version);
        Ok(task_definition)
    }

    pub async fn submit_task(&self, task_definition: TaskDefinition, inputs: serde_json::Value) -> Result<String> {
        let job = Job::new_user_task(QUEUE.to_string(), task_definition, inputs);
        
        // Submit via Zenoh
        let session = zenoh::open(zenoh::Config::default()).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let key = k_announce();
        let publisher = session.declare_publisher(&key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let job_json = serde_json::to_string(&job)?;
        publisher.put(job_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        
        println!("📤 Submitted user task: {} ({})", job.task_id, job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown"));
        Ok(job.task_id)
    }

    pub async fn worker_simulation(&self, worker_id: &str, latency_ms: u32) -> Result<()> {
        println!("👷 Worker {} started (latency: {}ms)", worker_id, latency_ms);
        
        // Use Zenoh for real messaging
        let session = zenoh::open(zenoh::Config::default()).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let key = k_announce();
        let subscriber = session.declare_subscriber(&key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        
        while self.running.load(Ordering::Relaxed) {
            match subscriber.recv_async().await {
                Ok(sample) => {
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
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
                    let claim_publisher = session.declare_publisher(&claim_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    let claim_json = serde_json::to_string(&claim)?;
                    claim_publisher.put(claim_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    println!("📝 Worker {} claimed job {}", worker_id, job.task_id);
                    
                    // Wait for assignment
                    let assign_key = k_assign(&job.task_id);
                    println!("🔑 Worker {} subscribing to assignment key: {}", worker_id, assign_key);
                    let assign_subscriber = session.declare_subscriber(&assign_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
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
                    let status_publisher = session.declare_publisher(&status_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    let status_json = serde_json::to_string(&status)?;
                    status_publisher.put(status_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    
                    // Execute the actual task using dynamic executor (async version for external code sources)
                    let executor = DynamicTaskExecutor::new()?;
                    let result = executor.execute_task_async(&job, worker_id).await?;
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Publish result
                    let result_key = k_result(&job.task_id);
                    let result_publisher = session.declare_publisher(&result_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    let result_json = serde_json::to_string(&result)?;
                    result_publisher.put(result_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    
                    let final_status = Status {
                        task_id: job.task_id.clone(),
                        state: "succeeded".to_string(),
                        progress: 1.0,
                    };
                    let final_status_json = serde_json::to_string(&final_status)?;
                    status_publisher.put(final_status_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
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
        
        let session = zenoh::open(zenoh::Config::default()).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let announce_key = k_announce();
        let job_subscriber = session.declare_subscriber(&announce_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let claim_key = format!("{}/tasks/*/claim", NS);
        let claim_subscriber = session.declare_subscriber(&claim_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        
        let mut pending_jobs: HashMap<String, Job> = HashMap::new();
        let mut claims: HashMap<String, Vec<Claim>> = HashMap::new();
        
        // Use a simpler approach - process jobs and claims sequentially with timeouts
        loop {
            // Try to receive a job with a short timeout
            match tokio::time::timeout(Duration::from_millis(100), job_subscriber.recv_async()).await {
                Ok(Ok(sample)) => {
                    if let Ok(job) = deserialize_from_sample_with_context::<Job>(&sample, "job") {
                        let job_id = job.task_id.clone();
                        let job_name = job.task_definition.as_ref().map(|td| td.name.as_str()).unwrap_or("unknown").to_string();
                        pending_jobs.insert(job_id.clone(), job);
                        println!("📋 Assigner received job: {} ({})", job_id, job_name);
                    }
                }
                Ok(Err(e)) => {
                    println!("❌ Assigner job error: {}", e);
                    break;
                }
                Err(_) => {
                    // Timeout - check for claims
                }
            }
            
            // Try to receive a claim with a short timeout
            match tokio::time::timeout(Duration::from_millis(100), claim_subscriber.recv_async()).await {
                Ok(Ok(claim_sample)) => {
                    if let Ok(claim) = deserialize_from_sample_with_context::<Claim>(&claim_sample, "claim") {
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
                }
                Ok(Err(e)) => {
                    println!("❌ Assigner claim error: {}", e);
                    break;
                }
                Err(_) => {
                    // Timeout - continue loop
                }
            }
            
            // Small delay to prevent busy waiting
            sleep(Duration::from_millis(10)).await;
        }
        
        Ok(())
    }

    pub async fn result_listener_simulation(&self) -> Result<()> {
        println!("👂 Result listener started");
        
        let session = zenoh::open(zenoh::Config::default()).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let result_key = format!("{}/tasks/*/result", NS);
        let subscriber = session.declare_subscriber(&result_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        
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

    pub async fn run_working_user_zenoh_demo(&self) -> Result<()> {
        println!("🚀 Zenoh User-Defined Compute Tasks Demo (Rust - Working User with Zenoh)");
        println!("==========================================================================");
        println!("Using Zenoh 1.6.2 API with real messaging for external code source tasks");
        println!("Loading task definitions from YAML/JSON files with GitHub Gist code sources");
        println!("Including WASM (WebAssembly) and Docker task execution from local and URL sources");
        println!();

        // Start assigner
        let assigner_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = WorkingUserZenohDemo { running };
                if let Err(e) = demo.assigner_simulation().await {
                    println!("❌ Assigner error: {}", e);
                }
            })
        };

        // Start result listener
        let listener_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = WorkingUserZenohDemo { running };
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
                    let demo = WorkingUserZenohDemo { running };
                    if let Err(e) = demo.worker_simulation(&worker_id, latency_ms).await {
                        println!("❌ Worker {} error: {}", worker_id, e);
                    }
                })
            })
            .collect();

        // Wait a bit for components to start
        sleep(Duration::from_millis(1000)).await;

        // Submit external task definitions from YAML/JSON files
        
        // Load and submit factorial task from YAML file
        println!("📋 Loading factorial task from YAML file...");
        let factorial_def = self.load_task_definition_from_yaml("task_definitions/factorial_from_url.yaml").await?;
        let factorial_inputs = serde_json::json!({"number": 10});
        self.submit_task(factorial_def.clone(), factorial_inputs).await?;
        
        sleep(Duration::from_millis(500)).await;
        
        // Load and submit fibonacci task from JSON file
        println!("📋 Loading fibonacci task from JSON file...");
        let fibonacci_def = self.load_task_definition_from_json("task_definitions/fibonacci_from_gist.json").await?;
        let fibonacci_inputs = serde_json::json!({"terms": 15});
        self.submit_task(fibonacci_def, fibonacci_inputs).await?;
        
        sleep(Duration::from_millis(500)).await;
        
        // Submit another factorial task with different input
        println!("📋 Submitting another factorial task...");
        let factorial_inputs2 = serde_json::json!({"number": 8});
        self.submit_task(factorial_def.clone(), factorial_inputs2).await?;

        sleep(Duration::from_millis(500)).await;

        // Submit WASM factorial task
        println!("📋 Loading WASM factorial task from YAML file...");
        let wasm_factorial_def = self.load_task_definition_from_yaml("task_definitions/factorial_wasm.yaml").await?;
        let wasm_factorial_inputs = serde_json::json!({"number": 12});
        self.submit_task(wasm_factorial_def, wasm_factorial_inputs).await?;

        sleep(Duration::from_millis(500)).await;

        // Submit WASM factorial task from URL
        println!("📋 Loading WASM factorial task from URL...");
        let wasm_factorial_url_def = self.load_task_definition_from_yaml("task_definitions/factorial_wasm_url.yaml").await?;
        let wasm_factorial_url_inputs = serde_json::json!({"number": 14});
        self.submit_task(wasm_factorial_url_def, wasm_factorial_url_inputs).await?;

        sleep(Duration::from_millis(500)).await;

        // Submit Docker factorial task
        println!("📋 Loading Docker factorial task...");
        let docker_factorial_def = self.load_task_definition_from_yaml("task_definitions/factorial_docker.yaml").await?;
        let docker_factorial_inputs = serde_json::json!({"number": 16});
        self.submit_task(docker_factorial_def, docker_factorial_inputs).await?;

        sleep(Duration::from_millis(500)).await;

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

        println!("\n✅ Working User Zenoh demo completed!");
        
        Ok(())
    }
}
