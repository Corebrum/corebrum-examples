#!/bin/bash
# AGI Operating System Demo Script
# Demonstrates autonomous mission agent creating and managing tasks

set -e

API_URL="http://localhost:6502"
ZENOH_ROUTER="${ZENOH_ROUTER:-tcp://127.0.0.1:7447}"

echo "🤖 Corebrum AGI Operating System Demo"
echo "======================================"
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."
echo ""

# Check if Zenoh is accessible
if ! zenoh info > /dev/null 2>&1; then
    echo "❌ Error: Zenoh router is not accessible"
    echo "   Start it with: zenohd"
    exit 1
fi
echo "✅ Zenoh router is accessible"

# Check if Corebrum daemon is running
# Try API first, then check if corebrum command works
if ! curl -s "$API_URL/api/jobs" > /dev/null 2>&1; then
    # API might not be available, check if corebrum command works
    if ! corebrum jobs > /dev/null 2>&1; then
        echo "❌ Error: Corebrum daemon is not running"
        echo "   Start it with: corebrum daemon --worker-count 4"
        echo "   Or use: corebrum cmos"
        exit 1
    fi
fi
echo "✅ Corebrum daemon is accessible"

# Check if Ollama is running
if ! curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "❌ Error: Ollama is not running on http://localhost:11434"
    echo "   Start it with: ollama serve"
    exit 1
fi
echo "✅ Ollama is running"

# Check for Qwen model
if ! ollama list | grep -q "qwen"; then
    echo "⚠️  Warning: Qwen model not found. Installing..."
    ollama pull qwen2.5vl:3b
fi
echo "✅ Qwen model available"
echo ""

# Step 1: Create identity
echo "1️⃣  Creating AGI agent identity..."
IDENTITY_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{"name": "AGI Mission Agent"}')

IDENTITY_ID=$(echo "$IDENTITY_RESPONSE" | jq -r '.key_id' 2>/dev/null)
if [ -z "$IDENTITY_ID" ] || [ "$IDENTITY_ID" = "null" ]; then
    echo "❌ Failed to create identity"
    echo "Response: $IDENTITY_RESPONSE"
    exit 1
fi
echo "✅ Created identity: $IDENTITY_ID"

# Enable memory feature
echo "2️⃣  Enabling memory feature..."
curl -s -X PUT "$API_URL/api/identity/$IDENTITY_ID/enable" \
  -H "Content-Type: application/json" \
  -d '{"feature": "memory"}' > /dev/null
echo "✅ Memory feature enabled"
echo ""

# Step 3: Submit AGI agent
echo "3️⃣  Submitting Autonomous Mission Agent..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_YAML="$SCRIPT_DIR/autonomous_mission_agent.yaml"

if [ ! -f "$AGENT_YAML" ]; then
    echo "❌ Error: Cannot find $AGENT_YAML"
    echo "   Make sure you're running from the correct directory"
    exit 1
fi

echo "   Command: corebrum submit --file $AGENT_YAML --identity $IDENTITY_ID"
echo ""

# Try to submit with timeout
SUBMIT_OUTPUT=$(timeout 10 corebrum submit \
  --file "$AGENT_YAML" \
  --identity "$IDENTITY_ID" 2>&1) || SUBMIT_EXIT_CODE=$?

echo "Raw output:"
echo "$SUBMIT_OUTPUT"
echo ""

