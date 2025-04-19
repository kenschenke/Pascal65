.include "cbm_kernal.inc"
.include "c64.inc"
.include "runtime.inc"

.export initAnimBss, animIrqReturn
.export SPR_MASKS, setSpriteXY, posx, posy, getIrqAddress
.export x0, x1, y0, y1, initLine, hastarget, speed

.export dx, dy, err

.import setIrq

NUM_SPRITES = 8

.code

; This macro calculates the address of the sprite coordinates in the
; VIC chip (as an offset from sprite 0). X contains the sprite number
; from 0-7. The number is multiplied by two and copied to Y.
; A and X are preserved.
.macro spriteAddr
    pha
    txa
    asl
    tay
    pla
.endmacro

.macro spriteYindex
    txa
    asl a
    tay
.endmacro

    ; Center: 175,150
    ; Octants:
    ;    1: 100,140 - works : m=(140-150)/(100-175)
    ;    2: 165,100 - works : m=(100-150)/(165-175)
    ;    3: 185,100 - works : m=(100-150)/(185-175)
    ;    4: 250,140 - works : m=(140-150)/(250-175)
    ;    5: 250,165 - works : m=(165-150)/(250-175)
    ;    6: 185,200 - works : m=(200-150)/(185-175)
    ;    7: 165,200 - works : m=(200-150)/(165-175)
    ;    8: 100,165 - works : m=(165-150)/(100-175)
    ;     \  2  |  3 /
    ;    1 \ +m | -m/  4
    ;   +m  \   |  / -m
    ;  -----------------
    ;   -m  /   |  \ +m
    ;    8 / -m | +m\  5
    ;     /  7  |  6 \
    ; Slope = y1-y0 / x1-x0

initAnimBss:
    ldx #endbss-startbss-1
    lda #0
:   sta startbss,x
    dex
    bpl :-
    rts

.proc isDyLessThanDx
    lda dy,x
    cmp dx,y
    lda #0
    sbc dx+1,y
    bvc L1
    eor #$80
L1: bpl L2
    lda #1
    rts
L2: lda #0
    rts
.endproc

.proc isX0GreaterThanX1
    lda x0,y
    cmp x1,y
    lda x0+1,y
    sbc x1+1,y
    bvc L1
    eor #$80
L1: bpl L2
    lda SPR_MASKS,x
    ora xdir
    sta xdir
    lda #0
    rts
L2: lda SPR_MASKS,x
    eor #$ff
    and xdir
    sta xdir
    lda #1
    rts
.endproc

.proc isY0GreaterThanY1
    lda y0,x
    cmp y1,x
    bvc L1
    eor #$80
L1:
    bpl L2
    lda SPR_MASKS,x
    ora ydir
    sta ydir
    lda #0
    rts
L2:
    lda SPR_MASKS,x
    eor #$55
    and ydir
    sta ydir
    lda #1
    rts
.endproc

.proc x1_minus_x0
    lda x1,y
    sec
    sbc x0,y
    sta dx,y
    lda x1+1,y
    sbc x0+1,y
    sta dx+1,y
    rts
.endproc

.proc y1_minus_y0
    lda y1,x
    sec
    sbc y0,x
    sta dy,x
    rts
.endproc

.proc neg_dx
    txa
    pha
    asl a
    tax
    lda dx+1,x
    eor #$ff
    sta dx+1,x
    lda dx,x
    eor #$ff
    clc
    adc #1
    sta dx,x
    lda dx+1,x
    adc #0
    sta dx+1,x
    pla
    tax
    rts
.endproc

.proc neg_dy
    lda dy,x
    eor #$ff
    clc
    adc #1
    sta dy,x
    rts
.endproc

.proc two_times_dy
    lda dy,x
    sta work
    lda #0
    sta work+1
    asl work
    rol work+1
    rts
.endproc

.proc incPosx
    lda posx,y
    clc
    adc #1
    sta posx,y
    bcc :+
    lda posx+1,y
    adc #0
    sta posx+1,y
    lda VIC_SPR_HI_X
    eor SPR_MASKS,x
    sta VIC_SPR_HI_X
    and SPR_MASKS,x
    sta posx+1,y
:   rts
.endproc

.proc decPosx
    lda posx,y
    sec
    sbc #1
    sta posx,y
    cmp #$ff
    bne DN
    lda posx+1,y
    beq :+
    lda #0
    sta posx+1,y
    lda SPR_MASKS,x
    eor #$ff
    and VIC_SPR_HI_X
    sta VIC_SPR_HI_X
    jmp DN
