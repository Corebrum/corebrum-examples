# Corebrum Task Definitions

This directory contains example task definitions organized by type and use case. Each subdirectory focuses on a specific integration pattern or technology.

## Directory Structure

### 📁 [ros2/](ros2/)
**ROS2 Integration Examples**
- Real-time robot control and computer vision
- Stream-reactive tasks for robotics applications
- Zenoh-based ROS2 topic integration

**Examples:**
- `object_detection.yaml` - YOLO-based object detection
- `follow_person.yaml` - Autonomous person following
- `multi_robot_formation.yaml` - Multi-robot coordination

### 📁 [docker/](docker/)
**Docker Container Examples**
- Containerized applications with isolated environments
- Complex dependency management
- Reproducible execution environments

**Examples:**
- `docker_task.yaml` - Basic Docker task
- `docker_with_dependencies.yaml` - Dependency management
- `factorial_docker.yaml` - Mathematical computation in containers

### 📁 [python/](python/)
**Python Integration Examples**
- Direct Python execution on workers
- Embedded code and external sources
- Mathematical and data processing tasks

**Examples:**
- `factorial_task.yaml` - Basic factorial computation
- `factorial_from_url.yaml` - Code from remote URL
- `fibonacci_task.json` - Fibonacci sequence generation
- `python_with_dependencies.yaml` - Package dependency management

### 📁 [wasm/](wasm/)
**WebAssembly Examples**
- High-performance compiled code execution
- Cross-language compatibility (Rust, C/C++, Go)
- Sandboxed execution environment

**Examples:**
- `factorial_wasm.yaml` - WASM-based factorial
- `factorial_wasm_url.yaml` - Remote WASM module loading

### 📁 [sequential/](sequential/)
**Sequential Pipeline Examples**
- Multi-stage data processing workflows
- AI/ML pipeline orchestration
- Complex task chaining and conditional execution

**Examples:**
- `sequential_ai_pipeline.yaml` - Complete AI/ML pipeline
- `sequential_data_transform.yaml` - Data transformation pipeline
- `sequential_pipeline.yaml` - Basic task chaining

### 📁 [general/](general/)
**General Task Examples**
- Basic testing and validation tasks
- External code source demonstrations
- Multi-dependency and complex configuration examples

**Examples:**
- `simple_test.yaml` - Basic system test
- `git_repo_task.json` - Git repository integration
- `mixed_sources_demo.yaml` - Multiple code sources
- `multi_dependency_task.yaml` - Complex dependencies

## Getting Started

### Quick Start
1. Choose a category that matches your use case
2. Read the README in that directory for detailed information
3. Copy and modify an example to fit your needs
4. Submit the task using the Corebrum CLI

### Basic Usage
```bash
# Submit a task definition
corebrum submit --file task_definitions/ros2/object_detection.yaml

# Monitor task execution
mesh-streams

# View task results
mesh-results <task-id>
```

### Task Definition Formats (updated I/O model)

Corebrum supports multiple task definition formats:

#### YAML Format (Recommended)
```yaml
task_definition:
  name: "example-task"
  description: "One-shot using embedded inputs, publishing to Zenoh"
  inputs:
    - name: "value"
      type: "number"
  outputs:
    - name: "result"
      type: "zenoh"
      key: "corebrum/examples/example/result"
  compute_logic:
    type: "expression"
    language: "python"
    timeout_seconds: 30
    code: |
      import json
      # Use the injected 'inputs' object directly
      result = {"doubled": inputs.get("value", 1) * 2}
      print(json.dumps(result))
```

#### JSON Format
```json
{
  "task_definition": {
    "name": "example-task",
    "compute_logic": {
      "type": "python",
      "code": "def main(inputs):\n    return {'result': inputs['value'] * 2}",
      "inputs": [
        {"name": "value", "type": "integer"}
      ],
      "outputs": [
        {"name": "result", "type": "integer"}
      ]
    }
  }
}
```
### Inputs/Outputs and Zenoh

- One-shot tasks
  - Inputs are injected as a Python variable named `inputs` (or language equivalent) containing a single JSON object.
  - Print a single JSON line to STDOUT. If `outputs` include a Zenoh entry with a `key`, Corebrum publishes this JSON there.

- Stream tasks
  - Stream-reactive tasks use Zenoh subscriptions/publications as configured in the task; see directory examples. Experimental features may change.

See examples:
- `python/factorial_stdin_stdout.yaml`
- `python/factorial_from_url.yaml`

## Task Types

### Python Tasks
- **Best for**: Quick prototyping, data processing, mathematical computations
- **Pros**: Easy to write and debug, rich ecosystem
- **Cons**: Slower than compiled languages, dependency management

### Docker Tasks
- **Best for**: Complex applications, specific environments, dependency isolation
- **Pros**: Reproducible, isolated, supports any language
- **Cons**: Higher overhead, requires Docker on workers

### WASM Tasks
- **Best for**: High-performance computations, cross-language compatibility
- **Pros**: Near-native performance, secure, portable
- **Cons**: Requires compilation, limited system access

### Sequential Pipelines
- **Best for**: Complex workflows, multi-stage processing, AI/ML pipelines
- **Pros**: Flexible, composable, supports conditional logic
- **Cons**: More complex to design and debug

## Monitoring and Debugging

### Corebrum Commands
```bash
# List active tasks
mesh-streams

# View task status
mesh-status <task-id>

# Get task results
mesh-results <task-id>

# Cancel a task
mesh-cancel <task-id>

# List available topics
mesh-topics

# Monitor network
netstat
```

### Logging and Debugging
- Check worker logs for execution details
- Use `mesh-topics` to monitor data flow
- Review task definitions for configuration issues
- Test with simple examples before complex workflows

## Best Practices

### Task Design
- **Single responsibility**: Each task should do one thing well
- **Clear interfaces**: Define explicit inputs and outputs
- **Error handling**: Handle failures gracefully
- **Resource efficiency**: Optimize for memory and CPU usage

### Development Workflow
- **Start simple**: Begin with basic examples
- **Iterate quickly**: Use Python tasks for rapid prototyping
- **Test thoroughly**: Validate with different input scenarios
- **Monitor performance**: Use built-in monitoring tools

### Security Considerations
- **Input validation**: Always validate and sanitize inputs
- **Resource limits**: Set appropriate memory and CPU limits
- **Access control**: Use appropriate permissions and isolation
- **Code review**: Review task definitions before deployment

## Contributing

### Adding New Examples
1. Choose the appropriate directory for your example
2. Follow the naming convention: `descriptive_name.yaml`
3. Include comprehensive documentation
4. Test thoroughly before submitting
5. Update the relevant README with your example

### Example Requirements
- **Clear purpose**: Each example should demonstrate a specific concept
- **Well documented**: Include usage instructions and explanations
- **Tested**: Verify that examples work as expected
- **Minimal**: Keep examples focused and easy to understand

## Support

### Documentation
- **Main README**: See the root README for general Corebrum information
- **Category READMEs**: Each subdirectory has detailed documentation
- **Code comments**: Examples include inline documentation

### Getting Help
- **CLI help**: Use `corebrum --help` for command-line help
- **Mesh commands**: Use `help <command>` in CMOS for detailed help
- **Examples**: Study existing examples for patterns and best practices

### Troubleshooting
- **Common issues**: Check category-specific READMEs for troubleshooting
- **Logs**: Review worker and task logs for error details
- **Network**: Use `mesh-topics` and `netstat` to diagnose connectivity issues
