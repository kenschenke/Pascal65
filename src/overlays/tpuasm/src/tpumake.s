;
; tpumake.s
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; tpuMakeX (tpuMake, tpu.inc) finds the next unit that must be compiled to
; its TPU before a source file can be compiled, as Turbo Pascal's Make
; did. The compiler apps call it until it finds none, compiling each unit
; it names (unit mode), then compile the file.
;
; It walks the units the file uses, and the units they use, depth first.
; It reads each unit's source, not parsing it: the source's CRC and the
; names its Uses clauses give, in one pass (scanSource). A unit with a
; pre-compiled header (.hdr) or "Implementation Library" is a library and
; is never compiled. A unit's TPU is current when it has this TPU and icode
; version, the CRC of the source it was compiled from, and the interface
; CRC of each unit it used: a unit's from its own current TPU, a library's
; made from its header as tpuBegin made it (interfaceCrc). The first unit,
; deepest first, whose TPU isn't current is the one to compile. A unit
; with no source keeps its TPU, as tokenizeAndParseUnits does.
;
; Nothing is kept between calls: the walk starts again each time, from
; files only, so a unit compiled since the last call is seen as current.
; The overlay's BSS doesn't survive the overlays loaded between calls.
;
; A DOS command closes every open file (doesFileExist, loadHeader), so a
; file is read whole before any check that needs one.
;
; tpuCleanX (tpuClean) makes the same walk, but erases the TPU of each
; unit make could compile in place of checking it, and the unit's object
; file, so the make loop after it compiles them all and code generation
; makes every unit's code again (Rebuild all).

.include "c64.inc"
.include "tpu.inc"
.include "error.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "4510macros.inc"
.include "icode.inc"

.export tpuMakeX, tpuCleanX

.import nameToFn, addSuffix, openIn, startCrc, crcByte, crc, interfaceCrc
.import fnBuf, fnLen, loadHeader, eraseFile

FILE_IN = 2                 ; as tpu.s's

NAME_MAX = 12               ; with ".pas", a CBM file name's 16

; An entry for each unit the walk meets, in a list in the heap
ENT_NEXT = 0                ; the next entry (4 bytes)
ENT_NAME = 4                ; the unit's name, null-terminated
ENT_STATE = ENT_NAME + NAME_MAX + 1 ; STATE_*
ENT_KIND = ENT_STATE + 1    ; KIND_*
ENT_CRC = ENT_KIND + 1      ; its interface CRC, for KIND_CRC (2 bytes)
ENT_SRCCRC = ENT_CRC + 2    ; its source's CRC (2 bytes)
ENT_DEPS = ENT_SRCCRC + 2   ; the units it uses, a list of nodes (4 bytes)
ENT_SIZE = ENT_DEPS + 4

STATE_NEW = 0
STATE_VISITING = 1          ; its units are being walked
STATE_DONE = 2              ; current, or never compiled

KIND_NONE = 0               ; no interface CRC to compare
KIND_CRC = 1                ; ENT_CRC is its interface CRC
KIND_HDR = 2                ; a library with a header, its CRC not made

; A node in a list of unit names: the units a source or a TPU names
NODE_NEXT = 0               ; 4 bytes
NODE_NAME = 4               ; null-terminated
NODE_CRC = NODE_NAME + NAME_MAX + 1 ; the CRC a TPU recorded (2 bytes)
NODE_SIZE = NODE_CRC + 2

STOP_COMPILE = 1            ; the result buffer names a unit to compile
STOP_ERROR = 2              ; an error was reported

.data

strPas: .asciiz ".pas"
strHdr: .asciiz ".hdr"
strTpu: .asciiz ".tpu"
strObj: .asciiz ".obj"
strSeqRead: .asciiz ",s,r"
strSystem: .asciiz "system"
strUses: .asciiz "uses"
strImpl: .asciiz "implementation"
strLibrary: .asciiz "library"

