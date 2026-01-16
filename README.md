[![CI](https://github.com/ppigazzini/get-native-properties/actions/workflows/ci.yml/badge.svg)](https://github.com/ppigazzini/get-native-properties/actions/workflows/ci.yml) [![CI lint](https://github.com/ppigazzini/get-native-properties/actions/workflows/lint.yml/badge.svg)](https://github.com/ppigazzini/get-native-properties/actions/workflows/lint.yml) [![Platform Smoke](https://github.com/ppigazzini/get-native-properties/actions/workflows/platform-smoke.yml/badge.svg)](https://github.com/ppigazzini/get-native-properties/actions/workflows/platform-smoke.yml)

# get-native-properties

Small, testable POSIX `sh` helper used for Stockfish’s build selection logic: it detects the *best* CPU/OS “architecture tier” string as expected by the [Stockfish Makefile](https://github.com/official-stockfish/Stockfish/blob/master/src/Makefile) (i.e. what `ARCH=native` should resolve to).

## What it does

Running the script prints a single line:

```
<true_arch>\n
```

Examples:

- `x86-64-avx2`
- `x86-64-avx512icl`
- `armv8-dotprod`
- `ppc-64-vsx`
- `loongarch64-lsx`

The selector is primarily based on:

- `uname -s` and `uname -m`
- CPU feature flags from `/proc/cpuinfo` (Linux / MSYS2 / Cygwin)
- `sysctl machdep.cpu.*` feature strings (macOS Intel)

## Scripts

- `scripts/get_native_properties.sh`
  - The current implementation.
  - Outputs only the architecture tier (`true_arch`).
  - Includes test hooks via environment variables so it can be unit-tested without needing specific hardware.

## Requirements

- Python: `>= 3.14` (CI uses `3.14` with prereleases enabled)
- Shell: POSIX `sh`

## Supported tiers (high level)

The script recognizes several CPU families and (where relevant) “feature tiers”, including:

- x86_64: `x86-64`, `x86-64-sse3-popcnt`, `x86-64-ssse3`, `x86-64-sse41-popcnt`, `x86-64-avx2`, `x86-64-bmi2`, `x86-64-avxvnni`, `x86-64-avx512`, `x86-64-vnni512`, `x86-64-avx512icl`
- x86 32-bit: `x86-32`, `x86-32-sse2`, `x86-32-sse41-popcnt`
- ARM: `armv7`, `armv7-neon`, `armv8`, `armv8-dotprod`, `apple-silicon`
- PPC: `ppc-32`, `ppc-64`, `ppc-64-altivec`, `ppc-64-vsx`
- LoongArch: `loongarch64`, `loongarch64-lsx`, `loongarch64-lasx`
- Others: `riscv64`, `e2k`

For unknown Linux/macOS machine types, it falls back to `general-32` / `general-64` based on detected bitness.

## Usage

Run locally:

```sh
sh scripts/get_native_properties.sh
```

Example use in a build script:

```sh
ARCH="$(sh scripts/get_native_properties.sh)"
echo "Detected ARCH=$ARCH"
```

## Testing

Unit tests validate the selector logic against curated `/proc/cpuinfo` fixtures.

```sh
python -m unittest discover -s tests -p 'test_*.py'
```

## Linting & formatting

CI runs Ruff for linting, import sorting, and formatting checks.

```sh
ruff check .
ruff check --select I .
ruff format --check .
```

To auto-fix what can be fixed automatically:

```sh
ruff check --fix .
ruff format .
```

### Test hooks / overrides

`scripts/get_native_properties.sh` supports these environment variables (used heavily by the tests):

- `GP_UNAME_S` / `GP_UNAME_M`: override `uname -s` / `uname -m`
- `GP_CPUINFO`: path to a cpuinfo-like file (defaults to `/proc/cpuinfo`)
- `GP_BITS`: override `getconf LONG_BIT` (useful for unknown-machine fallback)
- `GP_SYSCTL_FEATURES`: override macOS Intel `sysctl` feature strings

## Workflows (labels)

This repo has three GitHub Actions workflows:

- **CI** (`.github/workflows/ci.yml`): Python unit tests
- **CI lint** (`.github/workflows/lint.yml`): shell lint (shellcheck) + Ruff (lint / import sort / format check)
- **Platform Smoke** (`.github/workflows/platform-smoke.yml`): runs the current script on native runners and in QEMU containers
