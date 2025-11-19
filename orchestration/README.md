# Corebrum Orchestration Scripts

This directory contains example scripts demonstrating how to orchestrate all three Corebrum compute patterns (parallel, sequential, and stream tasks) with conditional logic.

## Scripts

### 1. `mesh_orchestrator.sh` - Standalone CLI Orchestration

A bash script that uses the `corebrum` CLI to orchestrate workflows. Can be run from any shell environment.

**Features:**
- Parallel task submission and waiting
- Sequential chain execution
- Stream task management
- Result extraction and conditional logic
- Error handling and workflow abort

**Usage:**
```bash
# Make executable
chmod +x mesh_orchestrator.sh

# Run with default Zenoh router
./mesh_orchestrator.sh

# Run with custom Zenoh router
ZENOH_ROUTER=tcp://192.168.1.100:7447 ./mesh_orchestrator.sh
```

**Requirements:**
- `corebrum` CLI installed and in PATH
- `jq` for JSON parsing
- Zenoh router running
- Corebrum daemon running

### 2. `cmos_orchestrator.sh` - CMOS Shell Orchestration

A script designed to run inside the CMOS shell environment, using CMOS-native commands.

**Features:**
- Uses CMOS commands (`submit`, `status`, `results`, `streams`)
- CMOS-compatible helper functions
- Stream monitoring with `streams` command
- Integrated with CMOS shell environment

**Usage:**
```bash
# Enter CMOS shell
corebrum cmos

# Run the script
CMOS[user@local] > ./cmos_orchestrator.sh

# Or source it to load functions
CMOS[user@local] > source cmos_orchestrator.sh
CMOS[user@local] > main
```

**Requirements:**
- Running inside CMOS shell
- Task definition files in relative paths
- `jq` for JSON parsing (if using result extraction)

### 3. `advanced_orchestrator.sh` - Result-Driven Conditional Logic

An advanced orchestration script demonstrating result-based conditional workflows.

**Features:**
- Result extraction and numeric/string parsing
- Conditional logic based on task results
- Dynamic task submission based on conditions
- Complex workflow branching
- Threshold-based decision making

**Usage:**
```bash
chmod +x advanced_orchestrator.sh
./advanced_orchestrator.sh
```

**Example Workflow:**
1. Run parallel analysis tasks
2. Check results for confidence thresholds
3. Conditionally aggregate if confidence is high
4. Check aggregate volume
5. Start high-frequency or standard stream based on volume

## Common Patterns

### Pattern 1: Parallel → Sequential → Stream

```bash
# 1. Submit parallel tasks
parallel_ids=($(submit_parallel_tasks "process.yaml" '[...]'))

# 2. Wait for completion
wait_for_parallel_tasks "${parallel_ids[@]}"

# 3. Run sequential chain
chain_id=$(submit_sequential_chain "aggregate.yaml" '{"source": "parallel"}')

# 4. Start stream
stream_id=$(start_stream_task "monitor.yaml" '{"topic": "rt/robot1/status"}')
```

### Pattern 2: Conditional Branching

```bash
# Check result condition
if check_condition "$task_id" ".confidence > 0.8"; then
    # High confidence path
    submit_sequential_chain "high_quality.yaml" "$input"
else
    # Low confidence path
    submit_sequential_chain "review.yaml" "$input"
fi
```

### Pattern 3: Result-Based Thresholds

```bash
# Extract numeric result
count=$(get_numeric_result "$task_id" ".total_count")

# Branch based on threshold
if [ "$count" -gt 1000 ]; then
    start_stream_task "high_freq.yaml" '{"rate_limit_hz": 20}'
else
    start_stream_task "standard.yaml" '{"rate_limit_hz": 10}'
fi
```

## Helper Functions

All scripts provide helper functions for common operations:

- `wait_for_task <task_id>` - Wait for task completion
- `get_task_result <task_id>` - Get task result as JSON
- `extract_result_value <task_id> <json_path>` - Extract specific value
- `submit_parallel_tasks <file> <json_array>` - Submit multiple tasks
- `wait_for_parallel_tasks <task_ids...>` - Wait for all parallel tasks
- `submit_sequential_chain <file> <input>` - Submit and wait for chain
- `start_stream_task <file> <input>` - Start stream task
- `stop_stream_task <task_id>` - Stop stream task

## Customization

To use these scripts with your own tasks:

1. **Update task file paths**: Replace placeholder paths with your actual task definition files
2. **Customize inputs**: Modify JSON input structures to match your task requirements
3. **Adjust conditions**: Update conditional logic to match your workflow needs
4. **Configure timeouts**: Adjust `MAX_WAIT_TIME` and `POLL_INTERVAL` as needed

## Example Workflow

Here's a complete example combining all three patterns:

```bash
#!/bin/bash
# my_workflow.sh

# 1. Process 100 images in parallel
image_inputs='[{"image": "img1.jpg"}, {"image": "img2.jpg"}, ...]'
image_ids=($(submit_parallel_tasks "process_image.yaml" "$image_inputs"))
wait_for_parallel_tasks "${image_ids[@]}"

# 2. Aggregate results sequentially
aggregate_id=$(submit_sequential_chain "aggregate_results.yaml" '{
    "sources": ["'${image_ids[0]}'", "'${image_ids[1]}'", ...]
}')

# 3. Check aggregate result
total_detections=$(get_numeric_result "$aggregate_id" ".total_detections")

# 4. Start appropriate stream based on result
if [ "$total_detections" -gt 50 ]; then
    start_stream_task "high_activity_monitor.yaml" '{"rate_limit_hz": 20}'
else
    start_stream_task "normal_monitor.yaml" '{"rate_limit_hz": 5}'
fi
```

## Troubleshooting

**Tasks not submitting:**
- Check Zenoh router is running: `corebrum netstat`
- Verify task definition files exist and are valid YAML/JSON
- Check worker capabilities match task requirements

**Tasks timing out:**
- Increase `MAX_WAIT_TIME` for long-running tasks
- Check task logs: `corebrum logs <task-id>`
- Verify workers are available: `corebrum netstat`

**Results not extracting:**
- Ensure `jq` is installed: `which jq`
- Verify result JSON structure matches expected paths
- Check task completed successfully: `corebrum status <task-id>`

## Next Steps

- Create workflow definition files (YAML/JSON) for declarative workflows
- Add workflow state persistence
- Implement retry logic and error recovery
- Add workflow visualization and monitoring
- Create a `corebrum workflow` command for native workflow support

## See Also

- [Corebrum README](../../README.md) - Main documentation
- [Task Definitions](../task_definitions/) - Example task definitions
- [Sequential Tasks](../task_definitions/sequential/) - Sequential pipeline examples
- [ROS2 Tasks](../task_definitions/ros2/) - Stream task examples

