# Corebrum Examples

This directory contains examples and demonstrations for the Corebrum decentralized mesh computing platform.

## Structure

- `src/` - Example Rust applications demonstrating various Corebrum features
- `task_definitions/` - Sample task definition files in various formats (JSON, YAML)
- `wasm_factorial/` - WebAssembly example project
- `wasm_factorial_url/` - WebAssembly example with URL-based loading

## Running Examples

To run any of the example binaries:

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

## WebAssembly Examples

The `wasm_factorial/` and `wasm_factorial_url/` directories contain WebAssembly examples that demonstrate how to run WASM tasks in the Corebrum environment.
