;;;
 ; runtime.inc
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Runtime library definitions and API addresses
 ; 
 ; Copyright (c) 2024
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

; Definitions for runtime used in code generated by the Pascal compiler

zp_base := $04

sp := zp_base + $00
sreg := zp_base + $02
ptr1 := zp_base + $04
ptr2 := zp_base + $06
ptr3 := zp_base + $08
ptr4 := zp_base + $0a
tmp1 := zp_base + $0c
tmp2 := zp_base + $0d
tmp3 := zp_base + $0e
tmp4 := zp_base + $0f
intOp1 := zp_base + $10                 ; 2 bytes
intOp2 := zp_base + $12                 ; 2 bytes
intOp32 := zp_base + $14                ; 4 bytes
intPtr := zp_base + $18                 ; 2 bytes
stackP := zp_base + $1a                 ; 2 bytes
savedStackPtr := zp_base + $1c          ; 2 bytes
currentNestingLevel := zp_base + $1e    ; 1 byte
exitHandler := zp_base + $1f            ; 2 bytes
FPBASE = zp_base + $21                  ; 44 bytes
FPBUF = zp_base + $4d                   ; 15 bytes
tensTable32Ptr = zp_base + $5c          ; 2 bytes
inputBuf = zp_base + $5e             ; 2 bytes
inputPos = zp_base + $60             ; 1 byte
inputBufUsed = zp_base + $61            ; 1 byte

; File Handles
; Used by read/write routines that are called by read/readln/write/writeln/writestr
fhStdio = $80                   ; Use screen/keyboard for IO
fhString = $81                  ; Use string for IO

; Jump table for runtime routines assembled at a fixed address

.ifdef __MEGA65__
rt_base = $2028         ; 0x2001 + 19 + 20 (exe header + DMA command block + jmp MAIN)
.else
rt_base = $810          ; 0x801 + 15 (exe header + jmp MAIN)
.endif

rtCalcStackOffset       = rt_base + 9
rtStoreInt              = rt_base + 12
rtFileOpen              = rt_base + 18
rtPopToIntOp1           = rt_base + 21
rtPushFromIntOp1        = rt_base + 27
rtPushReal              = rt_base + 30
rtStoreReal             = rt_base + 33
rtPopToReal             = rt_base + 36
rtFileClose             = rt_base + 39
rtEOF                   = rt_base + 42
rtSetIOResult           = rt_base + 48
rtPopToIntOp1And2       = rt_base + 57
rtGetIOResult           = rt_base + 60
rtFileErase             = rt_base + 63
rtStoreInt32            = rt_base + 66
rtPushFromIntOp1And2    = rt_base + 69
rtFileAssign            = rt_base + 72
rtFileRename            = rt_base + 78
rtHeapAlloc             = rt_base + 87
rtHeapFree              = rt_base + 90
rtPopEax                = rt_base + 99
rtWriteValue            = rt_base + 105
rtLeftPad               = rt_base + 108
rtStrCase               = rt_base + 114
rtTrim                  = rt_base + 117
rtSetFh                 = rt_base + 123
rtClearKeyBuf           = rt_base + 135
rtGetKey                = rt_base + 138
rtStrCompare            = rt_base + 141
rtPushAx                = rt_base + 144
rtAdd                   = rt_base + 150
rtMultiply              = rt_base + 156
rtPushEax               = rt_base + 198
rtStrToFloat            = rt_base + 225
rtConvertString         = rt_base + 234
rtLibLoadParam          = rt_base + 246
rtLibReturnValue        = rt_base + 249
rtLibStoreVarParam      = rt_base + 252
rtStrPos                = rt_base + 255
rtBeginsWith            = rt_base + 258
rtEndsWith              = rt_base + 261
rtContains              = rt_base + 264
rtSine                  = rt_base + 285
rtCosine                = rt_base + 288
rtTangent               = rt_base + 291
rtLibStackHeader        = rt_base + 318
rtLibCallRoutine        = rt_base + 321
rtAddIrqHandler         = rt_base + 324
rtIrqCleanup            = rt_base + 327
