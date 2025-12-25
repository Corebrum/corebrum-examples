# Identity and Memory Examples

Examples demonstrating Corebrum's identity and memory system for tasks and streams.

## Prerequisites

1. **Start Zenoh Router**:
   ```bash
   zenohd
   ```

2. **Start Corebrum Daemon**:
   ```bash
   corebrum daemon --zenoh-router tcp://localhost:7447
   ```

3. **Create an Identity**:
   ```bash
   corebrum identity create --name "Test Robot"
   # Note the key_id from the output
   ```

## Examples

### `task_with_identity.yaml`

Demonstrates a task running with identity context, accessing and storing memory.

```bash
# Create identity first
IDENTITY_ID=$(corebrum identity create --name "Test Robot" | grep -o '[a-f0-9-]\{36\}')

# Submit task with identity context
corebrum submit-and-wait --file task_definitions/identity/task_with_identity.yaml \
  --input '{"number": 8}' \
  --identity $IDENTITY_ID
```

**Key Features:**
- Task runs with identity context
- Memory API helpers are automatically available
- Task can read from and write to identity memory
- Results are automatically stored to identity memory

### `stream_with_identity.yaml`

Demonstrates a stream task running with identity context, continuously accessing memory.

```bash
# Create identity first
IDENTITY_ID=$(corebrum identity create --name "Stream Robot" | grep -o '[a-f0-9-]\{36\}')

# Submit stream task with identity context
corebrum submit --file task_definitions/identity/stream_with_identity.yaml \
  --identity $IDENTITY_ID

# Monitor the stream
corebrum streams

# Cancel when done
corebrum cancel <task-id>
```

**Key Features:**
- Stream task runs with identity context
- Memory is pre-loaded before execution
- Memory API helpers available throughout stream execution
- Can access own, ancestor, and hive memories

### `memory_persistence.yaml`

Demonstrates how task results persist in identity memory across multiple task executions.

```bash
# Create identity and set as default
IDENTITY_ID=$(corebrum identity create --name "Persistent Robot" | grep -o '[a-f0-9-]\{36\}')
corebrum identity set $IDENTITY_ID

# First execution - stores result
corebrum submit-and-wait --file task_definitions/identity/memory_persistence.yaml \
  --input '{"value": 42}'

# Second execution - retrieves previous result
corebrum submit-and-wait --file task_definitions/identity/memory_persistence.yaml \
  --input '{"value": 100}'
```

**Key Features:**
- Shows memory persistence across task executions
- Tasks can build on previous results
- Demonstrates stateful computation with identity memory

## Using Identity in Task Definitions

### Basic Task with Identity

```yaml
name: "identity_task"
version: "1.0"
description: "Task with identity context"
inputs: [{"name": "data", "type": "json"}]
outputs: [{"name": "result", "type": "json"}]
compute_logic:
  type: "expression"
  language: "python"
  timeout_seconds: 30
  code: |
    # Identity context is automatically available
    # identity_id and identity_memory are pre-loaded
    
    # Use memory API helpers (automatically injected)
    previous_result = get_memory(identity_id, "last_result")
    
    # Process data
    result = {"processed": inputs["data"], "previous": previous_result}
    
    # Store result for next execution
    put_memory(identity_id, "last_result", result)
```

### Stream Task with Identity

```yaml
name: "identity_stream"
version: "1.0"
description: "Stream task with identity context"
execution_mode: "stream_reactive"
stream_config:
  trigger: "on_message"
inputs:
  - name: "message"
    type: "zenoh"
    key_expr: "rt/sensor/data"
compute_logic:
  type: "expression"
  language: "python"
  timeout_seconds: 300
  code: |
    # Memory API helpers available in stream tasks too
    count = get_memory(identity_id, "message_count") or 0
    count += 1
    put_memory(identity_id, "message_count", count)
    
    # Process message
    result = {"count": count, "data": inputs["message"]}
```

## Memory API Reference

When a task or stream runs with identity context, these Python functions are automatically available:

### `get_memory(key_id, memory_key)`
Get memory for a specific identity and memory key.
```python
value = get_memory(identity_id, "preference")
```

### `put_memory(key_id, memory_key, value)`
Store memory for a specific identity and memory key.
```python
put_memory(identity_id, "result", {"status": "success"})
```

### `query_memory(key_id, prefix=None)`
Query memories for a specific identity with optional prefix.
```python
all_memories = query_memory(identity_id)
user_prefs = query_memory(identity_id, "user_")
```

### `get_hive_memory(hive_id, memory_key)`
Get memory from a hive (requires Hive feature license).
```python
shared_data = get_hive_memory("research_team", "shared_fact")
```

### `put_hive_memory(hive_id, memory_key, value)`
Store memory in a hive (requires Hive feature license).
```python
put_hive_memory("research_team", "discovery", {"fact": "new finding"})
```

## Environment Variables

When running with identity context, these environment variables are available:

- `COREBRUM_IDENTITY_ID`: The identity ID for the current task/stream
- `ZENOH_ROUTER`: The Zenoh router URL

## Feature Flags and License Checking

Memory operations require feature licenses:

- **Memory**: Required for `get_memory()`, `put_memory()`, `query_memory()`
- **Hive**: Required for `get_hive_memory()`, `put_hive_memory()`
- **AncestorAccess**: Required for accessing ancestor memories (automatic when loading memory)

If a feature is not enabled, operations will fail with a clear error message.

## Best Practices

1. **Set Default Identity**: Use `corebrum identity set <key_id>` to avoid passing `--identity` every time
2. **Use Descriptive Memory Keys**: Use clear, hierarchical keys like `user/preferences` or `task/results`
3. **Handle Missing Memory**: Always check if memory exists before using it
4. **Enable Auto-Store Results**: Set `auto_store_result: true` in task metadata to automatically save results
5. **Use Hive Memory for Collaboration**: Share knowledge across robots using hive memory

## See Also

- [Identity Commands](../README.md#identity-commands)
- [Memory Commands](../README.md#memory-commands)
- [Hive Commands](../README.md#hive-commands)
- [Identity, Memory, and Hive System](../README.md#identity-memory-and-hive-system)

