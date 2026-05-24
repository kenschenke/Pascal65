;
; loadLibrary.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; loadLibrary routine

.include "asm.inc"
.include "ast.inc"
.include "c64.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"

codeBase = $2001

.export loadLibrary

.import incCodeOffset

.data

strCleanup: .asciiz "cleanup"
strInit: .asciiz "init"
strRtnEnter: .asciiz "rtnenter"
strLibDecl: .asciiz "libdecl"
strLib: .asciiz ".lib"
strSuffix: .asciiz ",p,r"

.bss

buf: .res 3
libName: .res 4
libRoot: .res 4
libBase: .res 2
libBuf: .res 4
filename: .res 16
label: .res 16
page: .res 1
pages: .res 1
numRead: .res 2
currentDecl: .res 4
; pos: .res 2

.code

; Name in ptr1
; Unit AST root in ptr2
.proc loadLibrary
    ldq ptr1
    stq libName
    ldq ptr2
    stq libRoot

    lda #.lobyte(codeBase)
    clc
    adc codeOffset
    sta libBase
    lda #.hibyte(codeBase)
    adc codeOffset+1
    sta libBase+1

    jsr openLibrary

    ; Read the starting address
    ldx #2
    jsr CHKIN
    jsr CHRIN
    cmp #0              ; Library must start on a page boundary
    beq :+
    lda #2              ; expected library to start on a page boundary
    jsr CLOSE
    rts

:   jsr CHRIN
    sta page

    ; Read the entire library into a memory buffer
    jsr readLibrary
    lda #2
    jsr CLOSE

    ; Calculate the number of pages needed
    lda numRead+1
    sta pages
    lda numRead
    beq :+
    inc pages

    ldx #1
    jsr CHKOUT

:   jsr processJumpTable

    jsr processLibraryObjCode

    ldq libBuf
    jsr freeMemBuf

    rts
.endproc

.proc openLibrary
    ldq libName
    stq ptr1
    ldx #0
    ldz #0
:   nop
    lda (ptr1),z
    beq :+
    sta filename,x
    inx
    inz
    bne :-
:   ldy #0
:   lda strLib,y
    beq :+
    sta filename,x
    inx
    iny
    bne :-
:   ldy #0
:   lda strSuffix,y
    beq :+
    sta filename,x
    inx
    iny
    bne :-

    ; Open the library file
:   phx             ; Save the filename length
    ldx DEVNUM
    lda #2
    tay
    iny
    jsr SETLFS
    ; Call SETNAM
    ldx #<filename
    ldy #>filename
    pla             ; filename length
    jsr SETNAM
    ; Open the file
    jsr OPEN

    rts
.endproc

; Read the library into a memory buffer
.proc readLibrary
    lda #0
    sta numRead
    sta numRead+1

    jsr allocMemBuf
    stq libBuf

L1: lda STATUS
    and #$40
    beq :+
    ldq libBuf
    stq ptr1
    lda #0
    tax
    jsr setMemBufPos
    rts

:   jsr CHRIN
    sta buf

    ; Write the byte to the memory buffer
    ldq libBuf
    stq ptr1
    lda #<buf
    sta ptr2
    lda #>buf
    sta ptr2+1
    ldx #0
    stx ptr2+2
    stx ptr2+3
    lda #1
    jsr writeToMemBuf

    lda numRead
    clc
    adc #1
    sta numRead
    lda numRead+1
    adc #0
    sta numRead+1
    bra L1
.endproc

.proc processJumpTable
    ; Write the entry point for the library initialization
    lda #<buf
    ldx #>buf
    ldy #3
    jsr readLibBuf
    lda buf
    cmp #OC_JMP
    bne :+
    jsr relocAddr
:   ldq libRoot
    stq intOp32
    lda #<strInit
    ldx #>strInit
    jsr writeLibJumpTableEntry

    ; Write the entry point for the library cleanup
    lda #<buf
    ldx #>buf
    ldy #3
    jsr readLibBuf
    lda buf
    cmp #OC_JMP
    bne :+
    jsr relocAddr
:   ldq libRoot
    stq intOp32
    lda #<strCleanup
    ldx #>strCleanup
    jsr writeLibJumpTableEntry

    ; Loop through the library's interface declarations
    ldq libRoot
    stq ptr1
    ldz #decl::code
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr1
    ldz #stmt::interfaceDecl
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl

L1: ldq currentDecl
    jsr isQZero
    bne :+
    rts

:   stq ptr1
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    stq ptr2

    ldz #type::kind
    nop
    lda (ptr2),z
    cmp #TYPE_FUNCTION
    bne :+
    jsr handleRoutine
    bra NX
:   cmp #TYPE_PROCEDURE
    bne :+
    jsr handleRoutine
    bra NX
:   ldz #decl::kind
    nop
    lda (ptr1),z
    cmp #DECL_VARIABLE
    bne NX
    jsr handleVariable

NX: ldq currentDecl
    stq ptr1
    ldz #decl::next
    neg
    neg
    nop
    lda (ptr1),z
    stq currentDecl
    bra L1
.endproc

.proc handleRoutine
    lda #<buf
    ldx #>buf
    ldy #3
    jsr readLibBuf
    lda buf
    cmp #OC_JMP
    beq :+
    rts

:   jsr relocAddr
    ldq currentDecl
    stq intOp32
    lda #<strRtnEnter
    ldx #>strRtnEnter
    jsr writeLibJumpTableEntry
    rts
.endproc

; Z flag is set if buffer is at end
; .proc isLibBufAtEnd
;     ; Compare the high bytes first
;     lda pos + 1
;     cmp numRead + 1
;     bcc L2
;     bne L1

