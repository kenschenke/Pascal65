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

The project has nine test suites, located in `src/apps`:

  - tokenizertest
  - parsertest
  - resolvertest
  - typechecktest
  - icodetest
  - memtest (memory heap allocator in asmlib)
  - compilertestasm
  - editortest (editor buffer management)
  - themestest (themes overlay: theme files, palette, theme screen)

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
|$23 |verifyHeap|

Code $23 isn't a bad free. With `__DEBUG__` defined, `heapAlloc` and
`heapFree` call `verifyHeap`, which walks the bank's MAT and executes BRK if
the heap's caches (see `memheap.s`) don't match it.

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

### Editor Tests

`editortest` runs a test build of the editor overlay: `make EDITORTEST=1` in
`src/overlays/editorasm` defines `__EDITORTEST__` and builds `editor-test`
from `obj/mega65-test`. The normal `editor` has none of the hooks. They are
in `editortest.s`, with `.ifdef`s in `editorReadKey`, `editorRun`,
`editorNewFile` and `keybuf.s`, and three more jump table entries
(`editorTestSetup`, `editorTestCleanup`, `editorTestState` in
`editoroverlay.inc`).

A test is a key script and what the editor must leave: the current file's
cursor, `numLines` and lines, then other checks (`CHK_*` in `tests.inc`):
EDITFILE fields, highlighting, the screen, files on the disk and what
`editorRun` returned. `editorReadKey` takes keys from the script. When it
runs out, the edit buffer is closed and `editorRun` returns, wherever the
editor was waiting. `getline` takes them too: `editorTestSetup` points its
jump table entry at the hook. Scripts are ASCII, as the keyboard sends them,
and the expected text is PETSCII. The `KEYS` and `TEXT` macros switch the
character map. `NEWFILE` opens a new file, a Pascal file if the test says
so, and `OPENFILE` opens a file by its row in the directory screen.
`editorTestCleanup` frees everything without prompts before the leak check.
A script that ends in the directory screen leaks its list, so it leaves it.

The tests don't fit in one program. Program N (`TESTPROGS`) runs
`src/testsN.s` from its own disk, made fresh for each run because the tests
change it. Each disk has the files in `files/`, in the order `FIXNAMES` in
the Makefile gives, which is their order in the directory screen. Saving a
file that is on the disk moves it to the end of the directory.

`make TARGET=mega65 coverage` in `src/apps/editortest` runs every program
against copies of the overlay with probes in them (`cov/mkcov.py`) and lists
the lines that never ran in `bin/mega65/coverage.txt`. The probes don't all
fit in the overlay at once, so the files are instrumented in sets
(`COVFILESn`). A set that no longer fits fails to link and must be split.
Like `test`, it needs asmlib built with `MEMCHECK=1`.

### Heap Tests

`memtest` checks block addresses and exact MAT entries. When you change `memheap.s`, run `make TARGET=mega65 coverage` in `src/apps/memtest`. It runs the tests against a copy of `memheap.s` with a probe at every basic block (`cov/mkcov.py`) and lists the lines that never ran.

### Compiler Tests

