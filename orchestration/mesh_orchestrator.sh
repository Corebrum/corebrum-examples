#!/bin/bash
# mesh_orchestrator.sh - Combines parallel, sequential, and stream tasks
# 
# This script demonstrates how to orchestrate all three Corebrum compute patterns:
# 1. Massively parallel computing
# 2. Serialized computation task chains
# 3. Physical AI robotics streams
#
# Usage:
#   ./mesh_orchestrator.sh
#   ZENOH_ROUTER=tcp://192.168.1.100:7447 ./mesh_orchestrator.sh

set -e  # Exit on error

# Configuration
ZENOH_ROUTER="${ZENOH_ROUTER:-tcp://127.0.0.1:7447}"
MAX_WAIT_TIME=300  # 5 minutes max wait
POLL_INTERVAL=2    # Check every 2 seconds

# Helper function: Wait for task completion
wait_for_task() {
    local task_id=$1
    local max_attempts=$((MAX_WAIT_TIME / POLL_INTERVAL))
    local attempts=0
    
    echo "⏳ Waiting for task $task_id to complete..."
    
    while [ $attempts -lt $max_attempts ]; do
        local status=$(corebrum status "$task_id" --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '"state": "[^"]*"' | cut -d'"' -f4)
        
        case "$status" in
            "COMPLETED")
                echo "✅ Task $task_id completed!"
                return 0
                ;;
            "FAILED"|"ERROR")
                echo "❌ Task $task_id failed!"
                return 1
                ;;
            *)
                attempts=$((attempts + 1))
                if [ $((attempts % 5)) -eq 0 ]; then
                    echo "⏳ Still waiting... (attempt $attempts/$max_attempts)"
                fi
                sleep $POLL_INTERVAL
                ;;
        esac
    done
    
    echo "⏰ Timeout waiting for task $task_id"
    return 1
}

# Helper function: Get task result as JSON
get_task_result() {
    local task_id=$1
    corebrum results "$task_id" --format json --zenoh-router "$ZENOH_ROUTER" 2>/dev/null
}

# Helper function: Extract value from JSON result
extract_result_value() {
    local task_id=$1
    local key=$2
    get_task_result "$task_id" | jq -r "$key" 2>/dev/null || echo ""
}

# Helper function: Submit parallel tasks
submit_parallel_tasks() {
    local task_file=$1
    local input_list=$2  # JSON array of inputs
    local task_ids=()
    
    echo "🚀 Submitting parallel tasks from $task_file..."
    
    # Parse input list (expects JSON array)
    local count=$(echo "$input_list" | jq 'length')
    echo "📊 Submitting $count parallel tasks..."
    
    for i in $(seq 0 $((count - 1))); do
        local input=$(echo "$input_list" | jq -r ".[$i]")
        local task_id=$(corebrum submit "$task_file" \
            --input "$input" \
            --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '[a-f0-9-]\{36\}' | head -1)
        
        if [ -n "$task_id" ]; then
            task_ids+=("$task_id")
            echo "  ✓ Submitted task $task_id"
        fi
    done
    
    # Return task IDs as space-separated string
    echo "${task_ids[@]}"
}

# Helper function: Wait for all parallel tasks
wait_for_parallel_tasks() {
    local task_ids=("$@")
    local failed=0
    
    echo "⏳ Waiting for ${#task_ids[@]} parallel tasks to complete..."
    
    for task_id in "${task_ids[@]}"; do
        if ! wait_for_task "$task_id"; then
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo "✅ All parallel tasks completed successfully!"
        return 0
    else
        echo "⚠️  $failed task(s) failed"
        return 1
    fi
}

# Helper function: Submit sequential chain
submit_sequential_chain() {
    local task_file=$1
    local input=$2
    
    echo "🔗 Submitting sequential task chain from $task_file..."
    
    local task_id=$(corebrum submit "$task_file" \
        --input "$input" \
        --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '[a-f0-9-]\{36\}' | head -1)
    
    if [ -n "$task_id" ]; then
        echo "  ✓ Submitted sequential chain $task_id"
        wait_for_task "$task_id"
        echo "$task_id"
    else
        return 1
    fi
}

