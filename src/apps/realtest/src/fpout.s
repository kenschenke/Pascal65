; Floating point output routine.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"

.import FPBASE, FPBUF, COMPLM, MOVIND, ROTATL, ROTATR, DECBIN, FPD10, FPX10

.export FPOUT

.bss

XBUF: .res 1

.code

; This routine outputs FPACC to the console.
; FPACC and FPOP are modified.

FPOUT:
    lda #0
    sta FPBASE + IOEXPD ; Clear decimal exponent storage
    sta XBUF            ; Clear index for buffer
    ldx #FPBUFSZ - 1    ; Set offset for clearing output buffer
CLRBUF:
    sta FPBUF,x         ; Clear byte in output buffer
    dex                 ; Decrement index
    bpl CLRBUF          ; If >= 0, continue clearing
    lda FPBASE + FPMSW  ; Is value to output negative?
    bmi OUTNEG          ; Yes, make positive and output minus
    lda #'+'            ; Else, set ASCII code for plus sign
    bne AHEAD1          ; Go display plus sign
OUTNEG:
    ldx #FPLSW          ; Set pointer to LS byte of FPACC
    ldy #$3             ; Set precision counter
    jsr COMPLM          ; Make FPACC positive
    lda #'-'            ; Set ASCII code for minus sign
AHEAD1:
    ldx XBUF            ; Load index of output buffer
    sta FPBUF,x         ; Store sign of result
    inx                 ; Increment buffer index
    lda #'0'            ; Set up ASCII zero
    sta FPBUF,x         ; Store a zero in the buffer
    inx                 ; Increment buffer index
    lda #'.'            ; Set up ASCII decimal point
    sta FPBUF,x         ; Store decimal point in the buffer
    inx                 ; Increment buffer index
    stx XBUF            ; Store buffer index for later
    dec FPBASE + FPACCE ; Decrement FPACC exponent
DECEXT:
    bpl DECEXD          ; If compensated, exponent >= 0
    lda #$4             ; Exponent negative, add four to FPACCE
    clc                 ; Clear carry for addition
    adc FPBASE + FPACCE ; Add four to FPACC exponent
    bpl DECOUT          ; If exponent >= 0, output mantissa
    jsr FPX10           ; Else, multiply mantissa by ten
DECREP:
    lda FPBASE + FPACCE ; Get exponent
    jmp DECEXT          ; Repeat test for >= 0
DECEXD:
    jsr FPD10           ; Multiply FPACC by 0.1
    jmp DECREP          ; Check status of FPACC exponent
DECOUT:
    ldx #IOSTR          ; Set up for move operation
    stx FPBASE + TOPNT  ; Set TOPNT to working register
    ldx #FPLSW          ; Set pointer to FPACC LS byte
    stx FPBASE + FMPNT  ; Store in FMPNT
    ldx #$3             ; Set precision counter
    jsr MOVIND          ; Move FPACC to output registers
    lda #$0
    sta FPBASE + IOSTR3 ; Clear output register MS byte + 1
    ldx #IOSTR          ; Set pointer to LS byte
    ldy #$3             ; Set precision counter
    jsr ROTATL          ; Rotate to compensate for sign bit
    jsr DECBIN          ; Output register x 10, overflow in MS byte + 1
COMPEN:
    inc FPBASE + FPACCE ; Increment FPACC exponent
    beq OUTDIG          ; Output digit when compensation is done
    ldx #IOSTR3         ; Else, rotate right to compensate
    ldy #$4             ; For any remainder in binary exponent
    jsr ROTATR          ; Perform rotate right operation
    jmp COMPEN          ; Repeat loop until exponent = 0
OUTDIG:
    lda #$7             ; Set digit counter to seven
    sta FPBASE + CNTR   ; For output operation
    lda FPBASE + IOSTR3 ; Fetch BCD, see if first digit = zero
    beq ZERODG          ; Yes, check remainder of digits
OUTDGS:
    lda FPBASE + IOSTR3 ; Get BCD from output register
    ora #'0'            ; Form ASCII code for numbers
    ldx XBUF            ; Index in output buffer
    sta FPBUF,x         ; Store digit in output buffer
    inx                 ; Increment buffer index
    stx XBUF            ; Store buffer index
