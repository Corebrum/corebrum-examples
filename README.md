# Corebrum Examples

This directory contains example task definitions and workflows for Corebrum mesh computing.

## Sequential Task Examples

### 1. Sequential Pipeline (`sequential_pipeline.yaml`)

A basic 3-task sequential workflow demonstrating data processing:
- **Task 1**: Fetch data from API
- **Task 2**: Process and filter data
- **Task 3**: Store results and generate summary

**Usage:**
```bash
corebrum submit --file task_definitions/sequential_pipeline.yaml
```

### 2. Data Transform Chain (`sequential_data_transform.yaml`)

A CSV data processing pipeline:
- **Task 1**: Load and parse CSV data
- **Task 2**: Filter for engineering department
- **Task 3**: Calculate statistics

**Usage:**
```bash
corebrum submit --file task_definitions/sequential_data_transform.yaml
```

### 3. AI Inference Pipeline (`sequential_ai_pipeline.yaml`)

An AI/ML inference workflow:
- **Task 1**: Preprocess image data
- **Task 2**: Run AI model inference
- **Task 3**: Postprocess and analyze results

**Usage:**
```bash
corebrum submit --file task_definitions/sequential_ai_pipeline.yaml
```

## Sequential Execution Features

### Key Concepts

1. **Task Arrays**: Define multiple tasks in a single YAML file using the `tasks` array
2. **Automatic Chaining**: Tasks execute in order, with each task's output becoming the next task's input
3. **Previous Result Access**: In Python tasks, access the previous task's output via the `result` variable
4. **Decentralized Execution**: Any worker can claim any task in the sequence
5. **Error Handling**: If any task fails, the entire sequence fails

### Monitoring Sequential Tasks

```bash
# View results for entire chain
corebrum cmos
CMOS[user@local] > mesh-results <parent-task-id> --chain

# View logs for entire chain  
CMOS[user@local] > mesh-logs <parent-task-id> --chain

# Check status of individual tasks
CMOS[user@local] > mesh-status <parent-task-id>-0  # First task
CMOS[user@local] > mesh-status <parent-task-id>-1  # Second task
CMOS[user@local] > mesh-status <parent-task-id>-2  # Third task
```

### Task ID Structure

Sequential tasks use a hierarchical ID structure:
- **Parent ID**: The original task submission ID (e.g., `abc123-def456`)
- **Child IDs**: Individual tasks in the sequence (e.g., `abc123-def456-0`, `abc123-def456-1`, `abc123-def456-2`)

### Use Cases

- **Data Processing Pipelines**: ETL workflows with multiple transformation stages
- **AI/ML Workflows**: Preprocessing → Inference → Postprocessing chains
- **Multi-stage Analysis**: Extract → Transform → Load (ETL) processes
- **Robotics Computing**: Sensor → Process → Actuate control loops
- **Scientific Computing**: Simulation → Analysis → Visualization pipelines

## Running Examples

1. **Start the daemon:**
   ```bash
   corebrum daemon --worker-count 4
   ```

2. **Submit a sequential task:**
   ```bash
   corebrum submit --file task_definitions/sequential_pipeline.yaml
   ```

3. **Monitor progress:**
   ```bash
   corebrum cmos
   CMOS[user@local] > mesh-status <task-id>
   ```

4. **View results:**
   ```bash
   CMOS[user@local] > mesh-results <task-id> --chain
   ```

## Customizing Examples

You can modify these examples to suit your needs:

1. **Change the number of tasks**: Add or remove tasks from the `tasks` array
2. **Modify task logic**: Update the `code` section in each task's `compute_logic`
3. **Adjust timeouts**: Change `timeout_seconds` for each task
4. **Add inputs/outputs**: Define custom `inputs` and `outputs` for each task
5. **Use different languages**: Change `language` to `javascript`, `rust`, etc.

## Best Practices

1. **Error Handling**: Always check for errors in your task code
2. **Data Validation**: Validate input data from previous tasks
3. **Resource Management**: Set appropriate timeouts for each task
4. **Logging**: Use print statements for debugging and monitoring
5. **Idempotency**: Design tasks to be safely re-runnable