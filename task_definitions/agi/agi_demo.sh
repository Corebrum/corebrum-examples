#!/bin/bash
# AGI Operating System Demo Script
# Demonstrates autonomous mission agent creating and managing tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:6502"
ZENOH_ROUTER="${ZENOH_ROUTER:-tcp://127.0.0.1:7447}"

# Find corebrum binary
# Get the script's directory to resolve relative paths correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if command -v corebrum > /dev/null 2>&1; then
    COREBRUM_CMD="corebrum"
elif [ -f "$PROJECT_ROOT/../corebrum/target/release/corebrum" ]; then
    COREBRUM_CMD="$PROJECT_ROOT/../corebrum/target/release/corebrum"
elif [ -f "$PROJECT_ROOT/../corebrum/target/debug/corebrum" ]; then
    COREBRUM_CMD="$PROJECT_ROOT/../corebrum/target/debug/corebrum"
elif [ -f "$SCRIPT_DIR/../../corebrum/target/release/corebrum" ]; then
    COREBRUM_CMD="$SCRIPT_DIR/../../corebrum/target/release/corebrum"
elif [ -f "$SCRIPT_DIR/../../corebrum/target/debug/corebrum" ]; then
    COREBRUM_CMD="$SCRIPT_DIR/../../corebrum/target/debug/corebrum"
elif [ -f "../corebrum/target/release/corebrum" ]; then
    COREBRUM_CMD="../corebrum/target/release/corebrum"
elif [ -f "../corebrum/target/debug/corebrum" ]; then
    COREBRUM_CMD="../corebrum/target/debug/corebrum"
elif [ -f "./corebrum" ]; then
    COREBRUM_CMD="./corebrum"
else
    echo -e "${YELLOW}⚠️  Warning: corebrum command not found in PATH or common locations${NC}"
    echo "   Attempting to use 'corebrum' from PATH anyway..."
    echo "   If this fails, ensure corebrum is in your PATH or set COREBRUM_CMD environment variable"
    COREBRUM_CMD="corebrum"
fi

# Allow override via environment variable
if [ -n "$COREBRUM_CMD_ENV" ]; then
    COREBRUM_CMD="$COREBRUM_CMD_ENV"
fi

# Check if timeout command is available (optional)
if command -v timeout > /dev/null 2>&1; then
    USE_TIMEOUT=true
else
    USE_TIMEOUT=false
fi

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
# Try multiple methods to detect the daemon (works with both direct daemon and CMOS)
DAEMON_RUNNING=false

# Method 1: Check if corebrum CLI commands work (most reliable)
# Try jobs first - this works if daemon is running (even if no jobs exist)
if [ "$USE_TIMEOUT" = true ]; then
    if timeout 2 $COREBRUM_CMD jobs 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    elif timeout 2 $COREBRUM_CMD streams 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    elif timeout 2 $COREBRUM_CMD netstat 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    fi
else
    if $COREBRUM_CMD jobs 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    elif $COREBRUM_CMD streams 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    elif $COREBRUM_CMD netstat 2>/dev/null > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    fi
fi

# Method 2: Try API endpoint (might not be available in all setups)
if [ "$DAEMON_RUNNING" = false ]; then
    if curl -s --max-time 2 "$API_URL/api/jobs" > /dev/null 2>&1; then
        DAEMON_RUNNING=true
    fi
fi

if [ "$DAEMON_RUNNING" = false ]; then
    echo "⚠️  Warning: Could not detect Corebrum daemon via standard methods"
    echo "   This might be okay if you're using CMOS or a custom setup"
    echo "   The script will continue, but submit commands will fail if daemon is not running"
    echo ""
    # Only prompt if running interactively
    if [ -t 0 ]; then
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   Start daemon with: $COREBRUM_CMD daemon --worker-count 4"
            echo "   Or use: $COREBRUM_CMD cmos"
            exit 1
        fi
    else
        echo "   Continuing (non-interactive mode)..."
    fi
else
    echo "✅ Corebrum daemon is accessible"
fi

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

