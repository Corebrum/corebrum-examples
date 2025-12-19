#!/bin/bash
# Local LLM Mission Test - Qwen via Ollama
# This script tests Corebrum's local LLM integration using Qwen models via Ollama

set +e  # Don't exit on errors, we want to see what happens

API_URL="http://localhost:6502"

echo "🔬 Local LLM Mission Test (Qwen via Ollama)"
echo "==========================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."
echo ""

# Check if Corebrum is running
if ! curl -s "$API_URL/api/identity" > /dev/null 2>&1; then
    echo "❌ Error: Corebrum service is not running on $API_URL"
    echo "   Start it with: cargo run --bin corebrum -- web"
    exit 1
fi
echo "✅ Corebrum service is running"

# Check if Ollama is running
if ! curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "❌ Error: Ollama is not running on http://localhost:11434"
    echo "   Start it with: ollama serve"
    exit 1
fi
echo "✅ Ollama service is running"

# List available Ollama models
echo ""
echo "📦 Available Ollama models:"
ollama list | grep -E "NAME|qwen" || echo "  (No Qwen models found)"
echo ""

# Check available providers
echo "🔌 Available LLM providers in Corebrum:"
echo "  ✅ local (Ollama/Qwen)"
if [ -n "$OPENAI_API_KEY" ]; then
    echo "  ✅ openai"
fi
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "  ✅ anthropic"
fi
echo ""

# Step 1: Create an identity
echo "1️⃣  Creating identity..."
IDENTITY_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{}')

KEY_ID=$(echo "$IDENTITY_RESPONSE" | jq -r '.key_id' 2>/dev/null)
if [ -z "$KEY_ID" ] || [ "$KEY_ID" = "null" ]; then
    echo "❌ Failed to create identity"
    echo "Response: $IDENTITY_RESPONSE"
    exit 1
fi
echo "✅ Created identity: $KEY_ID"
echo ""

# Step 2: Test simple prompt
echo "2️⃣  Test 1: Simple Question"
echo "---------------------------"
PROMPT1="What is cognitive identity in AI systems?"
echo "Prompt: $PROMPT1"
echo ""

RESPONSE1=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"$PROMPT1\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.7,
    \"max_tokens\": 200
  }")

if echo "$RESPONSE1" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$RESPONSE1" | jq -r '.error')"
else
    TEXT1=$(echo "$RESPONSE1" | jq -r '.text // .error' 2>/dev/null)
    MODEL1=$(echo "$RESPONSE1" | jq -r '.model' 2>/dev/null)
    echo "✅ Response (model: $MODEL1):"
    echo "$TEXT1"
fi
echo ""

# Step 3: Test creative prompt
echo "3️⃣  Test 2: Creative Writing"
echo "----------------------------"
PROMPT2="Write a short poem (3-4 lines) about artificial intelligence and cognitive identity."
echo "Prompt: $PROMPT2"
echo ""

RESPONSE2=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"$PROMPT2\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.9,
    \"max_tokens\": 150
  }")

if echo "$RESPONSE2" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$RESPONSE2" | jq -r '.error')"
else
    TEXT2=$(echo "$RESPONSE2" | jq -r '.text // .error' 2>/dev/null)
    echo "✅ Response:"
    echo "$TEXT2"
fi
echo ""

# Step 4: Test reasoning prompt
echo "4️⃣  Test 3: Reasoning Task"
echo "--------------------------"
PROMPT3="List 3 key principles of cognitive identity and explain each in one sentence."
echo "Prompt: $PROMPT3"
echo ""

RESPONSE3=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"$PROMPT3\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.6,
    \"max_tokens\": 250
  }")

if echo "$RESPONSE3" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$RESPONSE3" | jq -r '.error')"
else
    TEXT3=$(echo "$RESPONSE3" | jq -r '.text // .error' 2>/dev/null)
    USAGE3=$(echo "$RESPONSE3" | jq -r '.usage' 2>/dev/null)
    echo "✅ Response:"
    echo "$TEXT3"
    if [ "$USAGE3" != "null" ] && [ -n "$USAGE3" ]; then
        echo ""
        echo "📊 Usage: $USAGE3"
    fi
fi
echo ""

# Step 5: Test with different model (if available)
echo "5️⃣  Test 4: Different Model (if available)"
echo "-------------------------------------------"
# Try llava if available, otherwise use qwen2.5vl
MODEL_CHOICE="qwen2.5vl:3b"
if ollama list | grep -q "llava:7b"; then
    MODEL_CHOICE="llava:7b"
    echo "Using llava:7b model"
else
    echo "Using qwen2.5vl:3b model"
fi

PROMPT4="Explain the concept of distributed cognitive identity in 2-3 sentences."
echo "Prompt: $PROMPT4"
echo ""

RESPONSE4=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"$PROMPT4\",
    \"provider\": \"local\",
    \"model\": \"$MODEL_CHOICE\",
    \"temperature\": 0.7,
    \"max_tokens\": 200
  }")

if echo "$RESPONSE4" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$RESPONSE4" | jq -r '.error')"
else
    TEXT4=$(echo "$RESPONSE4" | jq -r '.text // .error' 2>/dev/null)
    MODEL4=$(echo "$RESPONSE4" | jq -r '.model' 2>/dev/null)
    echo "✅ Response (model: $MODEL4):"
    echo "$TEXT4"
fi
echo ""

# Summary
echo "📊 Test Summary"
echo "==============="
echo "Identity: $KEY_ID"
echo "Provider: local (Ollama)"
echo "Model: qwen2.5vl:3b"
echo ""
echo "✅ Local LLM mission test completed!"
echo ""
echo "💡 Tips:"
echo "  - To test with different models, change the 'model' parameter"
echo "  - Check available models: ollama list"
echo "  - Pull new models: ollama pull <model-name>"
echo "  - View Ollama logs: Check terminal where 'ollama serve' is running"

