###
 # mkreloc.py
 # Ken Schenke (kenschenke@gmail.com)
 #
 # Links a library in the v2 format (a relocation table).
 #
 # Copyright (c) 2026
 # Use of this source code is governed by an MIT-style
 # license that can be found in the LICENSE file or at
 # https://opensource.org/licenses/MIT
###

# The library is linked twice: at START (a page boundary) and at START plus
# SHIFT. SHIFT's low byte isn't zero, so every address in the library
# differs in both bytes between the two links, by exactly SHIFT. A byte that
# differs any other way is half of an address (#<label or #>label), which
# can't be relocated, and the link fails with its offset.
#
# The output is:
#
#   $00 $00          load address 0 marks v2 (page 0 is never a library's)
#   page             START's page
#   code length      word
#   BSS length       word
#   reloc count      word
#   offsets          one word per address: its low byte's offset in the code
#   code             the first link, without its load address
#
# BSS isn't in the file. The loader adds BSS length zero bytes after the
# code. The BSS length comes from the first link's map file.
#
# ld65 is the Windows build, so every path given to it must be relative.

import argparse
import os
import re
import subprocess
import sys

SHIFT = 0x2081


def fail(msg):
    print('mkreloc: ' + msg, file=sys.stderr)
    sys.exit(1)


def link(cfg, start, out, mapfile, objects):
    cmd = ['ld65', '-C', cfg, '-S', '0x{:04x}'.format(start), '-o', out]
    if mapfile:
        cmd += ['-m', mapfile]
    cmd += objects
    r = subprocess.run(cmd)
    if r.returncode != 0:
        fail('ld65 failed')
    with open(out, 'rb') as f:
        return f.read()


def segments(mapfile):
    # Returns {name: (start, size)} from the map's segment list
    segs = {}
    inList = False
    with open(mapfile, 'r') as f:
        for line in f:
            if line.startswith('Segment list:'):
                inList = True
                continue
            if inList:
                if line.startswith('Exports list') or \
                        line.startswith('Imports list'):
                    break
                m = re.match(r'^(\w+)\s+([0-9A-Fa-f]{6})\s+([0-9A-Fa-f]{6})'
                             r'\s+([0-9A-Fa-f]{6})', line)
                if m:
                    segs[m.group(1)] = (int(m.group(2), 16),
                                        int(m.group(4), 16))
    return segs


def relocs(a, b, start):
    # Returns the offsets of the addresses in a. b is linked SHIFT higher.
    if len(a) != len(b):
        fail('the two links differ in length ({} and {} bytes)'
             .format(len(a), len(b)))
    offsets = []
    i = 0
    while i < len(a):
        if a[i] == b[i]:
            i += 1
            continue
        if i + 1 < len(a):
            wa = a[i] | (a[i + 1] << 8)
            wb = b[i] | (b[i + 1] << 8)
            if (wb - wa) & 0xffff == SHIFT:
                offsets.append(i)
                i += 2
                continue
        fail('byte at offset ${:04x} (address ${:04x}) is part of an '
             'address but not a whole one (#<label or #>label?)'
             .format(i, start + i))
    return offsets


def main():
    p = argparse.ArgumentParser(description='Link a v2 library')
    p.add_argument('-C', dest='cfg', required=True, help='ld65 config')
    p.add_argument('-S', dest='start', required=True,
                   help='start address of the first link, a page boundary')
    p.add_argument('-o', dest='out', required=True, help='output file')
    p.add_argument('objects', nargs='+')
    args = p.parse_args()

    start = int(args.start, 0)
    if start & 0xff or start < 0x100:
        fail('start ${:04x} must be a page boundary after page 0'
             .format(start))

    tmpA = args.out + '.a'
    tmpB = args.out + '.b'
    mapA = args.out + '.map'
    a = link(args.cfg, start, tmpA, mapA, args.objects)
    b = link(args.cfg, start + SHIFT, tmpB, None, args.objects)
    os.remove(tmpA)
    os.remove(tmpB)

    if len(a) < 2 or a[0] | (a[1] << 8) != start:
        fail('first link does not start at ${:04x}'.format(start))
    code = a[2:]
    offsets = relocs(code, b[2:], start)

    bssLen = 0
    segs = segments(mapA)
    if 'BSS' in segs and segs['BSS'][1]:
        bssStart, bssLen = segs['BSS']
        if bssStart != start + len(code):
            fail('BSS must follow the code: it starts at ${:04x}, '
                 'the code ends at ${:04x}'
                 .format(bssStart, start + len(code)))
    if start + len(code) + bssLen > 0x10000:
        fail('the library is too large')

    out = bytearray([0, 0, start >> 8])
    for w in (len(code), bssLen, len(offsets)):
        out += bytes([w & 0xff, w >> 8])
    for o in offsets:
        out += bytes([o & 0xff, o >> 8])
    out += code
    with open(args.out, 'wb') as f:
        f.write(out)

    print('{}: {} bytes of code, {} of BSS, {} addresses'
          .format(args.out, len(code), bssLen, len(offsets)))


main()
