# ROS2 Integration Examples

This directory contains examples of stream-reactive tasks that integrate Corebrum with ROS2 robots via Zenoh.

## Overview

Corebrum seamlessly integrates with ROS2 robots by treating ROS2 topics as Zenoh topics. This enables robots to offload compute-intensive tasks to the mesh supercomputer while maintaining real-time responsiveness.

## How It Works

**Modern ROS2 (Jazzy+)**: Native Zenoh support - no bridge needed  
**Legacy ROS2 (DDS)**: Use `zenoh-bridge-ros2dds` to convert DDS ↔ Zenoh

ROS2 topics appear as Zenoh topics with `rt/` prefix:
- `/cmd_vel` → `rt/cmd_vel`
- `/camera/color/image_raw` → `rt/camera/color/image_raw`

## Examples

### 1. Object Detection (`object_detection.yaml`)

Real-time YOLO object detection from robot camera streams.

**Features:**
- Subscribes to camera image stream (`rt/robot1/camera/color/image_raw`)
- Runs YOLO inference on each frame
- Publishes detection results (`rt/robot1/vision/detections`)
- Rate-limited to 10 Hz to prevent overwhelming the system

**Usage:**
```bash
corebrum submit --file task_definitions/ros2/object_detection.yaml
```

### 2. Person Following (`follow_person.yaml`)

Autonomous person following behavior using computer vision and depth sensing.

**Features:**
- Subscribes to detection results and depth images
- Implements proportional control for following
- Publishes velocity commands (`rt/robot1/cmd_vel`)
- Reactive to detection messages (up to 20 Hz)

**Usage:**
```bash
corebrum submit --file task_definitions/ros2/follow_person.yaml
```

### 3. Multi-Robot Formation (`multi_robot_formation.yaml`)

Coordinate multiple robots in a triangle formation.

**Features:**
- Subscribes to odometry from 3 robots
- Implements formation control algorithm
- Publishes velocity commands to all robots
- Fixed 20 Hz control loop (50ms intervals)

**Usage:**
```bash
corebrum submit --file task_definitions/ros2/multi_robot_formation.yaml
```

## Robot Setup

### For Modern ROS2 (Native Zenoh)

```bash
# Configure ROS2 to use Zenoh RMW
export RMW_IMPLEMENTATION=rmw_zenoh_cpp

# Run your ROS2 nodes normally
ros2 run realsense2_camera realsense2_camera_node
ros2 run navigation2 nav2_bringup
```

### For Legacy ROS2 (DDS-based)

```bash
# Run the bridge on the robot
zenoh-bridge-ros2dds --namespace /robot1

# Run your ROS2 nodes normally
ros2 run realsense2_camera realsense2_camera_node
ros2 run navigation2 nav2_bringup
```

## Stream-Reactive Task Configuration

All examples use the `stream_reactive` execution mode with different trigger types:

- **`on_message`**: Execute when any input receives a message
- **`time_interval`**: Execute at fixed intervals (e.g., 50ms for 20 Hz)
- **`rate_limited`**: Execute on every message but rate-limited (e.g., 10 Hz max)

## Monitoring Stream Tasks

Use CMOS commands to monitor active stream tasks:

```bash
# List active stream tasks
mesh-streams

# Cancel a stream task
mesh-stream-cancel <task-id>

# List all Zenoh topics (ROS2 and Corebrum)
mesh-topics

# List only ROS2 topics
mesh-topics ros2

# List only Corebrum topics
mesh-topics corebrum

# Echo messages from a topic
zenoh-echo rt/robot1/cmd_vel
```

## Topic Discovery and Filtering

The `mesh-topics` command provides powerful topic discovery and filtering capabilities to help you explore the mesh network:

### Basic Usage
```bash
# Discover all topics on the mesh network
mesh-topics

# Filter by topic type
mesh-topics ros2        # Show only ROS2 topics
mesh-topics corebrum    # Show only Corebrum topics
mesh-topics all         # Show all topics (same as no filter)
```

### Topic Types
- **ROS2 Topics**: Topics from ROS2 nodes (prefixed with `rt/`)
- **Corebrum Topics**: Internal Corebrum system topics (prefixed with `corebrum/`)

### Example Output
```bash
$ mesh-topics ros2
📡 Discovering ROS2 topics on the mesh network...
📡 Discovered 5 topics (ROS2):
Topic                                    Type            Publishers   Subscribers  
---------------------------------------------------------------------------------
rt/robot1/cmd_vel                       ROS2            0            0            
rt/robot1/odom                          ROS2            0            0            
rt/robot1/scan                          ROS2            0            0            
rt/robot1/camera/color/image_raw        ROS2            0            0            
rt/robot1/tf                            ROS2            0            0            
```

### Tips
- Use `mesh-topics ros2` to focus on robot topics without Corebrum system noise
- The command discovers topics by subscribing to the mesh network for 3 seconds
- Topics are automatically categorized based on their prefixes
- Publisher/subscriber counts are not yet implemented but reserved for future use

## Key Advantages

1. **Zero ROS2 Code in Corebrum**: Just Zenoh pub/sub
2. **Works with Modern & Legacy ROS2**: Transparent to Corebrum
3. **Declarative Behaviors**: Define robot intelligence as YAML
4. **Multi-Robot Ready**: Namespace support via Zenoh keys
5. **Observable**: Use existing mesh commands to monitor
6. **Scalable**: Add compute nodes to handle more robots

## Dependencies

The examples assume the following Python packages are available on the worker nodes:

```bash
pip install ultralytics opencv-python numpy
```

## Customization

To adapt these examples for your robots:

1. Update the `key_expr` values to match your robot namespaces
2. Modify the Python code to handle your specific message formats
3. Adjust the `rate_limit_hz` and `interval_ms` based on your requirements
4. Update the `inputs` and `outputs` to match your robot's topic structure

## Troubleshooting

### No Topics Discovered
- Ensure ROS2 nodes are running and publishing
- Check that Zenoh bridge is running (for legacy ROS2)
- Verify network connectivity between robot and Corebrum mesh
- Use `mesh-topics` to see what topics are available

### Tasks Not Executing
- Check that the task is submitted successfully with `mesh-streams`
- Verify that input topics are publishing data
- Check worker logs for Python import errors
- Ensure required Python packages are installed on workers
