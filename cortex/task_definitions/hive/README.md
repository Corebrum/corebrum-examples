# Hive Examples

Examples demonstrating Corebrum's hive memory sharing system, where multiple robots can collaborate and share knowledge through named groups.

## Prerequisites

1. **Start Corebrum Web Server**:
   ```bash
   corebrum web
   ```

2. **Start Corebrum Daemon** (with requests capability):
   ```bash
   corebrum daemon --capabilities "python,requests"
   ```

3. **Create Identities** (if you don't have any):
   ```bash
   # Create identity 1
   curl -X POST 'http://localhost:6502/api/identity' \
     -H 'Content-Type: application/json' \
     -d '{"name": "Robot Alpha"}'
   
   # Create identity 2
   curl -X POST 'http://localhost:6502/api/identity' \
     -H 'Content-Type: application/json' \
     -d '{"name": "Robot Beta"}'
   ```

## Examples

### `hive_shared_knowledge.yaml`

Demonstrates storing and retrieving shared knowledge in a hive.

**Setup:**
```bash
# 1. Create a hive
curl -X POST 'http://localhost:6502/api/hives?key_id=YOUR_KEY_ID' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Research Team",
    "description": "Shared knowledge base for research"
  }'
# Note the hive_id from the response

# 2. Add robots to the hive
curl -X PUT "http://localhost:6502/api/hives/HIVE_ID/members/KEY_ID_1"
curl -X PUT "http://localhost:6502/api/hives/HIVE_ID/members/KEY_ID_2"
```

**Usage:**
```bash
# Robot 1 stores knowledge in the hive
corebrum submit-and-wait \
  --file cortex/task_definitions/hive/hive_shared_knowledge.yaml \
  --input '{
    "hive_id": "YOUR_HIVE_ID",
    "key_id": "KEY_ID_1",
    "knowledge_key": "fact_1",
    "knowledge_value": "The speed of light is 299,792,458 m/s"
  }'

# Robot 2 stores different knowledge
corebrum submit-and-wait \
  --file cortex/task_definitions/hive/hive_shared_knowledge.yaml \
  --input '{
    "hive_id": "YOUR_HIVE_ID",
    "key_id": "KEY_ID_2",
    "knowledge_key": "fact_2",
    "knowledge_value": "Water freezes at 0°C"
  }'

# Robot 1 can now access Robot 2's knowledge (and vice versa)
# The knowledge is shared through the hive!
```

**Key Features:**
- Robots store knowledge in hive memory using REST API
- All hive members can access shared knowledge
- Knowledge persists across robot sessions
- Uses `memory/hives/{hive_id}/memory/{key}` namespace

### `hive_collaborative_learning.yaml`

Demonstrates collaborative learning where robots share insights and learn from each other.

**Setup:**
```bash
# Create a hive (same as above)
# Add multiple robots to the hive
```

**Usage:**
```bash
# Robot 1 shares an insight
corebrum submit-and-wait \
  --file cortex/task_definitions/hive/hive_collaborative_learning.yaml \
  --input '{
    "hive_id": "YOUR_HIVE_ID",
    "key_id": "KEY_ID_1",
    "robot_name": "Robot Alpha",
    "insight": "I discovered that using batch processing improves efficiency by 30%"
  }'

# Robot 2 shares a different insight
corebrum submit-and-wait \
  --file cortex/task_definitions/hive/hive_collaborative_learning.yaml \
  --input '{
    "hive_id": "YOUR_HIVE_ID",
    "key_id": "KEY_ID_2",
    "robot_name": "Robot Beta",
    "insight": "I found that caching reduces computation time by 50%"
  }'

# Robot 1 runs again - now sees all shared insights
corebrum submit-and-wait \
  --file cortex/task_definitions/hive/hive_collaborative_learning.yaml \
  --input '{
    "hive_id": "YOUR_HIVE_ID",
    "key_id": "KEY_ID_1",
    "robot_name": "Robot Alpha"
  }'
# Output shows all insights from both robots!
```

**Key Features:**
- Robots share insights with timestamps
- All hive members can see all shared insights
- Enables collaborative learning and knowledge accumulation
- Insights are organized by robot and timestamp

## Using Hives via CLI

You can also manage hives using the CLI:

```bash
# Create a hive
corebrum hive create "Research Team" \
  --description "Shared knowledge base" \
  --key-id YOUR_KEY_ID

# List hives
corebrum hive list --key-id YOUR_KEY_ID

# Join a hive
corebrum hive join HIVE_ID --key-id YOUR_KEY_ID

# Store memory in a hive
corebrum hive memory put HIVE_ID "fact_1" '{"value": "The sky is blue"}' \
  --key-id YOUR_KEY_ID

# Query hive memories
corebrum hive memory query HIVE_ID --key-id YOUR_KEY_ID
```

## Memory Access Patterns

Corebrum supports three memory access patterns:

1. **Own Memory**: `memory/{key_id}/{key}` - Private to each robot
2. **Ancestor Memory**: Automatically accessible from parent robots in the identity graph
3. **Hive Memory**: `memory/hives/{hive_id}/memory/{key}` - Shared among hive members

When querying memory for an identity (`GET /api/memory/{key_id}`), all three types are automatically aggregated:
- Own memories
- Ancestor memories (from parent robots)
- Hive memories (from all hives the robot belongs to)

## Architecture

```
┌─────────────────────────────────────────┐
│         Robot Memory Access              │
└─────────────────────────────────────────┘
              │
    ┌─────────┼─────────┐
    │         │         │
┌───▼───┐ ┌──▼──┐ ┌────▼────┐
│  Own  │ │Anc. │ │  Hive   │
│Memory │ │Mem. │ │ Memory  │
└───────┘ └─────┘ └─────────┘
    │         │         │
    └─────────┼─────────┘
              │
      ┌───────▼───────┐
      │   Aggregated  │
      │   Memory View │
      └───────────────┘
```

## Best Practices

1. **Hive Organization**: Create hives for specific purposes (e.g., "Research Team", "Production Workers", "Learning Group")
2. **Knowledge Keys**: Use descriptive, hierarchical keys (e.g., `insights/robot-name/timestamp`, `facts/category/item`)
3. **Access Control**: Only hive members can read/write hive memories
4. **Memory Cleanup**: Periodically review and clean up old hive memories
5. **Collaboration**: Use hives for knowledge that benefits multiple robots, not for robot-specific data

For complete documentation, see the [Corebrum Hive System](../../README.md#hive-system) documentation.

