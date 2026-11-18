#!/bin/sh
#
# Checks that the compiler makes the same PRGs as before (plans/objcode.md).
# A set's compile step writes its programs to the set's disk image. Each one
# must match the SHA-256 recorded for it in prgsums/setN.txt.
#
# usage: prgsums.sh list <d81-file>
#        prgsums.sh check <d81-file> <before-list> <sums-file>
#        prgsums.sh save <d81-file> <before-list> <sums-file>
#
#   list   prints the names of the PRG files on the disk. The Makefile keeps
#          the list from before the compile step, so the files the step
#          added are the compiled programs.
#   check  fails unless each compiled program has a recorded checksum and
#          matches it.
#   save   records the checksums of the compiled programs (make savesums).

MODE=$1
D81=$2
BEFORE=$3
SUMS=$4

if [ -z "$MODE" ] || [ -z "$D81" ]; then
    echo "usage: $0 list|check|save <d81-file> [<before-list> <sums-file>]" >&2
    exit 2
fi

# An absolute path, for a file named before the cd below
abspath() {
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

if [ "$MODE" != list ]; then
    if [ -z "$BEFORE" ] || [ -z "$SUMS" ]; then
        echo "usage: $0 $MODE <d81-file> <before-list> <sums-file>" >&2
        exit 2
    fi
    BEFORE=$(abspath "$BEFORE")
    SUMS=$(abspath "$SUMS")
fi

# c1541 is a Windows program and can't open a Linux path, so work in the
# disk's directory with relative names
cd "$(dirname "$D81")" || exit 1
D81=$(basename "$D81")

# The PRG files on the disk, one name a line
prgNames() {
    c1541 "$D81" -list 2>/dev/null | tr -d '\r' |
        sed -n 's/^[0-9][0-9]* *"\([^"]*\)" *prg.*$/\1/p'
}

if [ "$MODE" = list ]; then
    prgNames
    exit 0
fi

# The compiled programs: the PRG files that weren't on the disk before
compiled() {
    prgNames | while read -r name; do
        grep -qxF "$name" "$BEFORE" || echo "$name"
    done
}

# The SHA-256 of a PRG on the disk
prgSum() {
    rm -f prgsum.tmp
    c1541 "$D81" -read "$1" prgsum.tmp >/dev/null 2>&1
    if [ ! -s prgsum.tmp ]; then
        echo "missing"
    else
        sha256sum prgsum.tmp | cut -d ' ' -f 1
    fi
    rm -f prgsum.tmp
}

NAMES=$(compiled)
if [ -z "$NAMES" ]; then
    echo "prgsums: FAIL (no compiled programs on $D81)"
    exit 1
fi

if [ "$MODE" = save ]; then
    : > "$SUMS"
    for name in $NAMES; do
        echo "$name $(prgSum "$name")" >> "$SUMS"
    done
    echo "prgsums: saved $(wc -l < "$SUMS") checksums to $SUMS"
    exit 0
fi

if [ "$MODE" != check ]; then
    echo "$0: unknown mode $MODE" >&2
    exit 2
fi

echo "=== Checking PRG checksums"
FAILED=0
for name in $NAMES; do
    # Git's autocrlf may check the sums out with CRLF line endings
    WANT=$(tr -d '\r' < "$SUMS" 2>/dev/null |
        sed -n "s/^$name \([0-9a-f]*\)$/\1/p")
    GOT=$(prgSum "$name")
    if [ -z "$WANT" ]; then
        echo "$name: no checksum recorded (make savesums)"
        FAILED=1
    elif [ "$GOT" != "$WANT" ]; then
        echo "$name: PRG differs from the recorded checksum"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo "prgsums: PASS"
    exit 0
fi
echo "prgsums: FAIL"
exit 1
