; Floating point memory layout
;
; All floating point operations occur in an area of memory
; starting at FPBASE.  The following are offsets from FPBASE.

; Accumulator (FPACC) layout:
;    FPBASE + FPLSWE : Extension
;    FPBASE + FPLSW  : Least significant byte
;    FPBASE + FPNSW  : Next significant byte
;    FPBASE + FPMSW  : Most significant byte
;    FPBASE + FPACCE : Exponent
;
; Operand (FPOP) layout:
;    FPBASE + FOPSWE : Extension
;    FPBASE + FOPLSW : Least significant byte
;    FPBASE + FOPNSW : Next significant byte
;    FPBASE + FOPMSW : Most significant byte
;    FPBASE + FOPEXP : Exponent

CNTR   = $4     ; Counter Storage
TSIGN  = $5     ; Sign indicator
SIGNS  = $6     ; Signs indicator (multiply and divide)
FPLSWE = $7     ; FPACC extension
FPLSW  = $8     ; FPACC least significant byte
FPNSW  = $9     ; FPACC next significant byte
FPMSW  = $a     ; FPACC most siginifcant byte
FPACCE = $b     ; FPACC exponent
MCAND0 = $c     ; Multiplication work area
MCAND1 = $d     ; Multiplication work area
MCAND2 = $e     ; Multiplication work area
FOLSWE = $f     ; FPOP extension
FOPLSW = $10    ; FPOP least significant byte
FOPNSW = $11    ; FPOP next significant byte
FOPMSW = $12    ; FPOP most significant byte
FOPEXP = $13    ; FPOP exponent
WORK0  = $14    ; Work area
WORK1  = $15    ; Work area
WORK2  = $16    ; Work area
WORK3  = $17    ; Work area
WORK4  = $18    ; Work area
WORK5  = $19    ; Work area
WORK6  = $1a    ; Work area
WORK7  = $1b    ; Work area
INMTAS = $1c    ; I/O Mantissa Sign
INEXPS = $1d    ; I/O Exponent Sign
INPRDI = $1e    ; I/O Period Indicator
IOLSW  = $1f    ; I/O Work Area Least Significant Byte
IONSW  = $20    ; I/O Work Area Next Significant Byte
IOMSW  = $21    ; I/O Work Area Most Significant Byte
IOEXP  = $22    ; I/O Work Area Exponent
IOSTR  = $23    ; I/O Storage
IOSTR1 = $24    ; I/O Storage
IOSTR2 = $25    ; I/O Storage
IOSTR3 = $26    ; I/O Storage
IOEXPD = $27    ; I/O Exponent Storage
TPLSW  = $28    ; Temporary Input Storage Least Significant Byte
TPNSW  = $29    ; Temporary Input Storage Next Significant Byte
TPMSW  = $2a    ; Temporary Input Storage Most Significant Byte
TPEXP  = $2b    ; Temporary Input Storage Exponent
TEMP1  = $2c    ; Temporary Storage
