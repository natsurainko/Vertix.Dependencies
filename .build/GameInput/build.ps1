param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "GameInput"

. "$PSScriptRoot\..\common.ps1"

if ($SkipDownload) {
    Write-Error "GameInput always downloads fresh. -SkipDownload is not supported."
    exit 1
}

Write-BuildLog "INF" $LogCtx "Fetching latest GameInput release..."
$release = Get-LatestRelease -Repo "microsoftconnect/GameInput"
$tag = $release.tag_name
$releaseTitle = $release.name
Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

$cacheDir = "$ScriptDir\.cache"
$null = New-Item -ItemType Directory -Force -Path $cacheDir
$zipPath = "$cacheDir\gameinput-source.zip"
$extractPath = "$cacheDir\gameinput-extract"

Write-BuildLog "INF" $LogCtx "Downloading source archive..."
Invoke-WebRequest -Uri $release.zipball_url -OutFile $zipPath -UseBasicParsing

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$sourceRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
$sourceRoot = $sourceRoot.FullName

$includeDir = Clear-Includes -Name "GameInput"
Write-BuildLog "INF" $LogCtx "Copying GameInput.h to $includeDir..."
Copy-Item "$sourceRoot\include\GameInput.h" "$includeDir\GameInput.h" -Force

$libDir = "$RepoRoot\libraries"
$null = New-Item -ItemType Directory -Force -Path $libDir
Write-BuildLog "INF" $LogCtx "Copying GameInput.lib to $libDir..."
Copy-Item "$sourceRoot\lib\x64\GameInput.lib" "$libDir\GameInput.lib" -Force

$licenseDir = Clear-Licenses -Name "GameInput"

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

Write-BuildLog "INF" $LogCtx "Done! GameInput $tag copied."
