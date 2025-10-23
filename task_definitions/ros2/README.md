# ROS2 Integration Examples

This directory contains examples of how to use Corebrum with ROS2 systems via Zenoh.

## Available Examples

### 1. Basic Test (`basic_test.yaml`)
- **Purpose**: Simple test to verify ROS2 integration works
- **Complexity**: Basic
- **Status**: ✅ Working
- **Description**: Basic task that returns test data to verify the system is working

### 2. Simple Image Processing (`simple_image_processing.yaml`)
- **Purpose**: Simulated image processing task
- **Complexity**: Simple
- **Status**: ⚠️ Issues with results retrieval
- **Description**: Simulates grabbing latest frame from ROS2 camera topic

### 3. Camera Frame Analysis (`camera_frame_analysis.yaml`)
- **Purpose**: Analyze latest frame from ROS2 camera topic
- **Complexity**: Intermediate
- **Status**: ⚠️ Issues with results retrieval
- **Description**: More realistic camera analysis with detailed image statistics

### 4. Object Detection (`object_detection.yaml`)
- **Purpose**: Stream-reactive object detection task
- **Complexity**: Advanced
- **Status**: ❌ Not working (stream-reactive tasks not implemented)
- **Description**: Continuous object detection from camera stream

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

## Testing Commands

```bash
# Discover ROS2 topics
mesh-topics ros2

# Submit a basic test
mesh-submit basic_test.yaml

# Check task status
mesh-status <task-id>

# Get results
mesh-results <task-id>
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