.bss

rootFn: .res 2              ; the file to compile's name
cleanMode: .res 1           ; non-zero for tpuCleanX: erase, don't check
cleanBuf: .res NAME_MAX + 5 ; tpuCleanX's result buffer, never written
resultBuf: .res 2           ; the caller's buffer
prevFn: .res NAME_MAX + 5   ; the buffer's name from the last call
entries: .res 4             ; the entries
thisEnt: .res 4
thisDep: .res 4
listHead: .res 4            ; a list appendNode adds to
usedList: .res 4            ; the units a TPU lists
node: .res 4
hdrRoot: .res 4
fnEnt: .res 4               ; entryFnEnt's entry
name: .res NAME_MAX + 1     ; a unit's name, to find or add
stop: .res 1                ; STOP_*
tpuSrcCrc: .res 2           ; what a TPU recorded
tpuIfCrc: .res 2
cmpCrc: .res 2
count: .res 1
nameLen: .res 1
; scanSource's state
ch: .res 1
prev: .res 1
mode: .res 1                ; MODE_*
word: .res 16
wordLen: .res 1             ; WORD_LONG past what word holds
usesMode: .res 1            ; non-zero in a Uses clause
implFlag: .res 1            ; non-zero after "implementation"
isLib: .res 1

MODE_CODE = 0
MODE_BLOCK = 1              ; in (* *)
MODE_LINE = 2               ; in //
MODE_STRING = 3             ; in ' '
WORD_LONG = 16

.code

; This routine erases the TPU of every unit the file named at A/X (16
; bits, null-terminated) uses, and of the units they use, that make can
; compile again: a unit with a source that isn't a library. The make loop
; then compiles them all (Rebuild all in the IDE). Returns the carry set
; if it reported an error (errCircularUnitReference).
.proc tpuCleanX
    sta rootFn
    stx rootFn+1
    lda #1
    sta cleanMode
    lda #0
    sta cleanBuf
    lda #<cleanBuf
    ldx #>cleanBuf
    jmp walk
.endproc

; This routine finds the next unit to compile before the file named at
; A/X (16 bits, null-terminated). On the runtime stack is the 16-bit
; address of a buffer of 17 bytes, which the caller clears before its
; first call. Returns the carry set if it reported an error, or the carry
; clear with A zero if every unit is current, or A non-zero with the
; buffer holding the unit's source file's name. The same unit twice in a
; row means its compile left its TPU out of date: errUnitNotWritten.
.proc tpuMakeX
    sta rootFn
    stx rootFn+1
    lda #0
    sta cleanMode
    jsr popAX
    ; Fall through
.endproc

; This routine walks the units of the file in rootFn, the result buffer
; at A/X: tpuMakeX's, or tpuCleanX's
.proc walk
    sta resultBuf
    stx resultBuf+1

    ; The last call's result, then none
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    sta prevFn,y
    iny
    cpy #NAME_MAX + 5
    bne :-
    lda #0
    tay
    sta (ptr4),y
    sta stop
    sta usedList
    sta usedList+1
    sta usedList+2
    sta usedList+3
    sta entries
    sta entries+1
    sta entries+2
    sta entries+3

    ; The file's own entry, named by the file without ".pas", so a unit
    ; that uses it is a circular reference
    lda rootFn
    sta ptr4
    lda rootFn+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    cmp #'.'
    beq :+
    sta name,y
    iny
    cpy #NAME_MAX
    bne :-
:   lda #0
    sta name,y
    jsr addEntry
    stq thisEnt
    stq ptr1
    ldz #ENT_STATE
    lda #STATE_VISITING
    nop
    sta (ptr1),z

    ; Its units
    lda rootFn
    ldx rootFn+1
    jsr nameToFn
    jsr fileExists
    beq DN
    jsr scanSource
    jsr visitDeps
    bcs ST
DN: jsr freeEntries
    lda #0
    clc
    rts

