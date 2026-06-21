[CmdletBinding()]
param(
    [string]$GameRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [IO.Path]::GetFullPath($PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Split-Path -Parent $projectRoot
}
$gameRootPath = [IO.Path]::GetFullPath($GameRoot)
$repak = Join-Path $projectRoot 'tools\repak\repak.exe'
$repakArchive = Join-Path $projectRoot 'tools\repak_cli-v0.2.3-windows-x64.zip'
$stockPak = Join-Path $gameRootPath 'SwGame\Content\Paks\pakchunk0-WindowsNoEditor.pak'
$sourceRoot = Join-Path $projectRoot 'source\stock-patch9'
$buildRoot = Join-Path $projectRoot 'build'
$distRoot = Join-Path $projectRoot 'dist'

$expectedArchiveHash = '6720d602144d75df477a99d5bedb6ea780997546afc335901d4937cafeaa73fa'
$expectedExeHash = 'fcd538e5994b9bb833622d425ae346f4e0692f02d4b0025114a559f9b6286022'
$repakUrl = 'https://github.com/trumank/repak/releases/download/v0.2.3/repak_cli-x86_64-pc-windows-msvc.zip'
$utf8NoBom = New-Object Text.UTF8Encoding($false)

$presets = [ordered]@{
    Performance = @{
        MemoryHeadroom = 1152
        RetentionHeadroom = 1280
        MinimumPool = 1024
        MeshPool = 384
        MipBias = 2
        MaxScreenSize = 1440
        TexturesPerFrame = 2
        Anisotropy = 4
    }
    Balanced = @{
        MemoryHeadroom = 896
        RetentionHeadroom = 1024
        MinimumPool = 1280
        MeshPool = 512
        MipBias = 1
        MaxScreenSize = 1600
        TexturesPerFrame = 4
        Anisotropy = 8
    }
    Quality = @{
        MemoryHeadroom = 768
        RetentionHeadroom = 896
        MinimumPool = 1536
        MeshPool = 512
        MipBias = 1
        MaxScreenSize = 1920
        TexturesPerFrame = 4
        Anisotropy = 8
    }
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Expected
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file is missing: $Path"
    }

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected) {
        throw "SHA-256 mismatch for $Path. Expected $Expected, got $actual."
    }
}

