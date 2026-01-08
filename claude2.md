# CLAUDE.md — Corebrum Examples Workspace Guide

You are operating inside the `corebrum-examples` repository. This repo’s README is the authoritative “Getting Started Developer Guide” for Corebrum. Use it as the primary reference for commands, task formats, and workflow.  [oai_citation:2‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

## Prime Directives (must follow)

1. **Use documented Corebrum primitives only.** Prefer commands explicitly shown in this repo’s README (Corebrum CLI section) rather than inventing new flags or subcommands.  [oai_citation:3‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
2. **Run locally and iteratively.** When implementing an example, you should:
   - ensure Zenoh router is running (`zenohd`)
   - ensure Corebrum daemon/workers are running (`corebrum daemon`)
   - submit and validate the task via CLI
   - fetch logs/results and fix issues until it works
3. **Be conservative with changes.** Only modify files necessary for the requested feature/example. Keep changes minimal and well-scoped.
4. **Never assume hidden infrastructure.** If an example requires cloud auth, licenses, identity, or hive features, detect what’s available and degrade gracefully (e.g., run without identity unless asked).
5. **Prefer repeatable scripts.** If the user asks for an end-to-end demo, add a `run.sh` (or `run.ps1` on Windows) that starts what’s needed and runs the task.

---

## Corebrum “Primitives” You Must Use

### Network + runtime
- Zenoh router (local dev default):
  - Start: `zenohd` (default endpoint `tcp://127.0.0.1:7447`)  [oai_citation:4‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Corebrum daemon/workers:
  - Start: `corebrum daemon`  [oai_citation:5‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
  - Choose worker count: `corebrum daemon --worker-count 8`  [oai_citation:6‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
  - Choose capabilities: `corebrum daemon --capabilities "python,javascript,docker"`  [oai_citation:7‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
  - Choose router: `corebrum daemon --zenoh-router tcp://<router-ip>:7447`  [oai_citation:8‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

### Submission + waiting
- Submit a task definition:
  - `corebrum submit --file <task.yaml>`  [oai_citation:9‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
  - With inputs: `corebrum submit --file <task.yaml> --input '<json>'`  [oai_citation:10‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Submit and wait (preferred for examples):
  - `corebrum submit-and-wait --file <task.yaml> --input '<json>'`  [oai_citation:11‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

### Observe + debug
- Status:
  - `corebrum status <job_id>` and `corebrum status <job_id> --watch`  [oai_citation:12‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Logs:
  - `corebrum logs <job_id>`  [oai_citation:13‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Results:
  - `corebrum results <job_id>` (JSON)
  - `corebrum results <job_id> --format yaml`
  - `corebrum results <job_id> --output results.json`  [oai_citation:14‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Jobs list:
  - `corebrum jobs`  [oai_citation:15‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Cancel:
  - `corebrum cancel <job_id>`  [oai_citation:16‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

### Mesh introspection (useful for streaming + ROS2)
- Topics:
  - `corebrum topics`
  - `corebrum topics ros2`
  - `corebrum topics corebrum`  [oai_citation:17‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Streams:
  - `corebrum streams`  [oai_citation:18‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Publish/Subscribe:
  - `corebrum publish <topic> '<json>'`
  - `corebrum subscribe <topic>`  [oai_citation:19‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

### Health checks
- `corebrum netstat` (topology/workers)  [oai_citation:20‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- `corebrum compute-stats` (capacity)  [oai_citation:21‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- `corebrum ping <worker_id>`  [oai_citation:22‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

---

## Default Local Dev Workflow (the “golden path”)

When asked to create a new Corebrum-based application/example:

1. **Read the repo README and locate the closest existing example** to copy/extend.  [oai_citation:23‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
2. **Start Zenoh:**
   - `zenohd`  [oai_citation:24‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
3. **Start Corebrum daemon:**
   - `corebrum daemon --capabilities "python,javascript,docker"` (adjust to match the task)  [oai_citation:25‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
4. **Submit using `submit-and-wait`:**
   - `corebrum submit-and-wait --file <task.yaml> --input '<json>'`  [oai_citation:26‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
5. **If anything fails, debug in this order:**
   - `corebrum status <job_id> --watch`
   - `corebrum logs <job_id>`
   - `corebrum results <job_id>`  [oai_citation:27‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
6. **Document the example:**
   - Add an `examples/<name>/README.md` with:
     - prerequisites
     - exact commands to run (copy/paste)
     - expected output

---

## How to Build New “Corebrum Apps” in This Repo

A “Corebrum app” here should include:

- `task.yaml` (or similarly named) task definition file
- any code assets referenced by the task
- `README.md` with run instructions
- optional: `run.sh` (or `run.ps1`) to execute the end-to-end flow

### Inputs & outputs
- Inputs should be passed via `--input '<json>'` to keep the task reusable.  [oai_citation:28‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)
- Outputs should be retrieved via `corebrum results <job_id>` and shown in the example README.  [oai_citation:29‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

---

## Identity / Memory / Hives (only when requested)

Corebrum includes identity, memory, and hive primitives. If the user requests identity-based behavior, use:
- `corebrum identity create --name "My Robot"`
- `corebrum identity list`
- `corebrum identity set <id>`
- `corebrum identity enable <feature>`  [oai_citation:30‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

If identity features are unavailable (license/capability), clearly report the CLI error and offer a non-identity fallback.

---

## What you should do when uncertain

- **Search this repo first** for an existing task similar to the request.
- If a command/flag isn’t in the README, don’t guess. Instead:
  - search for it in the Corebrum CLI command sources path referenced by the README
  - or propose the closest documented workflow.  [oai_citation:31‡GitHub](https://raw.githubusercontent.com/Corebrum/corebrum-examples/refs/heads/master/README.md)

---

## Output expectations

When you finish implementing something, provide:

1. What files changed/added
2. The exact commands to run (Zenoh + daemon + submit-and-wait)
3. How to inspect status/logs/results
4. Expected output snippet or description