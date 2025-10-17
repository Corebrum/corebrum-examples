# Corebrum Examples

This directory contains examples and demonstrations for the Corebrum decentralized mesh computing platform.

## Structure

- `src/` - Example Rust applications demonstrating various Corebrum features
- `task_definitions/` - Sample task definition files in various formats (JSON, YAML)
- `wasm_factorial/` - WebAssembly example project
- `wasm_factorial_url/` - WebAssembly example with URL-based loading

## Running Examples

### Using the Corebrum CLI (Recommended)

The easiest way to run these examples is using the [Corebrum CLI](../corebrum-cli):

```bash
# Start the Corebrum daemon first
cd ../corebrum-rust
cargo run daemon 3

# In another terminal, use the CLI to submit tasks
cd ../corebrum-cli
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/factorial_task.yaml --input '{"number": 10}'
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/fibonacci_task.json --input '{"terms": 15}'
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/factorial_wasm.yaml --input '{"number": 12}'
```

### Running Example Binaries Directly

To run any of the example binaries directly:

```bash
cargo run --bin <example_name>
```

Available examples:
- `simple_user_demo` - Basic user demonstration
- `simple_user_zenoh_demo` - User demo with Zenoh integration
- `simple_zenoh_demo` - Basic Zenoh demonstration
- `simple_zenoh_demo_fixed` - Fixed version of Zenoh demo
- `fixed_user_demo` - Fixed user demonstration
- `fixed_zenoh_demo` - Fixed Zenoh demonstration
- `user_demo` - Advanced user demonstration
- `working_user_demo` - Working user demonstration
- `working_user_zenoh_demo` - Working user demo with Zenoh

## Task Definitions

The `task_definitions/` directory contains various sample task configurations that can be used to test the Corebrum platform.

### Using Task Definitions with the CLI

All task definitions in this repository can be used with the [Corebrum CLI](../corebrum-cli):

```bash
# Python factorial task
cargo run submit-and-wait --file task_definitions/factorial_task.yaml --input '{"number": 10}'

# Python fibonacci task
cargo run submit-and-wait --file task_definitions/fibonacci_task.json --input '{"terms": 15}'

# WebAssembly factorial task
cargo run submit-and-wait --file task_definitions/factorial_wasm.yaml --input '{"number": 12}'

# Docker task
cargo run submit-and-wait --file task_definitions/docker_task.yaml --input '{"number": 8}'

# Task with external code source (GitHub Gist)
cargo run submit-and-wait --file task_definitions/factorial_from_url.yaml --input '{"number": 5}'

# Task with dependencies (requires specific worker capabilities)
cargo run submit-and-wait --file task_definitions/python_with_dependencies.yaml --input '{"number": 8}'
cargo run submit-and-wait --file task_definitions/docker_with_dependencies.yaml --input '{"number": 6}'
cargo run submit-and-wait --file task_definitions/multi_dependency_task.yaml --input '{"text": "Hello Qwen!"}'
```

### Available Task Definition Files

| File | Type | Language | Code Source | Dependencies | Description |
|------|------|----------|-------------|--------------|-------------|
| `factorial_task.yaml` | expression | Python | Embedded | None | Basic factorial computation |
| `factorial_from_url.yaml` | expression | Python | GitHub Gist URL | None | Factorial from external URL |
| `factorial_wasm.yaml` | wasm | Rust | Local | None | Local WASM factorial module |
| `factorial_wasm_url.yaml` | wasm | Rust | URL | None | WASM factorial from external URL |
| `factorial_docker.yaml` | docker | Python | Docker | None | Docker containerized factorial |
| `fibonacci_task.json` | expression | Python | Embedded | None | Basic Fibonacci sequence |
| `fibonacci_from_gist.json` | expression | Python | GitHub Gist | None | Fibonacci from GitHub Gist |
| `docker_task.yaml` | docker | Python | Docker | None | Generic Docker task example |
| `git_repo_task.json` | expression | Python | Git Repository | None | Task from Git repository |
| `mixed_sources_demo.yaml` | expression | Python | Multiple | None | Demo with various code sources |
| `python_with_dependencies.yaml` | expression | Python | Embedded | python | Python task with dependency requirement |
| `docker_with_dependencies.yaml` | docker | Python | Docker | docker | Docker task with dependency requirement |
| `multi_dependency_task.yaml` | expression | Python | Embedded | python,qwen | Multi-capability task example |

## Task Dependencies

The examples include tasks that demonstrate the dependency system:

### How Dependencies Work

1. **Worker Capabilities**: Workers are configured with specific capabilities (e.g., `python`, `docker`, `qwen`)
2. **Task Requirements**: Tasks can specify dependencies they need
3. **Automatic Matching**: Only workers with matching capabilities will claim tasks
4. **Flexible Configuration**: Workers can have multiple capabilities

### Example Usage

```bash
# Start daemon with workers having different capabilities
cd ../corebrum-rust
cargo run daemon 3 --capabilities "python,docker" "python,qwen" "docker,wasm"

# In another terminal, submit tasks with dependencies
cd ../corebrum-cli

# This task will only be claimed by workers with 'python' capability
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/python_with_dependencies.yaml --input '{"number": 8}'

# This task will only be claimed by workers with 'docker' capability
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/docker_with_dependencies.yaml --input '{"number": 6}'

# This task will only be claimed by workers with BOTH 'python' AND 'qwen' capabilities
cargo run submit-and-wait --file ../corebrum-examples/task_definitions/multi_dependency_task.yaml --input '{"text": "Hello Qwen!"}'
```

### Available Dependencies

- **python**: Required for Python script execution
- **docker**: Required for Docker containerized tasks
- **qwen**: Required for Qwen model inference
- **wasm**: Required for WebAssembly module execution
- **javascript**: Required for JavaScript/Node.js execution

## WebAssembly Examples

The `wasm_factorial/` and `wasm_factorial_url/` directories contain WebAssembly examples that demonstrate how to run WASM tasks in the Corebrum environment.
