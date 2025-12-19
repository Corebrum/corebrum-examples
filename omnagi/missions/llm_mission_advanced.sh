#!/bin/bash
# Advanced LLM Mission Example
# Demonstrates multi-step reasoning with LLM chaining
# Note: Falls back to local provider if OpenAI/Anthropic are not configured

API_URL="http://localhost:6502"

echo "🧠 Advanced Corebrum LLM Mission"
echo "==============================="
echo ""

# Create identity
echo "1️⃣  Creating identity..."
IDENTITY_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{}')
KEY_ID=$(echo "$IDENTITY_RESPONSE" | jq -r '.key_id')
echo "✅ Identity: $KEY_ID"
echo ""

# Create a trace for this mission
echo "2️⃣  Creating mission trace..."
TRACE_RESPONSE=$(curl -s -X POST "$API_URL/api/traces" \
  -H "Content-Type: application/json" \
  -d "{\"key_id\": \"$KEY_ID\"}")
TRACE_ID=$(echo "$TRACE_RESPONSE" | jq -r '.trace_id')
echo "✅ Trace: $TRACE_ID"
echo ""

# Mission: Research and Analysis
echo "3️⃣  Mission: Research Topic Analysis"
echo "-----------------------------------"

TOPIC="The future of cognitive AI systems"

# Step 1: Generate research questions
echo "Step 1: Generating research questions..."
QUESTIONS_PROMPT="Generate 3 key research questions about: $TOPIC"
QUESTIONS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg key_id "$KEY_ID" \
    --arg prompt "$QUESTIONS_PROMPT" \
    '{key_id: $key_id, prompt: $prompt, provider: "openai", temperature: 0.8}')")

# Check if we got an error (provider not available or invalid JSON)
if ! echo "$QUESTIONS_RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo "⚠️  Invalid JSON response from API, trying local model..."
    QUESTIONS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg key_id "$KEY_ID" \
        --arg prompt "$QUESTIONS_PROMPT" \
        '{key_id: $key_id, prompt: $prompt, provider: "local", model: "qwen2.5vl:3b", temperature: 0.8}')")
elif echo "$QUESTIONS_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo "⚠️  OpenAI provider not available, using local model instead..."
  QUESTIONS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg key_id "$KEY_ID" \
      --arg prompt "$QUESTIONS_PROMPT" \
      '{key_id: $key_id, prompt: $prompt, provider: "local", model: "qwen2.5vl:3b", temperature: 0.8}')")
fi

# Extract questions with proper error handling
if ! echo "$QUESTIONS_RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo "⚠️  Invalid JSON response from API"
    echo "Response: $QUESTIONS_RESPONSE"
    QUESTIONS="Failed to generate questions: Invalid response"
else
    QUESTIONS=$(echo "$QUESTIONS_RESPONSE" | jq -r '.text // .error // "Failed to generate questions"')
fi

echo "Research Questions:"
echo "$QUESTIONS"
echo ""

# Step 2: Analyze each question
echo "Step 2: Analyzing questions..."
# Use jq to properly escape the QUESTIONS variable in JSON
ANALYSIS_PROMPT="Based on these questions: $QUESTIONS

Provide a comprehensive analysis of each question."

ANALYSIS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg key_id "$KEY_ID" \
    --arg prompt "$ANALYSIS_PROMPT" \
    '{key_id: $key_id, prompt: $prompt, provider: "anthropic", temperature: 0.7, max_tokens: 1000}')")

# Check if we got an error (provider not available or invalid JSON)
if ! echo "$ANALYSIS_RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo "⚠️  Invalid JSON response from API"
    ANALYSIS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg key_id "$KEY_ID" \
        --arg prompt "$ANALYSIS_PROMPT" \
        '{key_id: $key_id, prompt: $prompt, provider: "local", model: "qwen2.5vl:3b", temperature: 0.7, max_tokens: 1000}')")
elif echo "$ANALYSIS_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo "⚠️  Anthropic provider not available, using local model instead..."
  ANALYSIS_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg key_id "$KEY_ID" \
      --arg prompt "$ANALYSIS_PROMPT" \
      '{key_id: $key_id, prompt: $prompt, provider: "local", model: "qwen2.5vl:3b", temperature: 0.7, max_tokens: 1000}')")
fi

# Extract analysis with proper error handling
if ! echo "$ANALYSIS_RESPONSE" | jq -e . > /dev/null 2>&1; then
    echo "⚠️  Invalid JSON response from API"
    echo "Response: $ANALYSIS_RESPONSE"
    ANALYSIS="Failed to generate analysis: Invalid response"
else
    ANALYSIS=$(echo "$ANALYSIS_RESPONSE" | jq -r '.text // .error // "Failed to generate analysis"')
fi
echo "Analysis:"
echo "$ANALYSIS"
echo ""

# Step 3: Generate summary using local model
echo "Step 3: Generating summary (local model)..."
# Only summarize if we have valid analysis
if [ "$ANALYSIS" != "null" ] && [ "$ANALYSIS" != "Failed to generate analysis" ] && [ -n "$ANALYSIS" ]; then
  SUMMARY_PROMPT="Summarize this analysis in 2-3 sentences: $ANALYSIS"
  SUMMARY_RESPONSE=$(curl -s -X POST "$API_URL/api/llm/complete" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg key_id "$KEY_ID" \
      --arg prompt "$SUMMARY_PROMPT" \
      '{key_id: $key_id, prompt: $prompt, provider: "local", model: "qwen2.5vl:3b", temperature: 0.5}')")
  
  if ! echo "$SUMMARY_RESPONSE" | jq -e . > /dev/null 2>&1; then
      SUMMARY="Failed to generate summary: Invalid response"
  else
      SUMMARY=$(echo "$SUMMARY_RESPONSE" | jq -r '.text // .error // "Failed to generate summary"')
  fi
else
  SUMMARY="Cannot summarize: previous step did not produce valid analysis"
fi

echo "Summary:"
echo "$SUMMARY"
echo ""

# Note: Corebrum uses traces and ledgers instead of generic tasks
# The trace was already created above, so we'll skip task submission
echo "4️⃣  Trace created (task tracking via traces)"
echo "✅ Trace ID: $TRACE_ID"
echo ""

# Access trace (Corebrum traces don't require key_id query param for access)
echo "5️⃣  Accessing trace..."
TRACE_ACCESS=$(curl -s "$API_URL/api/traces/$TRACE_ID")
if echo "$TRACE_ACCESS" | jq -e '.error' > /dev/null 2>&1; then
    echo "⚠️  Trace access error: $(echo "$TRACE_ACCESS" | jq -r '.error')"
else
    echo "✅ Trace accessed successfully"
    echo "   Trace ID: $(echo "$TRACE_ACCESS" | jq -r '.trace_id')"
    echo "   Events: $(echo "$TRACE_ACCESS" | jq -r '.events | length')"
fi
echo ""

# List all traces for this key (including accessible ancestor traces)
echo "6️⃣  Listing all accessible traces for key..."
TRACES_LIST=$(curl -s "$API_URL/api/traces/$KEY_ID/list")
TRACE_COUNT=$(echo "$TRACES_LIST" | jq -r 'length')
echo "✅ Found $TRACE_COUNT accessible trace(s)"
echo ""

echo "✅ Advanced mission completed!"

