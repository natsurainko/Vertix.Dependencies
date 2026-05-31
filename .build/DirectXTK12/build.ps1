param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "DirectXTK12"

. "$PSScriptRoot\..\vs-env.ps1"
. "$PSScriptRoot\..\common.ps1"

if ($SkipDownload) {
    Write-Error "DirectXTK12 builds from a freshly downloaded source archive. -SkipDownload is not supported."
    exit 1
}

Write-BuildLog "INF" $LogCtx "Fetching latest DirectXTK12 release..."
$release = Get-LatestRelease -Repo "microsoft/DirectXTK12"
$tag = $release.tag_name
$releaseTitle = $release.name
Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

$cacheDir = "$ScriptDir\.cache"
$null = New-Item -ItemType Directory -Force -Path $cacheDir
$zipPath = "$cacheDir\directxtk12-source.zip"
$extractPath = "$cacheDir\directxtk12-extract"

Write-BuildLog "INF" $LogCtx "Downloading source archive..."
Invoke-WebRequest -Uri $release.zipball_url -OutFile $zipPath -UseBasicParsing

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$sourceRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
$sourceRoot = $sourceRoot.FullName

$projectFile = $null
if (Test-Path "$sourceRoot\DirectXTK_Desktop_2026.slnx") {
    $projectFile = "DirectXTK_Desktop_2026.slnx"
} elseif (Test-Path "$sourceRoot\DirectXTK_Desktop_2022_Win10.sln") {
    $projectFile = "DirectXTK_Desktop_2022_Win10.sln"
} elseif (Test-Path "$sourceRoot\DirectXTK_Desktop_2026.vcxproj") {
    $projectFile = "DirectXTK_Desktop_2026.vcxproj"
} else {
    Write-Error "Could not find a DirectXTK Desktop solution or project file."
    exit 1
}
Write-BuildLog "INF" $LogCtx "Building: $projectFile"

Write-BuildLog "INF" $LogCtx "Building Release..."
& msbuild "$sourceRoot\$projectFile" /p:Configuration=Release /p:Platform=x64 /t:Build /m
if ($LASTEXITCODE -ne 0) { Write-Error "Release build failed"; exit 1 }

Write-BuildLog "INF" $LogCtx "Building Debug..."
& msbuild "$sourceRoot\$projectFile" /p:Configuration=Debug /p:Platform=x64 /t:Build /m
if ($LASTEXITCODE -ne 0) { Write-Error "Debug build failed"; exit 1 }

$includeDir = Clear-Includes -Name "DirectXTK12"
Write-BuildLog "INF" $LogCtx "Copying headers from Inc/ to $includeDir..."
Copy-Item "$sourceRoot\Inc\*" "$includeDir\" -Force

$libSourceDir = "$sourceRoot\Bin\Desktop_2026\x64"
Copy-Libs -SourceDir $libSourceDir -LibName "DirectXTK12.lib" -RepoRoot $RepoRoot

$licenseDir = Clear-Licenses -Name "DirectXTK12"

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

Write-BuildLog "INF" $LogCtx "Done! DirectXTK12 $tag build complete."
