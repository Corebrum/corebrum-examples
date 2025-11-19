#!/bin/bash
# advanced_orchestrator.sh - Result-driven conditional orchestration
#
# This script demonstrates advanced orchestration patterns with:
# - Result-based conditional logic
# - Dynamic task submission based on results
# - Complex workflow branching
#
# Usage:
#   ./advanced_orchestrator.sh
#   ZENOH_ROUTER=tcp://192.168.1.100:7447 ./advanced_orchestrator.sh

set -e

# Configuration
ZENOH_ROUTER="${ZENOH_ROUTER:-tcp://127.0.0.1:7447}"
MAX_WAIT_TIME=300
POLL_INTERVAL=2

# Helper: Wait for task (reused from mesh_orchestrator.sh)
wait_for_task() {
    local task_id=$1
    local max_attempts=$((MAX_WAIT_TIME / POLL_INTERVAL))
    local attempts=0
    
    while [ $attempts -lt $max_attempts ]; do
        local status=$(corebrum status "$task_id" --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '"state": "[^"]*"' | cut -d'"' -f4)
        
        case "$status" in
            "COMPLETED")
                return 0
                ;;
            "FAILED"|"ERROR")
                return 1
                ;;
            *)
                attempts=$((attempts + 1))
                sleep $POLL_INTERVAL
                ;;
        esac
    done
    return 1
}

# Helper: Get task result as JSON
get_task_result() {
    local task_id=$1
    corebrum results "$task_id" --format json --zenoh-router "$ZENOH_ROUTER" 2>/dev/null
}

# Extract numeric value from result
get_numeric_result() {
    local task_id=$1
    local key=$2
    get_task_result "$task_id" | jq -r "$key // 0" 2>/dev/null
}

# Extract string value from result
get_string_result() {
    local task_id=$1
    local key=$2
    get_task_result "$task_id" | jq -r "$key // \"\"" 2>/dev/null
}

# Check if result meets condition (jq expression)
check_condition() {
    local task_id=$1
    local condition=$2  # e.g., ".count > 100", ".status == \"success\""
    
    local result=$(get_task_result "$task_id")
    local value=$(echo "$result" | jq -r "$condition" 2>/dev/null)
    
    [ "$value" = "true" ] && return 0 || return 1
}

# Submit task and return task ID
submit_task() {
    local task_file=$1
    local input=$2
    
    corebrum submit "$task_file" \
        --input "$input" \
        --zenoh-router "$ZENOH_ROUTER" 2>/dev/null | grep -o '[a-f0-9-]\{36\}' | head -1
}

# Submit parallel tasks
submit_parallel_tasks() {
    local task_file=$1
    local input_list=$2
    local task_ids=()
    
    local count=$(echo "$input_list" | jq 'length')
    
    for i in $(seq 0 $((count - 1))); do
        local input=$(echo "$input_list" | jq -r ".[$i]")
        local task_id=$(submit_task "$task_file" "$input")
        
        if [ -n "$task_id" ]; then
            task_ids+=("$task_id")
        fi
    done
    
    echo "${task_ids[@]}"
}

# Submit sequential chain
submit_sequential_chain() {
    local task_file=$1
    local input=$2
    
    local task_id=$(submit_task "$task_file" "$input")
    
    if [ -n "$task_id" ]; then
        wait_for_task "$task_id"
        echo "$task_id"
    else
        return 1
    fi
}

# Start stream task
start_stream_task() {
    local task_file=$1
    local input=$2
    
    local task_id=$(submit_task "$task_file" "$input")
    
    if [ -n "$task_id" ]; then
        echo "$task_id"
    else
        return 1
    fi
}

