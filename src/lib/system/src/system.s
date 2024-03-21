; Jump table for system library

.import chr, odd, peek, poke, length, trim, stringOfChar, getkey, getkeynowait
.import upCase, lowerCase

.segment "JMPTBL"

jmp chr
jmp getkey
jmp getkeynowait
jmp odd
jmp length
jmp lowerCase
jmp peek
jmp poke
jmp stringOfChar
jmp trim
jmp upCase