# Try to extract task ID from various possible formats
AGENT_TASK_ID=$(echo "$SUBMIT_OUTPUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)

# If no UUID found, try checking if it's already running via streams
if [ -z "$AGENT_TASK_ID" ]; then
    echo "⚠️  Could not extract task ID from output. Checking if task is already running..."
    STREAMS_OUTPUT=$(corebrum streams 2>&1)
    echo "$STREAMS_OUTPUT"
    
    # Check if there's an error in the output
    if echo "$SUBMIT_OUTPUT" | grep -qi "error\|failed\|invalid"; then
        echo "❌ Failed to submit AGI agent - error detected in output"
        exit 1
    fi
    
    # If submit command succeeded but no ID, maybe it's a streaming task that doesn't return ID immediately
    echo "⚠️  Submission may have succeeded but task ID not found. Continuing..."
    echo "   Check with: corebrum streams"
    echo "   Or check logs in Corebrum daemon"
    AGENT_TASK_ID="unknown"
else
    echo "✅ AGI agent submitted: $AGENT_TASK_ID"
    echo "   Monitor with: corebrum status $AGENT_TASK_ID"
fi
echo ""

# Step 4: Submit result monitor
echo "4️⃣  Submitting Mission Result Monitor..."
MONITOR_YAML="$SCRIPT_DIR/mission_result_monitor.yaml"

if [ ! -f "$MONITOR_YAML" ]; then
    echo "⚠️  Warning: Cannot find $MONITOR_YAML"
    echo "   Skipping result monitor (optional)"
    MONITOR_TASK_ID="skipped"
else
    echo "   Command: corebrum submit --file $MONITOR_YAML --identity $IDENTITY_ID"
    echo ""
    
    MONITOR_OUTPUT=$(timeout 10 corebrum submit \
      --file "$MONITOR_YAML" \
      --identity "$IDENTITY_ID" 2>&1) || MONITOR_EXIT_CODE=$?

echo "Raw output:"
echo "$MONITOR_OUTPUT"
echo ""

    MONITOR_TASK_ID=$(echo "$MONITOR_OUTPUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
    
    if [ -z "$MONITOR_TASK_ID" ]; then
        echo "⚠️  Could not extract task ID. Checking if task is already running..."
        if echo "$MONITOR_OUTPUT" | grep -qi "error\|failed\|invalid"; then
            echo "❌ Failed to submit result monitor - error detected"
            MONITOR_TASK_ID="failed"
        else
            echo "⚠️  Submission may have succeeded. Check with: corebrum streams"
            MONITOR_TASK_ID="unknown"
        fi
    else
        echo "✅ Result monitor submitted: $MONITOR_TASK_ID"
    fi
fi
echo ""

# Wait a moment for agents to initialize
echo "⏳ Waiting for agents to initialize..."
sleep 3
echo ""

# Step 5: Publish example mission
echo "5️⃣  Publishing research mission..."
MISSION_ID="research_$(date +%s)"
MISSION_JSON=$(cat <<EOF
{
  "mission_id": "$MISSION_ID",
  "mission_type": "research",
  "topic": "quantum computing",
  "depth": "comprehensive",
  "deliverable": "analysis report with at least 5 key findings",
  "requirements": {
    "min_findings": 5,
    "include_applications": true,
    "include_recent_developments": true
  },
  "adaptive": true
}
EOF
)

zenoh put -k agi/missions/goals -v "$MISSION_JSON" --encoder json
echo "✅ Mission published: $MISSION_ID"
echo ""

# Step 6: Monitor mission progress
echo "6️⃣  Monitoring mission progress..."
echo "   Mission ID: $MISSION_ID"
echo "   Press Ctrl+C to stop monitoring"
echo ""
echo "📊 Mission Status:"
echo "------------------"

# Monitor mission status
zenoh subscribe -k "agi/missions/$MISSION_ID/status" &
STATUS_PID=$!

# Monitor created tasks
zenoh subscribe -k "agi/missions/$MISSION_ID/created_tasks" &
TASKS_PID=$!

# Monitor final results
zenoh subscribe -k "agi/missions/$MISSION_ID/results" &
RESULTS_PID=$!

# Wait for user interrupt
trap "kill $STATUS_PID $TASKS_PID $RESULTS_PID 2>/dev/null; exit" INT
wait

echo ""
echo "✅ Demo completed!"
echo ""
echo "📊 Useful Commands:"
echo "-------------------"
echo ""
echo "View mission results:"
echo "  zenoh subscribe -k agi/missions/$MISSION_ID/results"
echo ""
echo "Check agent logs:"
echo "  corebrum logs $AGENT_TASK_ID"
if [ "$MONITOR_TASK_ID" != "skipped" ] && [ "$MONITOR_TASK_ID" != "failed" ]; then
    echo "  corebrum logs $MONITOR_TASK_ID"
fi
echo ""
echo "Check task execution:"
echo "  corebrum jobs"
echo ""
echo "Send another mission:"
echo "  zenoh put -k agi/missions/goals -v '{\"mission_type\": \"research\", \"topic\": \"your topic\", \"depth\": \"basic\"}' --encoder json"
echo ""
echo "Cancel agents:"
echo "  corebrum cancel $AGENT_TASK_ID"
if [ "$MONITOR_TASK_ID" != "skipped" ] && [ "$MONITOR_TASK_ID" != "failed" ] && [ "$MONITOR_TASK_ID" != "unknown" ]; then
    echo "  corebrum cancel $MONITOR_TASK_ID"
fi
echo ""
echo "Identity ID (save this for future use):"
echo "  $IDENTITY_ID"
