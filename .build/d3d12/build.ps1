param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "d3d12"

. "$PSScriptRoot\..\common.ps1"

if ($SkipDownload) {
    Write-Error "d3d12 always downloads fresh. -SkipDownload is not supported."
    exit 1
}

Write-BuildLog "INF" $LogCtx "Fetching latest DirectX-Headers release..."
$release = Get-LatestRelease -Repo "microsoft/DirectX-Headers"
$tag = $release.tag_name
$releaseTitle = $release.name
Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

$cacheDir = "$ScriptDir\.cache"
$null = New-Item -ItemType Directory -Force -Path $cacheDir
$zipPath = "$cacheDir\d3d12-source.zip"
$extractPath = "$cacheDir\d3d12-extract"

Write-BuildLog "INF" $LogCtx "Downloading source archive..."
Invoke-WebRequest -Uri $release.zipball_url -OutFile $zipPath -UseBasicParsing

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$sourceRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
$sourceRoot = $sourceRoot.FullName

$includeDir = Clear-Includes -Name "d3d12"
Write-BuildLog "INF" $LogCtx "Copying include/directx/ to $includeDir..."
Copy-Item "$sourceRoot\include\directx\*" "$includeDir\" -Force

# Fix uninitialized desc variables in d3dx12_core.h
$coreHeader = "$includeDir\d3dx12_core.h"
if (Test-Path $coreHeader) {
    Write-BuildLog "INF" $LogCtx "Patching uninitialized desc variables in d3dx12_core.h..."
    $content = Get-Content $coreHeader -Raw
    $content = $content.Replace("CD3DX12_SHADER_RESOURCE_VIEW_DESC desc;", "CD3DX12_SHADER_RESOURCE_VIEW_DESC desc = {};")
    $content = $content.Replace("CD3DX12_UNORDERED_ACCESS_VIEW_DESC desc;", "CD3DX12_UNORDERED_ACCESS_VIEW_DESC desc = {};")
    Set-Content $coreHeader -Value $content -NoNewline
}

$licenseDir = Clear-Licenses -Name "d3d12"

$licenseFiles = @("LICENSE", "README.md", "SECURITY.md")
foreach ($file in $licenseFiles) {
    if (Test-Path "$sourceRoot\$file") {
        Copy-Item "$sourceRoot\$file" "$licenseDir\$file" -Force
    } else {
        Write-BuildLog "WRN" $LogCtx "License file not found in source: $file"
    }
}

New-LicenseMarker -LicenseDir $licenseDir -ReleaseTitle $releaseTitle

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $cacheDir -Recurse -Force -ErrorAction SilentlyContinue

Write-BuildLog "INF" $LogCtx "Done! d3d12 $tag copied."
