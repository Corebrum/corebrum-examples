# Corebrum Examples

This directory contains example task definitions and workflows for Corebrum mesh computing, organized by technology and use case.

## Task Definitions

The `task_definitions/` directory contains examples organized by category:

- **[ros2/](task_definitions/ros2/)** - ROS2 robot integration examples
- **[docker/](task_definitions/docker/)** - Docker container examples  
- **[python/](task_definitions/python/)** - Python execution examples
- **[wasm/](task_definitions/wasm/)** - WebAssembly examples
- **[sequential/](task_definitions/sequential/)** - Pipeline and workflow examples
- **[general/](task_definitions/general/)** - General-purpose examples

Each directory contains detailed README files with usage instructions and examples.

## Quick Start

```bash
# Submit a simple test task
corebrum submit --file task_definitions/general/simple_test.yaml

# Submit a ROS2 robot control task
corebrum submit --file task_definitions/ros2/object_detection.yaml

# Submit a Python computation task
corebrum submit --file task_definitions/python/factorial_task.yaml
```

## Legacy Documentation

The following sections contain legacy documentation that may be useful for understanding Corebrum concepts:

## Parallel Computing Examples

Corebrum excels at parallel computing where multiple independent tasks can be executed simultaneously across the mesh network. These examples show how to structure different types of parallel workloads.

### 1. Mathematical Computations

#### Factorial Computation (`factorial_task.yaml`, `factorial_docker.yaml`, `factorial_wasm.yaml`)

Compute factorials using different execution environments:

**Local Python Task:**
```yaml
name: "factorial-computation"
language: "python"
source:
  inline:
    code: |
      import math
      def factorial(n):
          return math.factorial(n)
      
      result = factorial(inputs['number'])
      outputs = {"result": result}
```

**Docker Container:**
```yaml
name: "factorial-docker"
language: "docker"
source:
  docker:
    image: "python:3.9-slim"
    command: ["python", "-c", "import math; print(math.factorial({{inputs.number}}))"]
```

**WebAssembly (WASM):**
```yaml
name: "factorial-wasm"
language: "wasm"
source:
  wasm:
    url: "https://example.com/factorial.wasm"
    entry_point: "compute_factorial"
```

**Usage:**
```bash
# Submit with different numbers for parallel execution
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 10}'
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 15}'
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 20}'
```

#### Fibonacci Sequence (`fibonacci_task.json`)

Generate Fibonacci sequences with configurable terms:

```json
{
  "name": "fibonacci-sequence",
  "language": "python",
  "source": {
    "inline": {
      "code": "def fibonacci(n):\n    a, b = 0, 1\n    sequence = []\n    for _ in range(n):\n        sequence.append(a)\n        a, b = b, a + b\n    return sequence\n\noutputs = {\"sequence\": fibonacci(inputs['terms'])}"
    }
  },
  "inputs": [
    {
      "name": "terms",
      "type": "integer",
      "required": true,
      "description": "Number of Fibonacci terms to generate"
    }
  ]
}
```

**Usage:**
```bash
# Generate different sequence lengths in parallel
corebrum submit --file task_definitions/fibonacci_task.json --inputs '{"terms": 20}'
corebrum submit --file task_definitions/fibonacci_task.json --inputs '{"terms": 50}'
corebrum submit --file task_definitions/fibonacci_task.json --inputs '{"terms": 100}'
```

### 2. Container-Based Computing

#### Docker Tasks (`docker_task.yaml`)

Execute tasks in isolated Docker containers:

```yaml
name: "data-processing-docker"
language: "docker"
source:
  docker:
    image: "pandas/pandas:latest"
    command: 
      - "python"
      - "-c"
      - |
        import pandas as pd
        import json
        import sys
        
        # Process data from inputs
        data = json.loads('{{inputs.data}}')
        df = pd.DataFrame(data)
        
        # Perform analysis
        summary = df.describe().to_dict()
        print(json.dumps(summary))
        
requirements:
  memory_mb: 512
  cpu_cores: 2
  timeout_seconds: 300
```

**Usage:**
```bash
corebrum submit --file task_definitions/docker_task.yaml --inputs '{"data": [{"x": 1, "y": 2}, {"x": 3, "y": 4}]}'
```

