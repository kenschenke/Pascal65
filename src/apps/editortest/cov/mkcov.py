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
# Makes copies of the editor overlay's sources with coverage probes in them.
#
# usage: mkcov.py [-D sym]... [-m max] <out dir> <out.map> <in.s>...
#
# An input can be given as <in.s>:<first>-<last> to instrument only those
# lines, for a file too big to instrument whole. <first> must be 1 or a
# .proc line, so the first instruction starts a block. The other lines get
# no probes and aren't in the map, but their branches are still made long.
# Two sets can each instrument part of a file (see covreport.py).
#
# <first> and <last> can be the names of procs instead of line numbers, so
# the split doesn't move when the file changes. <first> is then the proc's
# .proc line and <last> the line before it. An empty <first> is the start
# of the file and an empty <last> its end: exprTypeCheck.s:-evalNegate and
# exprTypeCheck.s:evalNegate- are the two halves of the file.
#
# This is memtest's cov/mkcov.py, made for a whole overlay. A probe goes at
# the start of every basic block: at the start of each .proc, after each
# label, and after each branch, jump, jsr, rts, or brk. A probe is
#
#     php
#     lsr COVMAP+n
#     plp
#
# which is five bytes and keeps A, X, Y, Z and the flags. COVMAP is the
# address of the coverage map, one byte per probe. It is outside the overlay
# (see the Makefile) because the overlay has no room for it. The test
# program fills the map with $80, so a probe's byte is something else once
# the probe runs. It never wraps back to $80 (an INC would wrap after 256
# runs).
#
# Probes are numbered across all the files, in the order given. With -m it
# fails if there are more than max probes (the size of the map).
#
# Probes are never put between a NOP or NEG prefix and the instruction it
# modifies because a probe only goes after a label or a control transfer,
# and the sources never put those between the two.
#
# Branches are made into long (16-bit) branches so the probes do not push
# them out of range. They behave the same.
#
# .ifdef, .ifndef, .else and .endif are followed, with the symbols given by
# -D defined. Other .if directives are taken to be true. Lines in a part
# that isn't assembled are left out of the map.
#
# The map has one line for each instruction in a code segment:
#   <file> TAB <source line number> TAB <probe number> TAB <source text>

import os
import re
import sys

BRANCHES = {'bcc', 'bcs', 'beq', 'bne', 'bmi', 'bpl', 'bvc', 'bvs', 'bra'}
# Long branches are already long. They end a block too.
LONG_BRANCHES = {'l' + b for b in BRANCHES}
ENDERS = {'jmp', 'jsr', 'rts', 'rti', 'brk'} | LONG_BRANCHES

SEGMENT_RE = re.compile(r'^\s*\.(code|data|bss|rodata|segment)\b(.*)$',
                        re.IGNORECASE)
PROC_RE = re.compile(r'^\s*\.proc\b', re.IGNORECASE)
COND_RE = re.compile(r'^\s*\.(ifdef|ifndef|if\w*|else|elseif|endif)\b\s*(\S*)',
                     re.IGNORECASE)
# A label: "name:" or an anonymous ":"
LABEL_RE = re.compile(r'^\s*([A-Za-z_@][A-Za-z0-9_]*:(?!=)|:(?=\s|$))(.*)$')
MNEMONIC_RE = re.compile(r'^(\s*)([A-Za-z]+)')
# A symbol assignment, such as "offset = 4", isn't an instruction
ASSIGN_RE = re.compile(r'^\s*[A-Za-z_@][A-Za-z0-9_]*\s*:?=')


def strip_comment(line):
    """Returns the line without its comment. A ; in quotes (such as
    cmp #';') isn't a comment."""
    quote = None
    for i, c in enumerate(line):
        if quote:
            if c == quote:
                quote = None
        elif c in '\'"':
            quote = c
        elif c == ';':
            return line[:i]
    return line


