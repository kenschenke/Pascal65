
DUMPICODE_BASE = $4000

dumpIcode = DUMPICODE_BASE
dumpUnitIcode = DUMPICODE_BASE + 3 ; a unit compiled on its own, name in A/X
dumpTpu = DUMPICODE_BASE + 6    ; a unit's TPU (dumpTpu.s), name in A/X
