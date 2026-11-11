#!/usr/bin/env python3
"""Tests for mkthemes.py. Run from src/shared: python3 test_mkthemes.py

- themes.txt in format 0 must match the old src/shared/themes.dat blob,
  which was removed once it matched byte for byte (its SHA-256 is below).
- mkthemes-tests/good.txt must make the bytes written out here, in both
  formats, with --version and --truncate, and warn about its palette clash.
- Every other mkthemes-tests/*.txt is a bad input. Its first line is
  "# expect <line>: <text>": the generator must fail, naming that line, with
  that text in the message.
"""

import glob
import hashlib
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MKTHEMES = os.path.join(HERE, "mkthemes.py")
TESTDIR = os.path.join(HERE, "mkthemes-tests")

# SHA-256 of the 625-byte src/shared/themes.dat this generator replaced.
BLOB_SHA256 = \
    "6bc00ebdd35a0f32e6b8c9b16ad5aa940d921ea526e9df4aefdc213cbe43c8df"
BLOB_SIZE = 625

failures = 0


def fail(msg):
    global failures
    failures += 1
    print("FAIL: " + msg)


def run(src, *args):
    """Run mkthemes.py; return (status, stderr, output bytes or None)."""
    fd, out = tempfile.mkstemp(suffix=".def")
    os.close(fd)
    os.remove(out)
    try:
        p = subprocess.run([sys.executable, MKTHEMES, "-o", out, src]
                           + list(args), capture_output=True, text=True)
        data = None
        if os.path.exists(out):
            with open(out, "rb") as f:
                data = f.read()
        return p.returncode, p.stderr, data
    finally:
        if os.path.exists(out):
            os.remove(out)


def name(petscii):
    return petscii + b" " * (16 - len(petscii))


# good.txt, by hand
FIRST_V0 = (name(b"\xc6IRST") + bytes([
    5, 0, 15, 0,
    4, 15, 9, 12,
    3, 0, 15, 15,
    12, 10, 10, 10,
    1, 13, 13, 13,
    10, 15, 10, 7,
    19, 14, 14, 0,
    1, 13, 13, 13,
    21, 2, 3, 5,
]))
FIRST_V1 = FIRST_V0 + bytes([
    1, 13, 13, 13,      # error ui
    7, 15, 15, 0,       # warning 7: default yellow
])
SECOND_V0 = (name(b"SECOND 2") + bytes([
    5, 0, 15, 0,        # default RGB from here on
    4, 15, 0, 15,
    3, 0, 15, 15,
    12, 8, 8, 8,
    1, 0, 0, 0,
    10, 15, 7, 7,
    19, 14, 14, 0,
    1, 15, 15, 15,
    21, 2, 3, 5,
]))
SECOND_V1 = SECOND_V0 + bytes([
    2, 1, 2, 3,
    2, 1, 2, 3,         # warning error
])
GOOD_V0 = bytes([1]) + FIRST_V0 + SECOND_V0
GOOD_V1 = bytes([0xFF, 1, 1]) + FIRST_V1 + SECOND_V1


def test_blob():
    src = os.path.join(HERE, "themes.txt")
    status, err, data = run(src, "--format", "0")
    if status != 0 or data is None:
        fail("themes.txt format 0: status %d: %s" % (status, err.strip()))
        return
    if err:
        fail("themes.txt format 0 printed: %s" % err.strip())
    if len(data) != BLOB_SIZE:
        fail("themes.txt format 0 is %d bytes, not %d"
             % (len(data), BLOB_SIZE))
    if hashlib.sha256(data).hexdigest() != BLOB_SHA256:
        fail("themes.txt format 0 doesn't match the old themes.dat")
    # The default format, for the Makefile, is 0 until the editor reads 1.
    status, err, default = run(src)
    if status != 0 or default != data:
        fail("themes.txt default format isn't format 0")


def test_good():
    src = os.path.join(TESTDIR, "good.txt")
    checks = [
        ((), GOOD_V0),
        (("--format", "0"), GOOD_V0),
        (("--format", "1"), GOOD_V1),
        (("--format", "1", "--version", "2"),
         bytes([0xFF, 2]) + GOOD_V1[2:]),
        (("--format", "1", "--truncate", "10"), GOOD_V1[:-10]),
        (("--format", "0", "--truncate", "1000"), b""),
    ]
    for args, want in checks:
        status, err, data = run(src, *args)
        label = "good.txt %s" % " ".join(args)
        if status != 0:
            fail("%s: status %d: %s" % (label, status, err.strip()))
        elif data != want:
            fail("%s: bytes differ\n  got  %s\n  want %s"
                 % (label, data.hex() if data else data, want.hex()))
        if not re.search(r"good\.txt:19: warning: .*'operator' and 'ui' "
                         r"both use palette index 1", err):
            fail("%s: no palette warning for line 19: %s"
                 % (label, err.strip()))
    status, err, data = run(src, "--format", "0", "--version", "1")
    if status == 0:
        fail("--version without --format 1 was accepted")


def test_bad():
    for src in sorted(glob.glob(os.path.join(TESTDIR, "*.txt"))):
        base = os.path.basename(src)
        if base == "good.txt":
            continue
        with open(src) as f:
            m = re.match(r"# expect (\d+): (.*)", f.readline())
        if not m:
            fail("%s has no '# expect <line>: <text>' first line" % base)
            continue
        line, text = m.group(1), m.group(2).strip()
        for fmt in ("0", "1"):
            status, err, data = run(src, "--format", fmt)
            label = "%s format %s" % (base, fmt)
            if status == 0:
                fail("%s was accepted" % label)
            elif data is not None:
                fail("%s failed but wrote a file" % label)
            want = "%s:%s: error: " % (base, line)
            if want not in err or text not in err:
                fail("%s: expected '%s...%s', got: %s"
                     % (label, want, text, err.strip()))


def main():
    test_blob()
    test_good()
    test_bad()
    if failures:
        print("%d mkthemes test(s) failed" % failures)
        return 1
    print("mkthemes tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
