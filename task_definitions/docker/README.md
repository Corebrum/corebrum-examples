# Docker Integration Examples

This directory contains examples of tasks that run inside Docker containers on the Corebrum mesh.

## Overview

Docker tasks allow you to run containerized applications with specific dependencies, environments, and configurations. This is particularly useful for:

- **Isolated environments**: Run code with specific system dependencies
- **Reproducible builds**: Ensure consistent execution across different workers
- **Complex dependencies**: Package applications with their entire runtime environment
- **Security**: Isolate potentially unsafe code in containers

## Examples

### 1. Basic Docker Task (`docker_task.yaml`)

A simple example of running a Python script inside a Docker container.

**Features:**
- Uses a standard Python Docker image
- Runs a simple computation task
- Demonstrates basic Docker task configuration

**Usage:**
```bash
corebrum submit --file task_definitions/docker/docker_task.yaml
```

### 2. Docker with Dependencies (`docker_with_dependencies.yaml`)

Shows how to handle task dependencies when using Docker containers.

**Features:**
- Demonstrates dependency management in Docker tasks
- Shows how to chain Docker tasks together
- Handles input/output between dependent tasks

**Usage:**
```bash
corebrum submit --file task_definitions/docker/docker_with_dependencies.yaml
```

### 3. Factorial Docker (`factorial_docker.yaml`)

Computes factorial using a Docker container with specific Python dependencies.

**Features:**
- Uses a custom Docker image with math libraries
- Demonstrates parameter passing to Docker containers
- Shows output handling from containerized tasks

**Usage:**
```bash
corebrum submit --file task_definitions/docker/factorial_docker.yaml
```

## Docker Configuration

### Basic Docker Task Structure

```yaml
task_definition:
  name: "docker-example"
  compute_logic:
    type: "docker"
    docker_image: "python:3.9"
    command: ["python", "-c", "print('Hello from Docker!')"]
    inputs: []
    outputs: []
```

### Advanced Docker Configuration

```yaml
task_definition:
  name: "advanced-docker"
  compute_logic:
    type: "docker"
    docker_image: "custom-image:latest"
    command: ["python", "main.py"]
    environment:
      - "ENV_VAR=value"
    volumes:
      - "/host/path:/container/path"
    working_dir: "/app"
    inputs:
      - name: "input_data"
        type: "string"
    outputs:
      - name: "result"
        type: "string"
```

## Key Features

### Docker Image Management
- **Pre-built images**: Use existing images from Docker Hub
- **Custom images**: Build and use your own specialized images
- **Image caching**: Workers cache frequently used images for faster startup

### Environment Configuration
- **Environment variables**: Pass configuration to containers
- **Volume mounts**: Access host filesystem from containers
- **Working directory**: Set the execution context inside containers

### Resource Management
- **Memory limits**: Control container memory usage
- **CPU limits**: Limit CPU consumption
- **Network access**: Configure container networking

## Best Practices

### Image Selection
- Use official images when possible for security and reliability
- Choose minimal base images to reduce startup time
- Pin specific image versions for reproducible builds

### Security Considerations
- Run containers with non-root users when possible
- Limit container capabilities and permissions
- Use read-only filesystems where appropriate

### Performance Optimization
- Pre-pull commonly used images on workers
- Use multi-stage builds to reduce image size
- Cache dependencies in Docker layers

## Troubleshooting

### Container Startup Issues
- Verify the Docker image exists and is accessible
- Check that the command and arguments are correct
- Ensure the worker has Docker daemon running

### Permission Problems
- Check file permissions for volume mounts
- Verify container user permissions
- Ensure proper SELinux/AppArmor configuration

### Resource Constraints
- Monitor container memory and CPU usage
- Adjust resource limits if containers are being killed
- Consider using smaller base images

## Dependencies

Ensure Docker is installed and running on worker nodes:

```bash
# Install Docker (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

## Related Examples

- **Python tasks**: See `../python/` for non-containerized Python examples
- **Sequential pipelines**: See `../sequential/` for multi-step workflows
- **WASM tasks**: See `../wasm/` for WebAssembly-based tasks
