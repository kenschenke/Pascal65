; Jump table for system library

.import chr, odd, peek, poke

.segment "JMPTBL"

jmp chr
jmp odd
jmp peek
jmp poke
