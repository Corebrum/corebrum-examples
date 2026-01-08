Claude Integration Guide for Corebrum

This file tells Claude Code how to understand, build, run, and test Corebrum applications using the Corebrum CLI and examples in this repository.
⸻
Project Context

Repository: corebrum-examples

Purpose: Example tasks, task definitions, CLI commands, and usage patterns for Corebrum — a mesh supercomputer platform for decentralized computing.

Claude should treat this directory as the authoritative source of:

- Corebrum architecture overview
- CLI commands and flag semantics
- Task definition formats (YAML / JSON)
- Completed examples for parallel, sequential, and streaming tasks
⸻
Corebrum CLI Overview

All CLI commands start with:

corebrum

Task Execution

Submit and control tasks:

corebrum submit --file <task.yaml> --input '<json>'
corebrum submit-and-wait --file <task.yaml> --input '<json>'
corebrum status
corebrum results
corebrum logs
corebrum cancel

Network and Workers

corebrum netstat
corebrum jobs
corebrum ping

CLI Helpers

corebrum help
corebrum --version

CMOS (Interactive Shell)

Launch the interactive Corebrum shell:

corebrum cmos

⸻Task Definitions Format

Tasks are defined in YAML or JSON.

Minimal Example (YAML)

name: "example-task"
language: "python"

source:
  inline:
    code: |
      def handler(input1):
          return input1 * 2

inputs:
  - name: "input1"
    type: "integer"
    required: true

outputs:
  - name: "output"
    type: "integer"

Key Fields

- name – unique task identifier
- language – execution runtime (python, javascript, docker, wasm, etc.)
- source – where code lives (inline, git, URL, Docker image, WASM)
- inputs / outputs – arguments and return values
- requirements – optional (CPU, memory, timeout)
⸻
Running Examples

Submit a Task (Non-Blocking)

corebrum submit \
  --file task_definitions/python/factorial_task.yaml \
  --input '{"number": 10}'

Submit and Wait (Blocking)

corebrum submit-and-wait \
  --file task_definitions/python/factorial_task.yaml \
  --input '{"number": 10}'

Get Results

corebrum results --format json

Watch Status

corebrum status --watch

⸻Typical Workflow

Start Local Mesh

Ensure the local mesh is running (Zenoh router and Corebrum daemon), then submit tasks.

zenohd
corebrum daemon --zenoh-router tcp://127.0.0.1:7447

⸻Goals for Claude Code

When instructed to create and run a Corebrum application, Claude should:

1. Read README.md and relevant examples
2. Copy or adapt an existing task definition
3. Modify inline code or inputs as needed
4. Submit the task using the Corebrum CLI
5. Prefer submit-and-wait for end-to-end workflows
6. Fetch and display results
7. Iterate until the task succeeds

Claude must not invent CLI flags or APIs.
⸻
Behavioral Rules for Claude

- submit → asynchronous
- submit-and-wait → synchronous
- status / results → monitoring and output retrieval
⸻
Completion Criteria

A Corebrum task is complete when:

- CLI exits with code 0
- corebrum results returns success
- Output values match expected schema
⸻
Claude should behave like a disciplined Corebrum developer — not a speculative code generator.