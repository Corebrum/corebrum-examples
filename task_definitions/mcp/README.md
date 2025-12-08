# MCP (Model Context Protocol) Examples

This directory contains examples demonstrating how to integrate MCP (Model Context Protocol) jobs with Corebrum. MCP is a standardized protocol for AI systems (LLMs) to interact with external tools and data sources, enabling dynamic integration with diverse services.

## Overview

MCP jobs in Corebrum allow you to:
- **Call MCP servers** to perform operations (web search, weather lookup, database queries, etc.)
- **Stream MCP tool results** in real-time based on Zenoh topic triggers
- **Integrate AI/LLM capabilities** into your distributed computing workflows
- **Process sensor data** through MCP tools for AI-powered analysis

## Examples

### 1. MCP One-Shot Job (`mcp_one_shot_job.yaml`)

A one-shot task that calls an MCP server to perform a single operation.

**Features:**
- Calls MCP server via JSON-RPC 2.0 protocol
- Supports custom tool names and arguments
- Handles errors gracefully
- Returns structured results

**Usage:**
```bash
# Submit with default MCP server (localhost:3000)
corebrum submit --file task_definitions/mcp/mcp_one_shot_job.yaml \
  --inputs '{"mcp_server_url": "http://localhost:3000", "tool_name": "web_search", "tool_args": {"query": "Corebrum mesh computing"}}'

# Submit with custom MCP server
corebrum submit --file task_definitions/mcp/mcp_one_shot_job.yaml \
  --inputs '{"mcp_server_url": "http://your-mcp-server:8080", "tool_name": "get_weather", "tool_args": {"location": "San Francisco"}}'
```

**Example Input:**
```json
{
  "mcp_server_url": "http://localhost:3000",
  "tool_name": "web_search",
  "tool_args": {
    "query": "Corebrum distributed computing",
    "max_results": 5
  }
}
```

**Example Output:**
```json
{
  "status": "success",
  "tool_name": "web_search",
  "result": {
    "results": [
      {"title": "...", "url": "...", "snippet": "..."}
    ]
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 2. MCP Streaming Job (`mcp_streaming_job.yaml`)

A stream-reactive task that continuously processes triggers and calls MCP servers in real-time.

### 3. MCP ROS2 Image Analysis (`mcp_ros2_image_analysis.yaml`)

A streaming MCP job that processes ROS2 camera images through MCP AI tools and publishes analysis results back to ROS2 topics.

**Features:**
- Subscribes to ROS2 `sensor_msgs/Image` topics (CDR-encoded)
- Processes images through MCP AI vision tools
- Publishes analysis results to ROS2 topics
- Supports object detection, scene understanding, OCR, etc.

**Usage:**
```bash
# Submit ROS2 image analysis job
corebrum submit --file task_definitions/mcp/mcp_ros2_image_analysis.yaml \
  --inputs '{"mcp_server_url": "http://localhost:3000"}'

# Monitor analysis results
zenoh sub -k rt/robot1/camera/analysis

# Monitor detections
zenoh sub -k rt/robot1/camera/detections
```

**Input Topics:**
- `rt/robot1/camera/color/image_raw` - ROS2 camera image (CDR-encoded `sensor_msgs/Image`)

**Output Topics:**
- `rt/robot1/camera/analysis` - Image analysis results (JSON)
- `rt/robot1/camera/detections` - Detected object positions (CDR-encoded ROS2 message)

**Example MCP Tool Call:**
```json
{
  "method": "tools/call",
  "params": {
    "name": "analyze_image",
    "arguments": {
      "image": {
        "data": "<base64_encoded_image>",
        "width": 1280,
        "height": 720,
        "encoding": "rgb8"
      },
      "analysis_type": "object_detection",
      "options": {
        "confidence_threshold": 0.5,
        "max_detections": 10
      }
    }
  }
}
```

### 4. MCP ROS2 Sensor Control (`mcp_ros2_sensor_control.yaml`)

A streaming MCP job that processes ROS2 sensor data (odometry, battery, etc.) through MCP AI tools and publishes control commands back to ROS2 topics.

**Features:**
- Subscribes to ROS2 `nav_msgs/Odometry` and battery level topics
- Processes sensor data through MCP AI decision-making tools
- Publishes velocity commands (`geometry_msgs/Twist`) to ROS2 topics
- Supports navigation control, exploration, patrol, etc.

**Usage:**
```bash
# Submit ROS2 sensor control job
corebrum submit --file task_definitions/mcp/mcp_ros2_sensor_control.yaml \
  --inputs '{"mcp_server_url": "http://localhost:3000"}'

# Monitor velocity commands
zenoh sub -k rt/robot1/cmd_vel

