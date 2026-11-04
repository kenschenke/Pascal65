#!/usr/bin/env python3
#
# mkcov.py
# Ken Schenke (kenschenke@gmail.com)
#
# Copyright (c) 2026
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT
#
# Makes a copy of an assembly source with coverage probes in it.
#
# usage: mkcov.py <in.s> <out.s> <out.map>
#
# A probe goes at the start of every basic block: at the start of each .proc,
# after each label, and after each branch, jump, jsr, rts, or brk. A probe
# sets its byte in covMap to 1. It saves and restores A and the flags, so it
# can sit between an instruction that sets the flags and the branch that
# tests them.
#
# Probes are never put between a NOP prefix and the instruction it modifies
# because a probe only goes after a label or a control transfer, and the
# sources never put those between the two.
#
# Branches are made into long (16-bit) branches so the probes do not push
# them out of range. They behave the same.
#
# The exported routines get a cov_ prefix so a test can have the instrumented
# copy and asmlib's copy at the same time.
#
# The map has one line for each instruction in the code segment:
#   <source line number> TAB <probe number> TAB <source text>
# Conditional assembly is assumed to be enabled (the copy is assembled with
# the same symbols as asmlib, which defines __DEBUG__).

import re
import sys

RENAMED = ['initMemHeap', 'heapAlloc', 'heapFree', 'getMemHeapForBank',
           'clearMemHeap', 'isHeapAllocated']
BRANCHES = {'bcc', 'bcs', 'beq', 'bne', 'bmi', 'bpl', 'bvc', 'bvs', 'bra'}
ENDERS = {'jmp', 'jsr', 'rts', 'rti', 'brk'}

RENAME_RE = re.compile(r'\b(' + '|'.join(RENAMED) + r')\b')
SEGMENT_RE = re.compile(r'^\s*\.(code|data|bss|rodata|segment)\b(.*)$',
                        re.IGNORECASE)
PROC_RE = re.compile(r'^\s*\.proc\b', re.IGNORECASE)
# A label: "name:" or an anonymous ":"
LABEL_RE = re.compile(r'^\s*([A-Za-z_@][A-Za-z0-9_]*:(?!=)|:(?=\s|$))(.*)$')
MNEMONIC_RE = re.compile(r'^(\s*)([A-Za-z]+)')


def instrument(src):
    """Returns the instrumented lines, the map lines, and the probe count."""
    out_lines = []
    map_lines = []
    probes = 0
    pending = False
    in_code = True

    for line_no, line in enumerate(src, start=1):
        text = RENAME_RE.sub(r'cov_\1', line)

        # The code part of the line, without the comment
        code = text.split(';', 1)[0]

        m = SEGMENT_RE.match(code)
        if m:
            seg, arg = m.group(1).lower(), m.group(2)
            in_code = seg == 'code' or (
                seg == 'segment' and
                re.search(r'"CODE"', arg, re.IGNORECASE) is not None)
            out_lines.append(text)
            continue

        if not in_code:
            out_lines.append(text)
            continue

        if PROC_RE.match(code):
            pending = True
            out_lines.append(text)
            continue

        rest = code
        had_label = False
        m = LABEL_RE.match(rest)
        if m:
            out_lines.append(m.group(1))
            rest = m.group(2)
            pending = True
            had_label = True

        if rest.strip() == '':
            # Blank or comment only
            if not had_label:
                out_lines.append(text)
            continue
        if rest.lstrip().startswith('.'):
            # A directive
            out_lines.append(rest)
            continue

        if pending:
            n = probes
            probes += 1
            out_lines.extend([
                f'    php                     ; coverage probe {n}',
                '    pha',
                '    lda #1',
                f'    sta covMap+{n}',
                '    pla',
                '    plp',
            ])
        else:
            n = probes - 1
        pending = False

        m = MNEMONIC_RE.match(rest)
        mnem = m.group(2).lower() if m else ''
        if mnem in BRANCHES:
            rest = MNEMONIC_RE.sub(r'\1l\2', rest, count=1)
            pending = True
        elif mnem in ENDERS:
            pending = True

        out_lines.append(rest)
        map_lines.append(f'{line_no}\t{n}\t{line.lstrip()}')

    out_lines += [
        '',
        '; Coverage map, one byte per probe',
        '.export covMap',
        f'.export covSize: absolute = {probes}',
        '.bss',
        f'covMap: .res {probes}',
    ]
    return out_lines, map_lines, probes


def main():
    if len(sys.argv) != 4:
        sys.exit(f'usage: {sys.argv[0]} <in.s> <out.s> <out.map>')
    in_file, out_file, map_file = sys.argv[1:]

    with open(in_file, encoding='latin-1') as f:
        src = [line.rstrip('\r\n') for line in f]

    out_lines, map_lines, probes = instrument(src)

    with open(out_file, 'w', encoding='latin-1', newline='\n') as f:
        f.write('\n'.join(out_lines) + '\n')
    with open(map_file, 'w', encoding='latin-1', newline='\n') as f:
        f.write('\n'.join(map_lines) + '\n')

    print(f'mkcov: {probes} probes, {len(map_lines)} instructions')


if __name__ == '__main__':
    main()
