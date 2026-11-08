#!/usr/bin/env python3
#
# mkruntime.py
# Ken Schenke (kenschenke@gmail.com)
#
# Copyright (c) 2026
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT
#
# Links the split runtime (see src/asminc/rtpkg.inc).
#
# The runtime is a core, linked into every program, and packages that
# codegen links only into programs that need them. Packages follow the core
# in package order, so a package's address depends only on which packages
# before it are linked. This script links every combination of packages,
# each with the packages packed after the core, and writes:
#
#   coreN               the jump table, the core and its BSS
#   dynarraysNa         dynamic arrays, right after the core
#   filesNa, filesNb    files, after the core and after dynamic arrays
#   trigNa .. trigNd    trig, after the core plus each subset of the others
#   runtimeN            the whole runtime in one image (dynamic mode)
#
# N is RT_ABI_VERSION from asm.inc. A variant's letter is 'a' plus its
# position: the RTF_* bits of the packages before it.
#
# coreN starts with the length of the rest of the file (a word), not a load
# address, because codegen and the linker copy it rather than load it.
#
# runtimeN is loaded by programs at run time (see loader.s in codegenasm).
# It ends at $BFFF and starts at rtLow, a page boundary as high as it fits.
# It's linked once to get its size and again at rtLow. It starts with a
# header (RTH_* in asm.inc), then the jump table, then everything else.
#
# Build checks: the core links on its own (so it imports nothing from a
# package), each package links with only the core (so it imports nothing
# from another package), the core is identical in every link, each package
# fits its area, and the full image fits below $C000.
#
# ld65 is the Windows build, so every path given to it is relative.

import argparse
import os
import re
import struct
import subprocess
import sys

RT_BASE = 0x2028
JMPTBL_SIZE = 0x156
CEILING = 0xC000

# Package segment name, file name prefix, largest expected size. The order
# is the package order (RT_PKG_* in asm.inc).
PACKAGES = [
    ('DYNARRAYS', 'dynarrays', 0x500),
    ('FILES', 'files', 0x500),
    ('TRIG', 'trig', 0x280),
]

HDR_AREA_SIZE = 0x100

# The dynamic runtime's header (RTH_* in asm.inc)
RTH_MAGIC = b'P65R'
RTH_SIZE = 11


def fail(msg):
    sys.stderr.write('mkruntime.py: %s\n' % msg)
    sys.exit(1)


def abi_version(asm_inc):
    with open(asm_inc) as f:
        m = re.search(r'^RT_ABI_VERSION\s*=\s*(\d+)', f.read(), re.M)
    if not m:
        fail('RT_ABI_VERSION not found in ' + asm_inc)
    return int(m.group(1))


def core_segments():
    return [
        '    LOADADDR: load = LOADADDR, type = ro;',
        '    JMPTBL: load = JMPS, type = ro;',
        '    CODE: load = CORE, type = rw;',
        '    RODATA: load = CORE, type = ro, optional = yes;',
        '    DATA: load = CORE, type = rw, optional = yes;',
        # rw, not bss, so the core file carries its BSS as zeros and the
        # packages can follow it
        '    BSS: load = CORE, type = rw, optional = yes, define = yes;',
        '    PKGBSS: load = CORE, type = rw, define = yes;',
    ]


def config_text(sym, mem, seg):
    return ('SYMBOLS {\n%s\n}\nMEMORY {\n%s\n}\nSEGMENTS {\n%s\n}\n'
            % ('\n'.join(sym), '\n'.join(mem), '\n'.join(seg)))


