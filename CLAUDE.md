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
  - typechecktest (see "Typecheck Tests")
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

### Themes Tests

`themestest` runs a test build of the themes overlay: `make THEMESTEST=1`
in `src/overlays/themes` defines `__THEMESTEST__` and builds `themes-test`
from `obj/mega65-test`. The normal `themes` has none of the hooks. They
are in `themestest.s`, with an `.ifdef` in `getKey` (`keybuf.s`), and ten
more jump table entries after the two real ones (`themes.inc`).

A test names a fixture to copy to `themes.dat` and one to `themes.def`
(or `NOFILE`), then runs steps: calls into the overlay (`OP_*`) and checks
(`CHK_*`), listed in `tests.inc`. Before a test the program scratches both
files, copies the fixtures with the DOS `C:` command and resets the
palette; after it, it frees the list and runs the leak check.
`OP_SCREEN` runs the theme screen with a key script (ASCII, as the
keyboard sends it). The screen opens in the theme list and only returns
on F1, so a script starts with Return and ends with F1. A script that
runs out fails the test, except under `OP_SCREENOUT`, which expects it
to, so a check can look at the screen while it waits.

The fixtures are made by `mkthemes.py` from `files/*.txt`, with the
options in `<name>_ARGS` in the Makefile (bad versions, truncated files,
version 0). `CHK_FILE` compares `themes.dat` with a fixture, so the bytes
expected after a save are `.txt` files too. Keep them ASCII and out of the
`petcat` rule. A CBM disk can't hold an empty file, so the one-byte
`onlysel` fixture stands in for one. A new fixture goes in `FIXTURES`.

### Parser Tests

`parsertest` runs four kinds of test. `tests/testN.pas` (N to `NUM_TESTS`
in `runtests.s`) holds a program and, in its header comment, the AST dump
the parser must make for it. `errortests/errorN.pas` is a program with an
error. A line of its header comment names the first error the parser must
report and its line: `Error Test 12 - expect errInvalidExpression on line
9`. `mkerrortests.py` makes the table of them, so the tests must be
numbered 1 to N with none missing. `lines.pas` (`runlinetest.s`) checks
declaration line numbers, and `dirs.pas` (`rundirtest.s`) the stack size,
runtime mode and `$Expect` handlers the compiler gets. Every `.pas` file in
`tests` and `errortests` goes on the disk.

A failed error test doesn't stop the others: the failures are listed at
the end and the suite fails after the leak check. A test that hangs the
parser times out before the emulator saves the screen, so nothing says
which one. Run some of them to find it:
`make TARGET=mega65 test ERRTESTS="-D FIRST_ERROR_TEST=50 -D LAST_ERROR_TEST=60"`.

Every error the parser reports has an error test, and so do the ways a
file can end too soon. A parser loop that stops at a bad token must take
a token or end at the end of the file, or it hangs. `doResync`
(`resync.s`) returns at once when the token is in one of its lists.
Otherwise it reports errUnexpectedToken and skips to a token in a list, a
period or the end of the file. It never skips a period.

`make TARGET=mega65 coverage` in `src/apps/parsertest` runs the tests
against copies of the parser with probes in them (editortest's
`cov/mkcov.py`) and lists the lines that never ran in
`bin/mega65/coverage.txt`. The probes don't all fit in the overlay at once,
so the files are instrumented in sets (`COVFILESn`). A new parser file must
go in a set, and a set that no longer fits fails to link and must be
split. Like `test`, it needs asmlib built with `MEMCHECK=1`.

### Resolver Tests

`resolvertest` runs two kinds of test. `tests/testN.pas` holds a program
and, in its header comment, the symbol table dump the resolver must make
for it. `runTests` runs 1 to `NUM_TESTS` (`runtests.s`) and `main` runs
0 and 8 to 11. `errortests/errorN.pas` is a program with an error. The
table in `runerrortests.s` gives the line of its first error, the error
and the number of errors (`NUM_TESTS` there too). The parser's errors
count. A failed program test names its first error and line.

A name in an expression is reported by `exprResolve` alone, once.
`getRecordSymtab` and the routines it calls return NULL for a name that
isn't declared. A field with no record table isn't looked up: if
resolving its left reported an error (`resolverErrors`), that's the
only one, and otherwise the field is reported.

