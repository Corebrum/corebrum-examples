# JavaScript / Node.js Task Examples

This directory contains Corebrum task definitions that run **JavaScript (Node.js)** code on workers. They mirror the [Python examples](../python/) so you can run the same kinds of tasks in either language.

## Overview

- Workers run your code with **Node.js** (`node` must be on the worker PATH).
- Tasks receive an injected `inputs` object (from the submission JSON).
- Your code must set a `result` variable; Corebrum wraps it and prints `JSON.stringify(result)` to stdout for capture.

## Prerequisites

- Corebrum daemon and workers started with **javascript** capability, e.g.:
  ```bash
  corebrum daemon --zenoh-router tcp://127.0.0.1:7447
  # When using CMOS: start-workers, then choose "javascript" when prompted for capabilities
  ```
- `node` installed on worker machines (typically Node 16+).

## Examples

### 1. Factorial (from URL-style name) — `factorial_from_url.yaml`

Computes factorial of `number` and returns result plus timing.

```bash
corebrum submit --file task_definitions/javascript/factorial_from_url.yaml --input '{"number": 8}'
```

### 2. Factorial (stdin/stdout style) — `factorial_stdin_stdout.yaml`

Same idea with input key `n`.

```bash
corebrum submit --file task_definitions/javascript/factorial_stdin_stdout.yaml --input '{"n": 10}'
```

### 3. Pi calculation — `pi_calculation.yaml`

Uses `Math.PI` and rounds to `decimal_places`.

```bash
corebrum submit --file task_definitions/javascript/pi_calculation.yaml --input '{"decimal_places": 10}'
```

### 4. JavaScript with dependencies — `javascript_with_dependencies.yaml`

Declares `dependencies: ["javascript"]` for worker matching; code is still inline (no npm packages in this example).

```bash
corebrum submit --file task_definitions/javascript/javascript_with_dependencies.yaml --input '{"number": 6}'
```

## Checking results

```bash
corebrum results <task-id>
# or
corebrum status <task-id>
```

## Comparison with Python

| Python (../python/)              | JavaScript (this dir)                    |
|----------------------------------|------------------------------------------|
| `language: "python"`             | `language: "javascript"`                 |
| `inputs.get("key", default)`     | `inputs.key` or `inputs['key']`          |
| `print(json.dumps(result))`      | Set `result`; wrapper does JSON.stringify|
| `dependencies: ["python"]`       | `dependencies: ["javascript"]`            |

## Notes

- Task names are suffixed (e.g. `factorial_from_url_js`, `pi_calculation_js`) to avoid clashes with Python task names when both are loaded.
- For npm dependencies, use the `dependencies` field in the task definition; workers will run `npm install` in the task directory before executing your script.
