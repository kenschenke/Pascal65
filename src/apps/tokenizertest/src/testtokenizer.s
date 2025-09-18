.include "tokenizer.inc"
.include "zeropage.inc"
.include "asmlib.inc"
.include "4510macros.inc"
.include "cbm_kernal.inc"

.export testTokenizer

.bss

memBuf: .res 4
resultsPtr: .res 2
ch: .res 1
intBuf: .res 10

.data

sourceFn: .asciiz "test.pas"
passedMsg: .asciiz "Passed"
failedMsg: .asciiz "Failed, offset "
expectedMsg: .asciiz "   Expected "
sawMsg: .asciiz "   Saw "

results: .byte tzLineNum, $03, $00              ; 0
         .byte tzToken, tcPROGRAM               ; 3
         .byte tzIdentifier, $0a, "helloworld"  ; 5
         .byte tzToken, tcSemicolon             ; 17
         .byte tzLineNum, $05, $00              ; 19
         .byte tzByte, $7b                      ; 22
         .byte $03, "123"                       ; 24
         .byte tzWord, $39, $30                 ; 28
         .byte $05, "12345"                     ; 31
         .byte tzCardinal, $40, $e2, $01, $00   ; 37
         .byte $06, "123456"                    ; 42
         .byte tzToken, tcMinus                 ; 49
         .byte tzByte, $7b                      ; 51
         .byte $03, "123"                       ; 53
         .byte tzLineNum, $06, $00              ; 57
         .byte tzByte, $1a                      ; 60
         .byte $03, "$1a"                       ; 62
         .byte tzWord, $bc, $1a                 ; 66
         .byte $05, "$1abc"                     ; 69
         .byte tzCardinal, $cd, $ab, $01, $00   ; 75
         .byte $06, "$1abcd"                    ; 80
         .byte tzLineNum, $07, $00              ; 87
         .byte tzByte, $ad                      ; 90
         .byte $09, "%10101101"                 ; 92
         .byte tzWord, $91, $ae                 ; 102
         .byte $11, "%1010111010010001"         ; 105
         .byte tzCardinal, $9f, $e3, $9c, $bd   ; 123
         .byte $21, "%10111101100111001110001110011111" ; 128
         .byte tzLineNum, $08, $00              ; 162
         .byte tzString, $03, "'a'"             ; 165
         .byte tzString, $0e, "'Hello, World'"  ; 170
         .byte tzString, $11, "'How's it going?'" ; 186
         .byte tzLineNum, $09, $00              ; 205
         .byte tzString, $03, "'a'"             ; 208
         .byte tzString, $03, "'b'"             ; 213
         .byte tzLineNum, $10, $00              ; 218
         .byte tzToken, tcBEGIN                 ; 221
         .byte tzToken, tcEND                   ; 223
         .byte tzLineNum, $11, $00              ; 225
         .byte tzToken, tcBOOLEAN               ; 228
         .byte tzToken, tcBYTE                  ; 230
         .byte tzToken, tcCARDINAL              ; 232
         .byte tzToken, tcCHAR                  ; 234
         .byte tzToken, tcINTEGER               ; 236
         .byte tzToken, tcLONGINT               ; 238
         .byte tzToken, tcREAL                  ; 240
         .byte tzToken, tcSTRING                ; 242
         .byte tzToken, tcSHORTINT              ; 244
         .byte tzToken, tcWORD                  ; 246
         .byte tzLineNum, $12, $00              ; 248
         .byte tzToken, tcFALSE                 ; 251
         .byte tzToken, tcTRUE                  ; 253
         .byte tzToken, tcUpArrow               ; 255
         .byte tzToken, tcStar                  ; 257
         .byte tzToken, tcLParen                ; 259
         .byte tzToken, tcRParen                ; 261
         .byte tzToken, tcMinus                 ; 263
         .byte tzToken, tcPlus                  ; 265
         .byte tzToken, tcEqual                 ; 267
         .byte tzToken, tcLBracket              ; 269
         .byte tzToken, tcRBracket              ; 271
         .byte tzToken, tcColon                 ; 273  colonEqual?!? (s/b tcColon)
         .byte tzToken, tcSemicolon             ; 275
         .byte tzToken, tcGt                    ; 277
         .byte tzToken, tcLt                    ; 279
         .byte tzToken, tcComma                 ; 281
         .byte tzToken, tcPeriod                ; 283
         .byte tzToken, tcSlash                 ; 285
         .byte tzToken, tcColonEqual            ; 287
         .byte tzToken, tcLe                    ; 289
         .byte tzToken, tcGe                    ; 291
         .byte tzToken, tcNe                    ; 293
         .byte tzToken, tcDotDot                ; 295
         .byte tzToken, tcBang                  ; 297
         .byte tzToken, tcAmpersand             ; 299
         .byte tzToken, tcRShift                ; 301
         .byte tzToken, tcLShift                ; 303
         .byte tzToken, tcAt                    ; 305
         .byte tzLineNum, $13, $00              ; 307
         .byte tzToken, tcAND                   ; 310
         .byte tzToken, tcARRAY                 ; 312
         .byte tzToken, tcBEGIN                 ; 314
         .byte tzToken, tcCASE                  ; 316
         .byte tzToken, tcCONST                 ; 318
         .byte tzToken, tcDIV                   ; 320
         .byte tzToken, tcDO                    ; 322
         .byte tzToken, tcDOWNTO                ; 324
         .byte tzToken, tcELSE                  ; 326
         .byte tzToken, tcEND                   ; 328
         .byte tzToken, tcFILE                  ; 330
         .byte tzToken, tcFOR                   ; 332
         .byte tzToken, tcFUNCTION              ; 334
         .byte tzToken, tcGOTO                  ; 336
         .byte tzLineNum, $14, $00              ; 338
         .byte tzToken, tcIF                    ; 341
         .byte tzToken, tcIMPLEMENTATION        ; 343
         .byte tzToken, tcIN                    ; 345
         .byte tzToken, tcINTERFACE             ; 347
         .byte tzToken, tcLABEL                 ; 349
         .byte tzToken, tcMOD                   ; 351
         .byte tzToken, tcNIL                   ; 353
         .byte tzToken, tcNOT                   ; 355
         .byte tzToken, tcOF                    ; 357
         .byte tzToken, tcOR                    ; 359
         .byte tzToken, tcXOR                   ; 361
         .byte tzToken, tcPACKED                ; 363
         .byte tzLineNum, $15, $00              ; 365
         .byte tzToken, tcPROCEDURE             ; 368
         .byte tzToken, tcPROGRAM               ; 370
         .byte tzToken, tcRECORD                ; 372
         .byte tzToken, tcREPEAT                ; 374
         .byte tzToken, tcSET                   ; 376
         .byte tzToken, tcTEXT                  ; 378
         .byte tzToken, tcTHEN                  ; 380
         .byte tzToken, tcTO                    ; 382
         .byte tzToken, tcTYPE                  ; 384
         .byte tzToken, tcUNIT                  ; 386
         .byte tzToken, tcUNTIL                 ; 388
         .byte tzToken, tcUSES                  ; 390
         .byte tzLineNum, $16, $00              ; 392
         .byte tzToken, tcVAR                   ; 395
         .byte tzToken, tcWHILE                 ; 397
         .byte tzToken, tcWITH                  ; 399
         .byte tzLineNum, $17, $00              ; 401
         .byte tzReal, $07, "123.456"           ; 404
         .byte tzReal, $04, ".789"              ; 413
         .byte tzToken, tcMinus                 ; 419
         .byte tzReal, $04, ".123"              ; 421
         .byte tzToken, tcMinus                 ; 427
         .byte tzReal, $07, "123.456"           ; 429
         .byte tzLineNum, $18, $00              ; 438
         .byte tzReal, $09, "1.234e+06"         ; 441
         .byte tzReal, $09, "2.345E-07"         ; 452
         .byte tzReal, $0a, "3.456e+123"        ; 463
         .byte tzLineNum, $19, $00              ; 475
         .byte tzReal, $0c, "123.456e+123"      ; 478
         .byte tzToken, tcPlus                  ; 492
         .byte tzWord, $c8, $01                 ; 494
         .byte $03, "456"                       ; 497
         .byte tzReal, $06, "123.45"            ; 501
         .byte tzToken, tcPlus                  ; 509
         .byte tzWord, $a6, $02                 ; 511
         .byte $03, "678"                       ; 514
         .byte tzLineNum, $1a, $00              ; 518
         .byte tzIdentifier, $06, "begins"      ; 521
         .byte tzLineNum, $1b, $00              ; 529
         .byte tzToken, tcSTACKSIZE             ; 532
         .byte tzWord, $00, $04, $04, "1024"    ; 534
         .byte tzToken, tcSemicolon             ; 542
         .byte tzLineNum, $1c, $00              ; 544
         .byte tzToken, tcIF                    ; 547
         .byte tzToken, tcELSE                  ; 549
         .byte tzLineNum, $1d, $00              ; 551
         .byte tzToken, tcEndOfFile             ; 554

