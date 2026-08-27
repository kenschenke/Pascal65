;
; checkStdRoutine.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT

.include "ast.inc"
.include "asmlib.inc"
.include "symtab.inc"
.include "zeropage.inc"
.include "typecheck.inc"
.include "4510macros.inc"

retnTypePtrOffset = 0
argPtrOffset = retnTypePtrOffset + 4
typePtrOffset = argPtrOffset + 4

.export checkStdRoutine

.import loadStackValue, checkReadReadlnCall, checkWriteWritelnCall, checkAbsSqrCall
.import checkPredSuccCall, checkStdParms, checkDecIncCall

.proc checkStdRoutine
    ; Zero out the return type
    ldz #retnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    lda #0
    taz
:   nop
    sta (ptr1),z
    inz
    cpz #.sizeof(type)
    bne :-

    ; Check the routine code
    ldz #typePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::routineCode
    nop
    lda (ptr1),z

    cmp #rcRead
    bne :+
    jsr readReadln
    jmp DN
:   cmp #rcReadln
    bne :+
    jsr readReadln
    jmp DN
:   cmp #rcWrite
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcWriteln
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcWriteStr
    bne :+
    jsr writeWriteln
    jmp DN
:   cmp #rcAbs
    bne :+
    jsr absSqr
    jmp DN
:   cmp #rcSqr
    bne :+
    jsr absSqr
    jmp DN
:   cmp #rcPred
    bne :+
    jsr predSucc
    jmp DN
:   cmp #rcSucc
    bne :+
    jsr predSucc
    jmp DN
:   cmp #rcOrd
    bne :+
    jsr checkOrd
    jmp DN
:   cmp #rcRound
    bne :+
    jsr roundTrunc
    jmp DN
:   cmp #rcTrunc
    bne :+
    jsr roundTrunc
    jmp DN
:   cmp #rcDec
    bne :+
    jsr decInc
    jmp DN
:   cmp #rcInc
    bne :+
    jsr decInc
    jmp DN
:   lda #TYPE_VOID
    jsr setReturnType

DN: jsr popQ
    jsr popQ
    jsr popQ
    rts
.endproc

.proc absSqr
    pha
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    pla
    jsr pushA
    jsr checkAbsSqrCall
    jsr setReturnType
    rts
.endproc

.proc checkOrd
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    lda #(STDPARM_CHAR | STDPARM_ENUM | STDPARM_INTEGER)
    jsr pushA
    jsr checkStdParms
    lda #TYPE_INTEGER
    jsr setReturnType
    rts
.endproc

.proc decInc
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    jsr checkDecIncCall
    rts
.endproc

.proc predSucc
    ldz #argPtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #retnTypePtrOffset
    jsr loadStackValue
    stq ptr2
    ldq ptr1
    jsr pushQ
    ldq ptr2
    jsr pushQ
    jsr checkPredSuccCall
    rts
.endproc

.proc readReadln
    pha
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    pla
    jsr pushA
    jsr checkReadReadlnCall
    lda #TYPE_VOID
    jsr setReturnType
    rts
.endproc

.proc roundTrunc
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    lda #STDPARM_REAL
    jsr pushA
    jsr checkStdParms
    lda #TYPE_INTEGER
    jsr setReturnType
    rts
.endproc

.proc setReturnType
    pha
    ldz #retnTypePtrOffset
    jsr loadStackValue
    stq ptr1
    ldz #type::kind
    pla
    nop
    sta (ptr1),z
    rts 
.endproc

.proc writeWriteln
    pha
    ldz #argPtrOffset
    jsr loadStackValue
    jsr pushQ
    pla
    pha
    jsr pushA
    jsr checkWriteWritelnCall
    pla
    cmp #rcWriteStr
    bne L1
    lda #TYPE_STRING_OBJ
    bra L2
L1: lda #TYPE_VOID
L2: jsr setReturnType
    rts
.endproc
