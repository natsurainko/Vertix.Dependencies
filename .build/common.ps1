# Dot-source this script to get common output-directory helpers.
# Requires $RepoRoot to be set before calling helper functions.
#
# Usage: . "$PSScriptRoot\..\common.ps1"

function Write-BuildLog {
    param(
        [string]$Level,
        [string]$Context,
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff zzz"
    $tag = $Level.ToUpper().PadRight(3)
    if ($Level -eq "ERR") {
        Write-Host "[$ts][$tag] <$Context>: $Message" -ForegroundColor Red
    } elseif ($Level -eq "WRN") {
        Write-Host "[$ts][$tag] <$Context>: $Message" -ForegroundColor Yellow
    } else {
        Write-Host "[$ts][$tag] <$Context>: $Message"
    }
}

function Clear-Includes {
    param(
        [string]$Name,
        [string]$RepoRoot = (Get-Variable -Name RepoRoot -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
    )
    $dir = "$RepoRoot\includes\$Name"
    Write-BuildLog "INF" "common" "Clearing $dir..."
    if (Test-Path $dir) {
        Remove-Item "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    $null = New-Item -ItemType Directory -Force -Path $dir
    return $dir
}

function Clear-Licenses {
    param(
        [string]$Name,
        [string]$RepoRoot = (Get-Variable -Name RepoRoot -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
    )
    $dir = "$RepoRoot\licenses\$Name"
    Write-BuildLog "INF" "common" "Clearing $dir..."
    if (Test-Path $dir) {
        Remove-Item "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    $null = New-Item -ItemType Directory -Force -Path $dir
    return $dir
}

function New-LicenseMarker {
    param(
        [string]$LicenseDir,
        [string]$ReleaseTitle
    )
    if ($ReleaseTitle) {
        $marker = "$LicenseDir\$ReleaseTitle"
    } else {
        $marker = "$LicenseDir\release"
    }
    Write-BuildLog "INF" "common" "Creating license marker: $marker"
    $null = New-Item -ItemType File -Force -Path $marker
}

function Copy-Libs {
    param(
        [string]$SourceDir,
        [string]$LibName,
        [string]$RenameTo,
        [string]$RepoRoot = (Get-Variable -Name RepoRoot -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
    )
    if (-not $RenameTo) { $RenameTo = $LibName }

    $debugDir = "$RepoRoot\libraries\Debug"
    $releaseDir = "$RepoRoot\libraries\Release"

    $null = New-Item -ItemType Directory -Force -Path $debugDir
    $null = New-Item -ItemType Directory -Force -Path $releaseDir

    Write-BuildLog "INF" "common" "Copying Release lib to $releaseDir..."
    Copy-Item "$SourceDir\Release\$LibName" "$releaseDir\$RenameTo" -Force

    Write-BuildLog "INF" "common" "Copying Debug lib to $debugDir..."
    Copy-Item "$SourceDir\Debug\$LibName" "$debugDir\$RenameTo" -Force
}

function Get-LatestRelease {
    param(
        [string]$Repo
    )
    $uri = "https://api.github.com/repos/$Repo/releases/latest"
    $headers = @{ "Accept" = "application/vnd.github+json" }
    if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
    }

    try {
        return Invoke-RestMethod -Uri $uri -Headers $headers
    } catch {
        if ($_.Exception.Response -and ($_.Exception.Response.StatusCode -eq 403 -or $_.Exception.Response.StatusCode -eq 429)) {
            Write-Error "GitHub API rate limit hit. Set `$env:GITHUB_TOKEN to a personal access token, or wait until the limit resets."
        }
        throw
    }
}