# Main advanced workflow
advanced_workflow() {
    echo "🎯 Advanced Mesh Orchestration"
    echo "=============================="
    echo ""
    
    # Step 1: Parallel analysis
    echo "📊 Step 1: Parallel Analysis"
    echo "----------------------------"
    
    local analysis_inputs='[
        {"dataset": "dataset1", "threshold": 0.8},
        {"dataset": "dataset2", "threshold": 0.8},
        {"dataset": "dataset3", "threshold": 0.8}
    ]'
    
    # Note: Replace with actual task files
    echo "💡 Example: Submit analysis tasks"
    # local analysis_ids=($(submit_parallel_tasks "../task_definitions/python/analyze.yaml" "$analysis_inputs"))
    
    # For demonstration, we'll show the logic:
    local analysis_ids=("task1" "task2" "task3")  # Placeholder
    
    echo "  Submitted ${#analysis_ids[@]} analysis tasks"
    
    # Wait for all analysis tasks
    local all_completed=true
    for task_id in "${analysis_ids[@]}"; do
        if ! wait_for_task "$task_id"; then
            all_completed=false
        fi
    done
    
    if [ "$all_completed" != true ]; then
        echo "❌ Some analysis tasks failed"
        return 1
    fi
    
    # Step 2: Conditional processing based on results
    echo ""
    echo "🔍 Step 2: Conditional Processing"
    echo "----------------------------------"
    
    local should_aggregate=false
    local high_confidence_count=0
    
    for task_id in "${analysis_ids[@]}"; do
        # Check confidence threshold (example condition)
        # if check_condition "$task_id" ".confidence > 0.8"; then
        #     echo "  ✅ High confidence result from $task_id"
        #     should_aggregate=true
        #     high_confidence_count=$((high_confidence_count + 1))
        # fi
        
        # Example: Extract confidence value
        # local confidence=$(get_numeric_result "$task_id" ".confidence")
        # if (( $(echo "$confidence > 0.8" | bc -l) )); then
        #     echo "  ✅ High confidence ($confidence) from $task_id"
        #     should_aggregate=true
        #     high_confidence_count=$((high_confidence_count + 1))
        # fi
    done
    
    echo "  Found $high_confidence_count high-confidence results"
    
    if [ "$should_aggregate" = true ]; then
        # Step 3: Aggregate only if conditions met
        echo ""
        echo "📈 Step 3: Aggregation"
        echo "----------------------"
        
        local aggregate_input=$(echo "{\"sources\": [\"${analysis_ids[0]}\", \"${analysis_ids[1]}\", \"${analysis_ids[2]}\"]}" | jq .)
        
        # local aggregate_id=$(submit_sequential_chain "../task_definitions/sequential/sequential_pipeline.yaml" "$aggregate_input")
        local aggregate_id="aggregate_task"  # Placeholder
        
        if [ -n "$aggregate_id" ]; then
            wait_for_task "$aggregate_id"
            
            # Step 4: Check aggregate result for stream threshold
            # local total_count=$(get_numeric_result "$aggregate_id" ".total_count")
            local total_count=1500  # Placeholder
            
            echo "  Total count: $total_count"
            
            if [ "$total_count" -gt 1000 ]; then
                echo ""
                echo "🌊 Step 4: High-Frequency Stream"
                echo "--------------------------------"
                echo "  High volume detected ($total_count), starting high-frequency stream"
                
                local stream_input='{"rate_limit_hz": 20, "monitor_topic": "rt/robot1/status"}'
                # local stream_id=$(start_stream_task "../task_definitions/ros2/object_detection.yaml" "$stream_input")
                local stream_id="stream_task"  # Placeholder
                
                if [ -n "$stream_id" ]; then
                    echo "  ✅ High-frequency stream started: $stream_id"
                fi
            else
                echo ""
                echo "🌊 Step 4: Standard Stream"
                echo "-------------------------"
                echo "  Normal volume ($total_count), starting standard stream"
                
                local stream_input='{"rate_limit_hz": 10, "monitor_topic": "rt/robot1/status"}'
                # local stream_id=$(start_stream_task "../task_definitions/ros2/battery_monitor.yaml" "$stream_input")
                local stream_id="stream_task"  # Placeholder
                
                if [ -n "$stream_id" ]; then
                    echo "  ✅ Standard stream started: $stream_id"
                fi
            fi
        fi
    else
        echo ""
        echo "⚠️  Step 3: Skipping Aggregation"
        echo "-------------------------------"
        echo "  Low confidence results, skipping aggregation"
        echo "  Consider:"
        echo "    - Reviewing input data quality"
        echo "    - Adjusting analysis parameters"
        echo "    - Running additional analysis tasks"
    fi
    
    echo ""
    echo "✅ Advanced orchestration workflow completed!"
}

# Run workflow if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    advanced_workflow "$@"
fi

