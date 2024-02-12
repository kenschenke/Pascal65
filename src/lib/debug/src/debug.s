; Jump table for debug library

.import getHeapUsed, dumpHeap

.segment "JMPTBL"

jmp dumpHeap
jmp getHeapUsed
