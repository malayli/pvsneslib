# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

PVSnesLib is a toolchain + C library for developing Super Nintendo (SNES) ROMs in C and 65816 assembly. It bundles:
a cross compiler (`816-tcc`, a fork of tcc targeting the 65816), an assembler/linker (`wla-dx`: `wla-65816`, `wla-spc700`, `wla-superfx`, `wlalink`), an optimizer (`816-opt`) and constant-folding pass (`constify`), various asset conversion tools, the library sources themselves, and a large set of example ROMs.

## Repo layout

- `compiler/` — git submodules `tcc` (816-tcc) and `wla-dx`; built and installed into `devkitsnes/bin`.
- `tools/` — asset/data conversion utilities installed into `devkitsnes/tools` (see below).
- `devkitsnes/` — the "installed" toolchain: `bin/` (compiler+assembler+linker), `tools/` (converters), `include/`, and `snes_rules` — the shared Makefile fragment every buildable project (library, example, test) includes.
- `pvsneslib/source/` — the library itself, almost entirely 65816 assembly (`*.asm`) plus one C file (`libc_c.c`); builds into per-variant `.obj` files.
- `pvsneslib/include/snes/` — public C headers (`background.h`, `sprite.h`, `input.h`, `sound.h`, `map.h`, `object.h`, etc.), aggregated by `pvsneslib/include/snes.h`.
- `pvsneslib/lib/` — built library objects, one directory per ROM configuration: `{LoROM,HiROM}_{SlowROM,FastROM}/`.
- `pvsneslib/snesmod/` — SPC700 sound driver (`sm_spc_wla.asm`) linked into every ROM.
- `snes-examples/` — one subdirectory per example/demo, each an independent buildable project with its own `Makefile`.
- `snes-examples/tests/` — automated test suite (see Testing below).
- `podman/` — container definitions (centos/debian/fedora/ubuntu) for reproducible builds of the toolchain.
- `vscode-template/` — VS Code project template for consumers of the library.

## Build pipeline (how a project turns into a `.sfc` ROM)

Every buildable project (a `snes-examples/*` example, a test, or a user project) has a `Makefile` that:
1. Requires the `PVSNESLIB_HOME` env var to point at the repo root (or an installed release).
2. `include`s `${PVSNESLIB_HOME}/devkitsnes/snes_rules`, which defines `CC`/`AS`/`AS700`/`SUPERFX`/`LD`/tool paths and all the pattern rules below.
3. Sets `ROMNAME` and optionally `HIROM=1`, `FASTROM=1`, asset lists, etc., before including `snes_rules`.

Per-file compilation chain, driven by `snes_rules`:
```
foo.c  --816-tcc-->  foo.ps   (preprocessed/compiled asm-ish output)
foo.ps --816-opt-->  foo.asp  (peephole-optimized)
foo.asp --constify-> foo.asm  (constants moved/folded, using original foo.c + foo.asp)
foo.asm --wla-65816--> foo.obj
*.obj + prebuilt library .obj (from pvsneslib/lib/<ROMTYPE>_<SPEEDTYPE>/) --wlalink--> ROMNAME.sfc
```
`.asm` sources skip the C/optimizer steps and go straight to `wla-65816`. Sound (`*.it` via `smconv` → `soundbank.asm`), graphics (`gfx4snes`/`gfx2snes`), tilemaps (`tmx2snes`), and BRR audio (`snesbrr`) are converted to `.asm`/binary include data by dedicated tools before assembly, also wired up in `snes_rules`.

`HIROM`/`FASTROM` select which prebuilt library variant (`pvsneslib/lib/{LoROM,HiROM}_{SlowROM,FastROM}/`) gets linked. `PVSNESLIB_DEBUG=1` keeps intermediate `.ps`/`.asp`/`.dbg` artifacts around instead of deleting them, for diagnosing compiler/optimizer bugs.

## Build commands

Set once per shell before building anything:
```bash
export PVSNESLIB_HOME=$(pwd)   # repo root
```

