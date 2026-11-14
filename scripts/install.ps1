# VANTA installer for Windows.
#
#   irm https://vanta.aethlon.xyz/install.ps1 | iex
#
# Override the install directory with $env:VANTA_INSTALL_DIR, or pin a release
# with $env:VANTA_VERSION (for example, "v0.1.0").
$ErrorActionPreference = "Stop"

$Repo = "Aethlon/Vanta"
$InstallDir = if ($env:VANTA_INSTALL_DIR) {
    $env:VANTA_INSTALL_DIR
} else {
    Join-Path $env:LOCALAPPDATA "Programs\Vanta\bin"
}
$Version = $env:VANTA_VERSION
$Asset = "vanta-windows-x86_64.zip"

try {
    if (-not $Version) {
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
        } catch {
            throw "No published VANTA release is available yet. Visit https://vanta.aethlon.xyz or https://github.com/$Repo/releases"
        }
        $Version = $release.tag_name
    }
    if (-not $Version) {
        throw "No published VANTA release is available yet. Visit https://vanta.aethlon.xyz or https://github.com/$Repo/releases"
    }

    $url = "https://github.com/$Repo/releases/download/$Version/$Asset"
    $temp = Join-Path $env:TEMP ("vanta-install-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $temp | Out-Null
    $zip = Join-Path $temp $Asset

    Write-Host "Downloading VANTA $Version (windows/x86_64)..."
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    $expected = $null
    try {
        $checksumText = (Invoke-WebRequest -Uri "$url.sha256" -UseBasicParsing).Content
        $expected = ($checksumText -split "\s+")[0].ToLowerInvariant()
    } catch {
        Write-Host "warning: checksum unavailable; skipping verification"
    }
    if ($expected) {
        $actual = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($expected -ne $actual) {
            throw "checksum mismatch for $Asset"
        }
    }

    Expand-Archive -Path $zip -DestinationPath $temp -Force
    $binary = Get-ChildItem -Path $temp -Filter "vanta.exe" -Recurse | Select-Object -First 1
    if (-not $binary) {
        throw "archive did not contain vanta.exe"
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $target = Join-Path $InstallDir "vanta.exe"
    Copy-Item -Path $binary.FullName -Destination $target -Force

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @($userPath -split ";" | Where-Object { $_ })
    if ($parts -notcontains $InstallDir) {
        [Environment]::SetEnvironmentVariable("Path", (($parts + $InstallDir) -join ";"), "User")
        $env:Path = "$env:Path;$InstallDir"
        Write-Host "Added $InstallDir to your user PATH. Restart the terminal to pick it up."
    }

    Write-Host ""
    Write-Host "  ##   ##   #####   ##   ##  ######  #####" -ForegroundColor Cyan
    Write-Host "  ##   ##  ##   ##  ###  ##    ##    ##  ##" -ForegroundColor Cyan
    Write-Host "  ##   ##  #######  ## # ##    ##    ######" -ForegroundColor Cyan
    Write-Host "   ## ##   ##   ##  ##  ###    ##    ##  ##" -ForegroundColor Cyan
    Write-Host "    ###    ##   ##  ##   ##    ##    ##  ##" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  VANTA $Version installed" -ForegroundColor Cyan
    Write-Host "  deterministic code intelligence" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Start:    vanta"
    Write-Host "  Index:    vanta index ."
    Write-Host "  Update:   vanta update"
    Write-Host "  Docs:     https://vanta.aethlon.xyz/docs"
    Write-Host ""
    & $target --version
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