def make_config(core_file, pkgs):
    """pkgs is a list of (index, address, output file) for the packages in
    this link."""
    sym = ['    __LOADADDR__: type = import;']
    mem = [
        '    LOADADDR: file = "%s", start = $%04X, size = 2;'
        % (core_file, RT_BASE - 2),
        '    JMPS: file = "%s", start = $%04X, size = $%X;'
        % (core_file, RT_BASE, JMPTBL_SIZE),
        '    CORE: file = "%s", start = $%04X, size = $%X;'
        % (core_file, RT_BASE + JMPTBL_SIZE,
           CEILING - RT_BASE - JMPTBL_SIZE),
    ]
    seg = core_segments()
    for index, addr, out in pkgs:
        name, _, maxsize = PACKAGES[index]
        pos = index_position(index, [p[0] for p in pkgs])
        sym.append('    __%s_POS__: type = export, addrsize = zp, value = %d;'
                   % (name, pos))
        mem.append('    %sHDR: file = "%s", start = 0, size = $%X;'
                   % (name, out, HDR_AREA_SIZE))
        mem.append('    %s: file = "%s", start = $%04X, size = $%X;'
                   % (name, out, addr, maxsize))
        seg.append('    %sHDR: load = %sHDR, type = ro;' % (name, name))
        seg.append('    %s: load = %s, type = ro, define = yes;'
                   % (name, name))
    return config_text(sym, mem, seg)


def make_full_config(out, base, hdr_dir):
    """The full runtime at base: its header, the jump table, then the core
    with every package after it. The packages' headers are thrown away."""
    sym = ['    __LOADADDR__: type = import;']
    jmps = base + RTH_SIZE
    core = jmps + JMPTBL_SIZE
    mem = [
        '    LOADADDR: file = "%s", start = $%04X, size = 2;' % (out, base - 2),
        '    RTHDR: file = "%s", start = $%04X, size = $%X;'
        % (out, base, RTH_SIZE),
        '    JMPS: file = "%s", start = $%04X, size = $%X;'
        % (out, jmps, JMPTBL_SIZE),
        '    CORE: file = "%s", start = $%04X, size = $%X;'
        % (out, core, CEILING - core),
    ]
    seg = ['    RTHDR: load = RTHDR, type = ro, define = yes;']
    seg += core_segments()
    present = list(range(len(PACKAGES)))
    for index in present:
        name = PACKAGES[index][0]
        sym.append('    __%s_POS__: type = export, addrsize = zp, value = %d;'
                   % (name, index_position(index, present)))
        mem.append('    %sHDR: file = "%s", start = 0, size = $%X;'
                   % (name, os.path.join(hdr_dir, name.lower() + '.hdr'),
                      HDR_AREA_SIZE))
        seg.append('    %sHDR: load = %sHDR, type = ro;' % (name, name))
        seg.append('    %s: load = CORE, type = ro, define = yes;' % name)
    return config_text(sym, mem, seg)


def index_position(index, present):
    """The RTF_* bits of the packages in present that come before index."""
    return sum(1 << i for i in present if i < index)


def link(cfg_text, cfg_file, objects, mapfile=None):
    with open(cfg_file, 'w') as f:
        f.write(cfg_text)
    cmd = ['ld65', '-C', cfg_file]
    if mapfile:
        cmd += ['--mapfile', mapfile]
    # ld65 wants an output name even though every area names its own file
    cmd += ['-o', os.path.join(os.path.dirname(cfg_file), 'unused')]
    cmd += objects
    r = subprocess.run(cmd)
    if r.returncode != 0:
        fail('link failed: ' + ' '.join(cmd))


def read(path):
    with open(path, 'rb') as f:
        return f.read()


def write(path, data):
    with open(path, 'wb') as f:
        f.write(data)


def header_info(data):
    """Returns (package number, position, length, header size)."""
    if len(data) < 5:
        fail('package variant too short')
    count = data[4]
    return data[0], data[1], data[2] | (data[3] << 8), 5 + count * 3


def link_full(path, base, cfg, objects, tmp, mapfile=None):
    link(make_full_config(path, base, tmp), cfg, objects, mapfile)
    return read(path)


