;;;
 ; rtlayout.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; The layout of a compiled program
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; Include asm.inc first.

; The PRG loads here, at the start of BASIC, and the linker lays it out
; (genObjCode.s in linkerasm):
;
;    the BASIC line "10 BANK 0:SYS 8209", then JMP to the program header
;    20 bytes for the MEGA65's DMA command block
;    the runtime at RT_BASE: static, its jump table, core and packages;
;        dynamic, an empty jump table and the loader (loader.s)
;    the libraries, in the program's Uses order
;    the program module, which starts with the program header
;    the runtime's BSS (the linker symbols in linker.inc)
LINK_CODE_BASE = $2001
LINK_STUB_SIZE = 39         ; the BASIC line, the JMP and the DMA block
.assert LINK_CODE_BASE + LINK_STUB_SIZE = RT_BASE, error, "RT_BASE moved"

; A dynamic program's loader follows its empty jump table
LOADER_ADDR = RT_BASE + RT_JMPTBL_SIZE

; The program image, its heap and its runtime stack share $2001 up to the
; ceiling: $C000 for a static program, rtLow for a dynamic one. The linker
; fails a program that would leave less than MIN_HEAP_SIZE bytes of heap
; (errCodeSegmentOverflow or errCodeSegmentOverflowDyn). The dynamic
; loader checks the same against the runtime it loads.
LINK_STATIC_CEILING = $C000
MIN_HEAP_SIZE = 256

; Offsets in the program header (prgHeader.s in codegen) that the dynamic
; loader reads and patches when the program runs. prgHeader.s asserts them.
PRG_HEADER_CODE_OFFSET_1 = 13   ; .word the page zero backup
PRG_HEADER_CODE_OFFSET_2 = 62   ; the heap's bottom, low byte
PRG_HEADER_CODE_OFFSET_3 = 64   ; and high byte
PRG_HEADER_STACKSIZE1_L = 47    ; the runtime stack's size
PRG_HEADER_STACKSIZE1_H = 49
PRG_HEADER_STACKSIZE2_L = 54    ; the heap's top
PRG_HEADER_STACKSIZE2_H = 58
PRG_HEADER_STACKTOP_H = 41      ; the stack's top, high byte

; A static runtime package's header, before its entries (rtpkg.inc)
PKG_HEADER_SIZE = 5
