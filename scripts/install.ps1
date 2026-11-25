<#
.SYNOPSIS
  安装 DSH Science Skills Pack（50 个技能 + Biomolecular Structure Viewer MCP）。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Project D:\my-project
#>
param(
    [string]$Project = (Get-Location).Path,
    [string]$ConfigPath = (Join-Path $HOME '.dsh\cordis.patch.yml'),
    [switch]$SkipMcp,
    [switch]$SkipSkills
)

$ErrorActionPreference = 'Stop'
$packRoot = Split-Path -Parent $PSScriptRoot
$Project = (Resolve-Path -LiteralPath $Project).Path
$dshDir = Join-Path $Project '.dsh'
$stateRoot = Join-Path $dshDir 'biomolecular-viewer'

Write-Host "== DSH Science Skills Pack 1.0.0 =="
Write-Host "Project : $Project"
Write-Host "Pack    : $packRoot"
Write-Host ""

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Warning "node 不在 PATH 中：MCP 与 3D 查看器将无法启动。请先安装 Node.js 后重跑。"
}

if (-not $SkipSkills) {
    $src = Join-Path $packRoot 'skills'
    $dst = Join-Path $dshDir 'skills'
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item (Join-Path $src '*') $dst -Recurse -Force
    $count = (Get-ChildItem $dst -Directory).Count
    Write-Host "[ok] skills  -> $dst ($count 个技能)"
}

if (-not $SkipMcp) {
    $mcpDir = Join-Path $dshDir 'mcp\biomolecular_structure_viewer'
    $mcpParent = Split-Path $mcpDir -Parent
    New-Item -ItemType Directory -Force -Path $mcpParent | Out-Null
    if (Test-Path $mcpDir) { Remove-Item $mcpDir -Recurse -Force }
    Copy-Item (Join-Path $packRoot 'mcp\biomolecular_structure_viewer') $mcpDir -Recurse -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $stateRoot 'brain\dsh') | Out-Null
    Write-Host "[ok] mcp     -> $mcpDir"
    Write-Host "[ok] state   -> $stateRoot"

    $dataDir = Join-Path $stateRoot 'brain\dsh\scratch\sidecars\structural-biology\biomolecular_structure_viewer'
    $entry = @"
- id: mcp-structure-viewer
  name: "@deepseek-ai/dsh-mcp-client"
  config:
    serverName: structure_viewer
    transport: stdio
    command: node
    args:
      - '$((Join-Path $mcpDir 'dist\mcp_entry.cjs').Replace('\','/'))'
    cwd: '$($Project.Replace('\','/'))'
    env:
      BIOMOLECULAR_VIEWER_DATA_DIR: '$($dataDir.Replace('\','/'))'
    toolCallTimeoutMs: 120000
"@

    $cfgDir = Split-Path $ConfigPath -Parent
    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null

    if (Test-Path $ConfigPath) {
        $content = Get-Content $ConfigPath -Raw
        if ($content -match 'mcp-structure-viewer') {
            Write-Host "[skip] $ConfigPath 已包含 mcp-structure-viewer"
        } else {
            Copy-Item $ConfigPath "$ConfigPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
            if ($content.Trim() -eq '[]') {
                Set-Content -Path $ConfigPath -Value $entry -Encoding UTF8
            } else {
                Add-Content -Path $ConfigPath -Value $entry -Encoding UTF8
            }
            Write-Host "[ok] config  -> $ConfigPath (已备份原文件)"
        }
    } else {
        Set-Content -Path $ConfigPath -Value $entry -Encoding UTF8
        Write-Host "[ok] config  -> $ConfigPath (新建)"
    }
}

Write-Host ""
Write-Host "下一步："
Write-Host "  1) 完全退出并重启 DSH 桌面端（配置在启动时加载）"
Write-Host "  2) 新会话里说：列出结构查看器有哪些工具"
Write-Host "  3) 启动 3D 查看器：powershell -File $($packRoot)\scripts\start-viewer.ps1 -Project $Project"
Write-Host "  4) 浏览器打开：http://127.0.0.1:7793/?conversationId=dsh"
Write-Host ""
Write-Host "结构文件请放到：$(Join-Path $stateRoot 'brain\dsh')"