class Instrumenter:
    def __init__(self, defines):
        self.defines = set(defines)
        self.probes = 0
        self.map_lines = []

    def instrument(self, name, src, first=1, last=None):
        """Returns the instrumented lines of one file. Only lines first to
        last get probes."""
        if last is None:
            last = len(src)
        if first != 1 and (first > len(src) or
                           not PROC_RE.match(strip_comment(src[first - 1]))):
            sys.exit(f'mkcov: {name} line {first} is not a .proc')
        out_lines = []
        pending = False
        in_code = True
        # One entry for each open .if: is that part assembled?
        conds = []

        def active():
            return all(conds)

        for line_no, line in enumerate(src, start=1):
            code = strip_comment(line)

            m = COND_RE.match(code)
            if m:
                kind, arg = m.group(1).lower(), m.group(2)
                if kind == 'ifdef':
                    conds.append(arg in self.defines)
                elif kind == 'ifndef':
                    conds.append(arg not in self.defines)
                elif kind == 'endif':
                    conds.pop()
                elif kind == 'else':
                    conds[-1] = not conds[-1]
                elif kind.startswith('if'):
                    conds.append(True)
                out_lines.append(line)
                continue

            m = SEGMENT_RE.match(code)
            if m:
                seg, arg = m.group(1).lower(), m.group(2)
                in_code = seg == 'code' or (
                    seg == 'segment' and
                    re.search(r'"CODE"', arg, re.IGNORECASE) is not None)
                out_lines.append(line)
                continue

            if not in_code:
                out_lines.append(line)
                continue

            if PROC_RE.match(code):
                pending = True
                out_lines.append(line)
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
                    out_lines.append(line)
                continue
            if rest.lstrip().startswith('.') or ASSIGN_RE.match(rest):
                # A directive or a symbol assignment
                out_lines.append(rest)
                continue

            if not first <= line_no <= last:
                # Outside the range: no probe, but the branch is made long
                # because probes may come between it and its target
                m = MNEMONIC_RE.match(rest)
                if m and m.group(2).lower() in BRANCHES:
                    rest = MNEMONIC_RE.sub(r'\1l\2', rest, count=1)
                out_lines.append(rest)
                continue

            if pending:
                n = self.probes
                self.probes += 1
                out_lines.extend([
                    f'    php                     ; coverage probe {n}',
                    f'    lsr COVMAP+{n}',
                    '    plp',
                ])
            else:
                n = self.probes - 1
            pending = False

            m = MNEMONIC_RE.match(rest)
            mnem = m.group(2).lower() if m else ''
            if mnem in BRANCHES:
                rest = MNEMONIC_RE.sub(r'\1l\2', rest, count=1)
                pending = True
            elif mnem in ENDERS:
                pending = True

            out_lines.append(rest)
            if active():
                self.map_lines.append(
                    f'{name}\t{line_no}\t{n}\t{line.strip()}')

        return out_lines


def line_of(name, src, limit, default, offset):
    """Returns the line a range limit names: a line number, or the line of
    the proc's .proc line plus offset. An empty limit is the default."""
    if limit == '':
        return default
    if limit.isdigit():
        return int(limit)
    proc_re = re.compile(r'^\s*\.proc\s+' + re.escape(limit) + r'\b',
                         re.IGNORECASE)
    for line_no, line in enumerate(src, start=1):
        if proc_re.match(line):
            return line_no + offset
    sys.exit(f'mkcov: {name} has no .proc {limit}')


def main():
    args = sys.argv[1:]
    defines = []
    max_probes = None
    while len(args) >= 2 and args[0] in ('-D', '-m'):
        if args[0] == '-D':
            defines.append(args[1])
        else:
            max_probes = int(args[1])
        args = args[2:]
    if len(args) < 3:
        sys.exit(f'usage: {sys.argv[0]} [-D sym]... [-m max] '
                 '<out dir> <out.map> <in.s>...')
    out_dir, map_file = args[:2]

    inst = Instrumenter(defines)
    for arg in args[2:]:
        m = re.match(r'^(.*\.s):(\w*)-(\w*)$', arg)
        in_file = m.group(1) if m else arg
        name = os.path.basename(in_file)
        with open(in_file, encoding='latin-1') as f:
            src = [line.rstrip('\r\n') for line in f]
        first, last = 1, None
        if m:
            first = line_of(name, src, m.group(2), 1, 0)
            last = line_of(name, src, m.group(3), None, -1)
        out_lines = inst.instrument(name, src, first, last)
        with open(os.path.join(out_dir, name), 'w', encoding='latin-1',
                  newline='\n') as f:
            f.write('\n'.join(out_lines) + '\n')

    with open(map_file, 'w', encoding='latin-1', newline='\n') as f:
        f.write('\n'.join(inst.map_lines) + '\n')

    print(f'mkcov: {inst.probes} probes, {len(inst.map_lines)} instructions')
    if max_probes is not None and inst.probes > max_probes:
        sys.exit(f'mkcov: more than {max_probes} probes')


if __name__ == '__main__':
    main()