.code

.proc testTokenizer
    lda #<sourceFn
    ldx #>sourceFn
    jsr tokenize
    stq memBuf

    stq ptr1
    lda #0
    ldx #0
    jsr setMemBufPos

    lda #<results
    sta resultsPtr
    lda #>results
    sta resultsPtr+1

L1: ldq memBuf
    jsr isMemBufAtEnd
    bne :+
    bra L9

:   ldq memBuf
    stq ptr1
    lda #<ch
    sta ptr2
    lda #>ch
    sta ptr2+1
    lda #0
    sta ptr2+2
    sta ptr2+3
    lda #1
    ldx #0
    jsr readFromMemBuf

    lda resultsPtr
    sta ptr1
    lda resultsPtr+1
    sta ptr1+1
    ldy #0
    lda (ptr1),y
    cmp ch
    beq L2

    jmp showFailedMsg

L2: inc resultsPtr
    bne L1
    inc resultsPtr+1
    bra L1

L9: ldx #0
:   lda passedMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda #13
    jsr CHROUT
    ldq memBuf
    jsr freeMemBuf
    rts
.endproc

.proc showFailedMsg
    ldx #0
:   lda failedMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda resultsPtr
    sec
    sbc #<results
    sta intOp1
    lda resultsPtr+1
    sbc #>results
    sta intOp1+1
    lda intOp1
    ldx intOp1+1
    jsr printNum
    lda #13
    jsr CHROUT

    ldx #0
:   lda expectedMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda resultsPtr
    sta ptr1
    lda resultsPtr+1
    sta ptr1+1
    ldy #0
    lda (ptr1),y
    ldx #0
    jsr printNum
    lda #13
    jsr CHROUT

    ldx #0
:   lda sawMsg,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   lda ch
    ldx #0
    jsr printNum
    lda #13
    jsr CHROUT
    rts
.endproc

; Print the number in A/X
.proc printNum
    sta intOp1
    stx intOp1+1
    lda #<intBuf
    ldx #>intBuf
    jsr writeInt16
    ldx #0
:   lda intBuf,x
    beq :+
    jsr CHROUT
    inx
    bne :-
:   rts
.endproc