:   lda SPR_MASKS,x
    ora VIC_SPR_HI_X
    sta VIC_SPR_HI_X
    lda #1
    sta posx+1,y
DN: rts
.endproc

.proc initLine
    ; Clear state variables for this sprite
    lda #0
    sta dx,y
    sta dx+1,y
    sta dy,x
    sta yi,x
    sta err,y
    sta err+1,y
    lda SPR_MASKS,x
    eor #$ff
    and xi
    sta xi
    lda SPR_MASKS,x
    eor #$ff
    and xdir
    sta xdir
    lda SPR_MASKS,x
    eor #$ff
    and ydir
    sta ydir
    lda SPR_MASKS,x
    eor #$ff
    and horiz
    sta horiz
    ; if abs(y1 - y0) < abs(x1 - x0)
    spriteYindex
    jsr y1_minus_y0
    lda dy,x
    bpl :+
    jsr neg_dy
:   jsr x1_minus_x0
    lda dx+1,y
    bpl :+
    jsr neg_dx
:   jsr isDyLessThanDx
    beq HI
    jmp initLineHoriz ; horiz - dx > dy
HI: jmp initLineVert ; vert - dy > dx
.endproc

; X contains current sprite number
.proc initLineHoriz
    lda SPR_MASKS,x
    ora horiz
    sta horiz
    ; dx = x1 - x0
    jsr x1_minus_x0
    ; dy = y1 - y0
    jsr y1_minus_y0
    ; yi = positive
    lda #1
    sta yi,x
    ; if dy < 0
    lda dy,x
    bpl :+
    ;    yi = negative
    lda #$ff
    sta yi,x
    ;    dy = -dy
    jsr neg_dy
:   ; if dx < 0 then dx = -dx
    lda dx+1,y
    bpl :+
    jsr neg_dx
:   ; err = (2 * dy) - dx
    jsr two_times_dy
    lda work
    sec
    sbc dx,y
    sta err,y
    lda work+1
    sbc dx+1,y
    sta err+1,y
    ; x = x0
    lda x0,y
    sta posx,y
    lda x0+1,y
    sta posx+1,y
    ; y = y0
    lda y0,x
    sta posy,x
    jsr isX0GreaterThanX1
    rts
.endproc

.proc incLineHoriz ; horiz
    ; increment x
    lda SPR_MASKS,x
    and xdir
    bne :+
    ; subtract 1 instead
    jsr decPosx
    jmp L1
:   jsr incPosx
    ; if err >= 0
L1: lda err+1,y
    bmi L3
    ; y = y + yi
    lda posy,x
    clc
    adc yi,x
    sta posy,x
L2: ; err -= 2 * dx
    lda dx,y
    sta work
    lda dx+1,y
    sta work+1
    asl work
    rol work+1
    lda err,y
    sec
    sbc work
    sta err,y
    lda err+1,y
    sbc work+1
    sta err+1,y
L3: ; err += dy * 2
    jsr two_times_dy
    lda err,y
    clc
    adc work
    sta err,y
    lda err+1,y
    adc work+1
    sta err+1,y
    rts
.endproc

.proc initLineVert ; vert
    lda SPR_MASKS,x
    eor #$ff
    and horiz
    sta horiz
    ; dx = x1 - x0
    jsr x1_minus_x0
    ; dy = y1 - y0
    jsr y1_minus_y0
    ; xi = positive
    lda SPR_MASKS,x
    ora xi
    sta xi
    ; if dx < 0
    lda dx+1,y
    bpl :+
    ; xi = negative
    lda SPR_MASKS,x
    eor #$ff
    and xi
    sta xi
    ; dx = -dx
    jsr neg_dx
:   ; if dy < 0 then dy = -dy
    lda dy,x
    bpl :+
    jsr neg_dy
:   ; err = (dx * 2) - dy
    lda dx,y
    sta work
    lda dx+1,y
    sta work+1
    asl work
    rol work+1
    lda work
    sec
    sbc dy,x
    sta err,y
    lda work+1
    sbc #0
    sta err+1,y
    ; x = x0
    lda x0,y
    sta posx,y
    lda x0+1,y
    sta posx+1,y
    ; y = y0
    lda y0,x
    sta posy,x
    jsr isY0GreaterThanY1
    rts
.endproc

.proc incLineVert ; vert
    ; increment y
    lda SPR_MASKS,x
    and ydir
    bne :+
    dec posy,x
    jmp L0
:   inc posy,x
    ; if err >= 0
L0: lda err+1,y
    bmi L3
    ; x += xi
    lda SPR_MASKS,x
    and xi
    bne L1
    jsr decPosx
    jmp L2
