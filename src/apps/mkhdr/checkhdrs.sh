#!/bin/sh
#
# checkhdrs.sh
#
# Runs mkhdr in the emulator, headless, for each library unit and compares
# the .hdr it writes with the one checked in under src/lib/hdr. With "save"
# as the first argument it copies the new headers there instead.
#
# Usage (from src/apps/mkhdr, after make TARGET=mega65):
#   sh checkhdrs.sh [save]
#
# Like runtest.sh, it runs $XMEGA65 (default xmega65) and needs relative
# paths, since c1541 and the emulator are Windows programs.

EMU=${XMEGA65:-xmega65}
LIMIT=${TEST_TIMEOUT:-300}
MODE=$1
UNITS="system screen sprites spritemove time sound"
BIN=bin/mega65
HDRDIR=../../lib/hdr
FAILED=0

for u in $UNITS; do
    rm -f $BIN/gen.d81 $BIN/gen.screen $BIN/$u.hdr autosrc.petscii
    cp $BIN/mkhdr.d81 $BIN/gen.d81
    echo "$u.pas" | petcat -w2 -text -o autosrc.petscii
    c1541 $BIN/gen.d81 -write autosrc.petscii autosrc,seq >/dev/null 2>&1
    timeout "$LIMIT" "$EMU" -besure -headless -sleepless -testing \
        -prg $BIN/mkhdr -prgexit -8 $BIN/gen.d81 \
        -dumpscreen $BIN/gen.screen >/dev/null 2>&1
    c1541 $BIN/gen.d81 -read "$u.hdr" $BIN/$u.hdr >/dev/null 2>&1
    if [ ! -s $BIN/$u.hdr ]; then
        echo "$u.hdr: not written"
        sed 's/[{}]//g' $BIN/gen.screen 2>/dev/null | grep -v '^ *$' | tail -5
        FAILED=1
    elif [ "$MODE" = save ]; then
        cp $BIN/$u.hdr $HDRDIR/$u.hdr
        echo "$u.hdr: saved"
    elif cmp -s $BIN/$u.hdr $HDRDIR/$u.hdr; then
        echo "$u.hdr: same"
    else
        echo "$u.hdr: DIFFERENT"
        FAILED=1
    fi
done
rm -f $BIN/gen.d81 $BIN/gen.screen autosrc.petscii

if [ "$FAILED" -eq 0 ]; then
    echo "checkhdrs: PASS"
    exit 0
fi
echo "checkhdrs: FAIL"
exit 1
