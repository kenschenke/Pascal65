.include "runtime.inc"

.export cleanup

.proc cleanup
    jmp rtIrqCleanup
.endproc
