;
; membufasm.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Definitions for membuf routines in ASM LIB

MEMBUF_CHUNK_LEN = 50

.struct MEMBUF_CHUNK
    nextChunk .dword        ; Pointer to next chunk
    data .res 50
.endstruct

.struct MEMBUF
    firstChunk .dword
    currentChunk .dword
    posGlobal .word
    posChunk .byte
    capacity .word
    used .word
.endstruct
