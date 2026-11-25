param(
    [string]$Project = (Get-Location).Path,
    [string]$ConfigPath = (Join-Path $HOME '.dsh\cordis.patch.yml'),
    [switch]$RemoveFiles
)

$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path -LiteralPath $Project).Path

if (Test-Path $ConfigPath) {
    Copy-Item $ConfigPath "$ConfigPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    $lines = Get-Content $ConfigPath
    $kept = New-Object System.Collections.Generic.List[string]
    $skipping = $false
    foreach ($line in $lines) {
        if ($line -match '^-\s+id:\s*mcp-structure-viewer\s*$') { $skipping = $true; continue }
        if ($skipping -and $line -match '^-\s+id:') { $skipping = $false }
        if (-not $skipping) { $kept.Add($line) }
    }
    $remaining = @($kept | Where-Object { $_.Trim() -ne '' })
    if ($remaining.Count -eq 0) { $remaining = @('[]') }
    Set-Content -Path $ConfigPath -Value $remaining -Encoding UTF8
    Write-Host "[ok] 已从 $ConfigPath 移除 mcp-structure-viewer（原文件已备份）"
}

if ($RemoveFiles) {
    foreach ($p in @((Join-Path $Project '.dsh\skills'), (Join-Path $Project '.dsh\mcp'), (Join-Path $Project '.dsh\biomolecular-viewer'))) {
        if (Test-Path $p) { Remove-Item $p -Recurse -Force; Write-Host "[ok] removed $p" }
    }
}

Write-Host "卸载完成。重启 DSH 后生效。"
