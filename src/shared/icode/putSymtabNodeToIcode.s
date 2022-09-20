;;;
 ; putSymtabNodeToIcode.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.include "icode.inc"
.include "symtab.inc"

.export _putSymtabNodeToIcode

.import _checkIcodeBounds, putDataToIcode, _errorCount
.import popax, pushax

.bss

pNode: .res 2
chunkNum: .res 2

.code

; void putSymtabNodeToIcode(CHUNKNUM chunkNum, SYMTABNODE *pNode)
.proc _putSymtabNodeToIcode
    ; Store the pNode parameter
    sta pNode
    stx pNode + 1
    ; Store the chunkNum parameter
    jsr popax
    sta chunkNum
    stx chunkNum + 1

    ; Do nothing if _errorCount is non-zero
    lda _errorCount
    ora _errorCount + 1
    bne @Done

    ; check Icode bounds
    ; first parameter to _checkIcodeBounds
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; second parameter to _checkIcodeBounds
    lda #2
    ldx #0
    jsr _checkIcodeBounds

    ; write node to icode
    ; first parameter to _putSymtaNodeToIcode
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; second parameter to _putSymtabNodeToIcode
    lda pNode
    ldx pNode + 1
    jsr pushax
    ; third parameter to _putSymtabNodeToIcode
    lda #2
    ldx #0
    jsr putDataToIcode

@Done:
    rts

.endproc
