;;;
 ; putTokenToIcode.s
 ; Ken Schenke (kenschenke@gmail.com)
 ; 
 ; Intermediate Code Storage and Retrieval
 ; 
 ; Copyright (c) 2022
 ; Use of this source code is governed by an MIT-style
 ; license that can be found in the LICENSE file or at
 ; https://opensource.org/licenses/MIT
;;;

.export _putTokenToIcode

.import _checkIcodeBounds, _writeToMemBuf, _errorCount
.import popax, pushax

.bss

code: .res 1
chunkNum: .res 2

.code

; void putTokenToIcode(CHUNKNUM chunkNum, TTokenCode tc)
.proc _putTokenToIcode
    ; Store the code parameter
    sta code
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
    lda #1
    ldx #0
    jsr _checkIcodeBounds

    ; write token to icode
    ; first parameter to putDataToIcode
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; second parameter to putDataToIcode
    lda #<code
    ldx #>code
    jsr pushax
    ; third parameter to putDataToIcode
    lda #1
    ldx #0
    jsr _writeToMemBuf

@Done:
    rts

.endproc
