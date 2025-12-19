#!/bin/bash
# Sample LLM-based Mission for Corebrum
# This script demonstrates how to use Corebrum with various LLM providers

set -e

API_URL="http://localhost:6502"

echo "🚀 Corebrum LLM Mission Example"
echo "================================"
echo ""

# Step 1: Create an identity
echo "1️⃣  Creating identity..."
IDENTITY_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{}')

KEY_ID=$(echo "$IDENTITY_RESPONSE" | jq -r '.key_id')
echo "✅ Created identity: $KEY_ID"
echo ""

# Step 2: Example mission using OpenAI
if [ -n "$OPENAI_API_KEY" ]; then
  echo "2️⃣  Running mission with OpenAI GPT-4..."
  OPENAI_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
    -H "Content-Type: application/json" \
    -d "{
      \"key_id\": \"$KEY_ID\",
      \"prompt\": \"Write a short poem about artificial intelligence and cognitive identity.\",
      \"provider\": \"openai\",
      \"model\": \"gpt-4o\",
      \"temperature\": 0.7,
      \"max_tokens\": 200
    }")
  
  echo "Response:"
  echo "$OPENAI_RESPONSE" | jq -r '.text'
  echo ""
fi

# Step 3: Example mission using Anthropic
if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "3️⃣  Running mission with Anthropic Claude..."
  ANTHROPIC_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
    -H "Content-Type: application/json" \
    -d "{
      \"key_id\": \"$KEY_ID\",
      \"prompt\": \"Explain the concept of cognitive identity in AI systems in 3-4 sentences.\",
      \"provider\": \"anthropic\",
      \"model\": \"claude-3-5-sonnet-20241022\",
      \"temperature\": 0.5,
      \"max_tokens\": 300
    }")
  
  echo "Response:"
  echo "$ANTHROPIC_RESPONSE" | jq -r '.text'
  echo ""
fi

# Step 4: Example mission using local Qwen2.5 via Corebrum/Ollama
echo "4️⃣  Running mission with local Qwen2.5 (via Corebrum/Ollama)..."
LOCAL_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"What are the key principles of cognitive identity?\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.7,
    \"max_tokens\": 250
  }")

echo "Response:"
if echo "$LOCAL_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$LOCAL_RESPONSE" | jq -r '.error')"
    echo ""
    echo "💡 Troubleshooting:"
    echo "  - Make sure Corebrum web server is running: cargo run --bin corebrum -- web"
    echo "  - Make sure Corebrum workers are running: corebrum daemon --worker-count 2"
    echo "  - Make sure Ollama is running: ollama serve"
    echo "  - Check available models: ollama list"
else
    echo "$LOCAL_RESPONSE" | jq -r '.text // .error'
    MODEL=$(echo "$LOCAL_RESPONSE" | jq -r '.model' 2>/dev/null)
    if [ "$MODEL" != "null" ] && [ -n "$MODEL" ]; then
        echo ""
        echo "Model used: $MODEL"
    fi
fi
echo ""

# Step 4b: Test memory/identity persistence
echo "4️⃣b Testing Memory & Identity Persistence"
echo "-------------------------------------------"
echo "This test verifies that the LLM remembers information across multiple interactions."
echo ""

# Tell the LLM your name
TEST_NAME="Alice"
echo "Step 1: Telling LLM my name is $TEST_NAME..."
MEMORY_TEST1=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"My name is $TEST_NAME. Please remember this.\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.7,
    \"max_tokens\": 100
  }")

if echo "$MEMORY_TEST1" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$MEMORY_TEST1" | jq -r '.error')"
else
    echo "✅ Response: $(echo "$MEMORY_TEST1" | jq -r '.text // .error' | head -c 100)..."
fi
echo ""

# Small delay to ensure conversation history is saved
echo "   (Waiting 2 seconds for conversation history to be saved...)"
sleep 2
echo ""

# Ask the LLM to recall your name
echo "Step 2: Asking LLM to recall my name..."
MEMORY_TEST2=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_id\": \"$KEY_ID\",
    \"prompt\": \"What is my name?\",
    \"provider\": \"local\",
    \"model\": \"qwen2.5vl:3b\",
    \"temperature\": 0.7,
    \"max_tokens\": 100
  }")

if echo "$MEMORY_TEST2" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$MEMORY_TEST2" | jq -r '.error')"
    echo ""
    echo "⚠️  Memory test failed - LLM could not recall information"
else
    MEMORY_RESPONSE=$(echo "$MEMORY_TEST2" | jq -r '.text // .error')
    echo "Response: $MEMORY_RESPONSE"
    echo ""
    
    # Check if the response contains the name (case-insensitive)
    if echo "$MEMORY_RESPONSE" | grep -qi "$TEST_NAME"; then
        echo "✅ Memory test PASSED - LLM remembered the name!"
    else
        echo "⚠️  Memory test FAILED - LLM did not recall the name '$TEST_NAME'"
        echo "   This suggests conversation history may not be persisting correctly."
    fi
fi
echo ""

# Verify conversation history is stored
echo "Step 3: Verifying conversation history is stored..."
HISTORY=$(curl -s "$API_URL/api/memory/$KEY_ID/history")
HISTORY_COUNT=$(echo "$HISTORY" | jq -r 'length' 2>/dev/null || echo "0")
if [ "$HISTORY_COUNT" -gt 0 ]; then
    echo "✅ Conversation history found: $HISTORY_COUNT messages stored"
    echo "   First message: $(echo "$HISTORY" | jq -r '.[0].role // "unknown"')"
    echo "   Last message: $(echo "$HISTORY" | jq -r '.[-1].role // "unknown"')"
else
    echo "⚠️  No conversation history found - memory may not be persisting"
fi
echo ""

# Step 5: List available providers
echo "5️⃣  Available LLM providers:"
echo "  ✅ local (Ollama/Qwen)"
if [ -n "$OPENAI_API_KEY" ]; then
    echo "  ✅ openai"
fi
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo "  ✅ anthropic"
fi
echo ""

echo "✅ Mission completed!"

