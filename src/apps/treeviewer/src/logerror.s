.include "asmlib.inc"

.export logError, errorNum, errorCount, errorLine

.bss

errorNum: .res 1
errorLine: .res 2
errorCount: .res 1

.code

.proc logError
    sta errorLine
    stx errorLine+1
    sty errorNum
    inc errorCount
    jmp popQ
.endproc
