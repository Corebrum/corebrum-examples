# Python Integration Examples

This directory contains examples of tasks that run Python code directly on Corebrum workers. One-shot Python tasks receive inputs via an injected `inputs` dict; print a single JSON line to STDOUT for results.

## Overview

Python tasks allow you to run Python scripts and computations directly on worker nodes without containerization. This approach is ideal for:

- **Quick prototyping**: Fast iteration and testing
- **Simple computations**: Mathematical calculations and data processing
- **Lightweight tasks**: Tasks that don't require complex dependencies
- **Development**: Easy debugging and development workflows

## Examples

### 1. Basic Factorial (`factorial_task.yaml`)

A simple factorial calculation using embedded Python code.

**Features:**
- Embedded Python code in the task definition
- Demonstrates basic input/output handling
- Shows parameter passing to Python functions

**Usage:**
```bash
corebrum submit --file task_definitions/python/factorial_task.yaml
```

### 2. Factorial from URL (`factorial_from_url.yaml`)

Loads Python code from a remote URL and executes it.

**Features:**
- Fetches code from external sources
- Demonstrates dynamic code loading
- Shows how to handle remote dependencies

**Usage:**
```bash
corebrum submit --file task_definitions/python/factorial_from_url.yaml
```

### 3. Fibonacci Task (`fibonacci_task.json`)

Computes Fibonacci numbers using a JSON task definition.

**Features:**
- JSON-based task definition
- Demonstrates different task definition formats
- Shows mathematical computation patterns

**Usage:**
```bash
corebrum submit --file task_definitions/python/fibonacci_task.json
```

### 4. Fibonacci from Gist (`fibonacci_from_gist.json`)

Loads Fibonacci computation code from a GitHub Gist.

**Features:**
- Code stored in version control
- Demonstrates GitHub Gist integration
- Shows external code source management

**Usage:**
```bash
corebrum submit --file task_definitions/python/fibonacci_from_gist.json
```

### 5. Python with Dependencies (`python_with_dependencies.yaml`)

Shows how to handle Python package dependencies in tasks.

**Features:**
- Demonstrates dependency management
- Shows how to install packages at runtime
- Handles complex Python environments

**Usage:**
```bash
corebrum submit --file task_definitions/python/python_with_dependencies.yaml
```

## Python Task Configuration

### Basic Python Task Structure

```yaml
task_definition:
  name: "python-example"
  compute_logic:
    type: "python"
    code: |
      def main(inputs):
          result = inputs['number'] * 2
          return {'doubled': result}
    inputs:
      - name: "number"
        type: "integer"
    outputs:
      - name: "doubled"
        type: "integer"
```

### Python with External Code

```yaml
task_definition:
  name: "python-url-example"
  compute_logic:
    type: "python"
    code_source:
      type: "url"
      url: "https://example.com/script.py"
    inputs:
      - name: "data"
        type: "string"
    outputs:
      - name: "result"
        type: "string"
```

### Python with Dependencies

```yaml
task_definition:
  name: "python-deps-example"
  compute_logic:
    type: "python"
    dependencies:
      - "numpy"
      - "pandas"
      - "requests"
    code: |
      import numpy as np
      import pandas as pd
      
      def main(inputs):
          data = np.array(inputs['numbers'])
          df = pd.DataFrame({'values': data})
          return {'summary': df.describe().to_dict()}
```

## Key Features

### Code Sources
- **Embedded code**: Write Python directly in the task definition
- **URL sources**: Load code from remote URLs
- **GitHub Gists**: Use version-controlled code snippets
- **File references**: Point to local or remote Python files

### Dependency Management
- **Package installation**: Automatically install required packages
- **Version pinning**: Specify exact package versions
- **Virtual environments**: Isolate dependencies per task

### Input/Output Handling
- **Type safety**: Strongly typed input/output parameters
- **JSON serialization**: Automatic data serialization
- **Error handling**: Graceful error reporting and handling

## Best Practices

### Code Organization
- Keep Python code focused and single-purpose
- Use clear function names and documentation
- Handle errors gracefully with try/catch blocks

### Performance Considerations
- Minimize package imports to reduce startup time
- Use efficient data structures and algorithms
- Consider caching for repeated computations

### Security
- Validate all inputs before processing
- Avoid executing arbitrary code from untrusted sources
- Use sandboxed execution environments when possible

## Dependencies

Python tasks require Python 3.7+ on worker nodes. Common packages are automatically available:

```bash
# Core packages (usually pre-installed)
python3
pip3

# Common scientific packages
numpy
pandas
requests
matplotlib
```

## Troubleshooting

### Import Errors
- Ensure required packages are listed in dependencies
- Check that package names are correct
- Verify Python version compatibility

### Runtime Errors
- Check input data types and formats
- Validate that all required inputs are provided
- Review error messages in task logs

### Performance Issues
- Profile code to identify bottlenecks
- Consider using more efficient algorithms
- Check for memory leaks in long-running tasks

## Related Examples

- **Docker tasks**: See `../docker/` for containerized Python examples
- **Sequential pipelines**: See `../sequential/` for multi-step Python workflows
- **WASM tasks**: See `../wasm/` for WebAssembly-based computations
- **ROS2 integration**: See `../ros2/` for robot control with Python
