# Project Coding Standards

This is a Pascal compiler and IDE written for the MEGA65 computer in
4510 assembly language. The CC65 assembler is used.

## Project Structure

The compiler consists of a collection of overlays and programs (PRGs). Everything runs natively on a MEGA65 computer or within the emulator (xmega65). Programs are located in `src/apps` and overlays are located in `src/overlays`. Shared runtime code is located in asmlib: `src/lib/asmlib`. This code is used by both programs and overlays.

## MEGA65 Memory Layout

All programs load at the MEGA65's BASIC program address of $2001. All overlays load at $4000, which means only one overlay can be loaded at a time and overlays cannot call into each other.

Programs and overlays share a memory heap, managed by `asmlib`. The heap lives in two memory banks, as detailed in the table below.

The ca65 linker configuration files used for the programs and overlays enforce the available sizes in the memory map and will fail with the available size is exceeded.

### Memory Map

|Segment      |Addresses      |Size|
|-------------|---------------|----|
|Program space|$2000 - $3FFF  |8k  |
|Overlay space|$4000 - $8FFF  |20k |
|Asmlib       |$9000 - $BFFF  |12k |
|Memory heap  |$12000 - $1cffa|43k |
|Memory heap  |$42000 - $5EFFF|115k|
|Runtime stack|$5F000 - $5FFFF|4k  |

## Notables

The compiler was formerly written in C. The C code is still in the
repository for reference and historical purposes. All parts written
in C have been replaced by assembly language.

## Build, Test, and Development Commands

  1. `make TARGET=mega65` from the project root builds the entire project.
  2. `make TARGET=mega65` from a program or overlay directory such as `src/apps/compilerasm` or `src/overlays/parserasm` builds just that component.
  3. `make TARGET=mega65 run` from the root directory runs the compiler and IDE in the emulator. The same command from a program directory runs a test environment for that program such as `src/programs/parsertest`. Not all programs have a `run` target.
  4. `make TARGET=mega65 test` from the root runs all tests against all components. This MUST be run after any code changes. asmlib MUST be rebuilt with its memory checks first and without them afterwards (see "Running the Tests").

## Testing Methodology

The project has seven test suites, located in `src/apps`:

  - tokenizertest
  - parsertest
  - resolvertest
  - typechecktest
  - icodetest
  - memtest (memory heap allocator in asmlib)
  - compilertestasm

Each suite's `make test` goes through `src/apps/testcommon/runtest.sh`, which looks for a `RESULT: PASS` or `RESULT: FAIL` line in an emulator screen dump. New suites should reuse it and `testresult.s`.

### Running the Tests

The tests MUST run with asmlib's runtime double-free checks enabled. These checks are off in the normal build. Running the tests takes three steps:

  1. Rebuild asmlib with the checks: `make -C src/lib/asmlib TARGET=mega65 MEMCHECK=1`
  2. Run the tests from the root: `make TARGET=mega65 test`
  3. Once all the tests complete, whether they pass or fail, rebuild asmlib without the checks: `make -C src/lib/asmlib TARGET=mega65 MEMCHECK=0`

Changing `MEMCHECK` rebuilds every asmlib object. The flags are recorded in `src/lib/asmlib/obj/mega65/asflags`. A `make` without `MEMCHECK` keeps the last setting, because the suite Makefiles run make in asmlib during `make test`. So step 3 must name `MEMCHECK=0`. A clean asmlib build has no checks.

`MEMCHECK=1` defines `__DEBUG__`. With it defined, freeing memory that isn't allocated (such as a double free) executes BRK. Z holds a code naming the routine that found the problem:

|Code|Routine   |
|----|----------|
|$11 |freeDecl  |
|$12 |freeSymbol|
|$13 |freeSymtab|
|$14 |freeType  |
|$22 |heapFree  |

`testInit` in `testresult.s` points the KERNAL's BRK vector (`$0316`) at a trap. The trap reports any BRK as a test failure, with its code and routine. `testPass` and `testFail` restore the vector. A program that ends without either must call `testRestoreBrk`.

