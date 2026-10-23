#!/bin/bash
# Debug monitoring script for person following tasks

echo "🔍 Person Following Debug Monitor"
echo "================================="
echo ""

# Check for debug images
echo "📸 Debug Images:"
if ls /tmp/debug_image*.jpg > /dev/null 2>&1; then
    echo "✅ Found debug images:"
    ls -la /tmp/debug_image*.jpg
    echo ""
    echo "💡 To view the latest image:"
    echo "   eog /tmp/debug_image*.jpg  # or any image viewer"
else
    echo "❌ No debug images found in /tmp/"
fi
echo ""

# Check zenoh topics
echo "🌐 Zenoh Topics:"
echo "Running: ./../../../corebrum-cortex/target/debug/cortex topics"
./../../../corebrum-cortex/target/debug/cortex topics
echo ""

# Monitor velocity commands
echo "🚗 Monitoring velocity commands (rt/cmd_vel):"
echo "Press Ctrl+C to stop monitoring"
echo ""
./../../../corebrum-cortex/target/debug/cortex subscribe rt/cmd_vel
