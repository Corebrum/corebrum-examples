# Corebrum demo cheat sheet

Commands are written for a **Corebrum CLI** built or installed from a sibling checkout (`../corebrum`), with example task files in this repo (`../corebrum-examples/…`).

**Path layout after the core vs. cortex split:**

| Area | Directory in this repo |
|------|-------------------------|
| General mesh tasks (Python, JS, ROS2, sequential, Omnagi, etc.) | `task_definitions/` |
| Cortex (identity, memory, hive, OpenClaw) | `cortex/task_definitions/` |

Replace `tcp://192.168.0.145:7447` with your Zenoh router address. From the **examples repo root**, you can use relative paths like `task_definitions/python/...` instead of `../corebrum-examples/...`.

---

## Zenoh router

```bash
zenohd
# or, with a config file:
~/zenohd --config router.json5
```

## Daemon + CLI (from `../corebrum`)

```bash
cargo run -- --zenoh-router tcp://192.168.0.145:7447 daemon 1

cargo run -- --zenoh-router tcp://192.168.0.145:7447 submit-and-wait \
  --file ../corebrum-examples/task_definitions/python/factorial_from_url.yaml \
  --input '{"number": 8}'

cargo run -- --zenoh-router tcp://192.168.0.145:7447 results <task_id>
```

## CMOS

```bash
cargo run -- cmos
./corebrum cmos
```

Inside CMOS, paths are relative to your current working directory (often the `corebrum` tree). Examples:

```text
submit ../corebrum-examples/task_definitions/python/factorial_from_url.yaml --input '{"number": 8}'
submit-and-wait ../corebrum-examples/task_definitions/python/factorial_from_url.yaml --input '{"number": 8}'
```

```text
submit ../corebrum-examples/task_definitions/python/factorial_stdin_stdout.yaml --input '{"n": 8}'
```

### Submit from URL (e.g. GitHub Gist)

```bash
corebrum submit --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e --input '{"number": 8}'
# shorthand (if your CLI supports URL-as-file):
submit https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e --input '{"number": 8}'

corebrum submit --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e \
  --input '{"number": 8}' --capability python

corebrum submit-and-wait --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e \
  --input '{"number": 8}' --capability python
```

### Raw script URL

```bash
corebrum submit --file https://raw.githubusercontent.com/user/repo/main/script.py \
  --input '{"data": "value"}' --capability python
```

### Local YAML examples

```bash
corebrum submit --file ../corebrum-examples/task_definitions/ros2/ros2_message_type_demo.yaml

# From this repo’s root:
corebrum submit --file ../corebrum-examples/task_definitions/python/pi_calculation.yaml --input '{"decimal_places": 10}'
```

## JavaScript

```bash
corebrum submit --file ../corebrum-examples/task_definitions/javascript/factorial_from_url.yaml --input '{"number": 8}'
corebrum submit --file ../corebrum-examples/task_definitions/javascript/pi_calculation.yaml --input '{"decimal_places": 10}'
```

## Status and results

```bash
corebrum status
corebrum results <task-id>
```

## Sequential pipelines

**CMOS** (adjust path if your cwd differs):

```text
../corebrum-examples/task_definitions/sequential/sequential_pipeline.yaml
../corebrum-examples/task_definitions/sequential/sequential_ai_pipeline.yaml
../corebrum-examples/task_definitions/sequential/sequential_data_transform.yaml
```

**CLI:**

```bash
corebrum submit --file ../corebrum-examples/task_definitions/sequential/sequential_pipeline.yaml
```

```bash
corebrum results <task-id> --chain
```

## ROS2 + CMOS

```text
topics ros2
../corebrum-examples/task_definitions/ros2/object_detection.yaml
streams
```

Publish twist (CMOS):

```text
publish rt/cmd_vel '{"linear": {"x": 0.5, "y": 0.0, "z": 0.0}, "angular": {"x": 0.0, "y": 0.0, "z": 0.2}}'
```

**zenoh CLI** (stop / forward / turn):

```bash
zenoh --mode client --connect tcp://192.168.0.145:7447 put -k 'rt/cmd_vel' \
  -v '{"linear": {"x": 0.0, "y": 0.0, "z": 0.0}, "angular": {"x": 0.0, "y": 0.0, "z": 0.0}}'

zenoh --mode client --connect tcp://192.168.0.145:7447 put -k 'rt/cmd_vel' \
  -v '{"linear": {"x": 0.5, "y": 0.0, "z": 0.0}, "angular": {"x": 0.0, "y": 0.0, "z": 0.0}}'

zenoh --mode client --connect tcp://192.168.0.145:7447 put -k 'rt/cmd_vel' \
  -v '{"linear": {"x": 0.0, "y": 0.0, "z": 0.0}, "angular": {"x": 0.0, "y": 0.0, "z": 0.5}}'
```

**corebrum publish:**

```bash
corebrum publish rt/cmd_vel '{"linear":{"x":0,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0}}'
corebrum publish rt/cmd_vel '{"linear":{"x":0.5,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0}}'
corebrum publish rt/cmd_vel '{"linear":{"x":0,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0.5}}'
```

## Streams testing

```bash
# Use tcp:// (not tcp/) for Zenoh router URLs
submit ../corebrum-examples/task_definitions/ros2/person_follow_simple.yaml --zenoh-router tcp://192.168.0.145:7447

cargo run --bin corebrum -- streams --zenoh-router tcp://192.168.0.145:7447
./corebrum streams --zenoh-router tcp://192.168.0.145:7447

cargo run --bin corebrum -- cancel <task_uuid> --zenoh-router tcp://192.168.0.145:7447
./corebrum cancel <task_uuid> --zenoh-router tcp://192.168.0.145:7447
```

## Network topology

```bash
./corebrum --zenoh-router tcp://192.168.0.145:7447 network
```

## REST API

```bash
cargo run -- web
./corebrum web
```

Example URLs (replace task id):

- `http://localhost:6502/api/status/<task-id>`
- `http://localhost:6502/api/results/<task-id>`

**Web UI “submit” paths (this repo):**

- Task file: `task_definitions/python/factorial_from_url.yaml`
- Input: `{"number": 8}`
- Or Gist URL: `https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e` with the same input JSON

## Omnagi (local LLM)

Workers need `python` and `omnagi` capabilities. Example task:

```bash
./corebrum submit ../corebrum-examples/task_definitions/omnagi/qwen_llm_streaming.yaml
```

## Cortex: task/stream memory and identity

```bash
corebrum identity enable <key_id> memory
corebrum identity enable <key_id> hive
corebrum identity enable <key_id> ancestor_access
corebrum identity disable <key_id> memory
```

Example:

```text
identity enable 9f5ae164-4c3b-4c8a-9a83-fc7587b5f96a memory
```

Submit **Cortex** examples (note `cortex/task_definitions/…`):

```bash
submit ../corebrum-examples/cortex/task_definitions/identity/task_with_identity.yaml \
  --identity 9f5ae164-4c3b-4c8a-9a83-fc7587b5f96a

submit ../corebrum-examples/cortex/task_definitions/identity/memory_persistence.yaml \
  --identity 9f5ae164-4c3b-4c8a-9a83-fc7587b5f96a --input '{"value": 5}'
```

*(Older copies of this sheet used `task_definitions/identity/…` — those files now live only under `cortex/task_definitions/identity/`.)*

## OpenClaw

```bash
open-claw bridge start
corebrum submit --file ../corebrum-examples/cortex/task_definitions/openclaw/openclaw-test.json
```

*(OpenClaw task JSON is under `cortex/task_definitions/openclaw/`, not `task_definitions/openclaw/`.)*
