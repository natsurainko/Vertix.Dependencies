# Dot-source this script to initialize the Visual Studio developer environment.
# Exposes: $vsGenerator (e.g. "Visual Studio 17 2022"), $vsPath
#
# Usage: . "$PSScriptRoot\..\vs-env.ps1"

$vsYearMap = @{ "17" = "2022"; "18" = "2026"; "19" = "2028" }

$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vsWhere)) {
    $vsWhere = "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
}

if (-not (Test-Path $vsWhere)) {
    Write-Error "vswhere.exe not found. Is Visual Studio installed?"
    exit 1
}

$vsPath = & $vsWhere -latest -property installationPath 2>$null
if (-not $vsPath) {
    Write-Error "Could not locate Visual Studio installation."
    exit 1
}

Write-Host "Found Visual Studio at: $vsPath" -ForegroundColor Green

$vsVersion = & $vsWhere -latest -property installationVersion 2>$null
$vsMajor = $null
$vsYear = $null
if ($vsVersion -match "^(\d+)\.") {
    $vsMajor = $Matches[1]
    $vsYear = $vsYearMap[$vsMajor]
}

if (-not $vsMajor -or -not $vsYear) {
    Write-Host "Could not determine VS version, falling back to VS 2022..." -ForegroundColor Yellow
    $vsMajor = "17"
    $vsYear = "2022"
}

$vsGenerator = "Visual Studio $vsMajor $vsYear"
Write-Host "Using generator: $vsGenerator" -ForegroundColor Cyan

# Import VS developer environment so cmake, msbuild, cl, etc. are available
$devShellModule = "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
if (Test-Path $devShellModule) {
    Import-Module $devShellModule -Force -ErrorAction Stop
    Enter-VsDevShell -VsInstallPath $vsPath -DevCmdArguments "-arch=amd64" -SkipAutomaticLocation
    Write-Host "VS developer environment initialized." -ForegroundColor Green
} else {
    Write-Warning "DevShell module not found, hoping build tools are already in PATH..."
}
