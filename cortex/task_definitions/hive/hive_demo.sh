#!/bin/bash
# Hive Memory Sharing Demo
# Demonstrates how robots can share knowledge through hives

set -e

API_URL="http://localhost:6502"

echo "🐝 Corebrum Hive Memory Sharing Demo"
echo "====================================="
echo ""

# Step 1: Create identities
echo "1️⃣  Creating identities..."
IDENTITY1_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{"name": "Robot Alpha"}')

IDENTITY2_RESPONSE=$(curl -s -X POST "$API_URL/api/identity" \
  -H "Content-Type: application/json" \
  -d '{"name": "Robot Beta"}')

KEY_ID1=$(echo "$IDENTITY1_RESPONSE" | jq -r '.key_id')
KEY_ID2=$(echo "$IDENTITY2_RESPONSE" | jq -r '.key_id')

echo "✅ Created Robot Alpha: $KEY_ID1"
echo "✅ Created Robot Beta: $KEY_ID2"
echo ""

# Step 2: Create a hive
echo "2️⃣  Creating hive..."
HIVE_RESPONSE=$(curl -s -X POST "$API_URL/api/hives?key_id=$KEY_ID1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Research Team",
    "description": "Shared knowledge base for collaborative research"
  }')

HIVE_ID=$(echo "$HIVE_RESPONSE" | jq -r '.hive_id')
HIVE_NAME=$(echo "$HIVE_RESPONSE" | jq -r '.name')

echo "✅ Created hive: $HIVE_NAME (ID: $HIVE_ID)"
echo ""

# Step 3: Add both robots to the hive
echo "3️⃣  Adding robots to hive..."
curl -s -X PUT "$API_URL/api/hives/$HIVE_ID/members/$KEY_ID1" > /dev/null
curl -s -X PUT "$API_URL/api/hives/$HIVE_ID/members/$KEY_ID2" > /dev/null

echo "✅ Added Robot Alpha to hive"
echo "✅ Added Robot Beta to hive"
echo ""

# Step 4: Robot Alpha stores knowledge in the hive
echo "4️⃣  Robot Alpha sharing knowledge..."
ALPHA_KNOWLEDGE=$(curl -s -X PUT "$API_URL/api/hives/$HIVE_ID/memory/fact_1?key_id=$KEY_ID1" \
  -H "Content-Type: application/json" \
  -d '{
    "value": "The speed of light is 299,792,458 meters per second"
  }')

echo "✅ Robot Alpha stored: 'The speed of light is 299,792,458 m/s'"
echo ""

# Step 5: Robot Beta stores different knowledge
echo "5️⃣  Robot Beta sharing knowledge..."
BETA_KNOWLEDGE=$(curl -s -X PUT "$API_URL/api/hives/$HIVE_ID/memory/fact_2?key_id=$KEY_ID2" \
  -H "Content-Type: application/json" \
  -d '{
    "value": "Water freezes at 0°C and boils at 100°C"
  }')

echo "✅ Robot Beta stored: 'Water freezes at 0°C and boils at 100°C'"
echo ""

# Step 6: Robot Alpha retrieves all hive memories (including Beta's)
echo "6️⃣  Robot Alpha accessing shared knowledge..."
ALPHA_MEMORIES=$(curl -s -X GET "$API_URL/api/hives/$HIVE_ID/memory?key_id=$KEY_ID1")

echo "📚 Knowledge available to Robot Alpha:"
echo "$ALPHA_MEMORIES" | jq -r '.items[] | "   - \(.key): \(.value)"'
echo ""

# Step 7: Robot Beta retrieves all hive memories (including Alpha's)
echo "7️⃣  Robot Beta accessing shared knowledge..."
BETA_MEMORIES=$(curl -s -X GET "$API_URL/api/hives/$HIVE_ID/memory?key_id=$KEY_ID2")

echo "📚 Knowledge available to Robot Beta:"
echo "$BETA_MEMORIES" | jq -r '.items[] | "   - \(.key): \(.value)"'
echo ""

# Step 8: Show that each robot also has its own private memory
echo "8️⃣  Demonstrating private vs shared memory..."
echo "   Robot Alpha's private memory (not in hive):"
curl -s -X PUT "$API_URL/api/memory/memory/$KEY_ID1/private_note" \
  -H "Content-Type: application/json" \
  -d '{"value": "This is private to Robot Alpha only"}' > /dev/null

ALPHA_PRIVATE=$(curl -s -X GET "$API_URL/api/memory/$KEY_ID1")
PRIVATE_COUNT=$(echo "$ALPHA_PRIVATE" | jq -r '.items | length')
echo "   ✅ Robot Alpha has $PRIVATE_COUNT total memory items (own + hive)"
echo ""

# Step 9: Summary
echo "📊 Summary"
echo "=========="
echo "Hive: $HIVE_NAME"
echo "Members: 2 (Robot Alpha, Robot Beta)"
echo "Shared Knowledge Items: 2"
echo ""
echo "✅ Demo completed successfully!"
echo ""
echo "💡 Key Points:"
echo "   - Robots can share knowledge through hives"
echo "   - Each robot maintains its own private memory"
echo "   - Hive memories are accessible to all members"
echo "   - Memory is persistent and survives restarts"

