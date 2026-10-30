#!/bin/sh
#
# Runs one test program in the xmega65 emulator and reports PASS/FAIL.
#
# usage: runtest.sh <name> <prg-file> <d81-file>
#
# The emulator runs headless and at full speed. -prgexit makes it exit as soon
# as the program returns to the BASIC READY prompt, and -dumpscreen saves the
# final screen as text. The test programs (see testresult.s) print
# "RESULT: PASS" or "RESULT: FAIL" just before returning, and this script
# looks for that line. A run that hangs, crashes, or exits without printing a
# result is a failure.
#
# Environment:
#   XMEGA65      emulator command            (default: xmega65)
#   TEST_TIMEOUT seconds before giving up    (default: 900)

NAME=$1
PRG=$2
D81=$3
EMU=${XMEGA65:-xmega65}
LIMIT=${TEST_TIMEOUT:-900}

if [ -z "$NAME" ] || [ -z "$PRG" ] || [ -z "$D81" ]; then
    echo "usage: $0 <name> <prg-file> <d81-file>" >&2
    exit 2
fi

# A relative path in the current directory, not mktemp: when xmega65 is the
# Windows build run from WSL it cannot write to a Linux path such as /tmp.
SCREEN=$NAME.screen
rm -f "$SCREEN"
trap 'rm -f "$SCREEN"' EXIT

echo "=== Running $NAME"

timeout "$LIMIT" "$EMU" -besure -headless -sleepless -testing \
    -prg "$PRG" -prgexit -8 "$D81" -dumpscreen "$SCREEN" >/dev/null 2>&1
STATUS=$?

# The screen dump marks shifted letters as {X}, so strip the braces and
# ignore case when looking for the result.
RESULT=$(sed 's/[{}]//g' "$SCREEN" 2>/dev/null | tr 'a-z' 'A-Z' | grep 'RESULT: ' | tail -n 1)

case "$RESULT" in
    *"RESULT: PASS"*)
        echo "$NAME: PASS"
        exit 0
        ;;
    *"RESULT: FAIL"*)
        echo "$NAME: FAIL"
        ;;
    *)
        if [ "$STATUS" -eq 124 ]; then
            echo "$NAME: FAIL (timed out after ${LIMIT}s)"
        else
            echo "$NAME: FAIL (no result reported, emulator exit status $STATUS)"
        fi
        ;;
esac

echo "--- final screen ---"
sed 's/[{}]//g' "$SCREEN" 2>/dev/null
echo "--------------------"
exit 1
