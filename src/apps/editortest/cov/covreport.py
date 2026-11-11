#!/usr/bin/env python3
#
# covreport.py
# Ken Schenke (kenschenke@gmail.com)
#
# Copyright (c) 2026
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT
#
# Prints the line coverage of the editor overlay.
#
# usage: covreport.py <listing> -m <map> <coverage file>... [-m ...]
#
# Each map comes from mkcov.py, one for each coverage set (see the Makefile).
# A coverage file is the map as the test program saved it: a PRG file, so it
# starts with a two byte load address. The map starts filled with $80, and a
# probe that runs changes its byte. A line is covered if the probe for its
# basic block ran.
#
# A summary for each file goes to the standard output. The listing file gets
# the summary and every line that never ran.

import sys


def main():
    args = sys.argv[1:]
    if len(args) < 4 or args[1] != '-m':
        sys.exit(f'usage: {sys.argv[0]} <listing> '
                 '-m <map> <coverage file>... [-m <map> <coverage>...]...')
    listing = args[0]

    # Each set: its map and the coverage files of its runs
    sets = []
    for arg in args[1:]:
        if arg == '-m':
            sets.append(None)
        elif sets[-1] is None:
            sets[-1] = (arg, [])
        else:
            sets[-1][1].append(arg)

    # file -> [total, covered, blocks, blocks hit, missed lines]
    files = {}
    for map_file, cov_files in sets:
        # A probe ran if it ran in any of the runs
        hits = None
        for cov_file in cov_files:
            with open(cov_file, 'rb') as f:
                run = f.read()[2:]
            if hits is None:
                hits = bytearray(run)
            else:
                for i, b in enumerate(run):
                    if b != 0x80:
                        hits[i] = b
        with open(map_file, encoding='latin-1') as f:
            entries = [line.rstrip('\r\n') for line in f]
        for entry in entries:
            if entry == '':
                continue
            name, line, probe, text = entry.split('\t', 3)
            probe = int(probe)
            ran = probe < len(hits) and hits[probe] != 0x80
            st = files.setdefault(name, [0, 0, set(), set(), []])
            st[0] += 1
            st[2].add(probe)
            if ran:
                st[1] += 1
                st[3].add(probe)
            else:
                st[4].append((int(line), text))

    def pct(part, whole):
        return 100.0 * part / whole if whole else 0.0

    summary = []
    total = covered = 0
    for name in sorted(files, key=str.lower):
        t, c, blocks, hit, _ = files[name]
        total += t
        covered += c
        summary.append(f'{name:24s} {c:5d} / {t:5d} lines '
                       f'({pct(c, t):5.1f}%)  {len(hit):4d} / '
                       f'{len(blocks):4d} blocks')
    summary.append(f'{"total":24s} {covered:5d} / {total:5d} lines '
                   f'({pct(covered, total):5.1f}%)')

    print('\n'.join(summary))
    with open(listing, 'w', encoding='latin-1', newline='\n') as f:
        f.write('\n'.join(summary) + '\n')
        for name in sorted(files, key=str.lower):
            missed = files[name][4]
            if not missed:
                continue
            f.write(f'\n{name}: lines not executed\n')
            for line, text in missed:
                f.write(f'  {line:4d}: {text}\n')
    print(f'Lines not executed: {listing}')


if __name__ == '__main__':
    main()
