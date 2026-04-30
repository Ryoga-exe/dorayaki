param(
  [ValidateSet("build", "run", "debug", "clean")]
  [string]$Command = "build"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sampleDir = Join-Path $repoRoot "src\riscv\hello_qemu"
$buildDir = Join-Path $repoRoot "build\riscv\hello_qemu"
$toolsDir = Join-Path $repoRoot "xpacks\.bin"

$gcc = Join-Path $toolsDir "riscv-none-elf-gcc.cmd"
$qemu = Join-Path $toolsDir "qemu-system-riscv64.cmd"

$elf = Join-Path $buildDir "hello_qemu.elf"
$map = Join-Path $buildDir "hello_qemu.map"
$linker = Join-Path $sampleDir "linker.ld"
$startup = Join-Path $sampleDir "startup.S"
$main = Join-Path $sampleDir "main.c"

function Assert-Tool([string]$Path, [string]$Hint) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Hint not found at '$Path'. Run 'xpm install' first."
  }
}

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: $FilePath $($Arguments -join ' ')"
  }
}

function Build-Hello {
  Assert-Tool $gcc "RISC-V GCC"
  New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

  $commonFlags = @(
    "-march=rv64imac_zicsr",
    "-mabi=lp64",
    "-mcmodel=medany",
    "-ffreestanding",
    "-fno-builtin",
    "-nostdlib",
    "-nostartfiles",
    "-g3",
    "-O0",
    "-Wall",
    "-Wextra",
    "-Werror"
  )

  $linkerFlags = @(
    "-Wl,--build-id=none",
    "-Wl,-Map,$map",
    "-Wl,-T,$linker"
  )

  Invoke-Checked $gcc @commonFlags @linkerFlags "-o" $elf $startup $main
}

switch ($Command) {
  "build" {
    Build-Hello
  }
  "run" {
    Build-Hello
    Assert-Tool $qemu "QEMU RISC-V"
    Invoke-Checked $qemu "-machine" "virt" "-cpu" "rv64" "-nographic" "-monitor" "none" "-serial" "stdio" "-bios" "none" "-kernel" $elf
  }
  "debug" {
    Build-Hello
    Assert-Tool $qemu "QEMU RISC-V"
    Write-Host "QEMU waiting for GDB on tcp::3333"
    Invoke-Checked $qemu "-machine" "virt" "-cpu" "rv64" "-nographic" "-monitor" "none" "-serial" "stdio" "-bios" "none" "-kernel" $elf "-S" "-gdb" "tcp::3333"
  }
  "clean" {
    if (Test-Path -LiteralPath $buildDir) {
      Remove-Item -LiteralPath $buildDir -Recurse -Force
    }
  }
}