# Helper function: Start stream task
start_stream_task() {
    local task_file=$1
    local input=$2
    
    echo "🌊 Starting stream task from $task_file..."
    
    local task_id=$(corebrum submit "$task_file" \
        --input "$input" \
        --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '[a-f0-9-]\{36\}' | head -1)
    
    if [ -n "$task_id" ]; then
        echo "  ✓ Stream task $task_id started"
        echo "$task_id"
    else
        return 1
    fi
}

# Helper function: Stop stream task
stop_stream_task() {
    local task_id=$1
    echo "🛑 Stopping stream task $task_id..."
    corebrum cancel "$task_id" --zenoh-router "$ZENOH_ROUTER" 2>/dev/null
}

# Main orchestration example
main() {
    # Example workflow:
    # 1. Run parallel data processing tasks
    # 2. If successful, run sequential aggregation pipeline
    # 3. If aggregation succeeds, start monitoring stream
    
    echo "🎯 Starting mesh orchestration workflow..."
    echo "=========================================="
    
    # Step 1: Parallel processing
    echo ""
    echo "📊 Step 1: Parallel Data Processing"
    echo "------------------------------------"
    
    local parallel_inputs='[
        {"file": "data1.csv", "operation": "process"},
        {"file": "data2.csv", "operation": "process"},
        {"file": "data3.csv", "operation": "process"}
    ]'
    
    # Note: Replace with actual task definition file paths
    # local parallel_task_ids=$(submit_parallel_tasks "../task_definitions/python/process_data.yaml" "$parallel_inputs")
    # local parallel_array=($parallel_task_ids)
    
    # For demonstration, we'll use a placeholder
    echo "💡 Replace 'process_data.yaml' with your actual task definition file"
    echo "   Example: submit_parallel_tasks \"../task_definitions/python/factorial_task.yaml\" \"$parallel_inputs\""
    
    # Uncomment and modify when you have actual task files:
    # if wait_for_parallel_tasks "${parallel_array[@]}"; then
    #     echo "✅ Parallel processing completed!"
    #     
    #     # Step 2: Sequential aggregation (conditional on parallel success)
    #     local aggregation_input='{"source": "parallel_results"}'
    #     local chain_task_id=$(submit_sequential_chain "../task_definitions/sequential/sequential_pipeline.yaml" "$aggregation_input")
    #     
    #     if [ -n "$chain_task_id" ]; then
    #         # Extract result from chain
    #         local aggregate_status=$(extract_result_value "$chain_task_id" '.status')
    #         
    #         if [ "$aggregate_status" = "success" ]; then
    #             echo "✅ Aggregation pipeline completed!"
    #             
    #             # Step 3: Start monitoring stream (conditional on aggregation success)
    #             local stream_input='{"monitor_topic": "rt/robot1/status"}'
    #             local stream_task_id=$(start_stream_task "../task_definitions/ros2/battery_monitor.yaml" "$stream_input")
    #             
    #             if [ -n "$stream_task_id" ]; then
    #                 echo "🌊 Monitoring stream started: $stream_task_id"
    #                 echo "💡 Run 'corebrum cancel $stream_task_id' to stop"
    #                 
    #                 # Wait for user interrupt or condition
    #                 echo "⏳ Stream running... Press Ctrl+C to stop"
    #                 trap "stop_stream_task $stream_task_id; exit" INT
    #                 sleep 3600  # Run for 1 hour, or until interrupted
    #             fi
    #         else
    #             echo "❌ Aggregation failed, not starting stream"
    #             return 1
    #         fi
    #     else
    #         echo "❌ Sequential chain submission failed"
    #         return 1
    #     fi
    # else
    #     echo "❌ Parallel processing failed, aborting workflow"
    #     return 1
    # fi
    
    echo ""
    echo "✅ Orchestration script ready!"
    echo "💡 Uncomment and customize the workflow steps above for your use case"
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

