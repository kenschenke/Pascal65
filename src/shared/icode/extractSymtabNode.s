;;;
 ; extractSymtabNode.s
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

.export extractSymtabNode

.import pullDataFromIcode, _retrieveChunk
.import popax, pushax

.bss

pNode: .res 2
chunkNum: .res 2
hdrChunkNum: .res 2

.code

; char extractSymtabNode(CHUNKNUM hdrChunkNum, SYMTABNODE *pNode)
.proc extractSymtabNode
    ; Store the pNode parameter
    sta pNode
    stx pNode + 1
    ; Store the hdrChunkNum parameter
    jsr popax
    sta hdrChunkNum
    stx hdrChunkNum + 1

    ; Call pullDataFromIcode
    ; First parameter
    lda hdrChunkNum
    ldx hdrChunkNum + 1
    jsr pushax
    ; Second parameter
    lda #<chunkNum
    ldx #>chunkNum
    jsr pushax
    lda #2
    ldx #0
    jsr pullDataFromIcode

    ; Call retrieveChunk
    ; First parameter
    lda chunkNum
    ldx chunkNum + 1
    jsr pushax
    ; Second parameter
    lda pNode
    ldx pNode + 1
    jmp _retrieveChunk

.endproc