Each suite calls `testMemCheck` right after `initMemHeap`. It frees a block twice. If asmlib was built without the checks, that doesn't execute BRK, and the suite fails with "asmlib has no memory checks". New suites must do the same.

Each suite except memtest calls `testLeakCheck` after its tests. It walks the heap's MAT, and if any block is still allocated it prints the count and size and returns with the carry set. The suite then fails. Blocks the size of the compile-time error message buffer (`initCompilerErrors`) are skipped, because that buffer is never freed. New suites must do the same.

A test that expects a BRK (memtest's bad-free tests do) sets `brkCatch` to its own handler. The trap jumps there, with the code in `brkCode`, instead of failing.

### Uninitialized memory

The emulator zeros RAM at startup, but real hardware doesn't. The test
programs, `mkhdr`, `testhdr` and `treeviewer` start `main` with the
`poisonBss` macro (`src/asminc/poisonbss.inc`). In a debug build it fills the
program's BSS with `$A5`, so code that reads BSS before writing it fails in the
emulator as it would on hardware. In other builds it's empty.

`make DEBUG=1` in one of those app directories makes a debug build. It defines
`__DEBUG__` (see `src/apps/debug.mk`). A suite's `test` target always makes
one, and `testInit` then fails the test if BSS wasn't filled. New programs must
call `poisonBss` and include `debug.mk`. The compiler and editor programs,
overlays and asmlib don't fill BSS. `heapAlloc` zeros every block it returns.

### Heap Tests

`memtest` checks block addresses and exact MAT entries. When you change `memheap.s`, run `make TARGET=mega65 coverage` in `src/apps/memtest`. It runs the tests against a copy of `memheap.s` with a probe at every basic block (`cov/mkcov.py`) and lists the lines that never ran.

### Compiler Tests

`compilertestasm` runs as two sets because all the compiled programs don't fit on one D81. The `test` target runs a compile step, then a run step. Any compiler error or warning fails the compile step. Any test failure leaves a `testfailed` file that makes the last program, `done`, print FAIL. When you add a test, add it to `compiletests.s` (in set 1 or set 2) and to the D81 file list in the Makefile.

### Adding a test program

Name its failure maker `testfailed`, call `ReportFailure` and make sure the program doesn't use that filename itself.

### Makefile hazard

`make test` needs WSL, and the build tools (`make`, `c1541`, `petcat`) are only available there. It also needs `XMEGA65=xmega65.exe` set so WSL runs the Windows emulator.

### Orphaned emulators

`timeout` in `runtest.sh` kills the WSL wrapper, not the Windows `xmega65.exe`. A timed-out run leaves an emulator running that locks its D81 image, and the next run then fails with "Permission Denied" until the process is killed.

## Language and compiler quirks

### Comments

Use `//` comments in Pascal tests. The compiler does not support `{ }` comments. If used, the compiler will hang.

### Source line length

Source lines are limited to 80 characters. This limitation includes comments.

## Environment

### WSL

The build and test environment is run entirely inside WSL. All the tools needed for building and
testing are in the WSL path. The ca65 in WSL is the Windows build.

### Python

Python 3 is installed in WSL only (`python3`), which is where the Makefiles run it. On Windows, `python3` is only the Microsoft Store stub.

### Line endings

The `.pas` and `.s` sources use CRLF in the working tree. In Git Bash, `sed -i` strips the CRs, so check afterwards with `file`.

### Git

The repo's autocrlf setting means `git diff` shows LF, so don't read those as a line-ending problem.

## Pre-compiled headers

`src/lib/hdr/*.hdr` are generated by the `mkhdr` app. Library changes mean regenerating them.

## Non-negotiables

- NEVER reference any C code when debugging or writing code.
- NEVER modify any C code or C header files.
- When adding new behavior, add or update tests for that component.
- NEVER commit to Git without permission.