# Monitor control status
zenoh sub -k rt/robot1/control/status
```

**Input Topics:**
- `rt/robot1/odom` - ROS2 odometry (CDR-encoded `nav_msgs/Odometry`)
- `rt/robot1/battery/level` - Battery level (JSON)

**Output Topics:**
- `rt/robot1/cmd_vel` - Velocity command (CDR-encoded `geometry_msgs/Twist`)
- `rt/robot1/control/status` - Control status and reasoning (JSON)

**Example MCP Tool Call:**
```json
{
  "method": "tools/call",
  "params": {
    "name": "compute_control_command",
    "arguments": {
      "sensor_data": {
        "odometry": {
          "position": {"x": 1.0, "y": 2.0, "z": 0.0},
          "linear_velocity": {"x": 0.5, "y": 0.0, "z": 0.0}
        },
        "battery": {"level": 0.85}
      },
      "task": "navigation_control",
      "constraints": {
        "max_linear_velocity": 0.5,
        "max_angular_velocity": 1.0,
        "min_battery_level": 0.2
      }
    }
  }
}
```

**Features:**
- Subscribes to Zenoh topics for trigger data
- Calls MCP server on each trigger
- Publishes results back to Zenoh
- Rate-limited to prevent overload
- Runs continuously until cancelled

**Usage:**
```bash
# Submit streaming MCP job
corebrum submit --file task_definitions/mcp/mcp_streaming_job.yaml \
  --inputs '{"mcp_server_url": "http://localhost:3000"}'

# In another terminal, publish trigger data
zenoh pub -k mcp/trigger/data '{"tool_name": "analyze_sensor", "arguments": {"sensor_id": "temp_01", "value": 25.5}}'

