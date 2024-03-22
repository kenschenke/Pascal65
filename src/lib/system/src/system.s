; Jump table for system library

.import chr, odd, peek, poke, length, trim, stringOfChar, getkey, getkeynowait
.import upCase, lowerCase, compareStr

.segment "JMPTBL"

jmp chr
jmp compareStr
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
