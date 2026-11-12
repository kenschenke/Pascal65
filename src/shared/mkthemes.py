#!/usr/bin/env python3
"""Write the editor's theme file (themes.def / themes.dat) from a text file.

Input (see themes.txt):

    # Lines starting with # are comments; so is the rest of a line after #.
    selected 0

    theme Dracula
    number      5  0 15  0      # palette index, then R G B (0-15)
    keyword     4               # index alone: the MEGA65 default RGB
    error       ui              # another color's name: a copy of it
    ...

Every theme names each color once, in any order. The colors are written in
SYNTAXHL_* order (src/asminc/editor.inc).

Output, format 0 (the old file, no version marker):

    byte 0      selected theme number
    records     52 bytes: a 16-byte PETSCII name, then
                9 colors of 4 bytes (index, R, G, B)

Format 1 (the default):

    byte 0      $FF marker
    byte 1      $01 format version
    byte 2      selected theme number
    records     THEME_SIZE (60) bytes: the name, then 11 colors

Format 0 ignores the error and warning colors if a theme has them.

--version, --selected and --truncate make deliberately bad files for the
tests.

Errors name the file and line and exit with status 1. Warnings go to stderr
and don't stop the build.
"""

import argparse
import sys

# Color names in SYNTAXHL_* order (SYNTAXHL_NUMBER = 1 ..).
COLORS_V0 = [
    "number",       # SYNTAXHL_NUMBER
    "keyword",      # SYNTAXHL_KEYWORD
    "string",       # SYNTAXHL_STRING
    "comment",      # SYNTAXHL_COMMENT
    "operator",     # SYNTAXHL_OPERATOR
    "identifier",   # SYNTAXHL_IDENTIFIER
    "cursor",       # SYNTAXHL_CURSOR
    "ui",           # SYNTAXHL_FOREGROUND
    "background",   # SYNTAXHL_BACKGROUND
]
COLORS_V1 = COLORS_V0 + [
    "error",        # SYNTAXHL_ERROR
    "warning",      # SYNTAXHL_WARNING
]
ALL_COLORS = COLORS_V1

NAME_LEN = 16
MARKER = 0xFF
CURRENT_VERSION = 1
# The selected number is one byte, and a version 0 file's first byte must
# never be the $FF marker.
MAX_THEMES = 255

# The MEGA65 default palette (systemPalette in src/overlays/themes/src/
# themelist.s), R G B 0-15.
SYSTEM_PALETTE = [
    (0, 0, 0),      # Black
    (15, 15, 15),   # White
    (15, 0, 0),     # Red
    (0, 15, 15),    # Cyan
    (15, 0, 15),    # Purple
    (0, 15, 0),     # Green
    (0, 0, 15),     # Blue
    (15, 15, 0),    # Yellow
    (15, 6, 0),     # Orange
    (10, 4, 0),     # Brown
    (15, 7, 7),     # Light Red (Pink)
    (5, 5, 5),      # Dark Gray
    (8, 8, 8),      # Medium Gray
    (9, 15, 9),     # Light Green
    (9, 9, 15),     # Light Blue
    (11, 11, 11),   # Light Gray
    (14, 0, 0),     # Guru Meditation
    (15, 5, 0),     # Rambutan
    (15, 11, 0),    # Carrot
    (14, 14, 0),    # Lemon Tart
    (7, 15, 0),     # Pandan
    (6, 14, 6),     # Seasick Green
    (9, 14, 3),     # Soylent Green
    (0, 15, 9),     # Slimer Green
    (0, 13, 13),    # The Other Cyan
    (0, 9, 15),     # Sea Sky
    (0, 3, 15),     # Smurf Blue
    (0, 0, 14),     # Screen Of Death
    (7, 0, 15),     # Plum Sauce
    (12, 0, 15),    # Sour Grape
    (15, 0, 11),    # Bubble Gum
    (15, 3, 6),     # Hot Tamales
]


class ThemeError(Exception):
    def __init__(self, line, msg):
        super().__init__(msg)
        self.line = line
        self.msg = msg


