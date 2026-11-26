;;;
 ; heap.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ;
 ; The script language of the runtime heap tests (main.s, tests.s)
 ;
 ; Copyright (c) 2026
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; Each test is a script of steps. A step is an opcode and its arguments.
; Every script starts with INIT and ends with TEND.

OP_END = 0
OP_INIT = 1         ; bottom.w top.w
OP_ALLOC = 2        ; size.w address.w
OP_OOM = 3          ; size.w
OP_FREE = 4         ; address.w
OP_MAT = 5          ; count, count * (size.w address.w)
OP_SETMAT = 6       ; count, count * (size.w address.w)
OP_TOP = 7
OP_STRESS = 8       ; seed.w steps.w mask oomok
NUM_OPS = 8

; Fills TESTMEM with a guard byte and calls heapInit with the heap's
; bottom and top (the address of the MAT's first entry)
.macro INIT bottom, top
    .byte OP_INIT
    .word bottom, top
.endmacro

; heapAlloc of size must return address
.macro ALLOC size, address
    .byte OP_ALLOC
    .word size, address
.endmacro

; heapAlloc of size must end with rteOutOfMemory
.macro OOM size
    .byte OP_OOM
    .word size
.endmacro

; heapFree of address
.macro FREE address
    .byte OP_FREE
    .word address
.endmacro

; The MAT must hold count entries, given with USED and AVAIL, then its
; zero entry
.macro MAT count
    .byte OP_MAT, count
.endmacro

; Writes count entries, given with USED and AVAIL, and a zero entry to the
; MAT. The blocks are never written, so their addresses can be anywhere.
.macro SETMAT count
    .byte OP_SETMAT, count
.endmacro

; An entry for an allocated block
.macro USED size, address
    .word (size) | $8000, address
.endmacro

; An entry for a free block
.macro AVAIL size, address
    .word size, address
.endmacro

; heapAlloc's special call, $FFFF, must return the heap's top
.macro TOP
    .byte OP_TOP
.endmacro

; Allocates and frees blocks at random for steps steps, checking the heap
; after each (see stress in main.s). A block's size is a random number
; and mask, plus 1. With oomok non-zero the heap may run out of memory.
.macro STRESS seed, steps, mask, oomok
    .byte OP_STRESS
    .word seed, steps
    .byte mask, oomok
.endmacro

.macro TEND
    .byte OP_END
.endmacro
