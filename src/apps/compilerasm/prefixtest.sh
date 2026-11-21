#!/bin/sh
#
# prefixtest.sh
#
# Tests the compiler's unit prefix (9:name, plans/workdisks.md). Each case
# copies compiler.d81 (the system disk, unit 8), writes autosrc to it,
# makes a unit 9 disk and runs the compiler headless with both mounted.
#
# A compile that succeeds doesn't return to the READY prompt the way
# -prgexit sees it, so the emulator would run until the timeout and, on
# WSL, be left running (see CLAUDE.md, "Orphaned emulators"). The source
# has a parse error instead: the compiler must find it, which shows which
# disk it was given, report the error and return.
#
#   work    9:prog.pas, unit 9 a work disk with prog.pas and no runtimeN.
#           prog.pas must be compiled from unit 9, runtimeN copied there,
#           and the system disk left unchanged.
#   blank   9:prog.pas, unit 9 blank. The compiler must say it isn't a
#           work disk and write nothing.
#   nodev   11:prog.pas. Nothing answers on unit 11.
#   badunit 7:prog.pas. The compiler must say the units are 8 to 30.
#   single  8:prog.pas, prog.pas on the system disk: single-disk mode, so
#           nothing is written to unit 9.
#
# Usage (from src/apps/compilerasm, after make TARGET=mega65):
#   sh prefixtest.sh        (make TARGET=mega65 test runs it)
#
# Like runtest.sh, it runs $XMEGA65 (default xmega65) and needs relative
# paths, since c1541 and the emulator are Windows programs.

EMU=${XMEGA65:-xmega65}
LIMIT=${TEST_TIMEOUT:-300}
BIN=bin/mega65
OBJ=obj/mega65
SYS=$BIN/ptsys.d81
WORK=$BIN/ptwork.d81
SCREEN=$BIN/pt.screen
RTNAME=runtime$(sed -n 's/^RT_ABI_VERSION *= *\([0-9]*\).*/\1/p' \
    ../../asminc/asm.inc)
PARSEERR="error: missing ; -- prog.pas, line 3"
FAILED=0

mkdir -p $OBJ
printf 'Program Prog;\nBegin\n    Writeln(%s) x;\nEnd.\n' "'hi'" \
    | petcat -w2 -text -o $OBJ/prog.petscii
python3 ../../shared/mkmarker.py ../../asminc/workdisk.inc $OBJ/p65work

fail() {
    echo "$1: FAIL ($2)"
    echo "--- final screen ---"
    sed 's/[{}]//g' $SCREEN 2>/dev/null | grep -v '^ *$'
    echo "--------------------"
    FAILED=1
}

# The system disk, with autosrc naming $1
mksys() {
    rm -f $SYS
    cp $BIN/compiler.d81 $SYS
    echo "$1" | petcat -w2 -text -o $OBJ/autosrc.petscii
    c1541 $SYS -write $OBJ/autosrc.petscii autosrc,seq >/dev/null 2>&1
}

# Unit 9's disk: blank, then the files given as c1541 arguments
mkwork() {
    rm -f $WORK
    c1541 -format work,9a d81 $WORK "$@" >/dev/null 2>&1
}

# Runs the compiler. Fails if it didn't return.
run() {
    rm -f $SCREEN
    timeout "$LIMIT" "$EMU" -besure -headless -sleepless -testing \
        -prg $BIN/compiler -prgexit -8 $SYS -9 $WORK \
        -dumpscreen $SCREEN >/dev/null 2>&1
    if [ $? -eq 124 ]; then
        echo "$1: FAIL (timed out after ${LIMIT}s; kill xmega65.exe)"
        FAILED=1
        return 1
    fi
}

# Succeeds if the disk image $1 has the file $2
has() {
    c1541 $1 -list 2>/dev/null | grep -qi "\"$2\""
}

screenHas() {
    sed 's/[{}]//g' $SCREEN 2>/dev/null | tr 'A-Z' 'a-z' | grep -qF "$1"
}

# Succeeds if unit 9's disk has nothing but the files named
onlyFiles() {
    test "$(c1541 $WORK -list 2>/dev/null | grep -c '"[^"]*" *[a-z]*')" \
        -eq $(($# + 1))     # The header line has quotes too
}

# work
mksys "9:prog.pas"
mkwork -write $OBJ/p65work p65work,seq -write $OBJ/prog.petscii prog.pas,seq
SUM=$(sha256sum $SYS | cut -d' ' -f1)
if run work; then
    if ! screenHas "$PARSEERR"; then
        fail work "prog.pas wasn't compiled"
    elif ! has $WORK $RTNAME; then
        fail work "no $RTNAME on unit 9"
    elif [ "$(sha256sum $SYS | cut -d' ' -f1)" != "$SUM" ]; then
        fail work "the system disk changed"
    else
        echo "work: PASS"
    fi
fi

# blank
mksys "9:prog.pas"
c1541 $SYS -write $OBJ/prog.petscii prog.pas,seq >/dev/null 2>&1
mkwork
if run blank; then
    if ! screenHas "device 9: not a work disk"; then
        fail blank "no message"
    elif screenHas "compiling"; then
        fail blank "it compiled"
    elif ! onlyFiles; then
        fail blank "a file was written to unit 9"
    else
        echo "blank: PASS"
    fi
fi

# nodev
mksys "11:prog.pas"
c1541 $SYS -write $OBJ/prog.petscii prog.pas,seq >/dev/null 2>&1
mkwork
if run nodev; then
    if ! screenHas "device 11: nothing answers"; then
        fail nodev "no message"
    elif screenHas "compiling"; then
        fail nodev "it compiled"
    else
        echo "nodev: PASS"
    fi
fi

# badunit
mksys "7:prog.pas"
c1541 $SYS -write $OBJ/prog.petscii prog.pas,seq >/dev/null 2>&1
mkwork
if run badunit; then
    if ! screenHas "devices are 8 to 30"; then
        fail badunit "no message"
    elif screenHas "compiling"; then
        fail badunit "it compiled"
    else
        echo "badunit: PASS"
    fi
fi

# single
mksys "8:prog.pas"
c1541 $SYS -write $OBJ/prog.petscii prog.pas,seq >/dev/null 2>&1
mkwork
if run single; then
    if ! screenHas "$PARSEERR"; then
        fail single "prog.pas wasn't compiled"
    elif ! onlyFiles; then
        fail single "a file was written to unit 9"
    else
        echo "single: PASS"
    fi
fi

rm -f $SYS $WORK $SCREEN $OBJ/autosrc.petscii $OBJ/prog.petscii $OBJ/p65work

if [ "$FAILED" -eq 0 ]; then
    echo "prefixtest: PASS"
    exit 0
fi
echo "prefixtest: FAIL"
exit 1
