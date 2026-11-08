;;;
 ; rtpkg.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; Runtime packages
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; A runtime package is a part of the runtime that the core never calls,
; except through the jump table. Codegen links a package into a program only
; if the program needs it (see RTF_* in asm.inc). Packages always follow the
; core in package number order, so a package's address depends only on which
; of the packages before it are linked. The runtime build links each package
; once for each of those addresses (see mkruntime.py).
;
; A package's code and data are in a segment named after it, such as
; "FILES". Its variables are reserved in the core (see pkgbss.s), so they
; have the same address whatever is linked.
;
; Each package variant file starts with this header:
;
;    .byte package number (RT_PKG_*)
;    .byte position: the RTF_* bits of the packages linked before it
;    .word length of the package's code and data, which follow the header
;    .byte number of jump table entries
;    Then for each entry:
;       .byte jump table entry number (offset from RT_BASE / 3)
;       .addr the routine's address
;
; The core's jump table entries for a package point at a stub that raises
; rtePackageNotLinked. Codegen patches them from this list.

; Sizes of the package variables reserved in the core
DYNARRAYS_BSS_SIZE = 18
FILES_BSS_SIZE = 4

; Starts the header. name is the package's segment name. The linker
; defines __<name>_SIZE__ (the segment's size) and __<name>_POS__ (the
; package's position), and the header goes in the <name>HDR segment.
.macro pkgHeader name, num
    .segment .concat(name, "HDR")
    .import .ident(.concat("__", name, "_SIZE__"))
    .importzp .ident(.concat("__", name, "_POS__"))
    .byte num
    .byte .ident(.concat("__", name, "_POS__"))
    .word .ident(.concat("__", name, "_SIZE__"))
    .byte (pkgEntriesEnd - pkgEntries) / 3
pkgEntries:
.endmacro

; One jump table entry. entry is the entry's RT_* address (asm.inc).
.macro pkgEntry entry, routine
    .byte (entry - RT_BASE) / 3
    .addr routine
.endmacro

; Ends the header
.macro pkgEnd
pkgEntriesEnd:
.endmacro