# Step 1: Create identity (or use existing one)
if [ -n "$IDENTITY_ID" ]; then
    echo "1️⃣  Using provided identity: $IDENTITY_ID"
    echo "   (Set via IDENTITY_ID environment variable)"
else
    echo "1️⃣  Creating AGI agent identity..."
    
    # Try CLI method first (works with CMOS and direct daemon)
    if [ "$USE_TIMEOUT" = true ]; then
        IDENTITY_OUTPUT=$(timeout 10 $COREBRUM_CMD identity create --name "AGI Mission Agent" 2>&1)
    else
        IDENTITY_OUTPUT=$($COREBRUM_CMD identity create --name "AGI Mission Agent" 2>&1)
    fi
    IDENTITY_ID=$(echo "$IDENTITY_OUTPUT" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)
    
    # If CLI method failed, try API method
    if [ -z "$IDENTITY_ID" ]; then
        echo "   Trying API method..."
        IDENTITY_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
          -H "Content-Type: application/json" \
          -d '{"name": "AGI Mission Agent"}' 2>&1)
        
        IDENTITY_ID=$(echo "$IDENTITY_RESPONSE" | jq -r '.key_id' 2>/dev/null)
        if [ -z "$IDENTITY_ID" ] || [ "$IDENTITY_ID" = "null" ]; then
            echo -e "${RED}❌ Failed to create identity${NC}"
            echo "CLI output: $IDENTITY_OUTPUT"
            if [ -n "$IDENTITY_RESPONSE" ]; then
                echo "API response: $IDENTITY_RESPONSE"
            fi
            exit 1
        fi
    fi
fi

if [ -z "$IDENTITY_ID" ]; then
    echo -e "${RED}❌ Failed to create identity - could not extract ID${NC}"
    if [ -n "$IDENTITY_OUTPUT" ]; then
        echo "CLI output: $IDENTITY_OUTPUT"
    fi
    if [ -n "$IDENTITY_RESPONSE" ]; then
        echo "API response: $IDENTITY_RESPONSE"
    fi
    echo ""
    echo "You can create an identity manually and run the script with:"
    echo "  IDENTITY_ID=<your-id> ./task_definitions/agi/agi_demo.sh"
    exit 1
fi

echo -e "${GREEN}✅ Created/using identity: $IDENTITY_ID${NC}"

# Enable memory feature
echo "2️⃣  Enabling memory feature..."

# Try API method first (faster if web API is running)
if curl -s -X PUT "$API_URL/api/identity/$IDENTITY_ID/enable" \
  -H "Content-Type: application/json" \
  -d '{"feature": "memory"}' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Memory feature enabled (via API)${NC}"
else
    # Try CLI method
    if [ "$USE_TIMEOUT" = true ]; then
        ENABLE_CMD="timeout 5 $COREBRUM_CMD identity enable \"$IDENTITY_ID\" memory"
    else
        ENABLE_CMD="$COREBRUM_CMD identity enable \"$IDENTITY_ID\" memory"
    fi
    if eval "$ENABLE_CMD" 2>/dev/null > /dev/null; then
        echo -e "${GREEN}✅ Memory feature enabled (via CLI)${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: Could not enable memory feature${NC}"
        echo "   You can enable it manually with: $COREBRUM_CMD identity enable $IDENTITY_ID memory"
        echo "   Continuing anyway..."
    fi
fi
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

echo "   Command: $COREBRUM_CMD submit $AGENT_YAML --identity $IDENTITY_ID"
echo ""

# Try to submit (corebrum submit takes file as positional argument, not --file)
if [ "$USE_TIMEOUT" = true ]; then
    SUBMIT_OUTPUT=$(timeout 10 $COREBRUM_CMD submit \
      "$AGENT_YAML" \
      --identity "$IDENTITY_ID" 2>&1) || SUBMIT_EXIT_CODE=$?
else
    SUBMIT_OUTPUT=$($COREBRUM_CMD submit \
      "$AGENT_YAML" \
      --identity "$IDENTITY_ID" 2>&1) || SUBMIT_EXIT_CODE=$?
fi

echo "Raw output:"
echo "$SUBMIT_OUTPUT"
echo ""

