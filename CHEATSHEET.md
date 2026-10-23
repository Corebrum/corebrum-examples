# Corebrum demo cheat sheet

Commands are written for a **Corebrum CLI** built or installed from a sibling checkout (`../cortex`), with example task files in this repo (`../corebrum-examples/…`).

**Path layout after the core vs. cortex split:**

| Area | Directory in this repo |
|------|-------------------------|
| General mesh tasks (Python, JS, ROS2, sequential, Omnagi, etc.) | `task_definitions/` |
| Cortex (identity, memory, hive, OpenClaw) | `cortex/task_definitions/` |

Replace `tcp://192.168.0.145:7447` with your Zenoh router address (from `npx zenoh-fleet`, that is `tcp://<hub>:7447`). From the **examples repo root**, you can use relative paths like `task_definitions/python/...` instead of `../corebrum-examples/...`.

---

## Zenoh router

```bash
npx zenoh-fleet                      # hub JSON5 for a laptop+robots mesh
zenohd -c /path/to/<fleet>/zenohd.json5
# local only:
zenohd
# or, with a config file:
~/zenohd --config router.json5
```

## Daemon + CLI (from `../cortex`)

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
./cortex cmos
```

Inside CMOS, paths are relative to your current working directory (often the `cortex` tree). Examples:

```text
submit ../corebrum-examples/task_definitions/python/factorial_from_url.yaml --input '{"number": 8}'
submit-and-wait ../corebrum-examples/task_definitions/python/factorial_from_url.yaml --input '{"number": 8}'
```

```text
submit ../corebrum-examples/task_definitions/python/factorial_stdin_stdout.yaml --input '{"n": 8}'
```

### Submit from URL (e.g. GitHub Gist)

```bash
cortex submit --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e --input '{"number": 8}'
# shorthand (if your CLI supports URL-as-file):
submit https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e --input '{"number": 8}'

cortex submit --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e \
  --input '{"number": 8}' --capability python

cortex submit-and-wait --file https://gist.github.com/chrismatthieu/e06cdd5c6c3787d7e68e2c6977d81e9e \
  --input '{"number": 8}' --capability python
```

### Raw script URL

```bash
cortex submit --file https://raw.githubusercontent.com/user/repo/main/script.py \
  --input '{"data": "value"}' --capability python
```

### Local YAML examples

```bash
cortex submit --file ../corebrum-examples/task_definitions/ros2/ros2_message_type_demo.yaml

# From this repo’s root:
cortex submit --file ../corebrum-examples/task_definitions/python/pi_calculation.yaml --input '{"decimal_places": 10}'
```

## JavaScript

```bash
cortex submit --file ../corebrum-examples/task_definitions/javascript/factorial_from_url.yaml --input '{"number": 8}'
cortex submit --file ../corebrum-examples/task_definitions/javascript/pi_calculation.yaml --input '{"decimal_places": 10}'
```

## Status and results

```bash
cortex status
cortex results <task-id>
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
cortex submit --file ../corebrum-examples/task_definitions/sequential/sequential_pipeline.yaml
```

```bash
cortex results <task-id> --chain
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

**cortex publish:**

```bash
cortex publish rt/cmd_vel '{"linear":{"x":0,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0}}'
cortex publish rt/cmd_vel '{"linear":{"x":0.5,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0}}'
cortex publish rt/cmd_vel '{"linear":{"x":0,"y":0,"z":0},"angular":{"x":0,"y":0,"z":0.5}}'
```

## Streams testing

```bash
# Use tcp:// (not tcp/) for Zenoh router URLs
submit ../corebrum-examples/task_definitions/ros2/person_follow_simple.yaml --zenoh-router tcp://192.168.0.145:7447

cargo run --bin cortex -- streams --zenoh-router tcp://192.168.0.145:7447
./cortex streams --zenoh-router tcp://192.168.0.145:7447

cargo run --bin cortex -- cancel <task_uuid> --zenoh-router tcp://192.168.0.145:7447
./cortex cancel <task_uuid> --zenoh-router tcp://192.168.0.145:7447
```

## Network topology

```bash
./cortex --zenoh-router tcp://192.168.0.145:7447 network
```

## REST API

```bash
cargo run -- web
./cortex web
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
./cortex submit ../corebrum-examples/task_definitions/omnagi/qwen_llm_streaming.yaml
```

## Cortex: task/stream memory and identity

```bash
cortex identity enable <key_id> memory
cortex identity enable <key_id> hive
cortex identity enable <key_id> ancestor_access
cortex identity disable <key_id> memory
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
open-claw bridge-start --identity-id 08585eb1-0aa1-42b6-9792-de23ce452e3a
cortex submit --file ../corebrum-examples/cortex/task_definitions/openclaw/openclaw-test.json
```

*(OpenClaw task JSON is under `cortex/task_definitions/openclaw/`, not `task_definitions/openclaw/`.)*
