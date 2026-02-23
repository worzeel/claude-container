# Claude Code Container

Container image with Claude Code CLI pre-installed, with JetBrains IDE integration support.
Works with both Podman and Docker.

## How the JetBrains integration works

The JetBrains Claude plugin writes a lockfile to `~/.claude/ide/<port>.lock` containing the port,
auth token, and workspace info. Claude Code polls that directory to discover and connect to IDEs.

In a container:
1. `~/.claude/ide/` is bind mounted from host (read-only) so Claude Code sees the lockfile
2. `CLAUDE_CODE_IDE_HOST_OVERRIDE` redirects connections to the host machine instead of `127.0.0.1`
3. A wrapper script patches the lockfile PID so Claude Code doesn't treat it as stale and delete it

## Requirements

- Podman or Docker
- JetBrains IDE with the Claude Code plugin installed
- In your JetBrains IDE: Settings → Tools → Claude Code → enable **"Use Auth With All Interfaces"**
  (makes the plugin bind to `0.0.0.0` instead of `127.0.0.1` so the container can reach it)

## Setup

### 1. Build the image

```bash
# Podman
podman build -t claude-code .

# Docker
docker build -t claude-code .
```

### 2. Run

```bash
# From your project directory
./run.sh

# Or pass a project path explicitly
./run.sh ~/projects/my-app
```

The script auto-detects Podman or Docker. Override with:
```bash
CONTAINER_RUNTIME=docker ./run.sh
CONTAINER_RUNTIME=podman ./run.sh
```

### 3. First-time setup

On first run, complete the Claude Code onboarding (theme picker etc.) and login:
```bash
claude login
```

Both are persisted across container runs — you won't be asked again.

### 4. Use Claude Code

```bash
claude
```

Claude Code will auto-discover the running JetBrains IDE and offer to connect to it.

## What persists between runs

| What | How |
|---|---|
| Auth / login | `claude-code-config` named volume at `~/.claude` |
| Onboarding / settings | `~/.claude/.container-state.json` bind mounted to `~/.claude.json` |
| IDE lockfiles | `~/.claude/ide/` bind mounted read-only to `~/.ide-host/` |
