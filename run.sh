#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-code"
CONTAINER_NAME="claude-code"

# Optional: pass a project path as first arg, otherwise use cwd
PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(realpath "$PROJECT_DIR")"

# Container runtime: honour CONTAINER_RUNTIME env var, otherwise auto-detect
if [ -n "${CONTAINER_RUNTIME:-}" ]; then
  RUNTIME="$CONTAINER_RUNTIME"
elif command -v podman &>/dev/null; then
  RUNTIME="podman"
elif command -v docker &>/dev/null; then
  RUNTIME="docker"
else
  echo "Error: neither podman nor docker found in PATH" >&2
  exit 1
fi

# Docker needs --add-host to expose host.docker.internal; podman has host.containers.internal natively
if [ "$RUNTIME" = "docker" ]; then
  IDE_HOST="host.docker.internal"
  EXTRA_ARGS="--add-host=host.docker.internal:host-gateway"
else
  IDE_HOST="host.containers.internal"
  EXTRA_ARGS=""
fi

mkdir -p "$HOME/.claude/ide"
[ -f "$HOME/.claude/.container-state.json" ] || echo '{}' > "$HOME/.claude/.container-state.json"

echo "Using runtime: $RUNTIME"

$RUNTIME run -it --rm \
  --name "$CONTAINER_NAME" \
  $EXTRA_ARGS \
  -v claude-code-config:/home/developer/.claude \
  -v "$HOME/.claude/.container-state.json":/home/developer/.claude.json \
  -v "$HOME/.claude/ide":/home/developer/.ide-host:ro \
  -e CLAUDE_CODE_IDE_HOST_OVERRIDE="$IDE_HOST" \
  -e CLAUDE_CODE_IDE_SKIP_VALID_CHECK=true \
  -v "$PROJECT_DIR":/workspace \
  -w /workspace \
  "$IMAGE" bash