### 3. WebAssembly (WASM) Computing

#### WASM Tasks (`factorial_wasm.yaml`, `factorial_wasm_url.yaml`)

Execute high-performance computations using WebAssembly:

**Local WASM File:**
```yaml
name: "wasm-factorial"
language: "wasm"
source:
  wasm:
    file: "wasm_factorial/target/wasm32-unknown-unknown/release/wasm_factorial.wasm"
    entry_point: "compute_factorial"
    memory_pages: 16
```

**WASM from URL:**
```yaml
name: "wasm-factorial-url"
language: "wasm"
source:
  wasm:
    url: "https://github.com/user/repo/releases/latest/download/factorial.wasm"
    entry_point: "compute_factorial"
    memory_pages: 32
```

**Usage:**
```bash
# Build WASM module first
cd wasm_factorial
./build.sh

# Submit WASM task
corebrum submit --file task_definitions/factorial_wasm.yaml --inputs '{"number": 25}'
```

### 4. External Code Sources

#### GitHub Gist Integration (`fibonacci_from_gist.json`)

Execute code directly from GitHub Gists:

```json
{
  "name": "fibonacci-gist",
  "language": "python",
  "source": {
    "gist": {
      "id": "abc123def456",
      "filename": "fibonacci.py"
    }
  },
  "inputs": [
    {
      "name": "terms",
      "type": "integer",
      "required": true
    }
  ]
}
```

#### Git Repository Tasks (`git_repo_task.json`)

Execute code from Git repositories:

```json
{
  "name": "git-repo-task",
  "language": "python",
  "source": {
    "git": {
      "repository": "https://github.com/user/compute-examples.git",
      "path": "algorithms/sorting.py",
      "branch": "main"
    }
  }
}
```

### 5. Mixed Source Demo (`mixed_sources_demo.yaml`)

Demonstrate multiple source types in a single workflow:

```yaml
name: "mixed-sources-demo"
language: "python"
source:
  inline:
    code: |
      # This task can use multiple source types
      import requests
      
      # Fetch data from URL
      if 'url' in inputs:
          response = requests.get(inputs['url'])
          data = response.json()
      
      # Process with inline code
      result = {"processed": len(data) if 'data' in locals() else 0}
      outputs = result
```

## Parallel Computing Best Practices

### 1. Task Design Principles

- **Independence**: Each task should be independent and not rely on other tasks
- **Stateless**: Tasks should not maintain state between executions
- **Idempotent**: Tasks should produce the same result when run multiple times
- **Resource Awareness**: Set appropriate memory and CPU requirements

### 2. Input/Output Patterns

```yaml
# Well-structured inputs
inputs:
  - name: "data"
    type: "object"
    required: true
    description: "Input data for processing"
  - name: "options"
    type: "object"
    required: false
    default: {}
    description: "Optional configuration"

# Clear outputs
outputs:
  - name: "result"
    type: "object"
    description: "Processing result"
  - name: "metadata"
    type: "object"
    description: "Execution metadata"
```

### 3. Resource Management

```yaml
requirements:
  memory_mb: 1024        # Memory limit
  cpu_cores: 2           # CPU cores needed
  timeout_seconds: 600   # Execution timeout
  dependencies:          # External dependencies
    - "numpy"
    - "pandas"
```

### 4. Error Handling

```python
# In your task code
try:
    # Main computation
    result = compute_something(inputs['data'])
    outputs = {"result": result, "status": "success"}
except Exception as e:
    outputs = {"error": str(e), "status": "failed"}
```

### 5. Monitoring Parallel Tasks

```bash
# Submit multiple parallel tasks
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 10}' &
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 15}' &
corebrum submit --file task_definitions/factorial_task.yaml --inputs '{"number": 20}' &

# Monitor all tasks
corebrum cmos
CMOS[user@local] > mesh-status --all
CMOS[user@local] > mesh-results <task-id-1>
CMOS[user@local] > mesh-results <task-id-2>
CMOS[user@local] > mesh-results <task-id-3>
```

### 6. Performance Optimization

- **Batch Processing**: Group related computations into single tasks
- **Memory Efficiency**: Use streaming for large datasets
- **Caching**: Cache frequently used data and computations
- **Load Balancing**: Distribute tasks across available workers

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