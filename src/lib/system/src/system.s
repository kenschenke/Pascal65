; Jump table for system library

.import chr, odd, peek, poke, length

.segment "JMPTBL"

jmp chr
jmp odd
jmp peek
jmp poke
jmp length
