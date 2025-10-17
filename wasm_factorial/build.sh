#!/bin/bash

# Build script for WASM factorial module

echo "🔨 Building WASM factorial module..."

# Check if wasm-pack is installed
if ! command -v wasm-pack &> /dev/null; then
    echo "❌ wasm-pack is not installed. Installing..."
    curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
fi

# Build the WASM module
echo "📦 Compiling Rust to WebAssembly..."
wasm-pack build --target web --out-dir pkg

if [ $? -eq 0 ]; then
    echo "✅ WASM module built successfully!"
    echo "📁 Output files:"
    ls -la pkg/
else
    echo "❌ Failed to build WASM module"
    exit 1
fi

echo "🎉 WASM factorial module is ready!"
