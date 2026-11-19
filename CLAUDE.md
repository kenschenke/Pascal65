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

The project has ten test suites, located in `src/apps`:

  - tokenizertest
  - parsertest
  - resolvertest
  - typechecktest (see "Typecheck Tests")
  - icodetest
  - memtest (memory heap allocator in asmlib)
  - membuftest (membuf routines in asmlib)
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

With `__DEBUG__` defined, `heapFree` also fills the block it frees with
`$DD`, so code that reads a block after freeing it gets garbage at once
rather than the old bytes, whatever the heap's layout. A pointer read that
way is `$DDDDDDDD`, which the checks above report as a bad free, or sends
the program off into memory (no result). Three such reads were found this
way: `freeUnits` read `unit::next` after freeing the unit; `astFree` freed
a block's declarations before its statements, whose evaluated types share
the declared types (`evalType.s`); and icodetest freed the program's
symbol table before `icodeWrite`, which reads it. `astFree` now frees
every statement and value first (`astFreeBodies`), `freeUnits` frees every
unit's before freeing any unit, and icodetest frees the table after icode,
as the compiler does.

`testInit` in `testresult.s` points the KERNAL's BRK vector (`$0316`) at a trap. The trap reports any BRK as a test failure, with its code and routine. `testPass` and `testFail` restore the vector. A program that ends without either must call `testRestoreBrk`.

Each suite calls `testMemCheck` right after `initMemHeap`. It frees a block twice. If asmlib was built without the checks, that doesn't execute BRK, and the suite fails with "asmlib has no memory checks". New suites must do the same.

Each suite except memtest calls `testLeakCheck` after its tests. It walks the heap's MAT, and if any block is still allocated it prints the count and size and returns with the carry set. The suite then fails. Blocks the size of the compile-time error message buffer (`initCompilerErrors`) are skipped, because that buffer is never freed. New suites must do the same.