ST: jsr freeEntries
    lda stop
    cmp #STOP_COMPILE
    beq :+
    sec
    rts

    ; The same unit as last time?
:   lda resultBuf
    sta ptr4
    lda resultBuf+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    cmp prevFn,y
    bne OK
    cmp #0
    beq :+
    iny
    bra :-
:   lda resultBuf
    ldx resultBuf+1
    jsr setCompilerFilename
    lda #errUnitNotWritten
    ldx #0
    ldy #0
    jsr compilerError
    sec
    rts
OK: lda #1
    clc
    rts
.endproc

; This routine walks the entry in Q and the units it uses. The carry is
; clear if they are all current, or set with stop saying why not.
.proc visit
    stq thisEnt
    stq ptr1
    ldz #ENT_STATE
    nop
    lda (ptr1),z
    cmp #STATE_DONE
    bne :+
    clc
    rts
:   cmp #STATE_VISITING
    bne :+
    jmp circular
:   lda #STATE_VISITING
    nop
    sta (ptr1),z

    ; A library with a pre-compiled header
    lda #<strHdr
    ldx #>strHdr
    jsr entryFn
    jsr fileExists
    beq :+
    lda #KIND_HDR
    jmp DN

    ; Its source, and the units it uses
:   lda #<strPas
    ldx #>strPas
    jsr entryFn
    jsr fileExists
    beq NS
    jsr scanSource
    lda isLib
    bne LB
    jsr visitDeps
    bcs RT
    lda cleanMode
    beq CK
    lda #<strTpu
    ldx #>strTpu
    jsr entryFn
    lda #<fnBuf
    ldx #>fnBuf
    jsr eraseFile
    lda #<strObj                ; and its object (objcache.s in codegen)
    ldx #>strObj
    jsr entryFn
    lda #<fnBuf
    ldx #>fnBuf
    jsr eraseFile
    bra LB
CK: jsr checkTpu
    bcs CP
    lda tpuIfCrc
    ldx tpuIfCrc+1
    jsr setCrc
    lda #KIND_CRC
    jmp DN
LB: lda #KIND_NONE
    jmp DN

    ; It must be compiled. Its source's name, for the caller.
CP: lda resultBuf
    sta ptr4
    lda resultBuf+1
    sta ptr4+1
    ldq thisEnt
    stq ptr1
    ldz #ENT_NAME
    ldy #0
:   nop
    lda (ptr1),z
    beq :+
    sta (ptr4),y
    inz
    iny
    bra :-
:   ldx #0
:   lda strPas,x
    sta (ptr4),y
    beq :+
    inx
    iny
    bra :-
:   lda #STOP_COMPILE
    sta stop
    sec
RT: rts

    ; No source: its TPU as it is, and the units it lists
NS: lda #<strTpu
    ldx #>strTpu
    jsr entryFn
    jsr fileExists
    beq NO
    jsr readTpu
    bcs NO
    lda tpuIfCrc
    ldx tpuIfCrc+1
    jsr setCrc
    ldq thisEnt
    stq ptr1
    ldz #ENT_KIND
    lda #KIND_CRC
    nop
    sta (ptr1),z
    ldz #ENT_DEPS
    ldx #0
:   lda usedList,x
    nop
    sta (ptr1),z
    lda #0
    sta usedList,x
    inz
    inx
    cpx #4
    bne :-
    jsr visitDeps
    bcs RT
    ldq thisEnt
    stq ptr1
    ldz #ENT_KIND
    nop
    lda (ptr1),z
    bra DN
NO: lda #KIND_NONE

    ; Done: A is its kind
DN: pha
    ldq thisEnt
    stq ptr1
    pla
    ldz #ENT_KIND
    nop
    sta (ptr1),z
    ldz #ENT_STATE
    lda #STATE_DONE
    nop
    sta (ptr1),z
    clc
    rts
.endproc