;     ; Compare the lower bytes
;     lda pos
;     cmp numRead
;     bcc L2

; L1:
;     lda #0
;     rts

; L2:
;     lda #1
;     rts

;     ldq libBuf
;     jsr isMemBufAtEnd
;     rts
; .endproc

; This routine reads object code from the library file.
; It loads bytes into the buffer and searches for addresses
; to relocate.
.proc processLibraryObjCode
    ; Get the membuf position
    ; ldq libBuf
    ; jsr getMemBufPos
    ; sta pos
    ; stx pos+1

    ; Loop through the buffer
    ; Algorithm:
    ;    Read one byte before going into the loop
    ;    Loop:
    ;        If the end of the buffer has been reached, write the current byte and exit
    ;        Read another byte from the buffer
    ;        If the second byte is a page number to relocate:
    ;            Relocate the two bytes and write them both
    ;            If the end of the buffer, exit the loop
    ;            Read another byte from the buffer
    ;        Else
    ;            Write the first byte then keep the second byte for the next loop

    ; Read one byte to prime the pump
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readLibBuf

L1: ldq libBuf
    jsr isMemBufAtEnd
    bne L2
    ; End of the buffer - write the last byte then exit
    lda buf
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    bra DN

    ; Read another byte
L2: lda #<(buf+1)
    ldx #>(buf+1)
    ldy #1
    jsr readLibBuf

    ; Add 1 to pos
    ; lda pos
    ; clc
    ; adc #1
    ; sta pos
    ; lda pos+1
    ; adc #0
    ; sta pos+1

    ; Are we at the end of the buffer?
    ; ldq libBuf
    ; jsr isMemBufAtEnd
    ; jsr isLibBufAtEnd
    ; bne L2

    ; We are at the end
    ; lda buf
    ; jsr CHROUT
    ; lda #1
    ; jsr incCodeOffset
    ; bra DN

    ; Is this an address that needs to be relocated?
    jsr isPageInRange
    bcs L3                  ; Branch if the first byte of address to be relocated

    ; Write the first byte but keep the second byte
    lda buf
    jsr CHROUT
    lda #1
    jsr incCodeOffset
    lda buf+1
    sta buf
    bra L1

    ; Address needs to be relocated.
L3: lda buf+1
    sta buf+2
    lda buf
    sta buf+1
    jsr relocAddr
    lda buf+1
    jsr CHROUT
    lda buf+2
    jsr CHROUT
    lda #2
    jsr incCodeOffset

    ; If those were the last two bytes then exit
    ldq libBuf
    jsr isMemBufAtEnd
    beq DN

    ; Read another byte
    lda #<buf
    ldx #>buf
    ldy #1
    jsr readLibBuf

    ; Add another to pos
    ; lda pos
    ; clc
    ; adc #1
    ; sta pos
    ; lda pos+1
    ; adc #0
    ; sta pos+1

    bra L1

DN: rts
.endproc

; This routine checks the page number in buf+1 and determines
; if it in the range of page..(page+pages)
; Carry flag set if address needs to be relocated
.proc isPageInRange
    ; Is buf+1 < page
    lda buf+1
    cmp page
    bcc :+

    ; Is page+pages <= buf+1?
    lda page
    adc pages
    sec
    sbc #2
    sec
    sbc buf+1

:   rts
.endproc

.proc handleVariable
    ldz #decl::type
    neg
    neg
    nop
    lda (ptr1),z
    sta intOp32
    lda #<strLibDecl
    ldx #>strLibDecl
    jsr formatEntryLabel
    lda #<label
    ldx #>label
    jsr linkAddressSet

    lda #<buf
    ldx #>buf
    ldy #2
    jsr readLibBuf

    lda buf
    jsr CHROUT
    lda buf+1
    jsr CHROUT

    lda #2
    jsr incCodeOffset
    rts
.endproc

; Address to label prefix passed in A/X.
; Address of entry passed in intOp32
.proc formatEntryLabel
    sta ptr1
    stx ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    sta label,y
    iny
    bne :-
:   sty tmp1            ; length in tmp1
    lda #<label
    clc
    adc tmp1
    sta ptr1
    lda #>label
    adc #0
    sta ptr1+1
    lda ptr1
    ldx ptr1+1
    jsr hexstr
    rts
.endproc

; Address to label prefix passed in A/X.
; Address of entry passed in intOp32
.proc writeLibJumpTableEntry
    jsr formatEntryLabel
    lda #<label
    ldx #>label
    jsr linkAddressSet
    lda buf
    jsr CHROUT
    lda buf+1
    jsr CHROUT
    lda buf+2
    jsr CHROUT
    lda #3
    jsr incCodeOffset
    rts
.endproc

; This routine calculates the relocated address for the
; address in buf+1 and buf+2
;
; Page number in buf+2 and offset in buf+1
.proc relocAddr
    lda libBase
    sta intOp1
    lda libBase+1
    sta intOp1+1
    lda buf+2
    sec
    sbc page
    sta intOp2+1
    lda buf+1
    sta intOp2
    jsr addInt16
    lda intOp1
    sta buf+1
    lda intOp1+1
    sta buf+2
    rts
.endproc

; Buffer in A/X
; Number of bytes to read in Y
.proc readLibBuf
    ; Set up the buffer
    sta ptr2
    stx ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3

    ; Save the number of bytes to read
    phy

    ; Set up the membuf header
    ldq libBuf
    stq ptr1

    ; Number of bytes to read
    pla
    ldx #0

    jmp readFromMemBuf
.endproc
