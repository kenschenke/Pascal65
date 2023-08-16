
.import heapAlloc, heapFree, heapInit

.export _heapAlloc, _heapFree, _heapInit

; void *heapAlloc(short size);
.proc _heapAlloc
    jmp heapAlloc
.endproc

; void heapFree(void *p);
.proc _heapFree
    jmp heapFree
.endproc

; void heapInit(void);
.proc _heapInit
    jmp heapInit
.endproc
