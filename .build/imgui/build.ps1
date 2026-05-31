param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "imgui"

. "$PSScriptRoot\..\vs-env.ps1"
. "$PSScriptRoot\..\common.ps1"

Write-BuildLog "INF" $LogCtx "Parsing CMakeLists.txt for source files..."
$cmakeContent = Get-Content "$ScriptDir\CMakeLists.txt" -Raw
$pattern = '(?m)^\s+(include/\S+|src/\S+)'
$filePaths = [regex]::Matches($cmakeContent, $pattern) | ForEach-Object { $_.Groups[1].Value }
Write-BuildLog "INF" $LogCtx "Found $($filePaths.Count) source files."

if (-not $SkipDownload) {
    Write-BuildLog "INF" $LogCtx "Fetching latest imgui release..."
    $release = Get-LatestRelease -Repo "ocornut/imgui"
    $tag = $release.tag_name
    $releaseTitle = $release.name
    Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

    $cacheDir = "$ScriptDir\.cache"
    $null = New-Item -ItemType Directory -Force -Path $cacheDir
    $zipPath = "$cacheDir\imgui-source.zip"
    $extractPath = "$cacheDir\imgui-extract"

    Write-BuildLog "INF" $LogCtx "Downloading source archive..."
    Invoke-WebRequest -Uri $release.zipball_url -OutFile $zipPath -UseBasicParsing

    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    $sourceRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    $sourceRoot = $sourceRoot.FullName

    Write-BuildLog "INF" $LogCtx "Staging source files..."
    foreach ($filePath in $filePaths) {
        $repoFilename = $filePath -replace '^(include|src)/', ''
        $sourceFile = "$sourceRoot\$repoFilename"
        $destFile = "$ScriptDir\$filePath"

        if (Test-Path $sourceFile) {
            $destDir = Split-Path $destFile -Parent
            if (-not (Test-Path $destDir)) { $null = New-Item -ItemType Directory -Force -Path $destDir }
            Copy-Item $sourceFile $destFile -Force
        } else {
            Write-BuildLog "WRN" $LogCtx "File not found in source archive: $repoFilename"
        }
    }

    $licenseDir = Clear-Licenses -Name "imgui"
    $licenseFiles = @("LICENSE.txt", "README.md")
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
} else {
    Write-BuildLog "INF" $LogCtx "Skipping download, using existing source files..."
}

$includeDir = Clear-Includes -Name "imgui"
Copy-Item "$ScriptDir\include\*" "$includeDir\" -Recurse -Force

$buildDir = "$ScriptDir\cmake-build"

Write-BuildLog "INF" $LogCtx "Configuring CMake..."
& cmake "-S" $ScriptDir "-B" $buildDir "-G" $vsGenerator "-A" "x64"
if ($LASTEXITCODE -ne 0) { Write-Error "CMake configure failed"; exit 1 }

Write-BuildLog "INF" $LogCtx "Building Release..."
& cmake --build $buildDir --config Release
if ($LASTEXITCODE -ne 0) { Write-Error "Release build failed"; exit 1 }

Write-BuildLog "INF" $LogCtx "Building Debug..."
& cmake --build $buildDir --config Debug
if ($LASTEXITCODE -ne 0) { Write-Error "Debug build failed"; exit 1 }

Copy-Libs -SourceDir $buildDir -LibName "imgui_library.lib" -RenameTo "imgui.lib" -RepoRoot $RepoRoot

Write-BuildLog "INF" $LogCtx "Cleaning up staged source files..."
Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
    if ($_.Name -ne ".idea") {
        Remove-Item $_.FullName -Recurse -Force
    }
}

Write-BuildLog "INF" $LogCtx "Done! imgui $tag build complete."
