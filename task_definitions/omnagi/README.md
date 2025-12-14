# Omnagi Streaming Qwen LLM Service

This directory contains the streaming Qwen LLM service for Omnagi, which enables fast local LLM responses in the web chat UI without spinning up a new Corebrum job for each request.

## Overview

The streaming Qwen LLM service runs continuously on Corebrum and handles multiple concurrent LLM requests via Zenoh topics. This eliminates the overhead of job submission and initialization, making local LLM responses significantly faster.

## Architecture

### Topic Structure

- **Request Topic**: `omnagi/llm/requests` (single topic, service subscribes once)
- **Response Topics**: `omnagi/llm/responses/{task_id}` (per-task topics for concurrent requests)

### Request Format

Requests published to `omnagi/llm/requests` should be JSON:

```json
{
  "task_id": "uuid-here",
  "prompt": "Your question or prompt here",
  "model": "qwen2.5vl:3b",
  "temperature": 0.7,
  "max_tokens": 512
}
```

### Response Format

Responses are published to `omnagi/llm/responses/{task_id}`:

**Success Response:**
```json
{
  "task_id": "uuid-here",
  "text": "Response text from the LLM",
  "model": "qwen2.5vl:3b",
  "provider": "ollama",
  "status": "success",
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  },
  "timestamp": "2025-12-14T10:30:00"
}
```

**Error Response:**
```json
{
  "task_id": "uuid-here",
  "error": "Error message here",
  "status": "failed",
  "provider": "ollama",
  "timestamp": "2025-12-14T10:30:00"
}
```

## Prerequisites

1. **Ollama**: Must be running on `localhost:11434` with Qwen models installed
2. **Corebrum**: Must be running with Zenoh router
3. **Python Capability**: Corebrum worker must have `python` capability
4. **Omnagi Capability**: Corebrum worker must have `omnagi` capability (optional, for identification)

## Installation

### 1. Submit the Streaming Service to Corebrum

```bash
corebrum submit \
  --file task_definitions/omnagi/qwen_llm_streaming.yaml \
  --capabilities python \
  --capabilities omnagi
```

### 2. Verify Service is Running

Check Corebrum task status or monitor Zenoh topics:

```bash
# Monitor request topic (should see requests when using chat UI)
zenoh sub -k omnagi/llm/requests

# Monitor response topics (should see responses)
zenoh sub -k omnagi/llm/responses/**
```

## Usage

Once the service is running, Omnagi's web chat UI will automatically use it for local LLM requests. The service:

1. Listens for requests on `omnagi/llm/requests`
2. Processes each request using Ollama Qwen API
3. Publishes responses to `omnagi/llm/responses/{task_id}`
4. Handles multiple concurrent requests simultaneously

## Configuration

### Default Model

The default model can be configured when submitting the task:

```bash
corebrum submit \
  --file task_definitions/omnagi/qwen_llm_streaming.yaml \
  --inputs '{"model": "qwen2.5:7b"}' \
  --capabilities python \
  --capabilities omnagi
```

### Ollama URL

The service connects to Ollama at `http://localhost:11434/api/chat` by default. To use a different Ollama instance, modify the `ollama_url` variable in the Python code.

## Troubleshooting

### Service Not Responding

1. **Check Ollama is running:**
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. **Check Zenoh connection:**
   ```bash
   zenoh sub -k omnagi/llm/requests
   ```

3. **Check Corebrum task status:**
   ```bash
   corebrum status <task_id>
   ```

### Slow Responses

- Ensure Ollama has the model loaded: `ollama pull qwen2.5vl:3b`
- Check Corebrum worker resources (CPU, memory)
- Verify Zenoh network latency

### Multiple Concurrent Requests Not Working

- Ensure the service is running in `stream_reactive` mode
- Check that Zenoh topics are properly configured
- Verify task_id uniqueness for each request

## Fallback Behavior

If the streaming service is not available, Omnagi will automatically fall back to the traditional REST API submission method (slower but functional).

## Example: Manual Testing

You can test the service manually using Zenoh CLI:

```bash
# Terminal 1: Subscribe to responses
zenoh sub -k omnagi/llm/responses/**

# Terminal 2: Publish a request
zenoh pub -k omnagi/llm/requests '{
  "task_id": "test-123",
  "prompt": "What is 2+2?",
  "model": "qwen2.5vl:3b",
  "temperature": 0.7,
  "max_tokens": 100
}'

# Terminal 1 should show the response
```

## Related Files

- `qwen_llm_streaming.yaml` - Corebrum task definition
- `../../omnagi/src/llm/local.rs` - Omnagi local LLM provider implementation
- `../../omnagi/examples/corebrum_workers/qwen2_5_inference.py` - Original Qwen inference code

