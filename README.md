# dorayaki

Visual Studio Code configurations for embedded development.

## First sample: RISC-V on QEMU

This repository now includes a minimal bare-metal RISC-V sample under `src/riscv/hello_qemu`.
It targets the QEMU `virt` machine, writes to the UART at `0x10000000`, and exits via the
SiFive test finisher.

## Setup

Open the repository in the Dev Container. The container installs `xpm` and runs `xpm install`
from `.devcontainer/devcontainer.json`.

For a host setup, install the local xPack tools manually:

```sh
xpm install
```

## Build

```sh
xpm run build:riscv-hello
```

The ELF output is generated at `build/riscv/hello_qemu/hello_qemu.elf`.

## Run

```sh
xpm run run:riscv-hello
```

Expected output:

```text
Hello, world from dorayaki on QEMU!
```

## VSCode

The sample is wired into `.vscode/tasks.json` and `.vscode/launch.json` so you can:

- run `Tasks: Run Build Task` for the build
- run `Tasks: Run Task` and choose `riscv: run hello_qemu`
- open `Run and Debug` and choose `QEMU hello_qemu (GDB)` for the first-pass debugger flow
- use `QEMU hello_qemu (cortex-debug)` if you want to exercise the Cortex-Debug extension against the QEMU gdbstub

## Files

- `src/riscv/hello_qemu/main.c`: UART hello-world payload
- `src/riscv/hello_qemu/startup.S`: reset entry and BSS clear
- `src/riscv/hello_qemu/linker.ld`: memory layout for the QEMU `virt` machine
- `scripts/riscv-hello.mjs`: build, run, debug, and clean helper
