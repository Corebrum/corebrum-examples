# WebAssembly (WASM) Integration Examples

This directory contains examples of tasks that run WebAssembly modules on the Corebrum mesh.

## Overview

WebAssembly (WASM) tasks allow you to run compiled code from various languages (Rust, C/C++, Go, etc.) in a sandboxed environment. This approach provides:

- **Performance**: Near-native execution speed
- **Security**: Sandboxed execution environment
- **Language flexibility**: Use any language that compiles to WASM
- **Portability**: Run the same binary across different architectures

## Examples

### 1. Factorial WASM (`factorial_wasm.yaml`)

Computes factorial using a WebAssembly module.

**Features:**
- Embedded WASM binary in the task definition
- Demonstrates basic WASM execution
- Shows parameter passing to WASM functions

**Usage:**
```bash
corebrum submit --file task_definitions/wasm/factorial_wasm.yaml
```

### 2. Factorial WASM from URL (`factorial_wasm_url.yaml`)

Loads a WASM module from a remote URL and executes it.

**Features:**
- Fetches WASM binary from external sources
- Demonstrates dynamic module loading
- Shows how to handle remote WASM dependencies

**Usage:**
```bash
corebrum submit --file task_definitions/wasm/factorial_wasm_url.yaml
```

## WASM Task Configuration

### Basic WASM Task Structure

```yaml
task_definition:
  name: "wasm-example"
  compute_logic:
    type: "wasm"
    wasm_binary: "base64-encoded-wasm-binary"
    function_name: "main"
    inputs:
      - name: "number"
        type: "integer"
    outputs:
      - name: "result"
        type: "integer"
```

### WASM with External Binary

```yaml
task_definition:
  name: "wasm-url-example"
  compute_logic:
    type: "wasm"
    wasm_source:
      type: "url"
      url: "https://example.com/module.wasm"
    function_name: "compute"
    inputs:
      - name: "data"
        type: "string"
    outputs:
      - name: "result"
        type: "string"
```

## Key Features

### WASM Runtime
- **Wasmtime**: High-performance WASM runtime
- **Memory management**: Automatic memory allocation and cleanup
- **Function calls**: Direct function invocation from host to WASM

### Binary Sources
- **Embedded binary**: Include WASM binary directly in task definition
- **URL sources**: Load WASM modules from remote URLs
- **File references**: Point to local or remote WASM files

### Type System
- **Strong typing**: WASM functions have strict type signatures
- **JSON serialization**: Automatic conversion between JSON and WASM types
- **Error handling**: Graceful error reporting from WASM modules

## Development Workflow

### Building WASM Modules

#### Rust Example
```rust
// Cargo.toml
[package]
name = "factorial"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"

// src/lib.rs
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn factorial(n: u32) -> u32 {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}
```

Build with:
```bash
cargo build --target wasm32-unknown-unknown --release
wasm-bindgen target/wasm32-unknown-unknown/release/factorial.wasm --out-dir pkg
```

#### C/C++ Example
```c
// factorial.c
int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}
```

Build with:
```bash
emcc factorial.c -o factorial.wasm -s EXPORTED_FUNCTIONS="['_factorial']"
```

### Testing WASM Modules

```bash
# Test locally with Node.js
node -e "
const fs = require('fs');
const wasm = fs.readFileSync('factorial.wasm');
const wasmModule = new WebAssembly.Module(wasm);
const wasmInstance = new WebAssembly.Instance(wasmModule);
console.log(wasmInstance.exports.factorial(5));
"
```

## Best Practices

### Performance Optimization
- Use `--release` builds for production
- Minimize memory allocations in hot paths
- Consider using `wasm-opt` for additional optimization

### Security Considerations
- Validate all inputs before passing to WASM
- Use appropriate memory limits
- Avoid exposing sensitive host functions

### Error Handling
- Implement proper error handling in WASM modules
- Use meaningful error messages
- Handle edge cases gracefully

## Dependencies

WASM tasks require a WASM runtime on worker nodes:

```bash
# Install Wasmtime (recommended)
curl https://wasmtime.dev/install.sh -sSf | bash

# Or install via package manager
# Ubuntu/Debian
sudo apt-get install wasmtime

# macOS
brew install wasmtime
```

## Troubleshooting

### Module Loading Issues
- Verify WASM binary is valid and not corrupted
- Check that the function name exists in the module
- Ensure the WASM module exports the expected functions

### Runtime Errors
- Check input data types and formats
- Validate that all required inputs are provided
- Review error messages in task logs

### Performance Issues
- Profile WASM execution to identify bottlenecks
- Consider optimizing the WASM module itself
- Check for memory leaks in long-running tasks

## Related Examples

- **Rust source code**: See `../../wasm_factorial/` for complete Rust WASM project
- **Python tasks**: See `../python/` for Python-based computations
- **Docker tasks**: See `../docker/` for containerized applications
- **Sequential pipelines**: See `../sequential/` for multi-step WASM workflows
