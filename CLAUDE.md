# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a Docker workshop/lab repository for teaching Docker fundamentals to systems analysts. It is structured as a progressive, 4-step hands-on lab. The language of all educational materials is Russian.

## Commands

All demos are driven from the root-level `Makefile`. Run `make help` to see the full list.

### Stage 1 — Build
```bash
make build          # docker build for the backend image (docker-lab/orders-api)
make status         # docker images + docker ps
make run            # docker run the backend
make run-more       # run a second instance on a different port
make clean          # stop and remove containers/images
```

### Stage 2 — Compose
```bash
make compose-up     # docker compose up -d (steps/step_2_control/description/)
make logs           # docker logs
make monitor        # docker inspect / top / stats
make compose-down   # docker compose down
```

### Stage 3 — Mounts
```bash
make example-no-mount   # run without any mount (data lost on restart)
make example-mount      # run with bind mount
make example-volume     # run with Docker volume
make example-down       # stop mount example
```

### Stage 4 — Networks
```bash
make net-no-network  # frontend + backend, no shared network
make net-ports       # communicate via exposed port on the host
make net-network     # both containers in a shared bridge network (correct way)
make net-down        # stop network example
```

## Architecture

### Backend (`steps/step_1_build/description/backend/`)
- Python 3.11 + Flask + Gunicorn
- Serves a simple Orders REST API (`/health`, `/orders`)
- Uses SQLite at `./data/orders.db`; auto-seeds 3 rows on first run
- Listens on port **8080** inside the container
- Built into image `docker-lab/orders-api:latest`

### Frontend (`steps/step_4_network/description/frontend/`, also in `steps/step_3_mount/description/mount/`)
- Node.js Express app
- Listens on port **3000** inside the container
- Reads `BACKEND_HOST` and `BACKEND_PORT` env vars to locate the backend

### Step structure
Each of the four steps follows the same pattern:
- `description/` — teacher demo material (Dockerfiles, compose files, README theory)
- `execution/` — blank workspace where students complete their assignment (README with tasks)

### Ports used by demos
| Target | Host port |
|--------|-----------|
| Backend (step 1 & 2) | 8081 |
| Frontend / mount example | 3001 |

### Other directories
- `examples/nginx/`, `examples/rabbitmq/` — standalone compose examples
- `docs/cheatsheet.md` — Docker command reference (Russian)
- `docs/answers/` — teacher-only answer keys
- `docs/docker-advanced/` — advanced Dockerfile optimization scripts/examples
- `tools/telegram-bot/` — Python Telegram bot (`python-telegram-bot 20.7`) used to push lab announcements; requires a `.env` with bot token

### Makefile conventions
- `YELLOW` text = instructions/hints shown to students
- `GREEN` text = the Docker command being executed
- Plain text = command output
- `check_port` macro guards each demo target; if the required host port is already in use, it prints a diagnostic and exits before running `docker compose up`
