$ErrorActionPreference = "Continue"

$ScriptDir = $PSScriptRoot

$BuildModules = @(
    @{Name = "d3d12"      }
    @{Name = "dxcompiler" }
    @{Name = "GameInput"  }
    @{Name = "simdjson"   }
    @{Name = "fastgltf"   }
    @{Name = "imgui"      }
    @{Name = "DirectXTK12"}
)

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

Write-BuildLog "INF" "BuildAll" "=============================================="
Write-BuildLog "INF" "BuildAll" "Vertix.Dependencies -- Build All"
Write-BuildLog "INF" "BuildAll" "$($BuildModules.Count) modules to process"
Write-BuildLog "INF" "BuildAll" "=============================================="

$failed  = @()
$success = @()

foreach ($module in $BuildModules) {
    $name = $module.Name
    $buildScript = "$ScriptDir\$name\build.ps1"

    if (-not (Test-Path $buildScript)) {
        Write-BuildLog "ERR" "BuildAll" "${name}: build.ps1 not found"
        $failed += $name
        continue
    }

    Write-BuildLog "INF" "BuildAll" "Starting ${name}..."

    # Write a small wrapper script so quoting is handled cleanly.
    # On success the window auto-closes; on failure it pauses.
    $null = New-Item -ItemType Directory -Force -Path "$ScriptDir\.cache"
    $wrapper = "$ScriptDir\.cache\vx_build_${name}.ps1"
    @"
`$ErrorActionPreference = 'Continue'
`$ec = 0
`$finished = `$false
try {
    & "$buildScript"
    `$ok = `$?
    `$ec = if (Test-Path variable:LASTEXITCODE) { `$LASTEXITCODE } else { 0 }
    if (-not `$ok) { `$ec = 1 }
    `$finished = `$true
} finally {
    if (-not `$finished) { `$ec = 1 }
    if (`$ec -ne 0) {
        Write-Host ''
        Write-Host "Build FAILED (exit code: `$ec). Press any key to close..." -ForegroundColor Red
        `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}
exit 0
"@ | Set-Content $wrapper -Encoding UTF8

    $proc = Start-Process pwsh `
        -ArgumentList "-NoLogo", "-File", $wrapper `
        -PassThru `
        -WindowStyle Normal

    $proc.WaitForExit()

    # Clean up wrapper
    Remove-Item $wrapper -Force -ErrorAction SilentlyContinue

    if ($proc.ExitCode -ne 0) {
        Write-BuildLog "ERR" "BuildAll" "${name}: FAILED (exit code: $($proc.ExitCode))"
        $failed += $name
    } else {
        Write-BuildLog "INF" "BuildAll" "${name}: OK"
        $success += $name
    }
}

Write-BuildLog "INF" "BuildAll" "=============================================="
Write-BuildLog "INF" "BuildAll" "BUILD SUMMARY"
Write-BuildLog "INF" "BuildAll" "Succeeded: $($success.Count) -- $($success -join ', ')"
if ($failed.Count -gt 0) {
    Write-BuildLog "ERR" "BuildAll" "Failed   : $($failed.Count) -- $($failed -join ', ')"
} else {
    Write-BuildLog "INF" "BuildAll" "All modules built successfully."
}
Write-BuildLog "INF" "BuildAll" "=============================================="
Write-Host "Press any key to exit..." -NoNewline
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""
