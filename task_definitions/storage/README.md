# Storage Examples

Examples demonstrating Corebrum's persistent storage capabilities using Zenoh storage backends.

## Prerequisites

1. **Configure Zenoh Router** with a storage backend:
   ```bash
   # Using Filesystem backend (config in corebrum project)
   zenohd --config /path/to/corebrum/docs/zenoh_configs/zenohd-filesystem.json5
   
   # Or RocksDB backend
   zenohd --config /path/to/corebrum/docs/zenoh_configs/zenohd-rocksdb.json5
   
   # Or InfluxDB backend
   zenohd --config /path/to/corebrum/docs/zenoh_configs/zenohd-influxdb.json5
   ```

2. **Start Corebrum Daemon**:
   ```bash
   corebrum daemon --zenoh-router tcp://localhost:7447
   ```

## Examples

### `store_and_retrieve.yaml`

Basic storage operations: store data and retrieve it.

```bash
corebrum submit --file task_definitions/storage/store_and_retrieve.yaml \
  --input '{"data": {"result": 42, "computation": "test"}, "key": "test1"}'
```

**Key Features:**
- Store JSON data in persistent storage
- Retrieve stored data by key
- Uses `corebrum/storage/results/` namespace

### `factorial_with_cache.yaml`

Persistent result caching: compute factorial with caching.

```bash
# First call - computes and caches
corebrum submit-and-wait --file task_definitions/storage/factorial_with_cache.yaml \
  --input '{"n": 10}'

# Second call - retrieves from cache
corebrum submit-and-wait --file task_definitions/storage/factorial_with_cache.yaml \
  --input '{"n": 10}'
```

**Key Features:**
- Checks persistent cache before computation
- Stores results in `corebrum/storage/cache/`
- Reduces redundant computations

## Storage Key Conventions

- `corebrum/storage/results/{key}` - Task results
- `corebrum/storage/cache/{category}/{key}` - Cached computations
- `corebrum/storage/datasets/{key}` - Datasets and model data
- `corebrum/storage/config/{key}` - Configuration data

## Using Storage in Tasks

All examples use Zenoh's native storage API:

```python
import zenoh
import json

session = zenoh.open()

# Store data
session.put("corebrum/storage/results/key1", json.dumps(data).encode())

# Retrieve data
reply = session.get("corebrum/storage/results/key1")
if reply:
    data = json.loads(reply.payload.decode())
```

For complete documentation, see the [Storage Backends Guide](https://github.com/corebrum/corebrum/blob/main/docs/storage-backends.md) in the Corebrum repository.

