#!/usr/bin/env python3
#
# mkerrortests.py
# Ken Schenke (kenschenke@gmail.com)
#
# Copyright (c) 2026
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT
#
# Writes the table of expected errors for runerrortests.s.
#
# usage: mkerrortests.py <out.inc> <errorN.pas>...
#
# Each error test names the first error the parser must report, and its
# line, in a line of its header comment:
#
#     Error Test 12 - expect errInvalidExpression on line 9
#
# The tests must be numbered 1 to N with none missing, because the test
# program opens them by number. The table has three bytes for each test:
# the line number (low byte, then high) and the error code.

import re
import sys

EXPECT_RE = re.compile(r'expect\s+(err[A-Za-z]+)\s+on\s+line\s+(\d+)',
                       re.IGNORECASE)
NAME_RE = re.compile(r'error(\d+)\.pas$')


def main():
    if len(sys.argv) < 3:
        sys.exit(f'usage: {sys.argv[0]} <out.inc> <errorN.pas>...')
    out_file = sys.argv[1]

    tests = {}
    for path in sys.argv[2:]:
        m = NAME_RE.search(path)
        if not m:
            sys.exit(f'{path}: not named errorN.pas')
        num = int(m.group(1))
        with open(path, encoding='latin-1') as f:
            for line in f:
                m = EXPECT_RE.search(line)
                if m:
                    tests[num] = (m.group(1), int(m.group(2)))
                    break
            else:
                sys.exit(f'{path}: no "expect errXxx on line N" line')

    count = len(tests)
    missing = [n for n in range(1, count + 1) if n not in tests]
    if missing:
        sys.exit(f'error tests missing: {missing}')

    lines = [
        '; Made by mkerrortests.py from the error tests. Do not edit.',
        '',
        f'NUM_ERROR_TESTS = {count}',
        '',
        '; Three bytes for each test: the line (low, high) and the error',
        'errors:',
    ]
    for n in range(1, count + 1):
        err, line = tests[n]
        lines.append(f'    .byte ${line & 0xff:02x}, ${line >> 8:02x}, '
                     f'{err:28s} ; error{n}.pas')
    with open(out_file, 'w', encoding='latin-1', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