Top-level (`Makefile` at repo root), builds in dependency order `compiler → tools → pvsneslib → examples`:
```bash
make            # build+install compiler & tools, build library, build all examples
make clean      # clean compiler, tools, pvsneslib, and examples
make release    # full build + doxygen docs + zip a release/ tree (requires doxygen)
make version    # print gcc/cmake/make versions
```

Building just the library after the toolchain is installed:
```bash
make -C pvsneslib              # builds all 4 ROM-type/speed variants
make -C pvsneslib docs         # doxygen HTML docs (pvsneslib/docs/html)
```

Building a single example/test (each has its own self-contained Makefile):
```bash
cd snes-examples/hello_world
make                # produces hello_world.sfc
make clean          # cleanRom/cleanGfx/cleanBuildRes/cleanLogs
```

Optional build-time flags for any example/library build, set as env or `make` vars:
- `HIROM=1` — HiROM instead of default LoROM
- `FASTROM=1` — FastROM instead of default SlowROM
- `PVSNESLIB_DEBUG=1` — keep intermediate compiler/optimizer artifacts (`*.ps.01.dbg`, `*.opt.02.dbg`, `*.ctf.03.dbg`)

## Testing

`snes-examples/tests/` (see its `README.md` for full detail):
```bash
cd snes-examples/tests
./run_tests.sh /path/to/Mesen      # full suite; needs Mesen2 built with --testrunner/--lua support
./build_validation.sh              # no emulator: compiles all examples, checks ROM sizes are 32KB-4MB
cd arithmetic && /path/to/Mesen --testrunner test_arithmetic.sfc --lua run_test.lua   # one suite
cd tmx2snes_test && ./run_test.sh  # no emulator needed
```
Test suites: `arithmetic/` (816-tcc/816-opt codegen correctness, 71 cases), `malloc_test/` (heap regression), `background_init/` (BG layer setup), `tmx2snes_test/` (tilemap converter regression). ROM-based tests communicate pass/fail via fixed memory locations (`test_status`/`test_total`/`test_passed`/`test_failed`) that a Lua script running under Mesen polls. Exit codes: `0` all passed, `1` some failed, `2` Mesen not found/timeout.

New ROM-based tests follow the pattern in an existing `tests/*` subdir: a `main()` that runs checks and sets `test_status`, plus a `run_test.lua` polling script and a `Makefile` including `snes_rules`.

## Working on the library itself (`pvsneslib/source/`)

- Almost all logic lives in `.asm` files (`sprites.asm`, `backgrounds.asm`, `dmas.asm`, `input.asm`, `objects.asm`, `maps.asm`, `sounds.asm`, `videos.asm`, `vblank.asm`, `scores.asm`, `lzsss.asm`, `crt0_snes.asm` for startup, `hdr.asm` for the ROM header). `libc_c.c` + `libc.asm`/`libm.asm` provide C-runtime/math routines. `sm_spc.asm` is the SPC700 sound-driver source assembled separately (`AS700`/`wla-spc700`) from `snesmodwla.asm`'s glue.
- Public C API surface is `pvsneslib/include/snes/*.h`; changing library behavior usually means touching both the `.asm` implementation and its header declaration.
- `pvsneslib/source/Makefile` assembles the library into `SNESOBJS = crt0_snes.obj libm.obj libtcc.obj libc.obj` and moves the result into the matching `pvsneslib/lib/<ROMTYPE>_<SPEEDTYPE>/` directory — it is invoked once per ROM-type/speed combination by `pvsneslib/Makefile`.
- WLA assembler flags always include `-d` (disables label-subtraction A-B constant folding); removing it requires updates to `crt0_snes.asm`.

## Notes

- Windows builds require MSYS2/Unix-style paths for `PVSNESLIB_HOME` (e.g. `/c/snesdev`, not `C:\snesdev`) — `snes_rules` explicitly errors out on backslash paths.
- `compiler/tcc` and `compiler/wla-dx` are git submodules; if missing, `git submodule update --init --recursive`.
- CI (`.github/workflows/pvsneslib_build_package.yml`) builds `make release` across ubuntu/windows(msys2)/macos and uploads the resulting release zip + logs.