A test that expects a BRK (memtest's bad-free tests do) sets `brkCatch` to its own handler. The trap jumps there, with the code in `brkCode`, instead of failing.

### The CPU stack

The 6502 stack is one page, and the KERNAL keeps data in it below about
$0140. A routine that calls itself once for each item in a list overflows
it on a long list and the program hangs or crashes, often in a later
stage. Array literal elements and routine arguments are chained through
`expr::right`, so a walk over an expression must follow the right in a
loop, not a recursive call (`exprResolve`, `freeExpr`, and the argument
chain in `exprTypeCheck`, which checks each argument on its own with
`parentIsFuncCall` 2). A symbol table is an unbalanced binary tree, so
names declared in order make a chain as long as the table: `freeSymtab`
and `fixGlobalOffsets` keep the nodes to visit on the runtime stack, below
a zero marker, not in calls (resolvertest error test 47 has 258 names in
order). A hang leaves no
screen dump. To find one, fill the stack page below SP with a pattern
before a stage and look for the lowest byte it changed after.

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
EDITFILE fields, highlighting, the screen's text and its reverse bits and
colors (`CHKATTR`), files on the disk and what
`editorRun` returned. `editorReadKey` takes keys from the script. When it
runs out, the edit buffer is closed and `editorRun` returns, wherever the
editor was waiting. `getline` takes them too: `editorTestSetup` points its
jump table entry at the hook. Scripts are ASCII, as the keyboard sends them,
and the expected text is PETSCII. The `KEYS` and `TEXT` macros switch the
character map. `NEWFILE` opens a new file, a Pascal file if the test says
so, and `OPENFILE` opens a file by its row in the directory screen.
`editorRun` gets an `EDITORCTX` (`editor.inc`): the theme colors and a
pointer to a build result. A test gives it one with `TEST`'s eighth
argument (`BUILD` in `tests.inc`), or gets an empty one, and checks it
with `CHKBUILD`.
`editorTestCleanup` frees everything without prompts before the leak check.
A script that ends in the directory screen leaks its list, so it leaves it.

The tests don't fit in one program. Program N (`TESTPROGS`) runs
`src/testsN.s` from its own disk, made fresh for each run because the tests
change it. Each disk has the files in `files/`, in the order `FIXNAMES` in
the Makefile gives, which is their order in the directory screen. Saving a
file that is on the disk moves it to the end of the directory.

`buildtest` (`src/buildtest.s`), run first, doesn't use the overlay. It
links the editor app's `builderrors.s`, which keeps the IDE's build
result (`buildresult.inc`), calls `logError` and `logWarning` as the
compiler would and checks the bytes of `buildResult`.

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

A unit can use another unit (`Uses` in its interface). The parser adds a
unit to the units list once, however many modules name it (`addUnit`).
`injectUnit` skips a `Uses` in the interface: it makes the other unit
visible in the unit, not in its importers, and has no symbol in the unit's
table (it was `errMissingUnitDeclaration`). The variables `injectUnit` puts
in a unit's table get their slots from `fixGlobalOffsets`, which
`setUnitOffsets` runs on every unit's table once all are numbered; it was
only run on the program's, so a unit read another unit's variables at
level 0, offset 0. icodetest 44 and compilertestasm's `unituses` check this.

The parser adds a unit when a module first names it, so a unit only
another unit uses comes after it. `resolveUnits` first reorders the list
(`orderUnits`): each unit after the units its `Uses` name, depth first, the
rest in their order, so the program's own units keep its `Uses` order and
System stays first. Resolving, type checking, slot numbering, the init
calls and the imports all follow the new order, which the apps take back
with `getResolverUnitsList`. icode's imports table lists every library in
the units list (`icodeImports.s`), so a library only a unit uses is linked
with its init, cleanup and jump table. icodetest 45 and compilertestasm's
`unitlib` (set 1's first program) check this.

A symbol for a declaration (`resolveDeclarationName`), a parameter
(`paramListResolve`) or a unit's interface (`injectUnit`) shares the type it
was made from and has `SYMBOL_FLAG_SHAREDTYPE`, so `freeSymbol` leaves the
type alone. Declarations outlive the symbol tables (`astFreeBodies` frees
only statements and values, and units are freed last). A change to a
declaration's type is a change to its symbol's. When `resolveDeclared`
replaces a declaration's type it moves the symbol to the new one, unless
the old type's base is an enumeration: then the symbol keeps the old type
and owns it.

An expression's `evalType` is a shallow copy (`cloneEvalType` in asmlib):
it owns its name and a subtype with `TYPE_FLAG_ISTEMP`, and shares the
rest. Free it with `freeEvalType`, not `freeType`.

`getTypeSize` doesn't keep ptr1: a record's size leaves it on the last
field's type. A write through ptr1 after it once gave a record's last field
the record's size.

A symbol table node (`TREENODE`) is only as long as its key, which is its
last member. `compareKeys` moves ptr1 to the key and back.

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
split. `exprTypeCheck.s` and `checkFuncProcCall.s` are too big for one
set, so they're split at procs across sets (`exprTypeCheck.s:-saveEvalType`).
A set fits only about 240 probes, since the overlay itself is near 19k.
`mkcov` prints each set's count. Changing the sets needs a fresh
`obj/mega65/cov*`, because a set's stamp doesn't depend on the Makefile. Like `test`,
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

A test whose source is a unit is compiled on its own (unit mode), as a
unit will be compiled to its TPU. `checkUnitMode` (`runtest.s`) sees the
root is a unit, and `addMainUnit` puts it at the end of the units list
after `injectSystemUnit`, so `resolveUnits`, `setUnitOffsets` (from slot
0) and `typeCheckUnits` treat it as in a program compile; the program's
own `declResolve`, `setDeclOffsets` and `declTypeCheck` are skipped. It
must go in after `injectSystemUnit`: the parser gives the first module it
parses a `Uses` of System, and `injectSystemUnit` gives every unit in the
list another, which injected System's interface twice and leaked 33
symbols. icode sees the root is a unit (`writeUnitMode`) and writes only
the unit's own file, and dumpicode's `dumpUnitIcode` dumps it. A unit's
code is written with its own symbol table entered (`icodeUnitFile`), in
either mode, so both write the same: test 46 compiles `Test46` on its
own, and its dump is the same as `Test46`'s file in test 47's.

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
split. The overlay is near 18.9K, so a set holds only about 200 probes (17
sets), and `icodeExpr.s` is split in three at `exprField` and `exprNegate`
(`icodeExpr.s:-exprField`). Like
`test`, it needs asmlib built with `MEMCHECK=1`. The lines left are ones
no program can reach, such as defaults for kinds no caller passes and
cases the type checker rejects.

A unit's variables are level 1 slots after the program's, unit by unit in
the units list's order. The resolver numbers them in that order
(`setUnitOffsets.s`). `setDeclOffsets` skips a `DECL_USES` entry, so the
offsets come from that one pass. A library's variables are pushed by the
program's startup. A Pascal unit's are pushed by its own init block
(`icodeUnitInit`): `LOC`, the variables, then `UIR`, written before the
unit's routines. The startup calls it with `UIC`. Codegen makes `UIC` a
6502 `JSR` and `UIR` an `RTS`, since a routine's stack frame would pop
the slots. icodetest 39 and compilertestasm's `unitinit` check this.

The resolver records each unit's first slot and count in its `unit`
(`firstSlot`, `slots`), and the apps pass the program's own count to icode
(`setIcodeGlobalSlots`, from `setDeclOffsets`) for the header. icode
writes a frames table after the imports (`icodeFrames.s`): each unit or
library with slots that the module imports, in the units list's order,
with its count. A variable operand has a fourth byte, its frame: 0 for the
module's own, or a frame's number in its file's table from 1. `icodeVar`
makes a level 1 offset in a unit's range relative to the unit's first slot
(`frameOf`). Codegen writes the byte with a `LINKADDR_FRAME` relocation
against the import `name.frame` (`frames.s`), and the linker defines that
as the program's slots plus the counts of the frames before it (`frames.s`
in linkerasm) and adds it to the byte. A unit then needs no base it can't
know when compiled on its own. dumpicode shows the header's count, a `FRM
name slots` line for each frame and the frame's name after a variable
operand.

Each module has its own icode file. icode writes the program's,
`zztmpicode`, and each Pascal unit's own, `zzi` and its name
(`ICODE_UNIT_PREFIX`), from `icodeUnitRoutines`, on logical file 3 while
the program's stays open on 1, in the program's scope. A unit's file has
its header (kind unit, its own slots), its imports and frames (`moduleUnit`
and `inModule` in `icodeFrames.s`: the units its `Uses` name, and System),
its init block and routines, its data segments (`icodeKeepData`) and its
`EOM` with its own features (`icodeKeepFeatures`; `getRuntimeFeatures`
still gives them all). The program's imports list each unit
(`ICODE_IMPORT_UNIT`). Codegen reads the program's file, then each unit's
in the imports' order (`genUnits`), skipping a unit's imports and reading
its frames in place of the program's (`beginUnitFrames`). Frame 0 in a
unit's file is relocated against its own `name.frame`. A unit's code
follows the program's cleanup, which never falls through, and its data
the program's. dumpicode dumps the program's file, then each unit's. A DOS
command (`doesFileExist`, `scratchFile`) closes the command channel,
which closes every open file, so icode erases the old unit files before
it opens any (`icodeEraseUnitFiles`) and codegen deletes the icode files
only once the code file is closed (`deleteIcode`).

A variable operand's offset is one byte, so a scope has at most 256 slots,
and level 1 is one scope for the program and all its units. `setVarOffset`
(`setDeclOffsets.s`) reports `errTooManyVariables` at the variable that
takes offset 256, once per scope. `setUnitOffsets` reports a unit's in the
unit's file and puts the caller's file name back. The linker doesn't check
the frames' sum yet, since today one compile numbers every module; separate
compilation will need it. resolvertest error tests 47 and 48 and
compilertestasm's `slots256` (set 1's first program, all 256 slots used)
and `toomanyvars` (an error test) check this.

In icode, `isRead` 0 asks an expression for the address of what it
names, to write to or pass by reference, and 1 for its value. The
address of `p^` is p's value. A record variable holds its heap address,
`@rec` is that address, and a record in an array or record is inline, so
reading a whole record never reads memory (`MEM`).

### Heap Tests

`memtest` checks block addresses and exact MAT entries. When you change `memheap.s`, run `make TARGET=mega65 coverage` in `src/apps/memtest`. It runs the tests against a copy of `memheap.s` with a probe at every basic block (`cov/mkcov.py`) and lists the lines that never ran.

### Membuf Tests

`membuftest` tests the membuf routines (`src/lib/asmlib/src/membuf`). A
membuf is a header and a chain of 50-byte chunks. Each test keeps a model
of its membufs: their bytes, position and used. `WRITE`, `READ` and `SEEK`
do the same to the membuf and the model, `CHECK` walks the chunk chain
itself and compares it and the header with the model, and `CHKCUR` checks
which chunk is current and `posChunk`. Two membufs can be open at once
(`SELECT`). `TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m"` runs only those
tests (remove `obj/mega65/main.o` first).

A position at the end of a chunk is in that chunk, with `posChunk` 50, so
`setMemBufPos` to the capacity still has a current chunk, and a position
past the last chunk is the capacity. A membuf with chunks always has a
current chunk. A write that runs into a chunk already there takes the rest
of the caller's bytes, not the first ones again.

`make TARGET=mega65 coverage` in `src/apps/membuftest` runs the tests
against instrumented copies of the membuf files (editortest's
`cov/mkcov.py`) linked into the test program, with `cov/covpatch.s`
pointing asmlib's jump table at them, and lists the lines that never ran in
`bin/mega65/coverage.txt`. Every line runs. Like `test`, it needs asmlib
built with `MEMCHECK=1`.

### Compiler Tests

`compilertestasm` runs as three sets because all the compiled programs don't fit on one D81. A set's D81 also needs free space for the files its tests write (set 2's file tests hang on a full disk, which leaves no screen dump). Every D81 holds the compiler and its overlays, so an overlay that grows takes room from all three. The sources only set 3 compiles go on set 3's disk alone (`SET3PAS` and `SET3WRITE` in the Makefile). The `test` target runs a compile step, then a run step. Any compiler error or warning fails the compile step. Any test failure leaves a `testfailed` file that makes the last program, `done`, print FAIL. When you add a test, add it to `compiletests.s` (in one of the sets, `TESTSETS` and `FIRSTTESTn` in the Makefile) and to the D81 file list in the Makefile.

A program the compiler must refuse goes in `errorTests` in `compiletests.s` instead, followed by the error number it must report. These are compiled first and never run. The resolver reports some errors (`toomanyvars`), and one that code generation passes is linked, since the linker reports some errors. The compile step fails unless each one reports exactly that one error and leaves no object file and no PRG. `toolarge.pas` checks `errCodeSegmentOverflow`, which the linker reports when the program, a 256-byte minimum heap and the runtime stack don't fit below $C000 (static) or `rtLow` (dynamic). A dynamic program gets `errCodeSegmentOverflowDyn` ("Too big; try static") instead, so set 1 expects that and set 2 the other. Either is followed by a line, printed by the linker, saying how many bytes too large the program is.

A program that only has to compile and link, without an error or warning, goes in `compileOnlyTests`. It isn't run. `examples/fivedice.pas` is there, with the Screen library on the D81, to check the runtime leaves it room.

After a set's compile step, `prgsums.sh` checks every PRG it compiled against its SHA-256 in `prgsums/setN.txt`, so a change that mustn't change the programs (`plans/objcode.md`) is checked. A new test, or a change meant to change the code, needs new checksums: check the programs, then `make TARGET=mega65 savesums` in `src/apps/compilertestasm` (asmlib built with `MEMCHECK=1`) records them.

## Object file

Code generation writes only the program's own code, starting with the program header (`prgHeader.s`), to `zzcode` and keeps its linker tags (`linkerTags.s` in asmlib) in the heap. At the end `writeObjFile` (`objFile.s`) writes the object file, `zztmp`: a header (with the runtime mode, features and stack size), symbols, imports, the libraries, a relocation for each tag, then the code copied from `zzcode` (format in `linker.inc`). It deletes `zzcode` and frees the tags, so the codegen and linker overlays share nothing through the heap. A tag's location is its offset in the code, and a relocation's target is the offset of the label it names, so local labels need no symbol. A label referenced but never set is an import: the relocation has `LINKADDR_IMPORT` in its kind and the import's number as its target. Codegen keeps each import in the tag tree with `linkTagSet`.

The imports are library slots and linker symbols (`linker.inc`): the runtime's BSS, `heapbottom`, `stacktop`, `heaptop` and `rtinit`. icode lists each library the program or its units use, in the units list's order, with the kinds of its jump table's slots in the icode file's imports table (`icodeImports.s`, `ICODE_IMPORT_*` in `icode.inc`). Code generation keeps the table in a membuf (`imports.s`), calls each library's init (slot 0) and cleanup (slot 1) from it and copies it into the object file. Code generation doesn't use the AST or the units list. dumpicode shows each import as `IMP LIB name slotcount`, then its slots' kinds (`R` or `V`).

A reference to another module's entry is the label `name.N`: the module's name and the entry's number in decimal (`icodeExports.s`). A library's slots and a unit's entries are numbered alike: 0 the init, 1 the cleanup, then from 2 each interface routine and variable in order. icode names library calls and variables (`SSP`), a unit's init block (`UIC`), its interface routines (calls, `@`, their `LOC`) and its interface record and array variables' blocks (`DAT`, `DIR`, `DIA`, `DCC`, `DCF`, `SAL`) that way, through `icodeFormatDeclLabel`. A unit routine's symbol names its body's declaration, so an entry is matched through its interface declaration's symbol (`decl::node`). Code generation names the init and cleanup calls, and the linker defines `name.N` at each slot. No other label has a period: a block's field and element labels add `+` and an offset. A library's record and array variables are the program's, built by its startup, so their blocks keep their own labels (`icodeFormatBlockLabel`). dumpicode masks labels as `xxxxx` but shows an entry in full. icodetest 35, 39 and 43 and compilertestasm's `unitrefs` (set 1's first program) check this.

Every other label is local to its icode file, and is made from a heap address, so it is unique only in one compile. Code generation reads every file into one object, so a label from a unit's file that isn't an entry gets a scope byte in front, $80 plus the unit's number (`labelScope` and `scopeLabel` in `readOperand.s`), in instructions and inside `DAT` blocks (each saved block keeps its scope, `segmentScope`). A unit compiled on its own can then use the same labels as the program. Labels never reach the PRG, so every checksum stayed the same. A one-off build that put `BRA main` and `LOC main` in each unit's init block ran set 1 with the scoping and hung without it.

The linker (`genObjCode.s`) decides every address (`rtlayout.inc`). It reads the header (`errObjFileInvalid`), the imports (`imports.s`), the libraries and the relocations, sorted by offset (`sortLinkerTags.s`). It lays out the BASIC line, the runtime (`runtime.s`), each library (`loadLibrary.s`, which defines a symbol at each slot), the program module and the runtime's BSS (`runtimeBss.s`). An import nothing defines is `errUndefinedLabel`, with its name printed after it, and a missing or bad library is `errLibraryFileInvalid`. Then it checks the size (`checkCodeSize`) and writes the PRG, patching each relocation as it copies the code. Any error deletes the object file and leaves no PRG.

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

### Constant expressions

A positive literal under 128 is a ShortInt, so `4 * 12` is typed Integer.
The precision warnings (`checkIntegerPrecisionWarning`) and the mixed-sign
comparison warning (`checkConstOperand`) first ask `evalConstInt` for the
value of an expression of integer literals, constants, unary minus, `+`,
`-` and `*`, and warn only if the value doesn't fit. Anything else (Div,
a variable, a step past 32 bits) is checked by its type as before. The
value is only for warnings: the expression isn't folded or marked
`TYPE_FLAG_ISCONST`.

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
`getParserRuntimeMode` to `setIcodeRuntimeMode`, with the stack size
(`setIcodeStackSize`). The icode file's header carries both to code
generation (`readIcodeHeader` in codegenasm). The header is the file's
first bytes, before the instructions (`ICODE_*` in `icode.inc`). It holds
the format version, the kind (program or unit), the mode, the stack size
and the module's name. dumpicode prints it as the dump's first line,
`HDR PRG name mode stacksize`. A header code generation can't read is
`errIcodeFileInvalid`.

- **Dynamic, the default.** The PRG has an empty jump table at `RT_BASE` and
  the loader (`loader.s` in linkerasm) after it. The header calls the
  loader in place of `RT_RUNTIMEERRORINIT`. It loads `runtimeN` at `rtLow`
  (from the file's header, `RTH_*` in `asm.inc`), copies the jump table,
  patches the header's stack and heap tops and jumps to
  `RT_RUNTIMEERRORINIT`. A missing or bad runtime, or a program that doesn't
  fit below `rtLow`, prints a message and returns to BASIC. The linker
  reads `runtimeN`'s header at link time for `rtLow`, which `checkCodeSize`
  uses as the ceiling, and patches the header's address into the loader's
  first two instructions.
- **Static.** The linker (`runtime.s`) reads the core's jump table, patches
  it from each needed package's header, writes it and copies the rest of
  the core and the packages straight into the PRG.

The mode, the features and the stack size travel in the object file's
header, so the linker needs no entry point of its own for them.

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
`Tan`. They are known only once the code is written, so the file's last
instruction, `EOM`, carries them to code generation, which writes them to
the object file. In static mode the linker (`runtime.s`)
patches the jump table for each needed package and copies the core, then
the variant of each. Dynamic mode ignores the features. `make ALLPKGS=1` in
`src/overlays/codegenasm` links every package into every program, for
debugging.

`src/lib/runtime/rtfiles.mk` lists the runtime files. Every disk image the
compiler runs from must have them (`RTWRITE`), and dynamic programs need
`runtimeN` on the disk they run from.

Code generation keeps the code it writes short by calling the runtime for
anything it would repeat (`callframe.s`). Most of these routines take
their operands from the bytes after the `JSR` (`fetchInline1` to `3`
read them and move the return address past them on the CPU stack), so
the generated code is the `JSR` and the bytes: reading a variable or its
address (with a short form for a global), an assignment, a
comparison, `+` and `-`, a conversion, a constant, a branch and a call.

A call is `PUF`: `pushFrameCall` (or `pushFrameCall2` for a routine at
level 2) pushes the frame with no return address; then the arguments;
then `ASF` and `JSR` together: `callRoutine` (or `callLibRoutine`, and
the level 2 forms) takes the level and the routine's address from the
bytes after its `JSR`, activates the frame and stores the address past
them as the frame's return address; then the parameters' `POP`s and
`POF` together: `popFrameN` takes the number of parameters (plus $80 for
a function). Code generation holds `ASF` and the `POP`s back for this
(`pendingAsf`, `pendingPops` in `processIcodeInstructions.s`); any other
instruction writes the held `POP`s first. A call through a routine
pointer (`PPF`, `JRP`) still uses `pushFrame` with the return address.

A new jump table entry grows `RT_JMPTBL_SIZE` and needs a new
`RT_ABI_VERSION` once the old one has been released.

A test without a file variable can't write `testfailed`. The `rtpkg*` tests
end with a runtime error instead (division by zero), which stops the chain.

### Runtime tests

The `rtpkg*` tests, `soundfx` and `examples/fivedice.pas` say
`$StaticRuntime`. Set 2
of `compilertestasm` builds every program static (`FORCESTATIC`, from
`STATICSETS` in its Makefile); sets 1 and 3 are dynamic. `rtdyn` runs with
the dynamic runtime. After set 3 compiles, `rtdyntest.sh` checks that
`rtdyna` and `rtdynb` (with and without `$DynamicRuntime`) are the same PRG
and runs `rtdynb` with a missing, a bad and a too-low `runtimeN`. It also
runs `rterrexit`, which ends with a runtime error: `exit` (runtime) puts the
KERNAL's IRQ handler back and jumps to the program's exit handler, the
start of the libraries' cleanup, so the program must print the error and
return to BASIC. The chained tests can't check that: an error stops the
chain.

A function's String result is a string object (the type checker sets
`evalTypeKind` of a call returning String to `TYPE_STRING_OBJ`), so the
assignment, the parameter copy (`SCV`) or the concatenation that uses it
frees it. `strleak` calls such functions thousands of times and runs out
of memory if one leaks.

The header switches the BASIC ROM out of $A000-$BFFF. A large program's
cleanup is under it, so the cleanup switches it back in from a stub it
writes at $1600 (`prgCleanup.s`). `soundfx` is static and large enough
that its cleanup and chain code are under the ROM.

### Library callbacks

A library that runs a Pascal routine from an interrupt (System's raster
callback, Sprites' collision callback, Sound's done callback) brackets
the call with `rtIrqCallBegin` and `rtIrqCallEnd` (`irqcall.s` in the
runtime). They save the runtime's zero page and the runtime variables an
expression uses for a moment, which `irqcall.s` holds in one block (a new
one of those goes there), and the inputs of the hardware multiplier and
divider ($D770-$D777), move `sp` down, and set `stackP` and
`currentNestingLevel` to the program's frame (kept by `rtStackInit`) and
level 1: the interrupted code may be between setting one and the other.
After `rtLibCallRoutine` the library pops the parameters and calls
`rtLibStackCleanup`, which pulls the byte `rtLibCallRoutine` leaves on
the CPU stack. compilertestasm's `irqcb` and `soundseq` test this.

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

## Library object files

`loadLibrary.s` (linkerasm) reads two formats
(`docs/docs/libraries/objfile.md`). v1 is the ld65 PRG, relocated by
treating any byte in the library's own pages as an address's high byte.
v2 (load address $0000) carries a table of the addresses, written by
`src/lib/mkreloc.py`, which links twice and fails on `#<label` or
`#>label`. Its BSS isn't in the file; the loader writes zeros for it.
`demolib2` (demolib's `src2`, tested by compilertestasm's `libtest2`)
is the v2 twin of demolib.

## Pre-compiled headers

`src/lib/hdr/*.hdr` are generated by the `mkhdr` app. Library changes mean regenerating them. `mkhdr` parses the unit and writes the records with `hdrWrite` (`src/shared/hdr/hdrwrite.s`), which a Pascal unit's TPU will use for its interface: it writes the header and every record reachable from a module's root declaration to the current output, and returns the count or an `HDR_ERR_*` code. `make TARGET=mega65 checkhdrs` in `src/apps/mkhdr` (`checkhdrs.sh`) runs `mkhdr` headless for each library and compares what it writes with `src/lib/hdr`; `savehdrs` copies them there.

## Non-negotiables

- NEVER reference any C code when debugging or writing code.
- NEVER modify any C code or C header files.
- When adding new behavior, add or update tests for that component.
- NEVER commit to Git without permission.
