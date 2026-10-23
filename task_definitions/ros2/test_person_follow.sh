#!/bin/bash
# Test script for person-following examples

echo "🤖 Testing Person Following Examples"
echo "====================================="

# Check if Ollama is running
echo "🔍 Checking if Ollama is running..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is running"
else
    echo "❌ Ollama is not running. Please start it with: ollama serve"
    exit 1
fi

# Check if Qwen2.5VL model is available
echo "🔍 Checking for Qwen2.5VL model..."
if ollama list | grep -q "qwen2.5vl:3b"; then
    echo "✅ Qwen2.5VL model is available"
else
    echo "❌ Qwen2.5VL model not found. Please install it with: ollama pull qwen2.5vl:3b"
    exit 1
fi

# Check if Corebrum is available
echo "🔍 Checking if Corebrum is available..."
if [ -f "./../../../corebrum-cortex/target/debug/cortex" ]; then
    echo "✅ Corebrum binary found"
else
    echo "❌ Corebrum binary not found at ./../../../corebrum-cortex/target/debug/cortex"
    echo "   Please build cortex first or check the path."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "person_follow_simple.yaml" ]; then
    echo "❌ person_follow_simple.yaml not found. Please run this script from the ros2 examples directory."
    exit 1
fi

echo ""
echo "🚀 Starting person-following test..."
echo ""

# Submit the simple person-following task
echo "📤 Submitting person_follow_simple.yaml..."
SUBMIT_OUTPUT=$(./../../../corebrum-cortex/target/debug/cortex submit --file person_follow_simple.yaml 2>&1)
if [ $? -eq 0 ]; then
    TASK_ID=$(echo "$SUBMIT_OUTPUT" | grep -o '[0-9a-f-]\{36\}' | head -1)
    if [ -n "$TASK_ID" ]; then
        echo "✅ Task submitted with ID: $TASK_ID"
    else
        echo "❌ Failed to extract task ID from output: $SUBMIT_OUTPUT"
        exit 1
    fi
else
    echo "❌ Failed to submit task: $SUBMIT_OUTPUT"
    exit 1
fi


# Monitor the task
echo ""
echo "📊 Monitoring task status..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping task..."
    ./../../../corebrum-cortex/target/debug/cortex cancel $TASK_ID > /dev/null 2>&1
    echo "✅ Task cancelled"
    exit 0
}

# Set up signal handler
trap cleanup SIGINT

# Monitor task status and velocity commands
while true; do
    # Check task status
    STATUS=$(./../../../corebrum-cortex/target/debug/cortex status $TASK_ID 2>/dev/null | grep -o "Status: [A-Za-z]*" | cut -d' ' -f2)
    
    if [ "$STATUS" = "COMPLETED" ] || [ "$STATUS" = "FAILED" ]; then
        echo "📋 Task finished with status: $STATUS"
        break
    fi
    
    # Show current status
    echo -n "📊 Task status: $STATUS"
    
    # Check if velocity commands are being published to zenoh
    if ./../../../corebrum-cortex/target/debug/cortex topics | grep -q "rt/cmd_vel"; then
        echo " | 🚗 Velocity commands active (zenoh)"
    else
        echo " | ⏸️  No velocity commands (zenoh)"
    fi
    
    sleep 2
done

echo ""
echo "🏁 Test completed!"
echo ""
echo "💡 To monitor velocity commands in real-time, run:"
echo "   ./../../../corebrum-cortex/target/debug/cortex subscribe rt/cmd_vel"
echo ""
echo "💡 To check task results, run:"
echo "   ./../../../corebrum-cortex/target/debug/cortex results $TASK_ID"
echo ""
echo "💡 To check debug images (if any were saved), run:"
echo "   ls -la /tmp/debug_image*.jpg"
echo ""
echo "💡 To monitor all zenoh topics, run:"
echo "   ./../../../corebrum-cortex/target/debug/cortex topics"
