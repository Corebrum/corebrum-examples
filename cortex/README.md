# Corebrum Cortex examples

Task bundles under [`task_definitions/`](task_definitions/) assume **Corebrum Cortex** is running next to Corebrum (`cortex serve`, or your installed Cortex binary), with authentication and license state aligned with the main docs.

## Layout

| Directory | Topic |
|-----------|--------|
| [`task_definitions/identity/`](task_definitions/identity/) | Tasks submitted with identity context |
| [`task_definitions/memory/`](task_definitions/memory/) | Memory APIs (search, limits, caching) |
| [`task_definitions/hive/`](task_definitions/hive/) | Hive shared knowledge |
| [`task_definitions/openclaw/`](task_definitions/openclaw/) | OpenClaw workspace bridge |

From the repository root, paths are prefixed with `cortex/`:

```bash
corebrum submit --file cortex/task_definitions/openclaw/openclaw-test.json
```

Conceptual overview: root [`README.md`](../README.md), section **Corebrum Cortex: Identity, Memory, and Hiveminds**.
