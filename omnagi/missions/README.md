# LLM Mission Examples

This directory contains example scripts demonstrating how to use Omnagi with various LLM providers.

## Quick Start - Local Testing with Qwen

The easiest way to test Omnagi's LLM integration is using local Qwen models via Ollama:

### Prerequisites

1. **Start Omnagi:**
   ```bash
   cargo run
   ```

2. **Start Corebrum (in another terminal):**
   ```bash
   corebrum daemon --worker-count 2
   ```

3. **Start Ollama (in another terminal):**
   ```bash
   ollama serve
   ```

4. **Verify Ollama models:**
   ```bash
   ollama list
   ```
   You should see `qwen2.5vl:3b` or similar Qwen models.

### Run Local Test Script

```bash
chmod +x examples/missions/llm_mission_local.sh
./examples/missions/llm_mission_local.sh
```

This script will:
- ✅ Check prerequisites (Omnagi, Corebrum, Ollama)
- ✅ List available models
- ✅ Test multiple prompt types
- ✅ Show usage statistics
- ✅ Provide troubleshooting tips

## Available Scripts

### `llm_mission_local.sh` - Local-Only Testing ⭐ Recommended for First Test

**Best for:** Testing with local Qwen models via Ollama

```bash
./examples/missions/llm_mission_local.sh
```

**Features:**
- Prerequisite checks
- Multiple test scenarios
- Clear error messages
- Usage statistics

### `llm_mission_example.sh` - Multi-Provider Demo

**Best for:** Testing with multiple providers (OpenAI, Anthropic, Local)

```bash
./examples/missions/llm_mission_example.sh
```

**Requirements:**
- Set `OPENAI_API_KEY` for OpenAI tests
- Set `ANTHROPIC_API_KEY` for Anthropic tests
- Corebrum + Ollama for local tests

### `llm_mission_advanced.sh` - Multi-Step Reasoning

**Best for:** Complex reasoning workflows

```bash
./examples/missions/llm_mission_advanced.sh
```

**Features:**
- Multi-step LLM chaining
- Automatic fallback to local provider
- Trace creation
- Async task submission

## Troubleshooting

### "Provider not found" Error

- Check available providers: `curl http://localhost:8123/api/llm/providers`
- For local provider, ensure Corebrum is running

### "Failed to connect to Ollama" Error

- Start Ollama: `ollama serve`
- Verify it's running: `curl http://localhost:11434/api/tags`
- Check model is installed: `ollama list`

### "Corebrum API error" or Task Hangs

- Ensure Corebrum daemon is running: `corebrum daemon --worker-count 2`
- Check Corebrum REST API: `curl http://localhost:6502/api/jobs`
- Verify workers are available

### Script Returns "null" or Empty Response

- Check Omnagi logs for errors
- Verify the identity was created successfully
- Ensure the prompt is being passed correctly
- Check Corebrum task logs

## Model Configuration

### Using Different Qwen Models

If you have other Qwen models installed, you can use them:

```bash
# List available models
ollama list

# Use a specific model in the script
# Change the "model" parameter to match your installed model
# Examples: "qwen2.5vl:3b", "llava:7b", etc.
```

### Pulling New Models

```bash
# Pull a Qwen model
ollama pull qwen2.5vl:3b

# Or pull other models
ollama pull llava:7b
```

## Example API Calls

### Direct API Test

```bash
# First, create an identity
KEY_ID=$(curl -s -X POST http://localhost:8123/api/identity \
  -H "Content-Type: application/json" \
  -d '{}' | jq -r '.key_id')

# Test local LLM
curl -X POST http://localhost:8123/api/llm/complete \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"What is cognitive identity?\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.7
  }" | jq '.'
```

## See Also

- `TESTING.md` - Comprehensive testing guide
- `examples/README.md` - Detailed setup instructions
- `docs/api.md` - API documentation

