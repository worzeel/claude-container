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

## Known issues

### Windows + Podman: network connectivity problems

When running on Windows with Podman, the container may fail to reach the JetBrains IDE on the
host (`host.containers.internal` times out or refuses connections). The root cause is not fully
pinned down yet, but there are two leading suspects:

1. **WSL2 ↔ Windows host networking** — Podman on Windows runs inside a WSL2 VM. The virtual
   network adapter between WSL2 and the Windows host can be flaky, especially after sleep/wake
   cycles or when Windows Defender Firewall blocks traffic crossing the virtual NIC.
2. **Podman network backend / DNS settings** — Certain Podman configurations (CNI vs. Netavark
   backend, the DNS resolver inside the VM, or how `host.containers.internal` is resolved) may
   not work correctly out of the box on some Windows setups.

**Symptoms**

- Container starts fine but Claude Code cannot connect to the IDE (connection refused / timeout).
- `CLAUDE_CODE_IDE_HOST_OVERRIDE` is set to `host.containers.internal` but traffic never reaches
  the plugin.
- Sometimes works after a full Podman machine restart (`podman machine stop` then
  `podman machine start`), but not reliably.

**Things to try**

- Verify `host.containers.internal` resolves from inside the container:
  ```powershell
  podman exec claude-code ping host.containers.internal
  ```
- Check Windows Defender Firewall rules for the WSL virtual NIC (`vEthernet (WSL)`).
- Try passing a static IP for the Podman WSL2 VM directly:
  ```powershell
  # Find the WSL2 VM IP
  wsl hostname -I
  # Then override in run.ps1
  $env:CLAUDE_CODE_IDE_HOST_OVERRIDE = "<wsl-ip>"
  ```
- Switch the Podman network backend (CNI → Netavark or vice versa) via
  `podman system reset` after changing the backend in `~/.config/containers/containers.conf`.
- Try `podman machine set --rootful` — rootful mode sometimes has better host-routing support.
- Note: `--network=host` inside Podman on WSL2 binds to the WSL2 VM's network, **not** the
  Windows host network, so it does not help here.

If you find a reliable fix, please open an issue or PR with the details so this section can be
updated.