DECRDG:
    dec FPBASE + CNTR   ; Decrement digit counter
    beq EXPOUT          ; = zero, done output exponent
    jsr DECBIN          ; Else, get next digit
    jmp OUTDGS          ; Form ASCII and output
ZERODG:
    dec FPBASE + IOEXPD ; Decrement exponent for skipping display
    lda FPBASE + IOSTR2 ; Check if mantissa = 0
    bne DECRDG          ; If not zero, continue output
    lda FPBASE + IOSTR1
    bne DECRDG
    lda FPBASE + IOSTR
    bne DECRDG
    lda #$0             ; Mantissa zero, clear exponent
    sta FPBASE + IOEXPD
    beq DECRDG          ; Before finishing display
EXPOUT:
    lda #'E'            ; Setup ASCII code for E
    ldx XBUF            ; Load output buffer index
    sta FPBUF,x         ; Add E for exponent to output buffer
    inx                 ; Increment buffer index
    stx XBUF            ; Store buffer index
    lda FPBASE + IOEXPD ; Test if negative
    bmi EXOUTN          ; Yes, display minus sign and negate
    lda #'+'            ; No, set ASCII code for plus sign
    jmp AHEAD2          ; Display exponent value
EXOUTN:
    eor #$ff            ; Two's complement exponent
    sta FPBASE + IOEXPD ; To make negative value position
    inc FPBASE + IOEXPD ; For output of exponent value
    lda #'-'            ; Set ASCII code for minus sign
AHEAD2:
    ldx XBUF            ; Load output buffer index
    sta FPBUF,x         ; Store sign of exponent in output buffer
    inx                 ; Increment buffer index
    stx XBUF            ; Store output buffer index
    ldy #$0             ; Clear ten's counter
    lda FPBASE + IOEXPD ; Fetch exponent
SUB12:
    sec                 ; Set carry for subtraction
    sbc #$0a            ; Subtract ten's from exponent
    bmi TOMUCH          ; If minus, read for output
    sta FPBASE + IOEXPD ; Restore positive result
    iny                 ; Advance ten's counter
    jmp SUB12           ; Continue subtraction
TOMUCH:
    tya                 ; Put MS digit into A
    ora #'0'            ; Form ASCII code
    ldx XBUF            ; Load buffer index
    sta FPBUF,x         ; Store ten's digit in output buffer
    inx                 ; Increment buffer index
    lda FPBASE + IOEXPD ; Fetch unit's digit
    ora #'0'            ; Form ASCII code
    sta FPBUF,x         ; Add digit to output buffer
    inx                 ; Increment buffer index
    lda #0              ; Clear A
    sta FPBUF,x         ; Add NULL terminator to buffer
    rts

; This routine inserts bytes into FPBUF at a given position.
;    A - Position at which to insert
;    X - Number of bytes to insert
;
;
;    I - position at which to insert
;    N - number of bytes to insert
;    D - destination position
;    S - source position
;    C - number of interations to copy
;
; 0123456789ABCDE
;     ^       ^ ^
;     |       | |
;     |       | +-- Starting destination position
;     |       +-- Starting source position 
;     +-- Position at which to insert
; WORK0 : I = 2
; WORK1 : N = 1
;         D = FPBUFSZ - 1 (14)
;         S = D - N (13)
;         C = S - I (11)

INSBUF:
    sta FPBASE + WORK0  ; Store insertion point in WORK0
    stx FPBASE + WORK1  ; Store number of bytes in WORK1
    lda #FPBUFSZ - 1    ; Set A to destination index
    tay                 ; Transfer destination index to Y
    sec                 ; Set carry for subtraction
    sbc FPBASE + WORK1  ; Subtract number of bytes to insert
    tax                 ; Transfer source index to X
    sec                 ; Set carry for subtraction
    sbc FPBASE + WORK0  ; Subtract insertion position
    sta FPBASE + WORK0  ; Store number of bytes to copy in WORK0
L1:
    lda FPBUF,x         ; Load source byte
    sta FPBUF,y         ; Store in destination spot
    dex                 ; Decrement source index
    dey                 ; Decrement destination index
    dec FPBASE + WORK0  ; Decrement number of bytes to copy
    bpl L1              ; If >= 0, continue copying
    rts                 ; Return
