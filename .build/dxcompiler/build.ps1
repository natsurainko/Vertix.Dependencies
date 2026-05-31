param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "dxcompiler"

. "$PSScriptRoot\..\common.ps1"

if ($SkipDownload) {
    Write-Error "dxcompiler always downloads fresh. -SkipDownload is not supported."
    exit 1
}

Write-BuildLog "INF" $LogCtx "Fetching latest DirectXShaderCompiler release..."
$release = Get-LatestRelease -Repo "microsoft/DirectXShaderCompiler"
$tag = $release.tag_name
$releaseTitle = $release.name
Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

$zipAsset = $release.assets | Where-Object { $_.name -match '^dxc_.*\.zip$' } | Select-Object -First 1
if (-not $zipAsset) {
    Write-Error "Could not find dxc_*.zip in the release assets."
    exit 1
}
Write-BuildLog "INF" $LogCtx "Found asset: $($zipAsset.name)"

$cacheDir = "$ScriptDir\.cache"
$null = New-Item -ItemType Directory -Force -Path $cacheDir
$zipPath = "$cacheDir\dxc-release.zip"
$extractPath = "$cacheDir\dxc-extract"

Write-BuildLog "INF" $LogCtx "Downloading $($zipAsset.name)..."
Invoke-WebRequest -Uri $zipAsset.browser_download_url -OutFile $zipPath -UseBasicParsing

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$includeDir = Clear-Includes -Name "dxcompiler"
Write-BuildLog "INF" $LogCtx "Copying inc/ to $includeDir..."
Copy-Item "$extractPath\inc\*" "$includeDir\" -Recurse -Force

$libDir = "$RepoRoot\libraries"
$null = New-Item -ItemType Directory -Force -Path $libDir

Write-BuildLog "INF" $LogCtx "Copying libs to $libDir..."
Copy-Item "$extractPath\lib\x64\dxcompiler.lib" "$libDir\dxcompiler.lib" -Force
Copy-Item "$extractPath\lib\x64\dxil.lib" "$libDir\dxil.lib" -Force

Write-BuildLog "INF" $LogCtx "Copying DLLs to $libDir..."
Copy-Item "$extractPath\bin\x64\dxcompiler.dll" "$libDir\dxcompiler.dll" -Force
Copy-Item "$extractPath\bin\x64\dxil.dll" "$libDir\dxil.dll" -Force

$licenseDir = Clear-Licenses -Name "dxcompiler"

$licenseFiles = @("LICENSE-LLVM.txt", "LICENSE-MIT.txt", "LICENSE-MS.txt", "ReleaseNotes.md")
foreach ($file in $licenseFiles) {
    if (Test-Path "$extractPath\$file") {
        Copy-Item "$extractPath\$file" "$licenseDir\$file" -Force
    } else {
        Write-BuildLog "WRN" $LogCtx "License file not found in archive: $file"
    }
}

New-LicenseMarker -LicenseDir $licenseDir -ReleaseTitle $releaseTitle

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $cacheDir -Recurse -Force -ErrorAction SilentlyContinue

Write-BuildLog "INF" $LogCtx "Done! dxcompiler $tag copied."
