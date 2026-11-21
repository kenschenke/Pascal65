#!/usr/bin/env python3
#
# Writes a one-line BASIC 65 program, 10 RUN "name",U<unit>, as a PRG.
#
# usage: mkboot.py <name> <unit> <output>
#
# Set 4's run step (see the Makefile) starts with it, so the first test is
# loaded from the work disk and DEVNUM is the work disk's unit for it, as
# it is for every program the chain loads. The emulator's -prg doesn't
# load from a unit, so DEVNUM would be the system disk's, and the first
# program would read runtimeN and write testfailed there.

import sys

BASIC_START = 0x2001
TOKEN_RUN = 0x8A


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: mkboot.py <name> <unit> <output>")
    name, unit, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    # An unshifted letter in PETSCII is the ASCII capital
    text = b'"' + name.upper().encode("ascii") + b'",U' + \
        str(unit).encode("ascii")
    line = bytes([10, 0, TOKEN_RUN]) + text + b"\0"
    link = BASIC_START + 2 + len(line)
    prg = bytes([BASIC_START & 0xFF, BASIC_START >> 8,
                 link & 0xFF, link >> 8]) + line + b"\0\0"
    with open(out, "wb") as f:
        f.write(prg)


if __name__ == "__main__":
    main()