The harness resolves as the compiler does: `initStandardRoutines` before
`injectSystemUnit`, and the program's scope is freed with `freeSymtab`.

`make TARGET=mega65 coverage` in `src/apps/resolvertest` runs the tests
against a copy of the resolver with probes in it (editortest's
`cov/mkcov.py`) and lists the lines that never ran in
`bin/mega65/coverage.txt`. Every file is in one set (`COVFILES1`); split
it as parsertest does if it stops fitting. Like `test`, it needs asmlib
built with `MEMCHECK=1`. The lines left are ones no source can reach,
such as a lookup in a record's table that `exprResolve` never asks for.

### Typecheck Tests

`typechecktest` runs two kinds of test. `tests/testN.pas` (N to
`NUM_TESTS` in `runtests.s`) holds a program and, in its header comment,
the AST dump the type checker must make for it. `tests/errorN.pas` (N to
`NUM_TESTS` in `runerrortests.s`) marks each error and warning it must
report with a `$ExpectError` or `$ExpectWarn` directive on that line. An
error reported twice on a line is expected twice. A test with no
directives must check without an error. The harness type checks after
resolver errors, which the compiler doesn't, so the resolver's errors
count too.

The parser only takes a directive in a statement. One between two case
branches or in a declaration is an error, so a case branch with one is a
compound statement, and a declaration with an error is in a one-line
routine whose statements hold the directive. Errors in a routine's
heading are reported on its `Procedure` line.

`make TARGET=mega65 test TESTSEL="-D FIRST_TEST=1 -D LAST_TEST=0 -D
FIRST_ERROR_TEST=14 -D LAST_ERROR_TEST=14"` runs only those tests (a first
test after the last runs none). The screen dump only shows the last
screen, so a failing test is easier to read alone.

`make TARGET=mega65 coverage` in `src/apps/typechecktest` runs the tests
against copies of the type checker with probes in them (editortest's
`cov/mkcov.py`) and lists the lines that never ran in
`bin/mega65/coverage.txt`. The probes don't all fit in the overlay at
once, so the files are instrumented in sets (`COVFILESn`). A new file
must go in a set, and a set that no longer fits fails to link and must be
split. `exprTypeCheck.s` is too big for one set, so two sets each take
part of it, split at a proc (`exprTypeCheck.s:-evalNegate`). Like `test`,
it needs asmlib built with `MEMCHECK=1`. The lines left are ones no
program can reach, such as checks for undefined names that the resolver
reports first, and `integerOperands.s` and `realOperands.s`, which
nothing calls.

`getBaseType` changes ptr1, ptr2 and ptr4, and `pushQ` doesn't keep Q.
Several bugs were a pointer used after one of them.

### Icode Tests

`icodetest` runs `tests/testN.pas` (N to `NUM_TESTS` in `runtests.s`).
Each holds a program and, in its header comment, the intermediate code
dump it must make. `expectedFeatures` in `runtest.s` lists the runtime
features (`RTF_*`) each test must find. The tests in `unitTests`
(`runtests.s`) resolve and type check their units as the compiler does:
the ones that call System routines or use `iclib.pas` (a library) or
`icunit.pas`. Every `.pas` file in `tests` goes on the disk.

`make TARGET=mega65 savedump TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m"`
writes the dump of each selected test to `bin/mega65/dumpN.txt` in place
of comparing it, for a new test's header. Check every line of it before
using it: the header is the specification. `TESTSEL` works with `test`
too.

`make TARGET=mega65 coverage` in `src/apps/icodetest` runs the tests
against copies of the icode overlay with probes in them (editortest's
`cov/mkcov.py`) and lists the lines that never ran in
`bin/mega65/coverage.txt`. The probes don't all fit in the overlay at
once, so the files are instrumented in sets (`COVFILESn`). A new file
must go in a set, and a set that no longer fits fails to link and must be
split. Like `test`, it needs asmlib built with `MEMCHECK=1`. The lines
left are ones no program can reach, such as defaults for kinds no caller
passes and cases the type checker rejects. An array literal of more than
255 elements can't be tested: the type checker hangs on one of more than
90.

In icode, `isRead` 0 asks an expression for the address of what it
names, to write to or pass by reference, and 1 for its value. The
address of `p^` is p's value. A record variable holds its heap address,
`@rec` is that address, and a record in an array or record is inline, so
reading a whole record never reads memory (`MEM`).

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

