# Sequential Pipeline Examples

This directory contains examples of sequential task pipelines that chain multiple tasks together in a workflow.

## Overview

Sequential pipelines allow you to create complex workflows by chaining multiple tasks together, where the output of one task becomes the input of the next. This enables:

- **Data processing pipelines**: Transform data through multiple stages
- **AI/ML workflows**: Chain preprocessing, training, and inference steps
- **Complex computations**: Break down large problems into manageable steps
- **Conditional execution**: Execute different paths based on intermediate results

## Examples

### 1. Sequential AI Pipeline (`sequential_ai_pipeline.yaml`)

A complete AI/ML pipeline that processes data through multiple stages.

**Features:**
- Data preprocessing and cleaning
- Model training and validation
- Inference and result generation
- Demonstrates complex multi-stage workflows

**Usage:**
```bash
corebrum submit --file task_definitions/sequential/sequential_ai_pipeline.yaml
```

### 2. Sequential Data Transform (`sequential_data_transform.yaml`)

Transforms data through multiple processing stages.

**Features:**
- Data ingestion and validation
- Multiple transformation steps
- Output formatting and export
- Shows data flow between tasks

**Usage:**
```bash
corebrum submit --file task_definitions/sequential/sequential_data_transform.yaml
```

### 3. Sequential Pipeline (`sequential_pipeline.yaml`)

A basic example of chaining simple tasks together.

**Features:**
- Simple task chaining
- Parameter passing between tasks
- Error handling and recovery
- Demonstrates basic pipeline concepts

**Usage:**
```bash
corebrum submit --file task_definitions/sequential/sequential_pipeline.yaml
```

### 4. Sequential STDIN/STDOUT (`sequential_stdin_stdout.yaml`)

A minimal sequential example that makes the STDIN/STDOUT model explicit for one-shot steps: each step receives inputs injected as a Python `dict` and must print a single JSON object on STDOUT named `result`.

**Usage:**
```bash
corebrum submit --file task_definitions/sequential/sequential_stdin_stdout.yaml --input '{"seed": 5}'
```
Expected behavior: step 1 generates `[1..seed]`, step 2 squares them, step 3 aggregates to a final JSON result. Each step emits exactly one JSON object to STDOUT.

## Pipeline Configuration

### Basic Sequential Pipeline Structure

```yaml
task_definition:
  name: "sequential-pipeline"
  compute_logic:
    type: "sequential"
    tasks:
      - name: "step1"
        type: "python"
        code: |
          def main(inputs):
              result = inputs['data'] * 2
              return {'doubled': result}
        inputs:
          - name: "data"
            type: "integer"
        outputs:
          - name: "doubled"
            type: "integer"
      
      - name: "step2"
        type: "python"
        code: |
          def main(inputs):
              result = inputs['doubled'] + 10
              return {'final': result}
        inputs:
          - name: "doubled"
            type: "integer"
            source: "step1.doubled"
        outputs:
          - name: "final"
            type: "integer"
```

### Advanced Pipeline with Conditional Logic

```yaml
task_definition:
  name: "conditional-pipeline"
  compute_logic:
    type: "sequential"
    tasks:
      - name: "classifier"
        type: "python"
        code: |
          def main(inputs):
              score = inputs['score']
              if score > 0.8:
                  return {'category': 'high', 'confidence': score}
              elif score > 0.5:
                  return {'category': 'medium', 'confidence': score}
              else:
                  return {'category': 'low', 'confidence': score}
      
      - name: "high_processor"
        type: "python"
        code: |
          def main(inputs):
              return {'processed': f"High priority: {inputs['data']}"}
        condition: "classifier.category == 'high'"
      
      - name: "medium_processor"
        type: "python"
        code: |
          def main(inputs):
              return {'processed': f"Medium priority: {inputs['data']}"}
        condition: "classifier.category == 'medium'"
      
      - name: "low_processor"
        type: "python"
        code: |
          def main(inputs):
              return {'processed': f"Low priority: {inputs['data']}"}
        condition: "classifier.category == 'low'"
```

## Key Features

### Task Chaining
- **Output mapping**: Map outputs from one task to inputs of another
- **Data transformation**: Transform data between pipeline stages
- **Type safety**: Ensure type compatibility between tasks

### Conditional Execution
- **Branching logic**: Execute different tasks based on conditions
- **Parallel execution**: Run independent tasks simultaneously
- **Error handling**: Handle failures gracefully with fallback tasks

### Resource Management
- **Memory optimization**: Efficient data passing between tasks
- **Caching**: Cache intermediate results for reuse
- **Cleanup**: Automatic cleanup of temporary resources

## Best Practices

### Pipeline Design
- **Single responsibility**: Each task should have a clear, single purpose
- **Loose coupling**: Minimize dependencies between tasks
- **Error boundaries**: Design for failure at each stage

### Performance Optimization
- **Parallel execution**: Run independent tasks simultaneously
- **Data streaming**: Process data in chunks for large datasets
- **Resource pooling**: Reuse expensive resources across tasks

### Monitoring and Debugging
- **Logging**: Add comprehensive logging at each stage
- **Metrics**: Track performance and resource usage
- **Checkpoints**: Save intermediate results for debugging

## Common Patterns

### Data Processing Pipeline
```yaml
tasks:
  - name: "ingest"
    # Load and validate data
  - name: "clean"
    # Clean and normalize data
  - name: "transform"
    # Apply transformations
  - name: "analyze"
    # Perform analysis
  - name: "export"
    # Export results
```

### ML Training Pipeline
```yaml
tasks:
  - name: "preprocess"
    # Data preprocessing
  - name: "train"
    # Model training
  - name: "validate"
    # Model validation
  - name: "deploy"
    # Model deployment
```

### Conditional Workflow
```yaml
tasks:
  - name: "classify"
    # Classification step
  - name: "route_a"
    condition: "classify.result == 'A'"
  - name: "route_b"
    condition: "classify.result == 'B'"
  - name: "merge"
    # Merge results from both routes
```

## Troubleshooting

### Pipeline Execution Issues
- Check that all required inputs are available
- Verify task dependencies are correctly specified
- Review error messages from individual tasks

### Performance Problems
- Profile each pipeline stage to identify bottlenecks
- Consider parallelizing independent tasks
- Optimize data transfer between stages

### Data Flow Issues
- Validate data types between pipeline stages
- Check output mapping and input sources
- Ensure proper error handling for missing data

## Related Examples

- **Python tasks**: See `../python/` for individual Python computations
- **Docker tasks**: See `../docker/` for containerized pipeline stages
- **WASM tasks**: See `../wasm/` for high-performance pipeline components
- **ROS2 integration**: See `../ros2/` for real-time robot control pipelines
