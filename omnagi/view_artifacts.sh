#!/bin/bash
# View all artifacts for a key
# Usage: ./examples/view_artifacts.sh [key_id]

KEY_ID="${1:-9dd7ae25-758b-481b-be9e-257a7bce256d}"
API_URL="http://localhost:8123"

echo "🔍 Artifacts for Key: $KEY_ID"
echo "=============================="
echo ""

# 1. Identity and Preferences
echo "1️⃣  Identity & Learned Preferences:"
echo "-----------------------------------"
IDENTITY=$(curl -s "$API_URL/api/identity/$KEY_ID")
if echo "$IDENTITY" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$IDENTITY" | jq -r '.error')"
else
    echo "$IDENTITY" | jq '{
        key_id: .key_id,
        total_interactions: .preferences.context_preferences.total_interactions,
        preferred_provider: .preferences.context_preferences.preferred_provider,
        preferred_model: .preferences.context_preferences.preferred_model,
        preferred_temperature: .preferences.context_preferences.preferred_temperature,
        context_injection_enabled: .preferences.context_preferences.enable_context_injection,
        created_at: .created_at,
        updated_at: .updated_at
    }'
fi
echo ""

# 2. Trace Summary
echo "2️⃣  Trace Summary:"
echo "-----------------"
TRACES=$(curl -s "$API_URL/api/traces/$KEY_ID/list")
if echo "$TRACES" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$TRACES" | jq -r '.error')"
else
    TRACE_COUNT=$(echo "$TRACES" | jq 'length')
    echo "Total traces: $TRACE_COUNT"
    echo ""
    echo "Trace IDs (most recent first):"
    echo "$TRACES" | jq -r '.[].trace_id' | head -10
fi
echo ""

# 3. Recent LLM Interactions
echo "3️⃣  Recent LLM Interactions:"
echo "---------------------------"
if [ "$TRACE_COUNT" -gt 0 ] 2>/dev/null; then
    echo "$TRACES" | jq -r '.[].trace_id' | head -5 | while read TRACE_ID; do
        TRACE=$(curl -s "$API_URL/api/traces/$TRACE_ID?key_id=$KEY_ID")
        
        if echo "$TRACE" | jq -e '.error' > /dev/null 2>&1; then
            echo "⚠️  Trace $TRACE_ID: $(echo "$TRACE" | jq -r '.error')"
            continue
        fi
        
        # Get request event
        REQUEST=$(echo "$TRACE" | jq '.events[] | select(.event_type == "llm_request")' 2>/dev/null)
        # Get response event  
        RESPONSE=$(echo "$TRACE" | jq '.events[] | select(.event_type == "llm_response")' 2>/dev/null)
        
        if [ "$REQUEST" != "null" ] && [ -n "$REQUEST" ]; then
            PROMPT=$(echo "$REQUEST" | jq -r '.evidence.data.prompt // .message // ""' 2>/dev/null)
            MODEL=$(echo "$REQUEST" | jq -r '.context.model // "unknown"' 2>/dev/null)
            PROVIDER=$(echo "$REQUEST" | jq -r '.context.provider // "unknown"' 2>/dev/null)
            TEMP=$(echo "$REQUEST" | jq -r '.context.temperature // "unknown"' 2>/dev/null)
            
            echo "📝 Trace: $TRACE_ID"
            echo "   Provider: $PROVIDER"
            echo "   Model: $MODEL"
            echo "   Temperature: $TEMP"
            if [ -n "$PROMPT" ] && [ "$PROMPT" != "null" ]; then
                PROMPT_PREVIEW=$(echo "$PROMPT" | head -c 150)
                echo "   Prompt: $PROMPT_PREVIEW..."
            fi
            
            if [ "$RESPONSE" != "null" ] && [ -n "$RESPONSE" ]; then
                RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '.evidence.data.response_text // ""' 2>/dev/null)
                TOKENS=$(echo "$RESPONSE" | jq -r '.context.total_tokens // 0' 2>/dev/null)
                if [ -n "$RESPONSE_TEXT" ] && [ "$RESPONSE_TEXT" != "null" ]; then
                    RESPONSE_PREVIEW=$(echo "$RESPONSE_TEXT" | head -c 200)
                    echo "   Response: $RESPONSE_PREVIEW..."
                fi
                if [ "$TOKENS" != "0" ] && [ "$TOKENS" != "null" ]; then
                    echo "   Tokens: $TOKENS"
                fi
            fi
            echo ""
        fi
    done
else
    echo "No traces found"
fi
echo ""

# 4. Tasks
echo "4️⃣  Tasks:"
echo "--------"
TASKS=$(curl -s "$API_URL/api/tasks/$KEY_ID/list")
if echo "$TASKS" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$TASKS" | jq -r '.error')"
else
    TASK_COUNT=$(echo "$TASKS" | jq 'length')
    if [ "$TASK_COUNT" -gt 0 ]; then
        echo "$TASKS" | jq '.[] | {
            task_id: .task_id,
            status: .status,
            task_type: .task_type,
            created_at: .created_at,
            updated_at: .updated_at
        }'
    else
        echo "No tasks found"
    fi
fi
echo ""

# 5. Ledgers
echo "5️⃣  Ledgers:"
echo "-----------"
LEDGERS=$(curl -s "$API_URL/api/ledgers/$KEY_ID/list")
if echo "$LEDGERS" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$LEDGERS" | jq -r '.error')"
else
    LEDGER_COUNT=$(echo "$LEDGERS" | jq 'length')
    if [ "$LEDGER_COUNT" -gt 0 ]; then
        echo "$LEDGERS" | jq '.[] | {
            ledger_id: .ledger_id,
            title: .title,
            entries_count: (.entries | length),
            created_at: .created_at
        }'
    else
        echo "No ledgers found"
    fi
fi
echo ""

# 6. Reflection Logs
echo "6️⃣  Reflection Logs:"
echo "-------------------"
REFLECTIONS=$(curl -s "$API_URL/api/reflections" 2>/dev/null)
if echo "$REFLECTIONS" | jq -e '.error' > /dev/null 2>&1; then
    echo "No reflection logs endpoint available"
else
    echo "Reflection logs: $(echo "$REFLECTIONS" | jq 'length')"
fi
echo ""

echo "✅ Artifact viewing complete!"
echo ""
echo "💡 Tips:"
echo "  - To view a specific trace: curl \"$API_URL/api/traces/{trace_id}?key_id=$KEY_ID\" | jq '.'"
echo "  - To view full identity: curl \"$API_URL/api/identity/$KEY_ID\" | jq '.'"
echo "  - To view all traces: curl \"$API_URL/api/traces/$KEY_ID/list\" | jq '.'"