# Monitor results
zenoh sub -k mcp/results/processed
```

**Trigger Data Format:**
```json
{
  "tool_name": "process_data",
  "arguments": {
    "data": {...},
    "options": {...}
  }
}
```

**Result Format:**
```json
{
  "status": "success",
  "tool_name": "process_data",
  "result": {...},
  "timestamp": "2024-01-15T10:30:00",
  "trigger_data": {...}
}
```

## MCP Server Setup

### Running an MCP Server

MCP servers typically expose HTTP endpoints that accept JSON-RPC 2.0 requests. Here's a simple example:

**Simple MCP Server (Python):**
```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/', methods=['POST'])
def mcp_handler():
    data = request.json
    method = data.get('method')
    params = data.get('params', {})
    
    if method == 'tools/call':
        tool_name = params.get('name')
        tool_args = params.get('arguments', {})
        
        # Process tool call
        if tool_name == 'web_search':
            result = {"results": [...]}  # Your tool logic
        elif tool_name == 'get_weather':
            result = {"temperature": 72, "condition": "sunny"}
        else:
            return jsonify({
                "jsonrpc": "2.0",
                "id": data.get('id'),
                "error": {"code": -32601, "message": "Method not found"}
            })
        
        return jsonify({
            "jsonrpc": "2.0",
            "id": data.get('id'),
            "result": result
        })
    
    return jsonify({
        "jsonrpc": "2.0",
        "id": data.get('id'),
        "error": {"code": -32600, "message": "Invalid Request"}
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
```

### Using Existing MCP Servers

Many MCP servers are available:
- **Web Search**: Search the web and return results
- **Weather APIs**: Get weather information
- **Database Tools**: Query databases
- **File System**: Read/write files
- **Custom Tools**: Build your own MCP servers

## ROS2 Integration Examples

### ROS2 Image Processing Pipeline

The `mcp_ros2_image_analysis.yaml` example demonstrates a complete ROS2 image processing pipeline:

1. **Subscribe to ROS2 Camera Topic**: Receives CDR-encoded `sensor_msgs/Image` messages
2. **Decode Image**: System automatically decodes CDR to JSON format
3. **Process via MCP**: Sends image to MCP AI vision tool for analysis
4. **Publish Results**: Publishes analysis and detections back to ROS2 topics

**Example Workflow:**
```bash
# 1. Start ROS2 camera node (on robot)
ros2 run realsense_camera realsense_camera_node

# 2. Start zenoh-bridge-ros2dds (bridges ROS2 to Zenoh)
zenoh-bridge-ros2dds

# 3. Submit MCP image analysis job
corebrum submit --file task_definitions/mcp/mcp_ros2_image_analysis.yaml

# 4. Monitor results
zenoh sub -k rt/robot1/camera/analysis
```

### ROS2 Sensor-Based Control Pipeline

The `mcp_ros2_sensor_control.yaml` example demonstrates AI-powered robot control:

1. **Subscribe to Sensor Topics**: Receives odometry and battery data
2. **Process via MCP**: Sends sensor data to MCP AI decision-making tool
3. **Generate Commands**: MCP returns velocity commands based on sensor state
4. **Publish Commands**: Publishes `geometry_msgs/Twist` commands to ROS2

**Example Workflow:**
```bash
# 1. Start ROS2 robot nodes (on robot)
ros2 launch robot_bringup robot.launch.py

# 2. Start zenoh-bridge-ros2dds
zenoh-bridge-ros2dds

# 3. Submit MCP sensor control job
corebrum submit --file task_definitions/mcp/mcp_ros2_sensor_control.yaml

# 4. Monitor velocity commands
zenoh sub -k rt/robot1/cmd_vel
```

## Integration Patterns

### Pattern 1: Sensor Data → MCP → AI Analysis

```bash
# 1. Start streaming MCP job
corebrum submit --file task_definitions/mcp/mcp_streaming_job.yaml

# 2. Publish sensor data (e.g., from ROS2 robot)
zenoh pub -k mcp/trigger/data '{"tool_name": "analyze_image", "arguments": {"image_url": "http://..."}}'

# 3. Get AI analysis results
zenoh sub -k mcp/results/processed
```

### Pattern 2: Periodic MCP Calls

Use `time_interval` trigger for periodic MCP calls:

```yaml
stream_config:
  trigger: "time_interval"
  interval_ms: 60000  # Every minute
```

### Pattern 3: Rate-Limited MCP Processing

Use `rate_limited` trigger to process high-frequency data:

```yaml
stream_config:
  trigger: "rate_limited"
  rate_limit_hz: 10  # Max 10 calls per second
```

## Configuration

### Input Parameters

**One-Shot Job:**
- `mcp_server_url` (string): URL of the MCP server endpoint
- `tool_name` (string): Name of the MCP tool to call
- `tool_args` (object): Arguments to pass to the tool

**Streaming Job:**
- `mcp_server_url` (string, optional): MCP server URL (can be provided via Zenoh)
- `trigger_data` (zenoh): Trigger data from Zenoh topic

### Output Format

Both jobs return structured JSON with:
- `status`: "success" or "error"
- `tool_name`: Name of the tool called
- `result`: Tool execution result
- `timestamp`: ISO timestamp
- `error_*`: Error details (if failed)

## Error Handling

The examples include comprehensive error handling:
- **Network errors**: Connection failures, timeouts
- **JSON errors**: Malformed responses
- **MCP protocol errors**: Invalid JSON-RPC responses
- **Tool errors**: Tool-specific error codes and messages

## Dependencies

**Python Packages:**
- `requests`: HTTP client for MCP server communication
- `zenoh`: Zenoh networking (for streaming job)

**Installation:**
```bash
pip install requests zenoh
```

## Best Practices

### 1. Error Handling
Always check the `status` field in results:
```python
if result["status"] == "error":
    # Handle error
    error_message = result.get("error_message", "Unknown error")
```

### 2. Timeout Configuration
Set appropriate timeouts for MCP calls:
```python
response = requests.post(url, json=data, timeout=30)
```

### 3. Rate Limiting
Use `rate_limit_hz` in streaming jobs to prevent overwhelming MCP servers:
```yaml
stream_config:
  rate_limit_hz: 5  # Max 5 calls per second
```

### 4. Result Caching
Consider caching MCP results for frequently called tools:
```python
# Use Corebrum memory storage for caching
# See task_definitions/memory/ for examples
```

### 5. Security
- Validate MCP server URLs
- Sanitize tool arguments
- Use HTTPS for production MCP servers
- Implement authentication if required

## Troubleshooting

### MCP Server Not Responding
- Check MCP server is running: `curl http://localhost:3000`
- Verify URL is correct
- Check firewall/network settings

### JSON-RPC Errors
- Verify MCP server implements JSON-RPC 2.0
- Check request format matches MCP protocol
- Review error codes in response

### Streaming Job Not Processing
- Check Zenoh topic names match
- Verify trigger data format is correct
- Check rate limiting settings

## ROS2 Message Type Support

The ROS2 MCP examples leverage Corebrum's native ROS2 message type support:

- **CDR Encoding/Decoding**: Automatic conversion between ROS2 binary format and JSON
- **Message Type Detection**: Auto-detection from topic names or explicit specification
- **Type-Safe Outputs**: Outputs are automatically CDR-encoded based on message type

**Supported ROS2 Message Types:**
- `sensor_msgs/Image` - Camera images
- `nav_msgs/Odometry` - Robot odometry
- `geometry_msgs/Twist` - Velocity commands
- `geometry_msgs/Point` - 3D points
- `geometry_msgs/Vector3` - 3D vectors

**Example Input Configuration:**
```yaml
inputs:
  - name: "camera_image"
    type: "zenoh"
    key_expr: "rt/robot1/camera/color/image_raw"
    encoding: "cdr"
    message_type: "sensor_msgs/Image"  # Explicit type specification
```

**Example Output Configuration:**
```yaml
outputs:
  - name: "velocity_command"
    type: "zenoh"
    key_expr: "rt/robot1/cmd_vel"
    encoding: "cdr"
    message_type: "geometry_msgs/Twist"  # Automatically CDR-encoded
```

## Related Examples

- **ROS2 Integration**: See `../ros2/` for more ROS2 sensor data processing examples
- **Memory Storage**: See `../memory/` for caching MCP results
- **Sequential Pipelines**: See `../sequential/` for multi-step MCP workflows

## Further Reading

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [Corebrum Streaming Tasks](../ros2/README.md#stream-reactive-tasks)