def check_full(data, n, rt_low):
    """Checks runtimeN's load address and header."""
    load, = struct.unpack_from('<H', data, 0)
    hdr = data[2:2 + RTH_SIZE]
    magic, version, low, bss, bss_len = struct.unpack('<4sBHHH', hdr)
    if load != rt_low or low != rt_low:
        fail('runtime%d loads at $%04X, header says $%04X, expected $%04X'
             % (n, load, low, rt_low))
    if magic != RTH_MAGIC or version != n:
        fail('runtime%d has a bad magic number or version' % n)
    if not rt_low <= bss < bss + bss_len <= CEILING:
        fail('runtime%d BSS $%04X+$%X is outside the image'
             % (n, bss, bss_len))
    end = rt_low + len(data) - 2
    if end > CEILING:
        fail('runtime%d ends at $%04X, above $%04X' % (n, end, CEILING))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--asm-inc', required=True)
    ap.add_argument('--objdir', required=True)
    ap.add_argument('--bindir', required=True)
    ap.add_argument('--map', required=True)
    ap.add_argument('--jmptbl', required=True)
    ap.add_argument('--jmptbl-full', required=True)
    ap.add_argument('--rthdr', required=True,
                    help='the dynamic runtime header object')
    ap.add_argument('--pkg', nargs=3, required=True,
                    help='objects for dynamic arrays, files and trig')
    ap.add_argument('core', nargs='+', help='core objects')
    args = ap.parse_args()

    n = abi_version(args.asm_inc)
    tmp = os.path.join(args.objdir, 'rtlink')
    os.makedirs(tmp, exist_ok=True)
    cfg = os.path.join(tmp, 'link.cfg')
    core_objs = [args.jmptbl] + args.core

    # Every combination of packages, as an RTF_* mask: the core alone first,
    # then each package alone, whose sizes place the others.
    masks = sorted(range(1 << len(PACKAGES)),
                   key=lambda m: (bin(m).count('1'), m))
    core = None
    sizes = {}
    variants = {}
    for mask in masks:
        present = [i for i in range(len(PACKAGES)) if mask & (1 << i)]
        core_file = os.path.join(tmp, 'core.%d' % mask)
        p0 = RT_BASE - 2 + len(core) if core is not None else 0
        pkgs = []
        addr = p0
        for i in present:
            out = os.path.join(tmp, '%s.%d' % (PACKAGES[i][1], mask))
            pkgs.append((i, addr, out))
            addr += sizes.get(i, 0)
        link(make_config(core_file, pkgs), cfg,
             core_objs + [args.pkg[i] for i in present])

        data = read(core_file)
        if core is None:
            # The core alone, linked first: its size places the packages
            core = data
            continue
        if data != core:
            fail('the core differs when linked with packages %d' % mask)

        for i, a, out in pkgs:
            v = read(out)
            num, pos, length, hdr = header_info(v)
            expect = index_position(i, present)
            if num != i + 1 or pos != expect or len(v) != hdr + length:
                fail('bad header in ' + out)
            sizes.setdefault(i, length)
            if length != sizes[i]:
                fail('package %s changed size' % PACKAGES[i][1])
            name = '%s%d%c' % (PACKAGES[i][1], n, ord('a') + pos)
            if name in variants and variants[name] != v:
                fail(name + ' differs between links')
            variants[name] = v

        if mask == (1 << len(PACKAGES)) - 1 and addr > CEILING:
            fail('the runtime with every package ends at $%04X, above $%04X'
                 % (addr, CEILING))

    expected = 1 + 2 + 4
    if len(variants) != expected:
        fail('expected %d variants, made %d' % (expected, len(variants)))

    # The core file: the length of the rest, then the jump table and core
    image = core[2:]
    write(os.path.join(args.bindir, 'core%d' % n),
          struct.pack('<H', len(image)) + image)
    for name, v in sorted(variants.items()):
        write(os.path.join(args.bindir, name), v)

    # The full runtime, with every package in the core's area and every
    # jump table entry pointing at its routine. Link it once to get its
    # size, then again at the highest page it fits below the ceiling.
    full_file = os.path.join(args.bindir, 'runtime%d' % n)
    full_objs = [args.rthdr, args.jmptbl_full] + args.core + args.pkg
    size = len(link_full(full_file, 0x2000, cfg, full_objs, tmp)) - 2
    rt_low = (CEILING - size) & 0xFF00
    if rt_low < RT_BASE + JMPTBL_SIZE:
        fail('runtime%d is too large' % n)
    full = link_full(full_file, rt_low, cfg, full_objs, tmp, args.map)
    if len(full) - 2 != size:
        fail('runtime%d changed size between links' % n)
    check_full(full, n, rt_low)

    print('runtime: core %d bytes, packages %s, full %d bytes at $%04X'
          % (len(image),
             ', '.join('%s %d' % (PACKAGES[i][1], sizes[i])
                       for i in range(len(PACKAGES))),
             size, rt_low))


if __name__ == '__main__':
    main()
