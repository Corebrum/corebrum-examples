# ROS2 Person Following Robot Demo

This directory contains a complete person-following robot system using Corebrum, Zenoh, and Qwen2.5VL vision model.

## 🎯 Main Demo: Person Following Robot

### Overview
A streaming robot that uses computer vision to detect people and follow them by publishing velocity commands. The robot moves forward when a person is detected and stops when no person is visible.

### Key Files
- **`zenoh_person_follow.py`** - Main streaming person following system
- **`person_follow_simple.yaml`** - Corebrum task definition for person following
- **`simple_qwen_test.yaml`** - One-shot test to verify Qwen detection works
- **`test_person_follow.sh`** - Complete demo script with setup and monitoring
- **`monitor_twist_commands.py`** - Real-time twist command monitor

## 🚀 Quick Start

### 1. Prerequisites

**Install Ollama and Qwen2.5VL:**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull the Qwen2.5VL model
ollama pull qwen2.5vl:3b

# Start Ollama server
ollama serve
```

**Verify Ollama is running:**
```bash
curl http://localhost:11434/api/tags
```

### 2. Run the Complete Demo

```bash
# Make the demo script executable
chmod +x test_person_follow.sh

# Run the complete person following demo
./test_person_follow.sh
```

This script will:
- ✅ Check if Ollama and Qwen are running
- ✅ Submit the person following task
- ✅ Monitor velocity commands in real-time
- ✅ Show you exactly what the robot is doing

### 3. Monitor the Robot

**In separate terminals:**

```bash
# Monitor velocity commands (what the robot is doing)
python3 monitor_twist_commands.py

# Or use the built-in zenoh subscriber
./../../../corebrum/target/debug/corebrum subscribe rt/cmd_vel

# Check active zenoh topics
./../../../corebrum/target/debug/corebrum topics
```

## 📋 How It Works

### 1. **Image Input**
- Subscribes to `rt/camera/camera/color/image_raw` (ROS2 camera topic via Zenoh)
- Processes ROS2 `sensor_msgs/Image` binary format
- Saves debug images to `/tmp/` for troubleshooting

### 2. **Person Detection**
- Uses Qwen2.5VL vision model via Ollama API
- Prompt: "Is there a person clearly visible in this image? Answer only 'yes' or 'no'"
- Processes every 2nd image to avoid overwhelming the model

### 3. **Robot Control**
- **Person detected**: Publishes `linear_x = 0.3` (move forward)
- **No person**: Publishes `linear_x = 0.0` (stop)
- Publishes to `rt/cmd_vel` topic as ROS2 `geometry_msgs/Twist`

### 4. **Real-time Monitoring**
- Twist commands are published continuously
- Monitor shows exactly what the robot is doing
- Debug images saved for troubleshooting

## 🧪 Testing

### Test Qwen Detection
```bash
# Test if Qwen can detect people in your camera
./../../../corebrum/target/debug/corebrum submit --file simple_qwen_test.yaml
```

### Periodic Task Monitoring (Time Interval Trigger)

Corebrum supports time-based periodic tasks using the `time_interval` trigger. This is perfect for monitoring tasks that need to run at regular intervals without requiring system CRON.

**Example: Battery Level Monitor**
```bash
# Submit a task that checks battery level every 15 minutes
./../../../corebrum/target/debug/corebrum submit --file battery_monitor.yaml

# Monitor the battery status topic
./../../../corebrum/target/debug/corebrum subscribe rt/robot1/battery/status

# Check active stream tasks
./../../../corebrum/target/debug/corebrum streams

# Cancel the monitoring task when done
./../../../corebrum/target/debug/corebrum cancel <task-id>
```

**How it works:**
- Uses `execution_mode: "stream_reactive"` with `trigger: "time_interval"`
- Executes the task code at the specified `interval_ms` (e.g., 900000ms = 15 minutes)
- Runs continuously until cancelled
- Perfect for periodic monitoring, health checks, and scheduled tasks

**Customization:**
- Adjust `interval_ms` to change the check frequency
- Modify the battery topic name to match your robot
- Change the output topic to publish status elsewhere

### Zenoh Message In/Out Examples

```bash
# One-shot: read latest Zenoh message and produce a result
./../../../corebrum/target/debug/corebrum submit --file zenoh_message_in.yaml

