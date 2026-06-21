[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Performance', 'Balanced', 'Quality', 'Off')]
    [string]$Preset,

    [string]$GameRoot,

    [switch]$DisableConflictingFixes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Split-Path -Parent ([IO.Path]::GetFullPath($PSScriptRoot))
}
$gameRootPath = [IO.Path]::GetFullPath($GameRoot)
$paksDirectory = [IO.Path]::GetFullPath((Join-Path $gameRootPath 'SwGame\Content\Paks'))
$distDirectory = Join-Path $PSScriptRoot 'dist'
$ownPattern = 'zz_JS4GB_*_P9.pak'
$presetFiles = @{
    Performance = 'zz_JS4GB_Performance_P9.pak'
    Balanced = 'zz_JS4GB_Balanced_P9.pak'
    Quality = 'zz_JS4GB_Quality_P9.pak'
}
$conflictPatterns = @(
    'z_targetheadroom*.pak',
    'z_improved_meshes.pak',
    'z_increasedpool*.pak'
)

if (-not (Test-Path -LiteralPath $paksDirectory -PathType Container)) {
    throw "Jedi Survivor PAK directory was not found: $paksDirectory"
}

$conflicts = @(
    @(
        foreach ($pattern in $conflictPatterns) {
            Get-ChildItem -LiteralPath $paksDirectory -Filter $pattern -File -ErrorAction SilentlyContinue
        }
    ) | Sort-Object FullName -Unique
)

if ($Preset -ne 'Off' -and $conflicts.Count -gt 0) {
    if (-not $DisableConflictingFixes) {
        $names = ($conflicts.Name -join ', ')
        throw "Conflicting texture fix PAKs are installed: $names. Remove them or rerun with -DisableConflictingFixes."
    }

    foreach ($conflict in $conflicts) {
        $disabledPath = $conflict.FullName + '.disabled-by-js4gb'
        if ($PSCmdlet.ShouldProcess($conflict.FullName, "Rename to $disabledPath")) {
            Move-Item -LiteralPath $conflict.FullName -Destination $disabledPath
        }
    }
}

$installedPresets = @(Get-ChildItem -LiteralPath $paksDirectory -Filter $ownPattern -File -ErrorAction SilentlyContinue)
foreach ($installed in $installedPresets) {
    if ($PSCmdlet.ShouldProcess($installed.FullName, 'Remove installed Jedi Survivor 4 GB preset')) {
        Remove-Item -LiteralPath $installed.FullName -Force
    }
}

if ($Preset -eq 'Off') {
    Write-Host 'Jedi Survivor 4 GB Texture Fix is disabled.'
    exit 0
}

$sourcePak = Join-Path $distDirectory $presetFiles[$Preset]
if (-not (Test-Path -LiteralPath $sourcePak -PathType Leaf)) {
    throw "Preset has not been built: $sourcePak"
}

$manifestPath = Join-Path $distDirectory 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Build manifest is missing: $manifestPath"
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$expectedHash = $manifest.presets.$Preset.sha256
$sourceHash = (Get-FileHash -LiteralPath $sourcePak -Algorithm SHA256).Hash.ToLowerInvariant()
if ($sourceHash -ne $expectedHash) {
    throw "Preset checksum mismatch. Expected $expectedHash, got $sourceHash."
}

$destinationPak = Join-Path $paksDirectory $presetFiles[$Preset]
if ($PSCmdlet.ShouldProcess($destinationPak, "Install $Preset preset")) {
    Copy-Item -LiteralPath $sourcePak -Destination $destinationPak
}

$installedHash = (Get-FileHash -LiteralPath $destinationPak -Algorithm SHA256).Hash.ToLowerInvariant()
if ($installedHash -ne $expectedHash) {
    throw "Installed preset failed checksum verification."
}

Write-Host "$Preset preset installed and verified."
Write-Host 'Use 1920x1080, ray tracing off, and FSR Quality initially.'
if ($Preset -eq 'Balanced') {
    Write-Host 'Change FSR to Balanced if demanding Koboh areas remain below 30 FPS.'
}
