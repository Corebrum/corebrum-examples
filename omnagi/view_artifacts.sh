#!/bin/bash
# View all artifacts for a key
# Usage: ./view_artifacts.sh [key_id]

KEY_ID="${1:-}"
API_URL="http://localhost:6502"

# If no key_id provided, try to get the first identity from the list
if [ -z "$KEY_ID" ]; then
    echo "No key_id provided, fetching first identity..."
    IDENTITIES=$(curl -s "$API_URL/api/identity")
    KEY_ID=$(echo "$IDENTITIES" | jq -r '.[0].key_id' 2>/dev/null)
    if [ -z "$KEY_ID" ] || [ "$KEY_ID" = "null" ]; then
        echo "❌ Error: No identities found. Please create an identity first or provide a key_id."
        exit 1
    fi
    echo "Using identity: $KEY_ID"
    echo ""
fi

echo "🔍 Artifacts for Key: $KEY_ID"
echo "=============================="
echo ""

# 1. Identity and Preferences (via artifacts endpoint)
echo "1️⃣  Identity & Learned Preferences:"
echo "-----------------------------------"
ARTIFACTS=$(curl -s "$API_URL/api/artifacts/$KEY_ID/list")
if echo "$ARTIFACTS" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$ARTIFACTS" | jq -r '.error')"
else
    echo "Key ID: $KEY_ID"
    echo ""
    echo "Learned Preferences:"
    echo "$ARTIFACTS" | jq '.[] | select(.type == "preference") | "  \(.name): \(.value)"'
    echo ""
    echo "Metrics:"
    echo "$ARTIFACTS" | jq '.[] | select(.type == "metric") | "  \(.name): \(.value)"'
    echo ""
    echo "Patterns:"
    echo "$ARTIFACTS" | jq '.[] | select(.type == "pattern") | "  \(.name): \(.value)"'
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
        TRACE=$(curl -s "$API_URL/api/traces/$TRACE_ID")
        
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
            MODEL=$(echo "$REQUEST" | jq -r '.context.model // .context."model" // "unknown"' 2>/dev/null)
            PROVIDER=$(echo "$REQUEST" | jq -r '.context.provider // .context."provider" // "unknown"' 2>/dev/null)
            TEMP=$(echo "$REQUEST" | jq -r '.context.temperature // .context."temperature" // "unknown"' 2>/dev/null)
            
            echo "📝 Trace: $TRACE_ID"
            echo "   Provider: $PROVIDER"
            echo "   Model: $MODEL"
            echo "   Temperature: $TEMP"
            if [ -n "$PROMPT" ] && [ "$PROMPT" != "null" ] && [ "$PROMPT" != "" ]; then
                PROMPT_PREVIEW=$(echo "$PROMPT" | head -c 150)
                echo "   Prompt: $PROMPT_PREVIEW..."
            fi
            
            if [ "$RESPONSE" != "null" ] && [ -n "$RESPONSE" ]; then
                RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '.evidence.data.response_text // .evidence.data.text // ""' 2>/dev/null)
                TOKENS=$(echo "$RESPONSE" | jq -r '.context.total_tokens // .context."total_tokens" // 0' 2>/dev/null)
                if [ -n "$RESPONSE_TEXT" ] && [ "$RESPONSE_TEXT" != "null" ] && [ "$RESPONSE_TEXT" != "" ]; then
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

# 4. Memory Entries
echo "4️⃣  Memory Entries:"
echo "------------------"
MEMORY=$(curl -s "$API_URL/api/memory/$KEY_ID")
if echo "$MEMORY" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ Error: $(echo "$MEMORY" | jq -r '.error')"
else
    MEMORY_COUNT=$(echo "$MEMORY" | jq '.items | length' 2>/dev/null || echo "0")
    if [ "$MEMORY_COUNT" -gt 0 ]; then
        echo "Total memory entries: $MEMORY_COUNT"
        echo ""
        echo "Memory keys:"
        echo "$MEMORY" | jq -r '.items[] | "  - \(.key)"' 2>/dev/null | head -10
    else
        echo "No memory entries found"
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

# 6. Artifacts Summary
echo "6️⃣  Artifacts Summary:"
echo "---------------------"
if echo "$ARTIFACTS" | jq -e '.error' > /dev/null 2>&1; then
    echo "No artifacts available"
else
    ARTIFACT_COUNT=$(echo "$ARTIFACTS" | jq 'length' 2>/dev/null || echo "0")
    echo "Total artifacts: $ARTIFACT_COUNT"
    echo ""
    echo "Artifact types:"
    echo "$ARTIFACTS" | jq -r 'group_by(.type) | .[] | "  \(.[0].type): \(length)"' 2>/dev/null
fi
echo ""

echo "✅ Artifact viewing complete!"
echo ""
echo "💡 Tips:"
echo "  - To view a specific trace: curl \"$API_URL/api/traces/{trace_id}\" | jq '.'"
echo "  - To view all traces: curl \"$API_URL/api/traces/$KEY_ID/list\" | jq '.'"
echo "  - To view all ledgers: curl \"$API_URL/api/ledgers/$KEY_ID/list\" | jq '.'"
echo "  - To view memory: curl \"$API_URL/api/memory/$KEY_ID\" | jq '.'"
echo "  - To view artifacts: curl \"$API_URL/api/artifacts/$KEY_ID/list\" | jq '.'"