# Try to extract task ID from various possible formats
AGENT_TASK_ID=$(echo "$SUBMIT_OUTPUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)

    # If no UUID found, try checking if it's already running via streams
    if [ -z "$AGENT_TASK_ID" ]; then
        echo -e "${YELLOW}⚠️  Could not extract task ID from output. Checking if task is already running...${NC}"
        STREAMS_OUTPUT=$($COREBRUM_CMD streams 2>&1)
    echo "$STREAMS_OUTPUT"
    
    # Check if there's an error in the output
    if echo "$SUBMIT_OUTPUT" | grep -qi "error\|failed\|invalid\|No such file"; then
        echo -e "${RED}❌ Failed to submit AGI agent - error detected in output${NC}"
        echo "Output: $SUBMIT_OUTPUT"
        exit 1
    fi
    
    # If submit command succeeded but no ID, maybe it's a streaming task that doesn't return ID immediately
    echo -e "${YELLOW}⚠️  Submission may have succeeded but task ID not found. Continuing...${NC}"
    echo "   Check with: $COREBRUM_CMD streams"
    echo "   Or check logs in Corebrum daemon"
    AGENT_TASK_ID="unknown"
else
    echo "✅ AGI agent submitted: $AGENT_TASK_ID"
    echo "   Monitor with: $COREBRUM_CMD status $AGENT_TASK_ID"
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
    echo "   Command: $COREBRUM_CMD submit $MONITOR_YAML --identity $IDENTITY_ID"
    echo ""
    
    if [ "$USE_TIMEOUT" = true ]; then
        MONITOR_OUTPUT=$(timeout 10 $COREBRUM_CMD submit \
          "$MONITOR_YAML" \
          --identity "$IDENTITY_ID" 2>&1) || MONITOR_EXIT_CODE=$?
    else
        MONITOR_OUTPUT=$($COREBRUM_CMD submit \
          "$MONITOR_YAML" \
          --identity "$IDENTITY_ID" 2>&1) || MONITOR_EXIT_CODE=$?
    fi

echo "Raw output:"
echo "$MONITOR_OUTPUT"
echo ""

    MONITOR_TASK_ID=$(echo "$MONITOR_OUTPUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
    
    if [ -z "$MONITOR_TASK_ID" ]; then
        echo -e "${YELLOW}⚠️  Could not extract task ID. Checking if task is already running...${NC}"
        if echo "$MONITOR_OUTPUT" | grep -qi "error\|failed\|invalid\|No such file"; then
            echo -e "${RED}❌ Failed to submit result monitor - error detected${NC}"
            echo "Output: $MONITOR_OUTPUT"
            MONITOR_TASK_ID="failed"
        else
            echo -e "${YELLOW}⚠️  Submission may have succeeded. Check with: $COREBRUM_CMD streams${NC}"
            MONITOR_TASK_ID="unknown"
        fi
    else
        echo -e "${GREEN}✅ Result monitor submitted: $MONITOR_TASK_ID${NC}"
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
echo "  $COREBRUM_CMD logs $AGENT_TASK_ID"
if [ "$MONITOR_TASK_ID" != "skipped" ] && [ "$MONITOR_TASK_ID" != "failed" ]; then
    echo "  $COREBRUM_CMD logs $MONITOR_TASK_ID"
fi
echo ""
echo "Check task execution:"
echo "  $COREBRUM_CMD jobs"
echo ""
echo "Send another mission:"
echo "  zenoh put -k agi/missions/goals -v '{\"mission_type\": \"research\", \"topic\": \"your topic\", \"depth\": \"basic\"}' --encoder json"
echo ""
echo "Cancel agents:"
echo "  $COREBRUM_CMD cancel $AGENT_TASK_ID"
if [ "$MONITOR_TASK_ID" != "skipped" ] && [ "$MONITOR_TASK_ID" != "failed" ] && [ "$MONITOR_TASK_ID" != "unknown" ]; then
    echo "  $COREBRUM_CMD cancel $MONITOR_TASK_ID"
fi
echo ""
echo "Identity ID (save this for future use):"
echo "  $IDENTITY_ID"
