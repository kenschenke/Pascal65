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
# Prints the line coverage of an instrumented source.
#
# usage: covreport.py <map> <coverage file>
#
# The map comes from mkcov.py. The coverage file is covMap as the test program
# saved it: a PRG file, so it starts with a two byte load address. A line is
# covered if the probe for its basic block ran.

import sys


def main():
    if len(sys.argv) != 3:
        sys.exit(f'usage: {sys.argv[0]} <map> <coverage file>')
    map_file, cov_file = sys.argv[1:]

    with open(cov_file, 'rb') as f:
        hits = f.read()[2:]

    with open(map_file, encoding='latin-1') as f:
        entries = [line.rstrip('\r\n') for line in f]

    total = covered = 0
    probes_seen = set()
    probes_hit = set()
    missed = []
    for entry in entries:
        if entry == '':
            continue
        line, probe, text = entry.split('\t', 2)
        probe = int(probe)
        total += 1
        probes_seen.add(probe)
        if probe < len(hits) and hits[probe]:
            covered += 1
            probes_hit.add(probe)
        else:
            missed.append(f'  {int(line):4d}: {text}')

    def pct(part, whole):
        return 100.0 * part / whole if whole else 0.0

    print(f'memheap.s line coverage: {covered} of {total} lines '
          f'({pct(covered, total):.1f}%)')
    print(f'memheap.s block coverage: {len(probes_hit)} of '
          f'{len(probes_seen)} blocks '
          f'({pct(len(probes_hit), len(probes_seen)):.1f}%)')
    if missed:
        print('Lines not executed:')
        print('\n'.join(missed))


if __name__ == '__main__':
    main()