# Stream: subscribe to a Zenoh topic and publish processed messages
./../../../corebrum/target/debug/corebrum submit --file zenoh_message_in_out.yaml

# Publish a test message to the input topic for the stream example
./../../../corebrum/target/debug/corebrum publish corebrum/examples/ros2/stream/in '{"hello":"world"}'

# Subscribe to the output topic to see processed results
./../../../corebrum/target/debug/corebrum subscribe corebrum/examples/ros2/stream/out
```

### Test with Camera Publisher
```bash
# If you don't have a real camera publishing to zenoh, use the test publisher
./../../../corebrum/target/debug/corebrum submit --file camera_publisher.yaml
```

## 📊 Monitoring Commands

```bash
# Check active zenoh topics
./../../../corebrum/target/debug/corebrum topics

# Monitor velocity commands
./../../../corebrum/target/debug/corebrum subscribe rt/cmd_vel

# Check task status
./../../../corebrum/target/debug/corebrum status <task-id>

# Get task results
./../../../corebrum/target/debug/corebrum results <task-id>
```

## 🔧 Customization

### Adjust Robot Speed
Edit `zenoh_person_follow.py`:
```python
# Change this value (0.3 = 0.3 m/s forward)
linear_x = 0.3 if person_detected else 0.0
```

### Adjust Detection Sensitivity
Edit the Qwen prompt in `zenoh_person_follow.py`:
```python
"prompt": "Look at this image carefully. Is there a person (a man, woman, or person) clearly visible in this image? Answer only 'yes' or 'no'. Be very strict - only say 'yes' if you can clearly see a complete person."
```

### Change Processing Rate
Edit `person_follow_simple.yaml`:
```yaml
stream_config:
  trigger: "time_interval"
  rate_limit_hz: 0.5  # Process every 2 seconds
```

## 🐛 Troubleshooting

### Common Issues

**1. "Could not open camera"**
- Make sure a camera is publishing to `rt/camera/camera/color/image_raw`
- Use `camera_publisher.yaml` to test without real camera

**2. "Ollama API error"**
- Check if Ollama is running: `curl http://localhost:11434/api/tags`
- Make sure Qwen2.5VL is installed: `ollama pull qwen2.5vl:3b`

**3. "No velocity commands"**
- Check if the task is running: `./../../../corebrum/target/debug/corebrum status <task-id>`
- Look at debug images in `/tmp/` to see what the camera sees

**4. "Robot not stopping"**
- Check debug images to see if Qwen is detecting false positives
- Adjust the detection prompt to be more strict

### Debug Images
Debug images are saved to `/tmp/` with timestamps:
```bash
ls -la /tmp/debug_image*.jpg
ls -la /tmp/simple_zenoh_*.jpg
```

## 📁 File Structure

```
ros2/
├── zenoh_person_follow.py          # Main streaming person following system
├── person_follow_simple.yaml       # Corebrum task definition
├── simple_qwen_test.yaml          # One-shot Qwen detection test
├── camera_publisher.yaml          # Test camera publisher
├── test_person_follow.sh          # Complete demo script
├── monitor_twist_commands.py      # Twist command monitor
├── monitor_debug.sh               # Debug monitoring script
└── README.md                      # This documentation
```

## 🎮 Demo Scripts

### `test_person_follow.sh`
Complete demo that:
- Checks prerequisites (Ollama, Qwen)
- Submits person following task
- Monitors velocity commands
- Provides cleanup on exit

### `monitor_twist_commands.py`
Real-time twist command monitor that:
- Subscribes to `rt/cmd_vel`
- Decodes ROS2 Twist messages
- Shows robot actions (MOVING FORWARD/STOPPED)
- Displays velocity values

