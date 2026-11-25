param(
    [string]$Project = (Get-Location).Path,
    [int]$Port = 7793
)

$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path -LiteralPath $Project).Path
$mcpDir = Join-Path $Project '.dsh\mcp\biomolecular_structure_viewer'
$server = Join-Path $mcpDir 'dist\server.cjs'

if (-not (Test-Path $server)) {
    Write-Error "未找到 $server。请先运行 scripts\install.ps1 安装 MCP。"
    exit 1
}

$stateRoot = Join-Path $Project '.dsh\biomolecular-viewer'
$structures = Join-Path $stateRoot 'brain\dsh'
New-Item -ItemType Directory -Force -Path $structures | Out-Null

$env:ANTIGRAVITY_SIDECAR_WEB_PORT    = "$Port"
$env:ANTIGRAVITY_CONVERSATION_ID     = 'dsh'
$env:ANTIGRAVITY_APP_DATA_DIR        = $stateRoot
$env:ANTIGRAVITY_EXECUTABLE_DATA_DIR = $stateRoot

Write-Host "Viewer   : http://127.0.0.1:$Port/?conversationId=dsh"
Write-Host "结构目录 : $structures"
Write-Host "按 Ctrl+C 停止。"
node $server
