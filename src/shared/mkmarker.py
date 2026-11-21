#!/usr/bin/env python3
#
# mkmarker.py
# Ken Schenke (kenschenke@gmail.com)
#
# Copyright (c) 2026
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT
#
# Writes a work disk's marker, p65work (plans/workdisks.md), as wdCreate
# in the workdisk overlay writes it: WD_MAGIC0, WD_MAGIC1, WD_VERSION and
# WD_RELEASE, zero-terminated. The values are read from workdisk.inc, and
# the characters are converted to PETSCII as ca65's c64 target does.
#
# usage: mkmarker.py <workdisk.inc> <output>

import re
import sys


def petscii(ch):
    """A character as ca65's c64 character map has it"""
    if 'a' <= ch <= 'z':
        return ord(ch) - ord('a') + 0x41
    if 'A' <= ch <= 'Z':
        return ord(ch) - ord('A') + 0xC1
    return ord(ch)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: mkmarker.py <workdisk.inc> <output>")
    with open(sys.argv[1]) as f:
        text = f.read()

    def find(pattern, what):
        m = re.search(pattern, text, re.MULTILINE)
        if not m:
            sys.exit("mkmarker.py: no %s in %s" % (what, sys.argv[1]))
        return m.group(1)

    magic0 = find(r"^WD_MAGIC0\s*=\s*'(.)'", "WD_MAGIC0")
    magic1 = find(r"^WD_MAGIC1\s*=\s*'(.)'", "WD_MAGIC1")
    version = int(find(r"^WD_VERSION\s*=\s*(\d+)", "WD_VERSION"))
    release = find(r'^\.define\s+WD_RELEASE\s+"([^"]*)"', "WD_RELEASE")

    data = bytes([petscii(magic0), petscii(magic1), version])
    data += bytes(petscii(c) for c in release) + b"\0"
    with open(sys.argv[2], "wb") as f:
        f.write(data)


if __name__ == "__main__":
    main()
