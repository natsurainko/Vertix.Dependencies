param(
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot = Resolve-Path "$ScriptDir\..\.."
$LogCtx = "simdjson"

. "$PSScriptRoot\..\vs-env.ps1"
. "$PSScriptRoot\..\common.ps1"

Write-BuildLog "INF" $LogCtx "Parsing CMakeLists.txt for source files..."
$cmakeContent = Get-Content "$ScriptDir\CMakeLists.txt" -Raw
$pattern = '(?m)^\s+(\S+\.(?:h|cpp|cxx|c|hpp|inl))\s*$'
$fileNames = [regex]::Matches($cmakeContent, $pattern) | ForEach-Object { $_.Groups[1].Value }
Write-BuildLog "INF" $LogCtx "Found $($fileNames.Count) source files: $($fileNames -join ', ')"

if (-not $SkipDownload) {
    Write-BuildLog "INF" $LogCtx "Fetching latest simdjson release..."
    $release = Get-LatestRelease -Repo "simdjson/simdjson"
    $tag = $release.tag_name
    $releaseTitle = $release.name
    Write-BuildLog "INF" $LogCtx "Found: $releaseTitle (tag: $tag)"

    foreach ($fileName in $fileNames) {
        $asset = $release.assets | Where-Object { $_.name -eq $fileName }
        if (-not $asset) {
            Write-Error "Could not find '$fileName' in the release assets."
            exit 1
        }
        Write-BuildLog "INF" $LogCtx "Downloading $fileName..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$ScriptDir\$fileName" -UseBasicParsing
    }
} else {
    Write-BuildLog "INF" $LogCtx "Skipping download, using existing source files..."
}

$includeDir = Clear-Includes -Name "simdjson"
Copy-Item "$ScriptDir\simdjson.h" "$includeDir\simdjson.h" -Force

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

Copy-Libs -SourceDir $buildDir -LibName "simdjson.lib" -RepoRoot $RepoRoot

$licenseDir = "$RepoRoot\licenses\simdjson"
$null = New-Item -ItemType Directory -Force -Path $licenseDir
New-LicenseMarker -LicenseDir $licenseDir -ReleaseTitle $releaseTitle

Write-BuildLog "INF" $LogCtx "Cleaning up staged source files..."
Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
    if ($_.Name -ne ".idea") {
        Remove-Item $_.FullName -Recurse -Force
    }
}
Get-ChildItem -Path $ScriptDir -File | ForEach-Object {
    if ($_.Name -notin @("build.ps1", "CMakeLists.txt")) {
        Remove-Item $_.FullName -Force
    }
}

Write-BuildLog "INF" $LogCtx "Done! simdjson $tag build complete."