; This routine reports the entry in thisEnt, met again while walking its
; own units, as errCircularUnitReference in its source
.proc circular
    lda #<strPas
    ldx #>strPas
    jsr entryFn
    lda #<fnBuf
    ldx #>fnBuf
    jsr setCompilerFilename
    lda #errCircularUnitReference
    ldx #0
    ldy #0
    jsr compilerError
    lda #STOP_ERROR
    sta stop
    sec
    rts
.endproc

; This routine walks each unit the entry in thisEnt uses, in order. The
; carry is set as visit's.
.proc visitDeps
    ldq thisEnt
    stq ptr1
    ldz #ENT_DEPS
    neg
    neg
    nop
    lda (ptr1),z
L1: stq thisDep
    jsr isQZero
    bne :+
    clc
    rts

    ; Walking the unit changes thisEnt and thisDep
:   ldq thisEnt
    jsr pushQ
    ldq thisDep
    jsr pushQ
    ldq thisDep
    jsr nodeName
    jsr findEntry
    jsr isQZero
    bne :+
    jsr addEntry
:   jsr visit
    php
    jsr popQ
    stq thisDep
    jsr popQ
    stq thisEnt
    plp
    bcc :+
    rts
:   ldq thisDep
    stq ptr1
    ldz #NODE_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
.endproc

; This routine checks the TPU of the entry in thisEnt, whose units are
; walked. The carry is set if it must be compiled, or clear with its
; interface CRC in tpuIfCrc.
.proc checkTpu
    lda #<strTpu
    ldx #>strTpu
    jsr entryFn
    jsr fileExists
    bne :+
    sec
    rts
:   jsr readTpu
    bcc :+
    rts

    ; The source it was compiled from
:   ldq thisEnt
    stq ptr1
    ldz #ENT_SRCCRC
    nop
    lda (ptr1),z
    cmp tpuSrcCrc
    bne ST
    inz
    nop
    lda (ptr1),z
    cmp tpuSrcCrc+1
    bne ST

    ; The interface of each unit it used. A unit the walk didn't meet is
    ; one the source no longer uses.
    ldq usedList
L1: stq node
    jsr isQZero
    beq OK
    ldq node
    jsr nodeName
    jsr findEntry
    jsr isQZero
    beq ST
    jsr getCrc
    bcs NX
    ldq node
    stq ptr1
    ldz #NODE_CRC
    nop
    lda (ptr1),z
    cmp cmpCrc
    bne ST
    inz
    nop
    lda (ptr1),z
    cmp cmpCrc+1
    bne ST
NX: ldq node
    stq ptr1
    ldz #NODE_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    bra L1

OK: jsr freeUsed
    clc
    rts
ST: jsr freeUsed
    sec
    rts
.endproc

; This routine puts the interface CRC of the entry in Q in cmpCrc, making
; a library's from its header the first time. The carry is set if it has
; none to compare.
.proc getCrc
    stq hdrRoot                 ; the entry, for now
    stq ptr1
    ldz #ENT_KIND
    nop
    lda (ptr1),z
    cmp #KIND_CRC
    beq CR
    cmp #KIND_HDR
    beq :+
    sec
    rts

    ; A library's: made from its header, as tpuBegin made it
:   ldq hdrRoot
    jsr pushQ
    ldq hdrRoot
    stq fnEnt
    lda #<strHdr
    ldx #>strHdr
    jsr entryFnEnt
    lda #<fnBuf
    ldx #>fnBuf
    jsr loadHeader
    bcs :+
    jsr popQ
    stq ptr1
    ldz #ENT_KIND
    lda #KIND_NONE
    nop
    sta (ptr1),z
    sec
    rts
:   stq hdrRoot
    jsr interfaceCrc
    php
    ldq hdrRoot
    jsr astFree
    jsr popQ
    stq hdrRoot
    stq ptr1
    plp
    bcc :+
    ldz #ENT_KIND
    lda #KIND_NONE
    nop
    sta (ptr1),z
    sec
    rts