## 🔮 Future Enhancements

1. **Steering Control**: Add angular velocity for turning toward person
2. **Distance Following**: Adjust speed based on person distance
3. **Multiple Person Handling**: Follow the closest person
4. **Obstacle Avoidance**: Add safety checks
5. **Voice Commands**: Add speech recognition for control

## Current Status

### ✅ What's Working
- Basic task submission and execution
- ROS2 topic discovery via `mesh-topics`
- Simple Python task execution
- Status reporting (though with placeholder messages)

### ⚠️ Known Issues
1. **Result Retrieval**: Some tasks complete but results aren't retrievable via `mesh-results`
2. **Stream-Reactive Tasks**: Not implemented - tasks that should run continuously complete immediately
3. **Status Query System**: Shows "needs implementation for Zenoh 1.6.2"

### 🔧 Next Steps
1. **Fix Result Retrieval**: Investigate why some tasks don't return results
2. **Implement Stream-Reactive Tasks**: For continuous processing tasks like object detection
3. **Real ROS2 Integration**: Connect to actual ROS2 topics via Zenoh instead of simulation

## Person Following Examples

The new person-following examples demonstrate how to use Corebrum for continuous robot control based on computer vision:

### Prerequisites

1. **Ollama with Qwen2.5VL**: Install and run Ollama with the Qwen2.5VL model
   ```bash
   # Install Ollama (if not already installed)
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Pull the Qwen2.5VL model
   ollama pull qwen2.5vl:3b
   
   # Start Ollama server
   ollama serve
   ```

2. **ROS2 Camera**: Ensure your robot is publishing camera data to `rt/camera/camera/color/image_raw`

### Usage

```bash
# Submit the simple person-following task
submit person_follow_simple.yaml

# Or submit the advanced version
submit person_follow_qwen.yaml

# Monitor the robot's velocity commands
subscribe rt/cmd_vel

# Check task status
status <task-id>
```

### How It Works

1. **Image Capture**: Subscribes to `rt/camera/camera/color/image_raw` ROS2 topic
2. **Human Detection**: Uses Qwen2.5VL to analyze each image and detect humans
3. **Robot Control**: Publishes velocity commands to `rt/cmd_vel`:
   - **Human detected**: Move forward at 0.3 m/s
   - **No human**: Stop (0.0 m/s)
4. **Rate Limiting**: Processes every 2nd-5th image to avoid overwhelming the model

### Customization

- **Speed**: Modify `linear_x` values in the Python code
- **Detection Sensitivity**: Adjust the Qwen prompt or add confidence thresholds
- **Rate Limiting**: Change `rate_limit_hz` in the stream config
- **Turning**: Add angular velocity control for more sophisticated following

## Testing Commands

```bash
# Discover ROS2 topics
topics ros2

# Submit a basic test
submit basic_test.yaml

# Check task status
status <task-id>

# Get results
results <task-id>
```

## ROS2 Topics Available

Based on `mesh-topics ros2` output:
- `rt/camera/camera/color/camera_info`
- `rt/camera/camera/color/image_raw` ← Main camera feed
- `rt/camera/camera/color/metadata`
- `rt/camera/camera/depth/camera_info`
- `rt/camera/camera/depth/image_rect_raw`
- `rt/camera/camera/depth/metadata`

## Architecture Notes

- **Zenoh Bridge**: ROS2 topics are bridged to Zenoh with `rt/` prefix
- **Task Execution**: Python tasks run in Corebrum workers
- **Topic Discovery**: Uses Zenoh subscription to discover active topics
- **Stream Processing**: Not yet implemented for continuous tasks

## Future Enhancements

1. **Real Image Processing**: Connect to actual ROS2 image topics
2. **Stream Tasks**: Implement continuous processing for real-time applications
3. **Object Detection**: Full computer vision pipeline
4. **Multi-Robot**: Coordinate multiple robots via the mesh network