L1: jsr incPosx
L2: lda dy,x
    sta work
    lda #0
    sta work+1
    asl work
    rol work+1
    lda err,y
    sec
    sbc work
    sta err,y
    lda err+1,y
    sbc work+1
    sta err+1,y
L3:   ; err += dx * 2
    lda dx,y
    sta work
    lda dx+1,y
    sta work+1
    asl work
    rol work+1
    lda work
    clc
    adc err,y
    sta err,y
    lda err+1,y
    adc work+1
    sta err+1,y
    rts
.endproc

; Returns zero in A if target reached and sprite should stop moving
.proc checkTarget
    spriteYindex
    lda posx,y
    cmp x1,y
    bne NO
    lda posx+1,y
    cmp x1+1,y
    bne NO
    lda posy,x
    cmp y1,x
    bne NO
    lda #0
    rts
NO: lda #1
DN: rts
.endproc

.proc incLine
    spriteYindex
    lda SPR_MASKS,x
    and horiz
    beq :+
    jmp incLineHoriz
:   jmp incLineVert
.endproc

.proc setSpriteXY
    lda posy,x
    sta VIC_SPR0_Y,y
    lda posx,y
    sta VIC_SPR0_X,y
    lda posx+1,y
    beq :+
    lda VIC_SPR_HI_X
    ora SPR_MASKS,x
    sta VIC_SPR_HI_X
    rts
:   lda SPR_MASKS,x
    eor #$ff
    and VIC_SPR_HI_X
    sta VIC_SPR_HI_X
    rts
.endproc

.proc moveSprite
    lda speed,x
    sta speedn
    inc speedn
L1: dec speedn
    beq XY
    lda SPR_MASKS,x
    and hastarget
    beq :+
    jsr checkTarget
    beq ST
:   jsr incLine
    jmp L1
XY: jsr setSpriteXY
    jmp DN
ST: lda SPR_MASKS,x
    eor #$ff
    and hastarget
    sta hastarget
    lda #0
    sta speed,x
DN: rts
.endproc

; This gets the address of the IRQ handler (irqHandler) and 
; puts it on the CPU stack using JSR. The setIrq label pops the address
; back off the STACK to store in the CINV vector.
getIrqAddress:
    jsr setIrq
    ; spriteIrq must be the very next line
irqHandler:
    ; Look to see what triggered the interrupt
    lda #%10000000
    bit VIC_IRR
    beq animIrqReturn
    lda #%00000001          ; Mask the raster interrupt
    bit VIC_IRR
    beq animIrqReturn       ; Branch if not a raster interrupt
    ; Load the sprite-data collision info
    ; lda $d01f
    ; sta collisionData
    ; ora $64
    ; sta $64
    ; Move each active sprite
    ldx #NUM_SPRITES-1
L1: lda VIC_SPR_ENA
    and SPR_MASKS,x
    beq NX
    ; Is the sprite moving?
    lda speed,x
    beq NX
    ; Has the sprite collided?
    ; lda SPR_MASKS,x
    ; and collisionData
    ; and $64
    ; beq :+                  ; Branch if not collided
    ; Stop the sprite moving
    ; lda #0
    ; sta speed,x
    ; jmp NX
    ; Has the sprite hit the X target?
:   spriteYindex
    lda x1,y
    cmp posx,y
    bne MV
    lda x1+1,y
    cmp posx+1,y
    bne MV
    ; Has the sprite hit the Y target?
    lda y1,x
    cmp posy,x
    bne MV
    ; Move current sprite
MV: jsr moveSprite

NX: dex
    bpl L1

animIrqReturn:
    jmp $0000

.data

; vectable: .res $30
startbss:
x0: .res NUM_SPRITES*2
x1: .res NUM_SPRITES*2
y0: .res NUM_SPRITES
y1: .res NUM_SPRITES
dx: .res NUM_SPRITES*2
dy: .res NUM_SPRITES
xi: .res 1
yi: .res NUM_SPRITES
xdir: .res 1
ydir: .res 1
err: .res NUM_SPRITES*2
work: .res 2
posx: .res NUM_SPRITES*2
posy: .res NUM_SPRITES
speed: .res NUM_SPRITES
speedn: .res 1
; collisionData: .res 1
horiz: .res 1

; Bit is 1 if sprite has target to hit (destination for movement)
hastarget: .res 1
endbss:

SPR_MASKS:
    .byte %00000001
    .byte %00000010
    .byte %00000100
    .byte %00001000
    .byte %00010000
    .byte %00100000
    .byte %01000000
    .byte %10000000
