import { existsSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const command = process.argv[2] ?? "build";
const validCommands = new Set(["build", "run", "debug", "clean"]);

if (!validCommands.has(command)) {
  console.error(`Unknown command: ${command}`);
  process.exit(2);
}

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const sampleDir = join(repoRoot, "src", "riscv", "hello_qemu");
const buildDir = join(repoRoot, "build", "riscv", "hello_qemu");
const toolsDir = join(repoRoot, "xpacks", ".bin");

const executableSuffix = process.platform === "win32" ? ".cmd" : "";
const gcc = join(toolsDir, `riscv-none-elf-gcc${executableSuffix}`);
const qemu = join(toolsDir, `qemu-system-riscv64${executableSuffix}`);

const elf = join(buildDir, "hello_qemu.elf");
const map = join(buildDir, "hello_qemu.map");
const linker = join(sampleDir, "linker.ld");
const startup = join(sampleDir, "startup.S");
const main = join(sampleDir, "main.c");

const gccFlags = [
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
];

const qemuFlags = [
  "-machine", "virt",
  "-cpu", "rv64",
  "-nographic",
  "-monitor", "none",
  "-serial", "stdio",
  "-bios", "none"
];

function quoteWindowsArg(value) {
  return `"${value.replaceAll('"', '""')}"`;
}

function run(file, args) {
  if (!existsSync(file)) {
    console.error(`Missing tool: ${file}`);
    console.error("Run `xpm install` before building the sample.");
    process.exit(1);
  }

  const windowsCommand = ["call", quoteWindowsArg(file), ...args.map(quoteWindowsArg)].join(" ");
  const result = process.platform === "win32"
    ? spawnSync("cmd.exe", ["/d", "/c", windowsCommand], {
      stdio: "inherit",
      windowsVerbatimArguments: true
    })
    : spawnSync(file, args, { stdio: "inherit" });

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function buildHello() {
  mkdirSync(buildDir, { recursive: true });

  run(gcc, [
    ...gccFlags,
    "-Wl,--build-id=none",
    `-Wl,-Map,${map}`,
    `-Wl,-T,${linker}`,
    "-o",
    elf,
    startup,
    main
  ]);
}

switch (command) {
  case "build":
    buildHello();
    break;
  case "run":
    buildHello();
    run(qemu, [
      ...qemuFlags,
      "-kernel", elf
    ]);
    break;
  case "debug":
    buildHello();
    console.log("QEMU waiting for GDB on tcp::3333");
    run(qemu, [
      ...qemuFlags,
      "-kernel", elf,
      "-S",
      "-gdb", "tcp::3333"
    ]);
    break;
  case "clean":
    rmSync(buildDir, { recursive: true, force: true });
    break;
}