:   ldz #ENT_CRC
    lda crc
    nop
    sta (ptr1),z
    inz
    lda crc+1
    nop
    sta (ptr1),z
    ldz #ENT_KIND
    lda #KIND_CRC
    nop
    sta (ptr1),z

CR: ldq hdrRoot
    stq ptr1
    ldz #ENT_CRC
    nop
    lda (ptr1),z
    sta cmpCrc
    inz
    nop
    lda (ptr1),z
    sta cmpCrc+1
    clc
    rts
.endproc

; This routine sets the interface CRC of the entry in thisEnt from A/X
.proc setCrc
    pha
    phx
    ldq thisEnt
    stq ptr1
    ldz #ENT_CRC + 1
    pla
    nop
    sta (ptr1),z
    dez
    pla
    nop
    sta (ptr1),z
    rts
.endproc

; This routine reads the TPU named in fnBuf: its CRCs in tpuSrcCrc and
; tpuIfCrc and the units it lists in usedList. The carry is set if it
; isn't of this TPU and icode version.
.proc readTpu
    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    jsr CHRIN
    cmp #TPU_MAGIC0
    bne BD
    jsr CHRIN
    cmp #TPU_MAGIC1
    bne BD
    jsr CHRIN
    cmp #TPU_VERSION
    bne BD
    jsr CHRIN
    cmp #ICODE_VERSION
    beq :+
BD: jsr closeIn
    sec
    rts

:   jsr CHRIN                   ; the flags
    jsr CHRIN
    sta tpuSrcCrc
    jsr CHRIN
    sta tpuSrcCrc+1
    jsr CHRIN
    sta tpuIfCrc
    jsr CHRIN
    sta tpuIfCrc+1

    ; The units it used, each with its interface CRC
    lda #0
    sta listHead
    sta listHead+1
    sta listHead+2
    sta listHead+3
    jsr CHRIN
    sta count
L1: lda count
    beq DN
    dec count
    jsr CHRIN
    sta nameLen
    ldx #0
:   cpx nameLen
    beq :++
    phx
    jsr CHRIN
    plx
    cpx #NAME_MAX
    bcs :+
    sta name,x
:   inx
    bra :--
:   cpx #NAME_MAX
    bcc :+
    ldx #NAME_MAX
:   lda #0
    sta name,x
    jsr appendNode
    ldq node
    stq ptr1
    jsr CHRIN
    ldz #NODE_CRC
    nop
    sta (ptr1),z
    jsr CHRIN
    ldz #NODE_CRC + 1
    nop
    sta (ptr1),z
    bra L1

DN: jsr closeIn
    ldq listHead
    stq usedList
    clc
    rts
.endproc

; This routine reads the source named in fnBuf for the entry in thisEnt:
; its CRC, as tpuBegin makes it, and the units its Uses clauses name,
; after System, which every unit uses. isLib is set if it is a library.
.proc scanSource
    lda #0
    sta listHead
    sta listHead+1
    sta listHead+2
    sta listHead+3
    sta mode
    sta prev
    sta wordLen
    sta usesMode
    sta implFlag
    sta isLib
    ldx #0
:   lda strSystem,x
    sta name,x
    beq :+
    inx
    bra :-
:   jsr appendNode

    lda #<strSeqRead
    ldx #>strSeqRead
    jsr openIn
    jsr startCrc
L1: jsr CHRIN
    sta ch
    jsr crcByte
    jsr scanChar
    lda STATUS
    beq L1
    jsr endWord
    jsr closeIn

    ldq thisEnt
    stq ptr1
    ldz #ENT_SRCCRC
    lda crc
    nop
    sta (ptr1),z
    inz
    lda crc+1
    nop
    sta (ptr1),z
    ldz #ENT_DEPS
    ldx #0
