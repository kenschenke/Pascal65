#!/bin/sh
#
# Tests the dynamic runtime's loader (loader.s in codegenasm) and the
# $DynamicRuntime directive, with programs set 3 compiled.
#
# usage: rtdyntest.sh <d81-file> <abi-version>
#
#   1. rtdyna ($DynamicRuntime) and rtdynb (no directive) must be the same
#      PRG.
#   2. rtdynb is run from a disk without runtimeN, with a runtimeN whose
#      header is bad, and with one whose rtLow is too low for the program.
#      Each time the loader must print its message and return to BASIC.
#
# Environment:
#   XMEGA65      emulator command            (default: xmega65)
#   TEST_TIMEOUT seconds before giving up    (default: 120)

D81=$1
ABI=$2
EMU=${XMEGA65:-xmega65}
LIMIT=${TEST_TIMEOUT:-120}

if [ -z "$D81" ] || [ -z "$ABI" ]; then
    echo "usage: $0 <d81-file> <abi-version>" >&2
    exit 2
fi

# The Windows tools can't open a Linux path, so work in the disk's directory
# with relative names
cd "$(dirname "$D81")" || exit 1
D81=$(basename "$D81")
RT=runtime$ABI
FAILED=0

echo "=== Running rtdyn"

fail() {
    echo "rtdyn: FAIL ($1)"
    FAILED=1
}

rm -f rtdyna.prg rtdynb.prg
c1541 "$D81" -read rtdyna rtdyna.prg >/dev/null 2>&1
c1541 "$D81" -read rtdynb rtdynb.prg >/dev/null 2>&1
if [ ! -s rtdyna.prg ] || [ ! -s rtdynb.prg ]; then
    fail "rtdyna or rtdynb is not on $D81"
    exit 1
fi
cmp -s rtdyna.prg rtdynb.prg || fail "\$DynamicRuntime changes the PRG"

# A runtime file's first bytes: its load address, then its header (RTH_* in
# asm.inc). A bad magic number, and a good header with rtLow at $2100. The
# loader takes a file that ends in its header as bad, so some of the jump
# table follows.
VER=$(printf '\\%03o' "$ABI")
PAD='\114\000\000\114\000\000\114\000\000'
printf '\000\173BAD!'"$VER"'\000\173\000\000\000\000'"$PAD" > rtbad.prg
printf '\000\041P65R'"$VER"'\000\041\000\000\000\000'"$PAD" > rtlow.prg

# usage: run <case> <runtime file, or ""> <text the loader must print>
run() {
    DISK=rtdyn-$1.d81
    SCREEN=rtdyn-$1.screen
    rm -f "$DISK" "$SCREEN"
    c1541 -format "rtdyn,8a" d81 "$DISK" >/dev/null 2>&1
    if [ -n "$2" ]; then
        c1541 "$DISK" -write "$2" "$RT,prg" >/dev/null 2>&1
    fi
    timeout "$LIMIT" "$EMU" -besure -headless -sleepless -testing \
        -prg rtdynb.prg -prgexit -8 "$DISK" -dumpscreen "$SCREEN" \
        >/dev/null 2>&1
    STATUS=$?
    TEXT=$(sed 's/[{}]//g' "$SCREEN" 2>/dev/null | tr 'a-z' 'A-Z')
    if [ "$STATUS" -eq 124 ]; then
        fail "$1: timed out after ${LIMIT}s"
    elif ! echo "$TEXT" | grep -q "$3"; then
        fail "$1: no \"$3\""
    elif ! echo "$TEXT" | sed -n "/$3/,\$p" | grep -q '^READY\.'; then
        fail "$1: didn't return to BASIC"
    else
        rm -f "$DISK" "$SCREEN"
        return
    fi
    echo "--- final screen ---"
    sed 's/[{}]//g' "$SCREEN" 2>/dev/null
    echo "--------------------"
}

run missing "" "RUNTIME FILE RUNTIME$ABI NOT FOUND"
run invalid rtbad.prg "RUNTIME FILE RUNTIME$ABI IS INVALID"
run toolow rtlow.prg "PROGRAM TOO LARGE FOR DYNAMIC RUNTIME; TRY \$STATICRUNTIME"

rm -f rtbad.prg rtlow.prg rtdyna.prg rtdynb.prg
if [ "$FAILED" -eq 0 ]; then
    echo "rtdyn: PASS"
    exit 0
fi
exit 1