class Theme:
    def __init__(self, name, line):
        self.name = name
        self.line = line
        # color name -> (line, ("entry", (i, r, g, b)) or ("copy", name))
        self.specs = {}
        self.entries = {}   # color name -> (i, r, g, b), after resolve()


def to_petscii(name, line):
    """Convert an ASCII theme name to the PETSCII the disk holds."""
    if not name:
        raise ThemeError(line, "theme has no name")
    if len(name) > NAME_LEN:
        raise ThemeError(line, "theme name '%s' is %d characters; the limit "
                         "is %d" % (name, len(name), NAME_LEN))
    out = bytearray()
    for ch in name:
        c = ord(ch)
        if 0x61 <= c <= 0x7A:           # a-z
            out.append(c - 0x20)        # $41-$5A
        elif 0x41 <= c <= 0x5A:         # A-Z
            out.append(c + 0x80)        # $C1-$DA
        elif 0x20 <= c <= 0x3F:         # space, digits, punctuation
            out.append(c)
        else:
            raise ThemeError(line, "theme name '%s': character '%s' has no "
                             "PETSCII equivalent here" % (name, ch))
    out.extend(b" " * (NAME_LEN - len(out)))
    return bytes(out)


def parse_int(tok, line, what, lo, hi):
    try:
        v = int(tok, 10)
    except ValueError:
        raise ThemeError(line, "%s '%s' is not a number" % (what, tok))
    if not lo <= v <= hi:
        raise ThemeError(line, "%s %d is out of range (%d-%d)"
                         % (what, v, lo, hi))
    return v


