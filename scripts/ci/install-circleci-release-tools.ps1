#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$env:CARGO_TERM_COLOR = "never"
$env:CARGO_TERM_PROGRESS_WHEN = "never"
$env:NO_COLOR = "1"
trap {
    Write-Host $_
    [Environment]::Exit(1)
}

$cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
$rustMsBin = Join-Path $env:ChocolateyInstall "lib\rust-ms\tools\bin"

function Test-Command {
    param([string]$Name)

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-ChocoPackages {
    param([string[]]$Packages)

    if ($Packages.Count -eq 0) {
        return
    }

    choco feature enable -n allowGlobalConfirmation
    choco install @Packages -y --no-progress
}

function Add-RustPath {
    if (Test-Path $cargoBin) {
        $env:Path = "$cargoBin;$env:Path"
    }
    if (Test-Path $rustMsBin) {
        $env:Path = "$rustMsBin;$env:Path"
    }
}

Add-RustPath

function Install-RustToolchain {
    Write-Host "Ensuring Rust MSVC toolchain..."
    if ((Test-Command "cargo") -and (Test-Command "rustc")) {
        Write-Host "Rust toolchain already available."
        return
    }

    Write-Host "Installing rust-ms through Chocolatey..."
    choco install rust-ms --version=1.95.0 -y --no-progress
    if ($LASTEXITCODE -ne 0) {
        throw "rust-ms failed with exit code $LASTEXITCODE"
    }

    Add-RustPath
    if (-not ((Test-Command "cargo") -and (Test-Command "rustc"))) {
        throw "Missing cargo/rustc after rust-ms install."
    }
}

$fullRelease = $env:FULL_WINDOWS_RELEASE -eq "true"
$packages = @()
if (-not (Test-Command "git")) {
    $packages += "git"
}
if (-not (Test-Command "node")) {
    $packages += "nodejs-lts"
}
if ($fullRelease -and -not (Test-Command "gh")) {
    $packages += "gh"
}
if ($fullRelease -and -not (Test-Path (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"))) {
    $packages += "innosetup"
}

Install-ChocoPackages $packages

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
    [System.Environment]::GetEnvironmentVariable("Path", "User")
Add-RustPath

Install-RustToolchain

if (Test-Command "rustup") {
    rustup set auto-self-update disable
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: rustup auto-self-update disable failed with exit code $LASTEXITCODE"
    }
} else {
    Write-Host "rustup is not installed; rust-ms provides cargo/rustc directly."
}

$env:CARGO_BUILD_TARGET = "x86_64-pc-windows-msvc"

corepack enable
if ($LASTEXITCODE -ne 0) {
    throw "corepack enable failed with exit code $LASTEXITCODE"
}

corepack prepare pnpm@10.18.1 --activate
if ($LASTEXITCODE -ne 0) {
    throw "corepack prepare failed with exit code $LASTEXITCODE"
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vsInstall = & $vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
} else {
    $vsInstall = ""
}

if (-not $vsInstall) {
    throw "Missing Visual Studio C++ build tools. Select a CircleCI Windows image with MSVC installed or add a reviewed installer step."
}

git --version
cargo --version
rustc --version
pnpm --version

if ($fullRelease) {
    gh --version
    $iscc = Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"
    if (-not (Test-Path $iscc)) {
        throw "Inno Setup compiler not found at $iscc"
    }
    Write-Host "Inno Setup compiler: $iscc"
} else {
    Write-Host "Skipping full-release tools for warm Windows build."
}
