use anyhow::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use serde_json;
use crate::schema::*;
use crate::zenoh_utils::*;

const NS: &str = "comp";
const QUEUE: &str = "perception";

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

pub struct SimpleZenohDemo {
    running: Arc<AtomicBool>,
}

impl SimpleZenohDemo {
    pub fn new() -> Self {
        Self {
            running: Arc::new(AtomicBool::new(true)),
        }
    }

    pub async fn submit_job(&self) -> Result<String> {
        let inputs = vec![
            Input {
                name: "rgb".to_string(),
                input_type: InputType::Zenoh,
                key: Some("rt/cam/rgb".to_string()),
                url: None,
            },
            Input {
                name: "depth".to_string(),
                input_type: InputType::Zenoh,
                key: Some("rt/cam/depth".to_string()),
                url: None,
            },
        ];

        let mut params = serde_json::Map::new();
        params.insert("model".to_string(), serde_json::Value::String("vlm-x".to_string()));
        params.insert("max_objs".to_string(), serde_json::Value::Number(64.into()));

        let job = Job::new(QUEUE.to_string(), inputs, serde_json::Value::Object(params));
        let task_id = job.task_id.clone();
        
        // Submit via Zenoh
        let session = zenoh::open(zenoh::Config::default()).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let key = k_announce();
        let publisher = session.declare_publisher(&key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        let job_json = serde_json::to_string(&job)?;
        publisher.put(job_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
        
        println!("📤 Submitted job: {}", task_id);
        Ok(task_id)
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
                    println!("🔍 Worker {} received job: {}", worker_id, job.task_id);
                    
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
                    
                    // Execute task
                    println!("⚙️  Worker {} executing job {}", worker_id, job.task_id);
                    
                    // Simulate work
                    for _ in 0..(latency_ms / 10) {
                        if !self.running.load(Ordering::Relaxed) {
                            break;
                        }
                        sleep(Duration::from_millis(10)).await;
                    }
                    
                    if !self.running.load(Ordering::Relaxed) {
                        break;
                    }
                    
                    // Produce result
                    let mut detections = serde_json::Map::new();
                    let mut objects = serde_json::Value::Array(Vec::new());
                    
                    let mut cup = serde_json::Map::new();
                    cup.insert("label".to_string(), serde_json::Value::String("cup".to_string()));
                    cup.insert("score".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(0.92).unwrap()));
                    cup.insert("x".to_string(), serde_json::Value::Number(320.into()));
                    cup.insert("y".to_string(), serde_json::Value::Number(200.into()));
                    cup.insert("z_m".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(0.65).unwrap()));
                    objects.as_array_mut().unwrap().push(serde_json::Value::Object(cup));
                    
                    let mut bottle = serde_json::Map::new();
                    bottle.insert("label".to_string(), serde_json::Value::String("bottle".to_string()));
                    bottle.insert("score".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(0.84).unwrap()));
                    bottle.insert("x".to_string(), serde_json::Value::Number(150.into()));
                    bottle.insert("y".to_string(), serde_json::Value::Number(180.into()));
                    bottle.insert("z_m".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(0.92).unwrap()));
                    objects.as_array_mut().unwrap().push(serde_json::Value::Object(bottle));
                    
                    detections.insert("objects".to_string(), objects);
                    detections.insert("timestamp".to_string(), serde_json::Value::Number(chrono::Utc::now().timestamp_millis().into()));
                    detections.insert("worker_id".to_string(), serde_json::Value::String(worker_id.to_string()));
                    
                    let mut artifacts = HashMap::new();
                    artifacts.insert("detections.json".to_string(), serde_json::to_string(&detections)?);
                    
                    let result = crate::schema::Result::new(
                        job.task_id.clone(),
                        true,
                        artifacts,
                        format!("Perception task completed by {}", worker_id),
                    );
                    
                    // Publish result via Zenoh
                    let result_key = k_result(&job.task_id);
                    let result_publisher = session.declare_publisher(&result_key).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    let result_json = serde_json::to_string(&result)?;
                    result_publisher.put(result_json).await.await.map_err(|e| anyhow::anyhow!("Zenoh error: {}", e))?;
                    
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
                        pending_jobs.insert(job_id.clone(), job);
                        println!("📋 Assigner received job: {}", job_id);
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

    pub async fn run_simple_zenoh_demo(&self) -> Result<()> {
        println!("🚀 Zenoh P2P Computing Demo (Rust - Simple with Zenoh)");
        println!("=====================================================");
        println!("Using Zenoh 1.6.2 API with real messaging");
        println!();

        // Start assigner
        let assigner_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = SimpleZenohDemo { running };
                if let Err(e) = demo.assigner_simulation().await {
                    println!("❌ Assigner error: {}", e);
                }
            })
        };

        // Start result listener
        let listener_handle = {
            let running = self.running.clone();
            tokio::spawn(async move {
                let demo = SimpleZenohDemo { running };
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
                    let demo = SimpleZenohDemo { running };
                    if let Err(e) = demo.worker_simulation(&worker_id, latency_ms).await {
                        println!("❌ Worker {} error: {}", worker_id, e);
                    }
                })
            })
            .collect();

        // Wait a bit for components to start
        sleep(Duration::from_millis(1000)).await;

        // Submit jobs
        self.submit_job().await?;
        sleep(Duration::from_millis(500)).await;
        self.submit_job().await?;

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

        println!("\n✅ Simple Zenoh demo completed!");
        
        Ok(())
    }
}
