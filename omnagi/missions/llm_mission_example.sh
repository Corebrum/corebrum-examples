#!/bin/bash
# Sample LLM-based Mission for Omnagi
# This script demonstrates how to use Omnagi with various LLM providers

set -e

API_URL="http://localhost:4242"

echo "🚀 Omnagi LLM Mission Example"
echo "=============================="
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
    echo "  - Make sure Corebrum daemon is running: corebrum daemon --worker-count 2"
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

# Step 5: List available providers
echo "5️⃣  Available LLM providers:"
curl -s "$API_URL/api/llm/providers" | jq -r '.providers[]'
echo ""

echo "✅ Mission completed!"

