# Fleet GPU mesh examples

Tasks and scripts for verifying **CUDA worker placement** across a peered Zenoh mesh (Thor, Orin, etc.).

## Tasks

| File | Purpose |
|------|---------|
| `gpu_worker_probe.yaml` | Smoke test: hostname, `CUDA_VISIBLE_DEVICES`, optional `nvidia-smi` + small PyTorch CUDA check |
| `gpu_mesh_load_balance.yaml` | Heavier FP16 matmul on GPU (requires `torch` on workers) |

## Script

From the **examples repo root**:

```bash
chmod +x scripts/test_gpu_mesh.sh

# Router MUST match CMOS / daemon (hub is often NOT 127.0.0.1 on fleet meshes)
CORTEX_BIN=/home/nvidia/corebrum-cortex/target/release/cortex \
  ZENOH_ROUTER=tcp://192.168.8.196:7447 \
  JOBS=4 PARALLEL=0 \
  ./scripts/test_gpu_mesh.sh

# Parallel submits (queue on few GPU workers)
JOBS=8 PARALLEL=1 ./scripts/test_gpu_mesh.sh

# Matmul benchmark jobs (needs PyTorch on GPU workers)
HEAVY=1 JOBS=2 PARALLEL=0 ./scripts/test_gpu_mesh.sh
```

The script prints live `submit-and-wait` progress and errors if no local `cortex daemon` is running.

## CMOS

```text
submit-and-wait ../corebrum-examples/cortex/task_definitions/fleet/gpu_worker_probe.yaml
```

## Requirements

1. **GPU-aware cortex binary** — CMOS `start-workers` with Enter on capabilities (auto CPU + GPU), or `cortex daemon` without `--worker-count` on GPU robots.
2. **One daemon process** per robot — if `start-workers` says daemon already running, run `stop-workers` and `pkill -f 'cortex daemon'`, then start again so workers use the latest build.
3. Routers peered so workers on all machines appear in `compute-stats`.
4. Probe tasks use `dependencies: [cuda, gpu]` — they will **not** run on CPU-only workers. These names are **placement tags**, not pip packages.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Empty `Jobs per hostname`, script hangs on job 1 | Set `ZENOH_ROUTER` to the same URL as the daemon; ensure a daemon is running on a GPU host |
| `ok 1` then hang on job 2+ | Restart daemon on latest cortex (scheduler assigns job payload on assign); use `PARALLEL=0` with one GPU worker |
| No `gpu_line` in results | Auto-hardware off or CPU-only workers — restart daemon with auto layout |
| `torch_note` only | Normal without PyTorch on the worker; `nvidia-smi` fields still validate CUDA placement |

Cortex-side details: `docs/gpu-fleet.md` in the [corebrum-cortex](https://github.com/corebrum/corebrum-cortex) repo.
