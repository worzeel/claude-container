#Requires -Version 5.1
[CmdletBinding()]
param(
    # Optional project path - defaults to current directory
    [string]$ProjectDir = (Get-Location).Path,

    # Override container runtime: 'docker' or 'podman'
    [string]$Runtime = $env:CONTAINER_RUNTIME
)

$ErrorActionPreference = 'Stop'

$Image         = "claude-code"
$ContainerName = "claude-code"
$ProjectDir    = (Resolve-Path $ProjectDir).Path

# Auto-detect runtime if not specified
if (-not $Runtime) {
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        $Runtime = "podman"
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        $Runtime = "docker"
    } else {
        Write-Error "Neither podman nor docker found in PATH"
        exit 1
    }
}

# Docker needs --add-host for host.docker.internal; podman has host.containers.internal natively
if ($Runtime -eq "docker") {
    $IdeHost   = "host.docker.internal"
    $ExtraArgs = @("--add-host=host.docker.internal:host-gateway")
} else {
    $IdeHost   = "host.containers.internal"
    $ExtraArgs = @()
}

# Ensure host state dirs/files exist
$ClaudeDir     = Join-Path $env:USERPROFILE ".claude"
$IdeDir        = Join-Path $ClaudeDir "ide"
$StateFile     = Join-Path $ClaudeDir ".container-state.json"

New-Item -ItemType Directory -Force -Path $IdeDir | Out-Null
if (-not (Test-Path $StateFile)) {
    Set-Content -Path $StateFile -Value '{}'
}

Write-Host "Using runtime: $Runtime"

& $Runtime run -it --rm `
    --name $ContainerName `
    @ExtraArgs `
    -v "claude-code-config:/home/developer/.claude" `
    -v "${StateFile}:/home/developer/.claude.json" `
    -v "${IdeDir}:/home/developer/.ide-host:ro" `
    -e "CLAUDE_CODE_IDE_HOST_OVERRIDE=$IdeHost" `
    -e "CLAUDE_CODE_IDE_SKIP_VALID_CHECK=true" `
    -v "${ProjectDir}:/workspace" `
    -w /workspace `
    $Image bash