function Assert-ChildPath {
    param(
        [Parameter(Mandatory)][string]$Parent,
        [Parameter(Mandatory)][string]$Child
    )

    $parentPath = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childPath = [IO.Path]::GetFullPath($Child)
    if (-not $childPath.StartsWith($parentPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside $Parent`: $Child"
    }
}

function Reset-Directory {
    param([Parameter(Mandatory)][string]$Path)

    Assert-ChildPath -Parent $projectRoot -Child $Path
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Ensure-Repak {
    $repakDirectory = Split-Path -Parent $repak
    New-Item -ItemType Directory -Path (Split-Path -Parent $repakArchive) -Force | Out-Null

    if (-not (Test-Path -LiteralPath $repak -PathType Leaf)) {
        if (-not (Test-Path -LiteralPath $repakArchive -PathType Leaf)) {
            Write-Host "Downloading repak v0.2.3 from $repakUrl"
            Invoke-WebRequest -UseBasicParsing $repakUrl -OutFile $repakArchive
        }

        Assert-FileHash -Path $repakArchive -Expected $expectedArchiveHash
        if (Test-Path -LiteralPath $repakDirectory) {
            Assert-ChildPath -Parent $projectRoot -Child $repakDirectory
            Remove-Item -LiteralPath $repakDirectory -Recurse -Force
        }
        Expand-Archive -LiteralPath $repakArchive -DestinationPath $repakDirectory -Force
    }

    Assert-FileHash -Path $repakArchive -Expected $expectedArchiveHash
    Assert-FileHash -Path $repak -Expected $expectedExeHash
}
function Write-Utf8File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    [IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-PakEntryText {
    param(
        [Parameter(Mandatory)][string]$Pak,
        [Parameter(Mandatory)][string]$Entry
    )

    $lines = & $repak get $Pak $Entry
    if ($LASTEXITCODE -ne 0) {
        throw "repak failed to extract $Entry from $Pak"
    }
    return (($lines -join "`n").TrimEnd("`r", "`n") + "`n")
}

function Get-TextureLimit {
    param(
        [Parameter(Mandatory)][string]$Group,
        [Parameter(Mandatory)][string]$Preset
    )

    $preserve = @(
        'TEXTUREGROUP_UI',
        'TEXTUREGROUP_Lightmap',
        'TEXTUREGROUP_RenderTarget',
        'TEXTUREGROUP_Shadowmap',
        'TEXTUREGROUP_ColorLookupTable',
        'TEXTUREGROUP_Bokeh',
        'TEXTUREGROUP_IESLightProfile',
        'TEXTUREGROUP_Pixels2D',
        'TEXTUREGROUP_ProcBuilding_LightMap'
    )
    if ($preserve -contains $Group) {
        return $null
    }

    if ($Group -eq 'TEXTUREGROUP_Skybox') {
        return 2048
    }

    if ($Group -match '^TEXTUREGROUP_Project\d+$') {
        if ($Preset -eq 'Performance') { return 1024 }
        return 2048
    }

    if ($Preset -eq 'Performance') {
        if ($Group -match 'Specular$') { return 512 }
        if ($Group -eq 'TEXTUREGROUP_Terrain_Weightmap') { return 512 }
        if ($Group -match '^(TEXTUREGROUP_(World|WorldNormalMap|Character|CharacterNormalMap|Weapon|WeaponNormalMap|Vehicle|VehicleNormalMap|Cinematic|Effects|EffectsNotFiltered|MobileFlattened|ProcBuilding_Face|Terrain_Heightmap|HierarchicalLOD))$') {
            return 1024
        }
        return $null
    }

    if ($Preset -eq 'Balanced') {
        if ($Group -match '(NormalMap|Specular)$') { return 1024 }
        if ($Group -eq 'TEXTUREGROUP_Terrain_Weightmap') { return 1024 }
        if ($Group -match '^(TEXTUREGROUP_(World|Character|Weapon|Vehicle|Cinematic|Effects|EffectsNotFiltered|MobileFlattened|ProcBuilding_Face|Terrain_Heightmap|HierarchicalLOD))$') {
            return 2048
        }
        return $null
    }

    if ($Group -match 'Specular$') { return 1024 }
    if ($Group -match '^(TEXTUREGROUP_(World|WorldNormalMap|Character|CharacterNormalMap|Weapon|WeaponNormalMap|Vehicle|VehicleNormalMap|Cinematic|Effects|EffectsNotFiltered|MobileFlattened|ProcBuilding_Face|Terrain_Heightmap|Terrain_Weightmap|HierarchicalLOD))$') {
        return 2048
    }
    return $null
}

function Set-LodLimit {
    param(
        [Parameter(Mandatory)][string]$Line,
        [Parameter(Mandatory)][int]$Limit
    )

    $maxMatch = [regex]::Match($Line, '(?<!Optional)MaxLODSize=(\d+)')
    if ($maxMatch.Success -and [int]$maxMatch.Groups[1].Value -gt $Limit) {
        $Line = [regex]::Replace(
            $Line,
            '(?<!Optional)MaxLODSize=\d+',
            "MaxLODSize=$Limit",
            1
        )
    }

    $optionalMatch = [regex]::Match($Line, 'OptionalMaxLODSize=(\d+)')
    if ($optionalMatch.Success -and [int]$optionalMatch.Groups[1].Value -gt $Limit) {
        $Line = [regex]::Replace(
            $Line,
            'OptionalMaxLODSize=\d+',
            "OptionalMaxLODSize=$Limit",
            1
        )
    }
    return $Line
}

function New-DeviceProfiles {
    param(
        [Parameter(Mandatory)][string]$StockText,
        [Parameter(Mandatory)][string]$Preset,
        [Parameter(Mandatory)][hashtable]$Settings
    )

    $sectionPattern = '(?ms)^\[WindowsNoEditor DeviceProfile\]\r?\n.*?(?=^\[|\z)'
    $match = [regex]::Match($StockText, $sectionPattern)
    if (-not $match.Success) {
        throw 'The stock WindowsNoEditor DeviceProfile section was not found.'
    }

    $managedCvars = @(
        'r.Streaming.PoolSize',
        'D3D12.DynamicTexturePoolSize',
        'D3D12.AdjustTexturePoolSizeBasedOnBudget',
        'r.Streaming.MemoryTargetHeadroomMb',
        'r.Streaming.RetentionTargetHeadroomMb',
        'r.Streaming.MinimumPoolSize',
        'r.Streaming.PoolSizeForMeshes',
        'r.Streaming.UsePerTextureBias',
        'respawn.Streaming.MipBiasOnlyTextures',
        'r.Streaming.LimitPoolSizeToVRAM',
        'r.Streaming.MaxEffectiveScreenSize',
        'respawn.Streaming.MaxScreenSize',
        'r.Streaming.AmortizeCPUToGPUCopy',
        'r.Streaming.MaxNumTexturesToStreamPerFrame',
        'r.Streaming.MinMipForSplitRequest'
    )

    $sectionLines = $match.Value.TrimEnd("`r", "`n") -split '\r?\n'
    $result = New-Object Collections.Generic.List[string]
    $inserted = $false

    foreach ($line in $sectionLines) {
        $cvarMatch = [regex]::Match($line, '^\+CVars=([^=]+)=')
        if ($cvarMatch.Success -and $managedCvars -contains $cvarMatch.Groups[1].Value) {
            continue
        }

        if (-not $inserted -and $line.StartsWith('+TextureLODGroups=', [StringComparison]::Ordinal)) {
            $result.Add("+CVars=r.Streaming.PoolSize=3000")
            $result.Add("+CVars=D3D12.DynamicTexturePoolSize=1")
            $result.Add("+CVars=D3D12.AdjustTexturePoolSizeBasedOnBudget=1")
            $result.Add("+CVars=r.Streaming.MemoryTargetHeadroomMb=$($Settings.MemoryHeadroom)")
            $result.Add("+CVars=r.Streaming.RetentionTargetHeadroomMb=$($Settings.RetentionHeadroom)")
            $result.Add("+CVars=r.Streaming.MinimumPoolSize=$($Settings.MinimumPool)")
            $result.Add("+CVars=r.Streaming.PoolSizeForMeshes=$($Settings.MeshPool)")
            $result.Add("+CVars=r.Streaming.UsePerTextureBias=1")
            $result.Add("+CVars=respawn.Streaming.MipBiasOnlyTextures=1")
            $result.Add("+CVars=r.Streaming.LimitPoolSizeToVRAM=1")
            $result.Add("+CVars=r.Streaming.MaxEffectiveScreenSize=$($Settings.MaxScreenSize)")
            $result.Add("+CVars=respawn.Streaming.MaxScreenSize=$($Settings.MaxScreenSize)")
            $result.Add("+CVars=r.Streaming.AmortizeCPUToGPUCopy=1")
            $result.Add("+CVars=r.Streaming.MaxNumTexturesToStreamPerFrame=$($Settings.TexturesPerFrame)")
            $result.Add("+CVars=r.Streaming.MinMipForSplitRequest=1")
            $inserted = $true
        }

        $groupMatch = [regex]::Match($line, '^\+TextureLODGroups=\(Group=([^,\s]+)')
        if ($groupMatch.Success) {
            $limit = Get-TextureLimit -Group $groupMatch.Groups[1].Value -Preset $Preset
            if ($null -ne $limit) {
                $line = Set-LodLimit -Line $line -Limit $limit
            }
        }
        $result.Add($line)
    }

    if (-not $inserted) {
        throw 'The stock Windows profile did not contain TextureLODGroups.'
    }

    $newSection = ($result -join "`n") + "`n"
    return [regex]::Replace(
        $StockText,
        $sectionPattern,
        [Text.RegularExpressions.MatchEvaluator]{ param($unused) $newSection },
        1
    ).Replace("`r`n", "`n")
}

function New-Scalability {
    param(
        [Parameter(Mandatory)][string]$StockText,
        [Parameter(Mandatory)][hashtable]$Settings
    )

    $withoutTextureTiers = [regex]::Replace(
        $StockText.Replace("`r`n", "`n"),
        '(?ms)^\[TextureQuality@[0-3]\]\n.*?(?=^\[|\z)',
        ''
    ).TrimEnd()

    $tiers = New-Object Collections.Generic.List[string]
    foreach ($tier in 0..3) {
        $tiers.Add(@"
[TextureQuality@$tier]
r.Streaming.MipBias=$($Settings.MipBias)
r.Streaming.UsePerTextureBias=1
r.Streaming.AmortizeCPUToGPUCopy=1
r.Streaming.MaxNumTexturesToStreamPerFrame=$($Settings.TexturesPerFrame)
r.Streaming.Boost=1
r.MaxAnisotropy=$($Settings.Anisotropy)
r.VT.MaxAnisotropy=$($Settings.Anisotropy)
r.Streaming.LimitPoolSizeToVRAM=1
r.Streaming.MaxEffectiveScreenSize=$($Settings.MaxScreenSize)
"@.Trim())
    }

    return ($withoutTextureTiers + "`n`n" + ($tiers -join "`n`n") + "`n").Replace("`r`n", "`n").Replace("`r", "`n")
}

Ensure-Repak
if (-not (Test-Path -LiteralPath $stockPak -PathType Leaf)) {
    throw "Stock Patch 9 PAK was not found: $stockPak"
}

Reset-Directory -Path $sourceRoot
Reset-Directory -Path $buildRoot
Reset-Directory -Path $distRoot

$stockDeviceProfiles = Get-PakEntryText -Pak $stockPak -Entry 'SwGame/Config/DefaultDeviceProfiles.ini'
$stockScalability = Get-PakEntryText -Pak $stockPak -Entry 'SwGame/Config/DefaultScalability.ini'
Write-Utf8File -Path (Join-Path $sourceRoot 'DefaultDeviceProfiles.ini') -Content $stockDeviceProfiles
Write-Utf8File -Path (Join-Path $sourceRoot 'DefaultScalability.ini') -Content $stockScalability

$manifestPresets = [ordered]@{}
foreach ($presetEntry in $presets.GetEnumerator()) {
    $preset = $presetEntry.Key
    $settings = $presetEntry.Value
    $presetRoot = Join-Path $buildRoot $preset
    $configRoot = Join-Path $presetRoot 'SwGame\Config'
    New-Item -ItemType Directory -Path $configRoot -Force | Out-Null

    $deviceProfiles = New-DeviceProfiles -StockText $stockDeviceProfiles -Preset $preset -Settings $settings
    $scalability = New-Scalability -StockText $stockScalability -Settings $settings
    $devicePath = Join-Path $configRoot 'DefaultDeviceProfiles.ini'
    $scalabilityPath = Join-Path $configRoot 'DefaultScalability.ini'
    Write-Utf8File -Path $devicePath -Content $deviceProfiles
    Write-Utf8File -Path $scalabilityPath -Content $scalability

    $pakName = "zz_JS4GB_${preset}_P9.pak"
    $pakPath = Join-Path $distRoot $pakName
    & $repak pack --version V11 $presetRoot $pakPath
    if ($LASTEXITCODE -ne 0) {
        throw "repak failed while building $pakName"
    }

    $entries = @(& $repak list $pakPath)
    $expectedEntries = @(
        'SwGame/Config/DefaultDeviceProfiles.ini',
        'SwGame/Config/DefaultScalability.ini'
    )
    if (@(Compare-Object $expectedEntries $entries).Count -ne 0) {
        throw "$pakName contains unexpected files: $($entries -join ', ')"
    }

    $packedDeviceProfiles = Get-PakEntryText -Pak $pakPath -Entry $expectedEntries[0]
    $packedScalability = Get-PakEntryText -Pak $pakPath -Entry $expectedEntries[1]
    if ($packedDeviceProfiles -ne $deviceProfiles -or $packedScalability -ne $scalability) {
        throw "Round-trip verification failed for $pakName"
    }

    $manifestPresets[$preset] = [ordered]@{
        file = $pakName
        sha256 = (Get-FileHash -LiteralPath $pakPath -Algorithm SHA256).Hash.ToLowerInvariant()
        settings = $settings
    }
}

$manifest = [ordered]@{
    name = 'Jedi Survivor 4 GB Texture Fix'
    target = 'PC Patch 9 / RX 6400-class 4 GB VRAM / 1080p'
    stockPak = 'pakchunk0-WindowsNoEditor.pak'
    repakVersion = '0.2.3'
    repakArchiveSha256 = $expectedArchiveHash
    repakExeSha256 = $expectedExeHash
    presets = $manifestPresets
}
Write-Utf8File -Path (Join-Path $distRoot 'manifest.json') -Content (($manifest | ConvertTo-Json -Depth 8) + "`n")

$checksumLines = foreach ($preset in $manifestPresets.GetEnumerator()) {
    "$($preset.Value.sha256)  $($preset.Value.file)"
}
Write-Utf8File -Path (Join-Path $distRoot 'checksums.sha256') -Content (($checksumLines -join "`n") + "`n")

Write-Host ''
Write-Host 'Built and verified:'
Get-ChildItem -LiteralPath $distRoot -Filter '*.pak' |
    Select-Object Name, Length, @{ Name = 'SHA256'; Expression = { (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } } |
    Format-Table -AutoSize