:   lda listHead,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine takes the source's character in ch. Words are found as the
; tokenizer finds them, outside comments and strings.
.proc scanChar
    lda mode
    beq CD
    cmp #MODE_BLOCK
    bne :+
    lda prev
    cmp #'*'
    bne SV
    lda ch
    cmp #')'
    bne SV
    bra EN
:   cmp #MODE_LINE
    bne :+
    lda ch
    cmp #13
    beq EN
    cmp #10
    beq EN
    rts
:   lda ch                      ; MODE_STRING
    cmp #'''
    bne RT
EN: lda #MODE_CODE
    sta mode
    lda #0
    sta prev
RT: rts
SV: lda ch
    sta prev
    rts

    ; A letter, or a digit in a word
CD: lda ch
    jsr isLetter
    bcc AD
    lda wordLen
    beq :+
    lda ch
    cmp #'0'
    bcc :+
    cmp #'9' + 1
    bcc AD
:   jsr endWord
    lda prev
    cmp #'('
    bne :+
    lda ch
    cmp #'*'
    bne :+
    lda #MODE_BLOCK
    sta mode
    lda #0
    sta prev
    rts
:   lda prev
    cmp #'/'
    bne :+
    lda ch
    cmp #'/'
    bne :+
    lda #MODE_LINE
    sta mode
    rts
:   lda ch
    cmp #'''
    bne :+
    lda #MODE_STRING
    sta mode
    rts
:   cmp #';'
    bne PV
    lda #0
    sta usesMode
PV: lda ch
    sta prev
    rts

AD: ldx wordLen
    cpx #WORD_LONG - 1
    bcc :+
    lda #WORD_LONG              ; too long to be a name or keyword
    sta wordLen
    bra PV
:   lda ch
    and #$7f                    ; lower case, as the tokenizer's
    sta word,x
    inc wordLen
    bra PV
.endproc

; This routine returns the carry clear if A is a letter, as the
; tokenizer's getCharCode has them. They are numbers, since the c64
; character map changes 'A'.
.proc isLetter
    cmp #65
    bcc NO
    cmp #91
    bcc YS
    cmp #97
    bcc NO
    cmp #123
    bcc YS
    cmp #193
    bcc NO
    cmp #219
    bcc YS
NO: sec
    rts
YS: clc
    rts
.endproc

; This routine ends the word in word, if there is one: a name in a Uses
; clause, "uses", or "library" after "implementation"
.proc endWord
    ldx wordLen
    bne :+
    rts
:   lda #0
    sta wordLen
    cpx #WORD_LONG
    bne :+
    sta implFlag
    rts
:   sta word,x
    lda usesMode
    beq KW

    ; A name in a Uses clause, cut to NAME_MAX
    cpx #NAME_MAX + 1
    bcc :+
    ldx #NAME_MAX
:   lda #0
    sta name,x
CP: dex
    bmi :+
    lda word,x
    sta name,x
    bra CP
:   jmp appendNode

KW: lda #<strUses
    ldx #>strUses
    jsr isWord
    bne :+
    lda #1
    sta usesMode
    lda #0
    sta implFlag
    rts
:   lda implFlag
    beq IM
    lda #<strLibrary
    ldx #>strLibrary
    jsr isWord
    bne IM
    lda #1
    sta isLib
IM: lda #<strImpl
    ldx #>strImpl
    jsr isWord
    beq :+
    lda #0
    sta implFlag
    rts
:   lda #1
    sta implFlag
    rts
.endproc

; This routine returns Z set if word is the null-terminated string at A/X
.proc isWord
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    cmp word,y
    bne :+
    cmp #0
    beq :+
    iny
    bra :-
:   rts
.endproc

; This routine adds a node named by name to the end of listHead's list,
; and leaves it in node
.proc appendNode
    lda #NODE_SIZE
    ldx #0
    jsr heapAlloc
    stq node
    stq ptr1
    ldz #NODE_NAME
    ldx #0
