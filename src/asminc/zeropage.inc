;
; zeropage.inc
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; Zeropage definitions for ASM LIB

zp_base := $04

heapBottom := zp_base + $00     ; 4 bytes
heapTop := zp_base + $04        ; 4 bytes
ptr1 := zp_base + $08           ; 4 bytes
ptr2 := zp_base + $0c           ; 4 bytes
ptr3 := zp_base + $10           ; 4 bytes
ptr4 := zp_base + $14           ; 4 bytes
tmp1 := zp_base + $18           ; 1 byte
tmp2 := zp_base + $19           ; 1 byte
tmp3 := zp_base + $1a           ; 1 byte
tmp4 := zp_base + $1b           ; 1 byte
intOp1 := zp_base + $1c         ; 2 bytes
intOp2 := zp_base + $1e         ; 2 bytes
intOp32 := zp_base + $20        ; 4 bytes
savedStackPtr := zp_base + $24  ; 2 bytes
exitHandler := zp_base + $26    ; 2 bytes
currentFile := zp_base + $28    ; 4 bytes
gapCursor := zp_base + $2c      ; 2 bytes
gapEnd := zp_base + $2e         ; 2 bytes
