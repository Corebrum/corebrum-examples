#!/bin/bash
# cmos_orchestrator.sh - CMOS-compatible mesh orchestration script
# 
# This script is designed to run inside the CMOS shell environment.
# It demonstrates orchestration of parallel, sequential, and stream tasks
# using CMOS-native commands.
#
# Usage: In CMOS shell, run:
#   CMOS[user@local] > ./cmos_orchestrator.sh
#   CMOS[user@local] > source cmos_orchestrator.sh  # To load functions

# CMOS-compatible helper functions
cmos_wait_for_task() {
    local task_id=$1
    local max_wait=${2:-300}
    
    echo "⏳ Waiting for $task_id..."
    
    local attempts=0
    while [ $attempts -lt $max_wait ]; do
        # In CMOS, 'status' command is available directly
        local status_output=$(status "$task_id" 2>/dev/null)
        local state=$(echo "$status_output" | grep -i "state" | head -1 | grep -oE '(PENDING|RUNNING|COMPLETED|FAILED|ERROR)' | head -1)
        
        case "$state" in
            "COMPLETED")
                echo "✅ Task completed!"
                return 0
                ;;
            "FAILED"|"ERROR")
                echo "❌ Task failed!"
                return 1
                ;;
            *)
                sleep 2
                attempts=$((attempts + 2))
                ;;
        esac
    done
    
    echo "⏰ Timeout waiting for task"
    return 1
}

cmos_submit_parallel() {
    local task_file=$1
    shift
    local inputs=("$@")
    local task_ids=()
    
    echo "🚀 Submitting ${#inputs[@]} parallel tasks..."
    
    for input in "${inputs[@]}"; do
        local output=$(submit "$task_file" --input "$input" 2>&1)
        local task_id=$(echo "$output" | grep -oE '[a-f0-9-]{36}' | head -1)
        
        if [ -n "$task_id" ]; then
            task_ids+=("$task_id")
            echo "  ✓ Submitted: $task_id"
        else
            echo "  ✗ Failed to submit task"
        fi
    done
    
    # Return task IDs (space-separated)
    echo "${task_ids[@]}"
}

cmos_submit_chain() {
    local task_file=$1
    local input=$2
    
    echo "🔗 Submitting sequential chain..."
    
    # Use submit-and-wait for sequential chains
    local output=$(submit-and-wait "$task_file" --input "$input" 2>&1)
    local task_id=$(echo "$output" | grep -oE '[a-f0-9-]{36}' | head -1)
    
    if echo "$output" | grep -qi "completed\|success"; then
        echo "✅ Chain completed: $task_id"
        echo "$task_id"
        return 0
    else
        echo "❌ Chain failed"
        return 1
    fi
}

cmos_start_stream() {
    local task_file=$1
    local input=$2
    
    echo "🌊 Starting stream task..."
    
    local output=$(submit "$task_file" --input "$input" 2>&1)
    local task_id=$(echo "$output" | grep -oE '[a-f0-9-]{36}' | head -1)
    
    if [ -n "$task_id" ]; then
        echo "✅ Stream started: $task_id"
        echo "$task_id"
        return 0
    else
        echo "❌ Failed to start stream"
        return 1
    fi
}

cmos_stop_stream() {
    local task_id=$1
    echo "🛑 Stopping stream $task_id..."
    stream-cancel "$task_id" 2>/dev/null
}

# Extract result value using CMOS results command
cmos_get_result_value() {
    local task_id=$1
    local key=$2  # JSON path like ".status" or ".result.factorial"
    
    local result=$(results "$task_id" --format json 2>/dev/null)
    echo "$result" | jq -r "$key // empty" 2>/dev/null || echo ""
}

# Main orchestration workflow
main() {
    echo "🎯 Mesh Orchestration Workflow"
    echo "=============================="
    echo ""
    
    # Phase 1: Parallel batch processing
    echo "📊 Phase 1: Parallel Data Processing"
    echo "--------------------------------------"
    
    # Example: Submit multiple factorial tasks in parallel
    # Replace with your actual task files and inputs
    local parallel_ids=($(cmos_submit_parallel "../task_definitions/python/factorial_task.yaml" \
        '{"number": 5}' \
        '{"number": 10}' \
        '{"number": 15}'))
    
    if [ ${#parallel_ids[@]} -eq 0 ]; then
        echo "❌ No tasks were submitted"
        return 1
    fi
    
    local all_succeeded=true
    for task_id in "${parallel_ids[@]}"; do
        if ! cmos_wait_for_task "$task_id"; then
            all_succeeded=false
        fi
    done
    
    if [ "$all_succeeded" = true ]; then
        echo "✅ All parallel tasks succeeded!"
        
        # Phase 2: Sequential aggregation
        echo ""
        echo "🔗 Phase 2: Sequential Aggregation"
        echo "-----------------------------------"
        
        # Use sequential pipeline to aggregate results
        local chain_id=$(cmos_submit_chain "../task_definitions/sequential/sequential_pipeline.yaml" '{
            "api_url": "https://api.example.com/data"
        }')
        
        if [ -n "$chain_id" ]; then
            # Check aggregation result
            local result=$(results "$chain_id" --format json 2>/dev/null)
            local status=$(echo "$result" | jq -r '.status // .pipeline_status // "unknown"' 2>/dev/null)
            
            if [ "$status" = "completed" ] || [ "$status" = "success" ]; then
                echo "✅ Aggregation succeeded!"
                
                # Phase 3: Start monitoring stream
                echo ""
                echo "🌊 Phase 3: Start Monitoring Stream"
                echo "-----------------------------------"
                
                local stream_id=$(cmos_start_stream "../task_definitions/ros2/battery_monitor.yaml" '{
                    "monitor_interval_ms": 900000
                }')
                
                if [ -n "$stream_id" ]; then
                    echo "✅ Stream monitoring active!"
                    echo "💡 Use 'stream-cancel $stream_id' to stop"
                    echo ""
                    echo "⏳ Monitoring stream... (check with 'streams' command)"
                    
                    # Keep checking if stream is still active
                    local check_count=0
                    while [ $check_count -lt 60 ]; do  # Check for up to 2 minutes
                        if streams 2>/dev/null | grep -q "$stream_id"; then
                            sleep 2
                            check_count=$((check_count + 1))
                        else
                            echo "⚠️  Stream $stream_id is no longer active"
                            break
                        fi
                    done
                else
                    echo "❌ Failed to start stream"
                fi
            else
                echo "❌ Aggregation status: $status"
            fi
        else
            echo "❌ Sequential chain submission failed"
        fi
    else
        echo "❌ Some parallel tasks failed, aborting workflow"
        return 1
    fi
    
    echo ""
    echo "🎉 Orchestration workflow completed!"
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi

