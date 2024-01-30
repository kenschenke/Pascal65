; Routine to output a floating point number into a string.
;
; Based on floating point routines published in the book
; 6502 Software Gourmet Guide & Cookbook
; by Robert Findley

.include "float.inc"
.include "runtime.inc"

.import COMPLM, MOVIND, ROTATL, ROTATR, DECBIN, FPD10, FPX10, PRECRD

.export FPOUT, XBUF

.bss

XBUF: .res 1            ; Index in output buffer
ISNEG: .res 1           ; Bit 7 set if mantissa is negative
ISENOT: .res 1          ; Non-zero if output is 'E' notation

.code

; This routine outputs FPACC to FPBUF.
; FPACC and FPOP are modified.
;
; Precision is passed in A.  Use 0xff for scientific notation.
;
; Number of characters written is returned in A.
;
; It supports standard floating point format like 1.23 as well as
; scientific notation like 0.123E+01.  If the caller does not specify
; a precision (see FPBASE + PREC) or the exponent falls outside the range
; of -4 and +7, scientific notation is used.  Otherwise, standard notation.

FPOUT:
    sta FPBASE + PREC   ; Store the precision
    lda #0
    sta FPBASE + IOEXPD ; Clear decimal exponent storage
    sta ISNEG           ; Clear sign indicator
    sta XBUF            ; Clear index for buffer
    ldx #FPBUFSZ - 1    ; Set offset for clearing output buffer
    stx ISENOT          ; Assume we will be outputting in 'E' notation
CLRBUF:
    sta FPBUF,x         ; Clear byte in output buffer
    dex                 ; Decrement index
    bpl CLRBUF          ; If >= 0, continue clearing
    lda FPBASE + FPACCE ; Is the exponent >= 0?
    bpl CKEPOS          ; Yes
    eor #$ff            ; Make it positive
    clc                 ; Clear carry for addition
    adc #$01            ; Add one
    cmp #$10            ; Is the exponent >= $10?
    bcs SKIPRD          ; Yes, skip rounding
    jmp CKPREC          ; No, check if the caller wants the value rounded
CKEPOS:
    cmp #$16            ; Is the exponent >= $16?
    bcs SKIPRD          ; Yes, skip rounding
CKPREC:
    lda FPBASE + PREC   ; Is precision >= 0?
    bmi SKIPRD          ; No, skip ahead
    jsr PRECRD          ; Yes, round FPACC
    lda #$00            ; Clear A
    sta ISENOT          ; We will not be outputting in 'E' notation
SKIPRD:
    lda FPBASE + FPMSW  ; Is value to output negative?
    bmi OUTNEG          ; Yes, make positive and output minus
    jmp AHEAD1          ; Skip ahead
OUTNEG:
    sta ISNEG           ; Set the sign indicator
    ldx #FPLSW          ; Set pointer to LS byte of FPACC
    ldy #$3             ; Set precision counter
    jsr COMPLM          ; Make FPACC positive
AHEAD1:
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
    lda FPBASE + IOEXPD ; Load the exponent into A
    sta FPBASE + FPACCE ; Store in FPACCE
    lda ISENOT          ; Are we doing 'E' notation?
    beq ADDPNT          ; No, jump ahead
    jsr INS0PT          ; Insert "0." at start of buffer
    lda #'e'            ; Setup ASCII code for E
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
    jmp ADDNEG          ; See if the number is negative
ADDPNT:
    lda FPBASE + FPACCE ; Is the exponent negative?
    beq ZEROEXP
    bmi NEGEXP          ; Yes
    clc                 ; Clear carry for addition
    adc FPBASE + PREC   ; Add the precision in
    tax                 ; Transfer precision to X
    lda #0              ; Clear A
    sta FPBUF,x         ; Terminate buffer after precision
    lda FPBASE + PREC   ; Is the precision 0?
    cmp #$0
    beq ADDNEG          ; Yes, skip adding the decimal point
    lda FPBASE + FPACCE ; Load the exponent back into A
    ldx #$01            ; 1 character for insert
    jsr INSBUF          ; Insert 1 character for the dec pt
    ldx FPBASE + FPACCE ; Load exponent into X
    lda #'.'            ; Load decimal point
    sta FPBUF,x         ; Store decimal point in buffer
    jmp ADDNEG
ZEROEXP:
    ldx FPBASE + PREC   ; Load precision into X (index)
    lda #0              ; Clear A
    sta FPBUF,x         ; Store NULL terminator to truncate digits
    jsr INS0PT          ; Insert "0." at beginning of buffer
    lda FPBASE + PREC   ; Load precision into A
    bne ADDNEG          ; If precision is non-zero jump ahead
    ldx #0              ; Precision is zero, truncate the un-needed '.'
    sta FPBUF + 1       ; Write 0 over the '.'
    jmp ADDNEG          ; Skip ahead
NEGEXP:
    ldx FPBASE + PREC   ; Load precision into X
    dex                 ; Decrement
    dex                 ; Decrement again
    lda #0              ; Clear A
    sta FPBUF,x         ; Truncate buffer with null
    jsr INS0PT          ; Add "0." to start of buffer
    lda FPBASE + FPACCE ; Load exponent into A
    eor #$ff            ; Negate it by applying two's complement
    clc                 ; Clear carry for addition
    adc #$01            ; Add one
    pha                 ; Push the exponent onto the stack
    tax                 ; Copy it to X
    lda #$02            ; Start insert at position two
    jsr INSBUF          ; Insert characters at position two
    pla                 ; Pull exponent back off stack
    tay                 ; Transfer it to Y
    ldx #$02            ; Start at position two in output buffer
    lda #'0'            ; Load ASCII zero into A
STORE0:
    sta FPBUF,x         ; Store ASCII zero in output buffer
    inx                 ; Increment position in buffer
    dey                 ; Decrement index
    bne STORE0          ; Keep going if more zero's to write
ADDNEG:
    lda ISNEG           ; Was the number negative?
    bpl SKIPNEG         ; No, skip adding a minus sign
    lda FPBUF           ; Look at first buffer position
    cmp #'0'            ; Is it zero?
    bne ADDNEG1         ; No.  Proceed with the negative sign.
    lda FPBUF + 1       ; Look at second buffer position
    beq SKIPNEG         ; Buffer is "0".  Skip the negative sign.
ADDNEG1:
    lda #0
    ldx #1
    jsr INSBUF          ; Insert a space at the start of buffer
    lda #'-'            ; Load a minus sign in A
    sta FPBUF           ; Store a minus sign at start of buffer
SKIPNEG:
    ldx #0
CNTLOOP:
    lda FPBUF,x
    beq RETURN
    inx
    jmp CNTLOOP
RETURN:
    txa
    rts
INS0PT:
    lda #0              ; Insert at first position
    ldx #2              ; Insert two characters
    jsr INSBUF          ; at the beginning of the output buffer
    ldx XBUF            ; Load the buffer offset into X
    lda #'0'            ; Load ASCII zero into A
    sta FPBUF           ; Store it in the first buffer position
    inx                 ; Increment XBUF
    lda #'.'            ; Load ASCII decimal point into A
    sta FPBUF + 1       ; Store it in the second buffer position
    inx                 ; Increment XBUF
    stx XBUF            ; Store the new index in XBUF
    rts                 ; Return

; This routine inserts bytes into FPBUF at a given position.
;    A - Position at which to insert
;    X - Number of bytes to insert
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