def parse(text):
    """Return (selected, selected_line, themes)."""
    selected = None
    selected_line = 0
    themes = []
    theme = None
    for num, raw in enumerate(text.splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        toks = line.split()
        word = toks[0]
        if word == "selected":
            if selected is not None:
                raise ThemeError(num, "'selected' given twice")
            if len(toks) != 2:
                raise ThemeError(num, "expected 'selected <number>'")
            selected = parse_int(toks[1], num, "selected theme", 0,
                                 MAX_THEMES - 1)
            selected_line = num
        elif word == "theme":
            name = line[len("theme"):].strip()
            theme = Theme(name, num)
            to_petscii(name, num)       # check the name now
            themes.append(theme)
        elif word in ALL_COLORS:
            if theme is None:
                raise ThemeError(num, "color '%s' before the first theme"
                                 % word)
            if word in theme.specs:
                raise ThemeError(num, "color '%s' given twice in theme '%s' "
                                 "(first on line %d)"
                                 % (word, theme.name, theme.specs[word][0]))
            args = toks[1:]
            if len(args) == 1 and args[0] in ALL_COLORS:
                spec = ("copy", args[0])
            elif len(args) == 1:
                i = parse_int(args[0], num, "palette index", 0, 31)
                spec = ("entry", (i,) + SYSTEM_PALETTE[i])
            elif len(args) == 4:
                i = parse_int(args[0], num, "palette index", 0, 31)
                rgb = tuple(parse_int(a, num, what, 0, 15)
                            for a, what in zip(args[1:], ("red", "green",
                                                          "blue")))
                spec = ("entry", (i,) + rgb)
            else:
                raise ThemeError(num, "expected '%s <index> [<r> <g> <b>]' "
                                 "or '%s <color>'" % (word, word))
            theme.specs[word] = (num, spec)
        else:
            raise ThemeError(num, "unknown keyword or color '%s'" % word)

    if not themes:
        raise ThemeError(len(text.splitlines()), "no themes")
    if len(themes) > MAX_THEMES:
        raise ThemeError(themes[MAX_THEMES].line, "too many themes (the "
                         "limit is %d)" % MAX_THEMES)
    if selected is None:
        selected = 0
    if selected >= len(themes):
        raise ThemeError(selected_line, "selected theme %d is past the end "
                         "of the list (%d themes)" % (selected, len(themes)))
    return selected, themes


def resolve(theme, colors):
    """Fill in theme.entries; check it has the colors the format writes."""
    def entry(color, seen):
        num, (kind, val) = theme.specs[color]
        if kind == "entry":
            return val
        if val in seen:
            raise ThemeError(num, "colors in theme '%s' copy each other "
                             "in a loop" % theme.name)
        if val not in theme.specs:
            raise ThemeError(num, "color '%s' copies '%s', which theme '%s' "
                             "doesn't have" % (color, val, theme.name))
        return entry(val, seen | {val})

    # Resolve every color the theme gives, so a bad copy fails in either
    # format.
    for color in theme.specs:
        theme.entries[color] = entry(color, {color})

    for color in colors:
        if color not in theme.specs:
            raise ThemeError(theme.line, "theme '%s' has no '%s' color"
                             % (theme.name, color))


def palette_warnings(theme, colors):
    """Warn when two colors share a palette index with different RGB."""
    warnings = []
    seen = {}       # index -> (color, rgb)
    for color in colors:
        i, r, g, b = theme.entries[color]
        if i in seen and seen[i][1] != (r, g, b):
            other, rgb = seen[i]
            warnings.append(
                (theme.specs[color][0],
                 "theme '%s': '%s' and '%s' both use palette index %d with "
                 "different RGB (%d %d %d vs %d %d %d); '%s' wins"
                 % (theme.name, other, color, i, rgb[0], rgb[1], rgb[2],
                    r, g, b, color)))
        seen[i] = (color, (r, g, b))
    return warnings


def build(text, fmt, version=None, force_selected=None):
    """Return (bytes, warnings) for the theme text."""
    selected, themes = parse(text)
    if force_selected is not None:
        selected = force_selected
    colors = COLORS_V0 if fmt == 0 else COLORS_V1
    out = bytearray()
    if fmt == 0:
        out.append(selected)
    else:
        out.append(MARKER)
        out.append(CURRENT_VERSION if version is None else version)
        out.append(selected)
    warnings = []
    for theme in themes:
        resolve(theme, colors)
        warnings.extend(palette_warnings(theme, colors))
        out.extend(to_petscii(theme.name, theme.line))
        for color in colors:
            out.extend(theme.entries[color])
    return bytes(out), warnings


def main(argv=None):
    ap = argparse.ArgumentParser(description="Write a theme file.")
    ap.add_argument("input", help="theme text file (themes.txt)")
    ap.add_argument("-o", "--output", required=True, help="file to write")
    ap.add_argument("--format", type=int, choices=(0, 1), default=1,
                    help="0: the old unmarked 9-color file, 1: version 1 "
                    "(default)")
    ap.add_argument("--version", type=lambda s: int(s, 0), default=None,
                    help="write this version byte (format 1, for tests)")
    ap.add_argument("--selected", type=lambda s: int(s, 0), default=None,
                    help="write this selected number, unchecked (for tests)")
    ap.add_argument("--truncate", type=int, default=0, metavar="N",
                    help="drop the last N bytes (for tests)")
    args = ap.parse_args(argv)

    if args.version is not None:
        if args.format != 1:
            ap.error("--version needs --format 1")
        if not 0 <= args.version <= 255:
            ap.error("--version must be 0-255")
    if args.selected is not None and not 0 <= args.selected <= 254:
        ap.error("--selected must be 0-254")
    if args.truncate < 0:
        ap.error("--truncate must not be negative")

    with open(args.input, encoding="ascii", errors="replace") as f:
        text = f.read()
    try:
        data, warnings = build(text, args.format, args.version,
                               args.selected)
    except ThemeError as e:
        print("%s:%d: error: %s" % (args.input, e.line, e.msg),
              file=sys.stderr)
        return 1
    for line, msg in warnings:
        print("%s:%d: warning: %s" % (args.input, line, msg),
              file=sys.stderr)
    if args.truncate:
        data = data[:max(0, len(data) - args.truncate)]
    with open(args.output, "wb") as f:
        f.write(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