### Unary minus

A minus before a number literal sets the literal's `expr::neg`, which the
typecheck uses to type and range check it. A minus before anything else
makes an `EXPR_NEGATE` with the operand in `left` (`parseFactor`). The
typecheck keeps a signed integer's or real's type and makes Byte Integer,
and Word and Cardinal LongInt (`evalNegate`). icode converts the operand to
that type (`IC_CVI`) and negates it (`IC_NEG`), and codegen calls
`RT_NEGATE`.

### Subranges

A subrange's limits must both be integers, both characters or both values
of one enumeration. A limit can be a constant, so the resolver checks them
(`resolveSubranges`), not the parser. It gives an integer subrange the
narrowest of Byte, Word or Cardinal (low limit not negative) or ShortInt,
Integer or LongInt that holds both limits, and a character one Char. An
enumeration subrange keeps the parser's subtype, a declared type named
after its low limit (see `getBaseType`). It runs before the declaration's
symbol copies the type.

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

## Themes

The editor's syntax highlighting colors come from the themes overlay
(`src/overlays/themes`). A theme (`THEME` in `editor.inc`) is a 16-byte
PETSCII name, space-filled, and `THEME_COLORS` (11) colors of 4 bytes:
palette index 0-31, then R, G, B 0-15, in `SYNTAXHL_*` order (number,
keyword, string, comment, operator, identifier, cursor, UI, background,
error, warning). `loadDefaultTheme` fills a `THEME_BUFSIZE` buffer
indexed by `SYNTAXHL_*` (byte 0 unused) with VIC color numbers. A new
color is appended to `SYNTAXHL_*`, so no index moves.

### Theme file

`themes.dat` is the user's file and `themes.def` the defaults (F8 in the
theme screen). Version 1:

|Offset|Contents                                         |
|------|-------------------------------------------------|
|0     |`THEME_MARKER` ($FF)                             |
|1     |`THEME_VERSION` (1)                              |
|2     |The selected theme number                        |
|3     |`THEME_SIZE` (60) bytes per theme, until EOF     |

Version 0 has no marker or version: the selected number, then 52-byte
themes with the first nine colors. The reader converts it, filling in
error and warning with a copy of the theme's UI color, and the next save
(F1) writes version 1. Any other version, a file with no whole theme or a
missing file is unreadable: `themes.dat` falls back to `themes.def`, and
that to the built-in theme (`builtinTheme` in `themefile.s`). A partial
last theme is dropped, and a selected number past the end becomes 0.

Every color carries the RGB of its palette slot, so two colors on one
slot with different RGB clash (the last written wins). The theme screen
keeps a slot's colors in step when it edits one (`copyColorToTheme`) and
moves error and warning off the background's slot when the background
changes (`adjustHighlightColors`).

### Theme generator

`src/shared/mkthemes.py` writes a theme file from `src/shared/themes.txt`
(the 12 shipped themes, by name and color). The root `Makefile` builds
`bin/$(TARGET)/themes.def` from it and writes it to the D81 as both
`themes.dat` and `themes.def`. A color line is a name and an index with
R G B, an index alone (the MEGA65 default RGB) or another color's name
(a copy, as `error ui`). It warns about palette slot clashes and stops on
range, name and missing or duplicate color errors, naming the line.
`--format 0` writes version 0; `--version`, `--selected` and `--truncate`
make bad files for the tests. Theme names are ASCII; extend the PETSCII
conversion if a name needs characters it lacks.

`make mkthemes-test` (run first by `make test`) runs
`src/shared/test_mkthemes.py`: `themes.txt` against the SHA-256 of the
old blob in format 0 and the blob plus the copied colors in format 1,
the bytes of `mkthemes-tests/good.txt`, and the bad inputs in
`mkthemes-tests`, each of which names its expected line and message on
its first line.

## Pre-compiled headers

`src/lib/hdr/*.hdr` are generated by the `mkhdr` app. Library changes mean regenerating them.

## Non-negotiables

- NEVER reference any C code when debugging or writing code.
- NEVER modify any C code or C header files.
- When adding new behavior, add or update tests for that component.
- NEVER commit to Git without permission.