:   lda name,x
    nop
    sta (ptr1),z
    beq :+
    inz
    inx
    bra :-
:   ldq listHead
    jsr isQZero
    bne L1
    ldq node
    stq listHead
    rts
L1: stq ptr1
    ldz #NODE_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    jsr isQZero
    bne L1
    ldz #NODE_NEXT
    ldx #0
:   lda node,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    rts
.endproc

; This routine copies the name of the node in Q to name
.proc nodeName
    stq ptr1
    ldz #NODE_NAME
    ldx #0
:   nop
    lda (ptr1),z
    sta name,x
    beq :+
    inz
    inx
    bra :-
:   rts
.endproc

; This routine returns in Q the entry named by name, or zero
.proc findEntry
    ldq entries
L1: jsr isQZero
    beq DN
    stq ptr1
    ldz #ENT_NAME
    ldx #0
:   nop
    lda (ptr1),z
    cmp name,x
    bne NX
    cmp #0
    beq FD
    inz
    inx
    bra :-
NX: ldz #ENT_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    bra L1
FD: ldq ptr1
DN: rts
.endproc

; This routine adds an entry named by name and returns it in Q
.proc addEntry
    lda #ENT_SIZE
    ldx #0
    jsr heapAlloc
    stq ptr1
    ldz #ENT_NAME
    ldx #0
:   lda name,x
    nop
    sta (ptr1),z
    beq :+
    inz
    inx
    bra :-
:   ldz #ENT_NEXT
    ldx #0
:   lda entries,x
    nop
    sta (ptr1),z
    inz
    inx
    cpx #4
    bne :-
    ldq ptr1
    stq entries
    rts
.endproc

; This routine frees the entries and their lists
.proc freeEntries
    ldq entries
L1: stq thisEnt
    jsr isQZero
    beq DN
    stq ptr1
    ldz #ENT_DEPS
    neg
    neg
    nop
    lda (ptr1),z
    jsr freeList
    ldq thisEnt
    stq ptr1
    ldz #ENT_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    stq entries
    ldq thisEnt
    jsr heapFree
    ldq entries
    bra L1
DN: rts
.endproc

.proc freeUsed
    ldq usedList
    jsr freeList
    lda #0
    sta usedList
    sta usedList+1
    sta usedList+2
    sta usedList+3
    rts
.endproc

; This routine frees the list of nodes in Q
.proc freeList
L1: stq node
    jsr isQZero
    beq DN
    stq ptr1
    ldz #NODE_NEXT
    neg
    neg
    nop
    lda (ptr1),z
    stq listHead
    ldq node
    jsr heapFree
    ldq listHead
    bra L1
DN: rts
.endproc

; This routine puts the name of the entry in thisEnt in fnBuf, with the
; suffix at A/X
.proc entryFn
    pha
    phx
    ldq thisEnt
    stq fnEnt
    plx
    pla
    ; Fall through
.endproc

; This routine puts the name of the entry in fnEnt in fnBuf, with the
; suffix at A/X, and its length in fnLen
.proc entryFnEnt
    sta ptr4
    stx ptr4+1
    ldq fnEnt
    stq ptr1
    ldz #ENT_NAME
    ldx #0
:   nop
    lda (ptr1),z
    beq :+
    sta fnBuf,x
    inz
    inx
    bra :-
:   ldy #0
:   lda (ptr4),y
    sta fnBuf,x
    beq :+
    inx
    iny
    bra :-
:   stx fnLen
    rts
.endproc

; This routine returns Z clear if the file named in fnBuf exists
.proc fileExists
    lda #<fnBuf
    ldx #>fnBuf
    ldy #0
    ldz #0
    jsr doesFileExist
    cmp #0
    rts
.endproc

.proc closeIn
    jsr CLRCHN
    lda #FILE_IN
    jmp CLOSE
.endproc