`compilertestasm` runs as three sets because all the compiled programs don't fit on one D81. A set's D81 also needs free space for the files its tests write (set 2's file tests hang on a full disk). The `test` target runs a compile step, then a run step. Any compiler error or warning fails the compile step. Any test failure leaves a `testfailed` file that makes the last program, `done`, print FAIL. When you add a test, add it to `compiletests.s` (in one of the sets, `TESTSETS` and `FIRSTTESTn` in the Makefile) and to the D81 file list in the Makefile.

A program the compiler must refuse goes in `errorTests` in `compiletests.s` instead, followed by the error number it must report. These are compiled first and never linked or run. The compile step fails unless each one reports exactly that one error. `toolarge.pas` checks `errCodeSegmentOverflow`, which code generation reports when the program, a 256-byte minimum heap and the runtime stack don't fit below $C000.

A program that only has to compile and link, without an error or warning, goes in `compileOnlyTests`. It isn't run. `examples/fivedice.pas` is there, with the Screen library on the D81, to check the runtime leaves it room.

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
testing are in the WSL path.

`c1541`, `petcat`, `ca65`, `ld65` and `xmega65.exe` are Windows executables that WSL runs through
interop. They get the current directory, but they can't open a `/mnt/c/...` path. Give them
relative paths (`cd` first), as the Makefiles and `runtest.sh` do. `make`, `sed`, `dos2unix` and
`python3` are Linux programs.

Run WSL commands through a login shell: `wsl bash -lc "make TARGET=mega65"`. Without `-l`, `ca65`
isn't on the PATH and make fails with "ca65: No such file or directory".

From Git Bash, a `/mnt/c/...` argument to `wsl` is rewritten into a Windows path, and `$` inside
`wsl bash -lc "..."` is expanded by Git Bash before WSL sees it. Set `MSYS_NO_PATHCONV=1`, or put
the commands in a script file and run that.

`c1541` stops at the first command that fails, such as a `-write` of a file it can't open, and
skips the rest without saying so. List the disk's directory afterwards to check.

### Python

Python 3 is installed in WSL only (`python3`), which is where the Makefiles run it. On Windows, `python3` is only the Microsoft Store stub.

### Line endings

The `.pas` and `.s` sources use CRLF in the working tree. In Git Bash, `sed -i` strips the CRs, so check afterwards with `file`.

### Git

The repo's autocrlf setting means `git diff` shows LF, so don't read those as a line-ending problem.

## Runtime modes

A compiled program gets the runtime (`src/lib/runtime`) one of two ways,
chosen by the `(* $StaticRuntime *)` and `(* $DynamicRuntime *)` directives
(`RT_MODE_*` in `asm.inc`). Both are allowed only in a program
(`errDirectiveProgramOnly`) and not together (`errConflictingDirectives`).
The parser keeps `runtimeMode` and the compiler apps pass it from
`getParserRuntimeMode` to `setCodeGenRuntimeMode`.

- **Dynamic, the default.** The PRG has an empty jump table at `RT_BASE` and
  the loader (`loader.s` in codegenasm) after it. The header calls the
  loader in place of `RT_RUNTIMEERRORINIT`. It loads `runtimeN` at `rtLow`
  (from the file's header, `RTH_*` in `asm.inc`), copies the jump table,
  patches the header's stack and heap tops and jumps to
  `RT_RUNTIMEERRORINIT`. A missing or bad runtime, or a program that doesn't
  fit below `rtLow`, prints a message and returns to BASIC. Codegen reads
  `runtimeN`'s header at compile time for `rtLow`, which `checkCodeSize`
  uses as the ceiling.
- **Static.** Codegen writes the patched jump table and a `LINKADDR_RUNTIME`
  tag followed by the list of files to copy (`linker.inc`). The linker
  copies the rest of the core and the packages straight into the PRG.

`runtimeErrorInit` clears the runtime's BSS in both modes, so a program run
again from memory finds it zeroed.

## Runtime packages

The runtime linked into compiled programs (`src/lib/runtime`) is split into a
core and three packages: dynamic arrays (`dynarray.s`), files (`fileops.s`,
the file-only half of file I/O) and trig (`trig.s`). `src/asminc/rtpkg.inc`
describes the layout. The core never calls a package except through the jump
table. Its entries for a package point at a stub (`rterror.s`) that raises
`rtePackageNotLinked` and prints the package number.

`mkruntime.py` links every package combination and writes these files to
`bin/mega65`. N is `RT_ABI_VERSION` in `asm.inc`:

|File                |Contents                                       |
|--------------------|-----------------------------------------------|
|`coreN`             |Its length, then the jump table, core and BSS  |
|`dynarraysNa`       |Dynamic arrays, after the core                 |
|`filesNa`, `filesNb`|Files, after the core or after dynamic arrays  |
|`trigNa` to `trigNd`|Trig, after the core plus each subset of others|
|`runtimeN`          |Every package, at `rtLow` up to $BFFF (dynamic)|

`runtimeN` is linked twice: once for its size, then at the highest page it
fits below $C000.

A variant's letter is `a` plus the `RTF_*` bits of the packages before it.
Each variant starts with a header listing the jump table entries to patch.
The link fails if the core imports from a package, a package imports from
another package, or the core differs between links. A package's variables
are reserved in the core (`pkgbss.s`), so they don't move.

The icode overlay records the features a program uses in `runtimeFeatures`
(`RTF_*` in `asm.inc`): a file variable, record field or array element
(not a parameter), a `SetLength` call, or a library call to `Sin`, `Cos` or
`Tan`. The compiler apps read it with `getIcodeRuntimeFeatures` and pass it
to `setCodeGenRuntimeFeatures`. In static mode `genRuntime.s` patches the
jump table for each needed package and the linker copies the core, then the
variant of each. Dynamic mode ignores the features. `make ALLPKGS=1` in
`src/overlays/codegenasm` links every package into every program, for
debugging.

`src/lib/runtime/rtfiles.mk` lists the runtime files. Every disk image the
compiler runs from must have them (`RTWRITE`), and dynamic programs need
`runtimeN` on the disk they run from.

A test without a file variable can't write `testfailed`. The `rtpkg*` tests
end with a runtime error instead (division by zero), which stops the chain.

### Runtime tests

The `rtpkg*` tests and `examples/fivedice.pas` say `$StaticRuntime`. Set 2
of `compilertestasm` builds every program static (`FORCESTATIC`, from
`STATICSETS` in its Makefile); sets 1 and 3 are dynamic. `rtdyn` runs with
the dynamic runtime. After set 3 compiles, `rtdyntest.sh` checks that
`rtdyna` and `rtdynb` (with and without `$DynamicRuntime`) are the same PRG
and runs `rtdynb` with a missing, a bad and a too-low `runtimeN`.

Don't write `$Word` in a `(* *)` comment of a Pascal test: the tokenizer
reads it as a directive.

## Pre-compiled headers

`src/lib/hdr/*.hdr` are generated by the `mkhdr` app. Library changes mean regenerating them.

## Non-negotiables

- NEVER reference any C code when debugging or writing code.
- NEVER modify any C code or C header files.
- When adding new behavior, add or update tests for that component.
- NEVER commit to Git without permission.
