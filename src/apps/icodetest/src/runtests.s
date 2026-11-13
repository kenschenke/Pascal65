;
; runtests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2025
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; runTests routine
;
; Tests:
;    1: Scalar variable assignments
;    2: Expressions
;    3: Scalar variable initial values
;    4: While loops
;    5: Repeat..Until loop
;    6: For loops
;    7: Case statement
;    8: Arrays
;    9: Strings
;   10: Records
;   11. Pointers
;   12. Standard routines
;   13. Routines
;   14. Files
;   15. Array literals
;   16. Read, Readln, Readstr
;   17. Write, Writeln, Writestr
;   18. If, Then, Else
;   19. Array literals
;   20. Array inside record
;   21. Enumerations
;   22. Constants
;   23. Type casts
;   24. Three level array literal
;   25. Arrays indexed by a declared type
;   26. For loop with a subrange control variable
;   27. Dynamic arrays: SetLength, Length, Low and High
;   28. Unary minus
;   29. Comparisons, pointer arithmetic, Inc and Dec, Round
;   30. Fields, pointers, string subscripts and file fields
;   31. Forward declarations, value parameters and local variables
;   32. Array bounds and element types
;   33. Typed files of records and arrays
;   34. System library calls
;   35. A library unit's variables and routines (iclib.pas)
;   36. A unit with code (icunit.pas)
;   37. Dereferenced Var arguments and pointer offsets
;   38. Whole records from elements, fields and pointers

.export runTests

.import runTest

NUM_TESTS = 38

; Only some of the tests can be run:
; make test TESTSEL="-D FIRST_TEST=n -D LAST_TEST=m"
.ifndef FIRST_TEST
FIRST_TEST = 1
.endif
.ifndef LAST_TEST
LAST_TEST = NUM_TESTS
.endif

.bss

testNum: .res 2

.code

.proc runTests
.if ::FIRST_TEST <= ::LAST_TEST
    lda #.LOBYTE(FIRST_TEST)
    sta testNum
    lda #.HIBYTE(FIRST_TEST)
    sta testNum+1

L1: jsr usesSystemUnit
    lda testNum
    ldx testNum+1
    jsr runTest

    lda testNum
    cmp #.LOBYTE(LAST_TEST)
    bne L2
    lda testNum+1
    cmp #.HIBYTE(LAST_TEST)
    beq L3

L2: inc testNum
    bne L1
    inc testNum+1
    bra L1

L3:
.endif
    rts
.endproc

; This routine sets the carry flag if the current test resolves its units
; (the System unit and any it uses) and clears it if not.
.proc usesSystemUnit
    lda testNum+1
    bne NO
    ldx #0
:   lda unitTests,x
    beq NO
    cmp testNum
    beq YS
    inx
    bne :-
YS: sec
    rts
NO: clc
    rts
.endproc

.rodata

; The tests that resolve units, ending with 0. They call System routines
; or use a unit.
unitTests: .byte 27, 32, 34, 35, 36, 38, 0
