;
; compiletests.s
; Ken Schenke (kenschenke@gmail.com)
; 
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; compileTests routine

.include "zeropage.inc"
.include "cbm_kernal.inc"
.include "error.inc"
.include "c64.inc"
.include "asmlib.inc"

.export compileTests, nextTestPrg, expectedError

.import runCompiler, madeUnits, failTests, makeRebuild, genUnits

.data

pascalSuffix: .asciiz ".pas"
strAdd: .asciiz "add"
strAssign: .asciiz "assign"
strVarInit: .asciiz "varinit"
strConstants: .asciiz "constants"
strBitwiseA: .asciiz "bitwisea"
strBitwiseB: .asciiz "bitwiseb"
strIfThen: .asciiz "ifthen"
strLoops: .asciiz "loops"
strStdRoutines: .asciiz "stdroutines"
strIncDec: .asciiz "incdec"
strStrRoutines: .asciiz "strroutines"
strStrLeak: .asciiz "strleak"
strWriteWidth: .asciiz "writewidth"
strStrTests: .asciiz "strtests"
strStrComp: .asciiz "strcomp"
strRecArray: .asciiz "recarray"
strScopeTest: .asciiz "scopetest"
strCaseTest: .asciiz "casetest"
strProcFunc: .asciiz "procfunc"
strMultiply: .asciiz "multiply"
strSubtract: .asciiz "subtract"
strDivInt: .asciiz "divint"
strTrig: .asciiz "trig"
strVarTest: .asciiz "vartest"
strFileTestA: .asciiz "filetesta"
strFileTestB: .asciiz "filetestb"
strPointers: .asciiz "pointers"
strUnit: .asciiz "unit"
strLibTest: .asciiz "libtest"
strLibTest2: .asciiz "libtest2"
strSoundTest: .asciiz "soundtest"
strSoundFx: .asciiz "soundfx"
strSoundSeq: .asciiz "soundseq"
strIrqCb: .asciiz "irqcb"
strSoundCalls: .asciiz "soundcalls"
strRtnArray: .asciiz "rtnarray"
strRtnRecord: .asciiz "rtnrecord"
strRtnPtrs: .asciiz "rtnptrs"
strRecord: .asciiz "strrecord"
strArray: .asciiz "strarray"
strTypeCast: .asciiz "typecast"
strCharArray: .asciiz "chararray"
strExprClone: .asciiz "exprclone"
strNamedIdx: .asciiz "namedidx"
strForOrd: .asciiz "forord"
strDeclOrdr: .asciiz "declordr"
strNegate: .asciiz "negate"
strSubrange: .asciiz "subrange"
strUnitInit: .asciiz "unitinit"
strUnitRefs: .asciiz "unitrefs"
strUnitObjs: .asciiz "unitobjs"
strUnitUses: .asciiz "unituses"
strUnitLib: .asciiz "unitlib"
strSlots256: .asciiz "slots256"
strDynArrayA: .asciiz "dynarraya"
strDynArrayB: .asciiz "dynarrayb"
strDynArrayC: .asciiz "dynarrayc"
strRtPkgNone: .asciiz "rtpkgnone"
strRtPkgA: .asciiz "rtpkga"
strRtPkgB: .asciiz "rtpkgb"
strRtPkgC: .asciiz "rtpkgc"
strRtDyn: .asciiz "rtdyn"
strRtDynA: .asciiz "rtdyna"
strRtDynB: .asciiz "rtdynb"
strRtErrExit: .asciiz "rterrexit"
strStrOvf: .asciiz "strovf"
strFiveDice: .asciiz "fivedice"
strBubbles: .asciiz "bubbles"
strSfxDemo: .asciiz "sfxdemo"
strTuneDemo: .asciiz "tunedemo"
strStereoDemo: .asciiz "stereodemo"
strHangman: .asciiz "hangman"
strDone: .asciiz "done"
strTooLarge: .asciiz "toolarge"
strTooManyVars: .asciiz "toomanyvars"
strTooManyImpl: .asciiz "toomanyimpl"
strMkCycle: .asciiz "mkcycle"
strMkBad: .asciiz "mkbad"
strWdSearch: .asciiz "wdsearch"
strRun1: .asciiz "Run "
strRun2: .asciiz " to begin tests"

; The complete list of tests is too large to compile onto one D81 disk image.
; When the TESTSET symbol is defined (see the Makefile test target) the list
; is split in three. Each set ends by chaining to "done", which reports the
; overall PASS to the test harness. Without TESTSET the whole list is built.
; Set 4 runs some of set 1 and 2's tests again with a work disk on unit 9
; (WORKUNIT, see initlib.s): the units, a library only a unit uses, the
; file tests, the make tests and a unit found on the work disk first.
.ifndef TESTSET
TESTSET = 0
.endif

tests:
.if TESTSET = 0 || TESTSET = 1
    ; String comparisons, with the dynamic runtime. First, so adding it
    ; changed no other program's chain target.
    .byte .lobyte(strStrComp), .hibyte(strStrComp)
    ; Modules linked from their own object files, a unit used by two
    ; others. First, so adding it changed no other program's chain target.
    .byte .lobyte(strUnitObjs), .hibyte(strUnitObjs)
    ; A program and unit that fill all 256 level 1 slots. First, so adding
    ; it changed no other program's chain target.
    .byte .lobyte(strSlots256), .hibyte(strSlots256)
    ; A library only a unit uses. First, so adding it changed no other
    ; program's chain target.
    .byte .lobyte(strUnitLib), .hibyte(strUnitLib)
    ; A unit used by the program and by another unit. First, so adding it
    ; changed no other program's chain target.
    .byte .lobyte(strUnitUses), .hibyte(strUnitUses)
    ; References to a unit's entries (unit.N in icode). First, so adding it
    ; changed no other program's chain target.
    .byte .lobyte(strUnitRefs), .hibyte(strUnitRefs)
    .byte .lobyte(strAdd), .hibyte(strAdd)
    .byte .lobyte(strAssign), .hibyte(strAssign)
    .byte .lobyte(strVarInit), .hibyte(strVarInit)
    .byte .lobyte(strConstants), .hibyte(strConstants)
    .byte .lobyte(strBitwiseA), .hibyte(strBitwiseA)
    .byte .lobyte(strBitwiseB), .hibyte(strBitwiseB)
    .byte .lobyte(strIfThen), .hibyte(strIfThen)
    .byte .lobyte(strLoops), .hibyte(strLoops)
    .byte .lobyte(strStdRoutines), .hibyte(strStdRoutines)
    .byte .lobyte(strIncDec), .hibyte(strIncDec)
    .byte .lobyte(strStrRoutines), .hibyte(strStrRoutines)
    .byte .lobyte(strStrLeak), .hibyte(strStrLeak)
    .byte .lobyte(strWriteWidth), .hibyte(strWriteWidth)
    .byte .lobyte(strStrTests), .hibyte(strStrTests)
    .byte .lobyte(strRecArray), .hibyte(strRecArray)
    .byte .lobyte(strScopeTest), .hibyte(strScopeTest)
    .byte .lobyte(strCaseTest), .hibyte(strCaseTest)
    .byte .lobyte(strProcFunc), .hibyte(strProcFunc)
    .byte .lobyte(strMultiply), .hibyte(strMultiply)
    .byte .lobyte(strForOrd), .hibyte(strForOrd)
    .byte .lobyte(strDeclOrdr), .hibyte(strDeclOrdr)
    .byte .lobyte(strNegate), .hibyte(strNegate)
    .byte .lobyte(strSubrange), .hibyte(strSubrange)
    ; Units' init blocks (UIC/UIR), with the dynamic runtime. unit is in
    ; set 2, with the static one.
    .byte .lobyte(strUnitInit), .hibyte(strUnitInit)
.endif
.if TESTSET = 2
    ; String comparisons again, with the static runtime. First, so adding
    ; it changed no other program's chain target.
    .byte .lobyte(strStrComp), .hibyte(strStrComp)
.endif
.if TESTSET = 0 || TESTSET = 2
    .byte .lobyte(strSubtract), .hibyte(strSubtract)
    .byte .lobyte(strDivInt), .hibyte(strDivInt)
    .byte .lobyte(strUnit), .hibyte(strUnit)
    .byte .lobyte(strLibTest), .hibyte(strLibTest)
    .byte .lobyte(strTrig), .hibyte(strTrig)
    .byte .lobyte(strVarTest), .hibyte(strVarTest)
    .byte .lobyte(strPointers), .hibyte(strPointers)
    .byte .lobyte(strRtnArray), .hibyte(strRtnArray)
    .byte .lobyte(strRtnRecord), .hibyte(strRtnRecord)
    .byte .lobyte(strRtnPtrs), .hibyte(strRtnPtrs)
    .byte .lobyte(strRecord), .hibyte(strRecord)
    .byte .lobyte(strArray), .hibyte(strArray)
    .byte .lobyte(strTypeCast), .hibyte(strTypeCast)
    .byte .lobyte(strCharArray), .hibyte(strCharArray)
    .byte .lobyte(strExprClone), .hibyte(strExprClone)
    .byte .lobyte(strNamedIdx), .hibyte(strNamedIdx)
    .byte .lobyte(strFileTestA), .hibyte(strFileTestA)
    .byte .lobyte(strFileTestB), .hibyte(strFileTestB)
.endif
.if TESTSET = 0 || TESTSET = 3
    .byte .lobyte(strDynArrayA), .hibyte(strDynArrayA)
    .byte .lobyte(strDynArrayB), .hibyte(strDynArrayB)
    .byte .lobyte(strDynArrayC), .hibyte(strDynArrayC)
    ; Runtime packages (see rtpkg.inc). Together with the tests above they
    ; use every package variant file.
    .byte .lobyte(strRtPkgNone), .hibyte(strRtPkgNone)
    .byte .lobyte(strRtPkgA), .hibyte(strRtPkgA)
    .byte .lobyte(strRtPkgB), .hibyte(strRtPkgB)
    .byte .lobyte(strRtPkgC), .hibyte(strRtPkgC)
    ; The dynamic runtime, with every package
    .byte .lobyte(strRtDyn), .hibyte(strRtDyn)
    ; A library in the v2 format (relocation table)
    .byte .lobyte(strLibTest2), .hibyte(strLibTest2)
    ; The Sound library
    .byte .lobyte(strSoundTest), .hibyte(strSoundTest)
    ; The Sound library's effects
    .byte .lobyte(strSoundFx), .hibyte(strSoundFx)
    ; The Sound library's sequencer and done callback
    .byte .lobyte(strSoundSeq), .hibyte(strSoundSeq)
    ; The System and Sprites libraries' IRQ callbacks
    .byte .lobyte(strIrqCb), .hibyte(strIrqCb)
.endif
.if TESTSET = 4
    .byte .lobyte(strUnitObjs), .hibyte(strUnitObjs)
    .byte .lobyte(strUnitUses), .hibyte(strUnitUses)
    .byte .lobyte(strUnitLib), .hibyte(strUnitLib)
    .byte .lobyte(strLibTest), .hibyte(strLibTest)
    .byte .lobyte(strWdSearch), .hibyte(strWdSearch)
    .byte .lobyte(strFileTestA), .hibyte(strFileTestA)
    .byte .lobyte(strFileTestB), .hibyte(strFileTestB)
.endif
.if TESTSET <> 0
    .byte .lobyte(strDone), .hibyte(strDone)
.endif
    .byte $00, $00

; The Pascal units the tests use aren't listed. runCompiler compiles each
; one to its TPU (unit mode) when the first program that uses it is
; compiled (tpuMake), so every program is built with its units loaded from
; their TPUs (tpuload.s).

; The make tests: DOS commands that change the sources, TPUs and objects,
; and compiles that must compile exactly the units named, in that order
; (each followed by a space), then generate the code of exactly the units
; named second: those whose object isn't current for their TPU
; (objcache.s in codegen). MkProg uses MkB and MkC, MkB uses MkA in its
; interface and MkC uses MkB in its implementation.
MK_DOS = 1                  ; .word the command
MK_COMPILE = 2              ; .word the program, .word the units expected
                            ; to compile, .word those to generate
MK_REBUILD = 3              ; the same, rebuilding every unit (tpuClean)

.macro MKDOS cmd
    .byte MK_DOS
    .word cmd
.endmacro

.macro MKCOMPILE prog, units, gen
    .byte MK_COMPILE
    .word prog, units, gen
.endmacro

.macro MKREBUILD prog, units, gen
    .byte MK_REBUILD
    .word prog, units, gen
.endmacro

makeTests:
.if TESTSET = 0 || TESTSET = 1 || TESTSET = 4
    MKDOS strMkScratchTpus
    MKDOS strMkScratchA
    MKDOS strMkCopyA1
    ; No TPUs or objects: each unit, deepest first
    MKCOMPILE strMkProg, strMkAll, strMkAll
    ; All current
    MKCOMPILE strMkProg, strMkNone, strMkNone
    ; MkA's implementation changed: its interface CRC didn't, so it alone
    MKDOS strMkScratchA
    MKDOS strMkCopyA2
    MKCOMPILE strMkProg, strMkA, strMkA
    ; MkA's interface changed: MkB used it, but MkB's own interface
    ; didn't change, so MkC is current. MkB's TPU records MkA's new
    ; interface CRC, so its object isn't current either.
    MKDOS strMkScratchA
    MKDOS strMkCopyA3
    MKCOMPILE strMkProg, strMkAB, strMkAB
    ; MkC's TPU is of another icode version. Compiled again, its TPU is
    ; the one its object was made from, so the object is current.
    MKDOS strMkScratchC
    MKDOS strMkCopyStale
    MKCOMPILE strMkProg, strMkC, strMkNone
    ; MkA's TPU is missing. Compiled from the same source, its interface
    ; CRC is the same, so MkB is current, and so is MkA's object.
    MKDOS strMkScratchATpu
    MKCOMPILE strMkProg, strMkA, strMkNone
    ; MkB's object is missing: its code alone
    MKDOS strMkScratchBObj
    MKCOMPILE strMkProg, strMkNone, strMkB
    ; Rebuild all: every unit and every unit's code, though all are current
    MKREBUILD strMkProg, strMkAll, strMkAll
.endif
    .byte 0

strMkProg: .asciiz "mkprog"
strMkScratchTpus: .asciiz "s:mk*.tpu,mk*.obj"
strMkScratchBObj: .asciiz "s:mkb.obj"
strMkScratchA: .asciiz "s:mka.pas"
strMkScratchATpu: .asciiz "s:mka.tpu"
strMkScratchC: .asciiz "s:mkc.tpu"
strMkCopyA1: .asciiz "c:mka.pas=mka1.pas"
strMkCopyA2: .asciiz "c:mka.pas=mka2.pas"
strMkCopyA3: .asciiz "c:mka.pas=mka3.pas"
strMkCopyStale: .asciiz "c:mkc.tpu=mkstale.tpu"
strMkAll: .asciiz "mka mkb mkc "
strMkNone: .asciiz ""
strMkA: .asciiz "mka "
strMkAB: .asciiz "mka mkb "
strMkC: .asciiz "mkc "
strMkB: .asciiz "mkb "
strMkGenerated: .asciiz "Generated: "
strMkExpected: .asciiz "Expected: "
strMkMade: .asciiz "Compiled: "

; Programs the compiler must refuse, each followed by the one error it must
; report. They are compiled before the tests above, aren't linked and aren't
; part of the chain.
errorTests:
; Set 1 runs it with the dynamic runtime and set 2 with the static one
; (see FORCESTATIC in runcompiler.s). A dynamic program gets the error
; that suggests $StaticRuntime.
.if TESTSET = 0 || TESTSET = 1
    .byte .lobyte(strTooLarge), .hibyte(strTooLarge)
    .byte errCodeSegmentOverflowDyn
    ; Its unit's variables need slot 256. They're in the unit's
    ; interface, so the resolver numbers them from its TPU and reports it.
    .byte .lobyte(strTooManyVars), .hibyte(strTooManyVars)
    .byte errTooManyVariables
    ; Its unit's implementation's do, which its TPU doesn't show the
    ; resolver: the linker reports it from the frames (checkSlots)
    .byte .lobyte(strTooManyImpl), .hibyte(strTooManyImpl)
    .byte errTooManyVariables
    ; Its units use each other. The make walk reports it (tpumake.s).
    .byte .lobyte(strMkCycle), .hibyte(strMkCycle)
    .byte errCircularUnitReference
    ; Its unit has an error, which make finds compiling it. The unit's
    ; compile must erase its temporary files (runcompiler.s).
    .byte .lobyte(strMkBad), .hibyte(strMkBad)
    .byte errIncompatibleAssignment
.endif
.if TESTSET = 2
    .byte .lobyte(strTooLarge), .hibyte(strTooLarge)
    .byte errCodeSegmentOverflow
.endif
.if TESTSET = 4
    ; The make walk and a unit's failed compile, with the sources, TPUs
    ; and temporary files on the work disk
    .byte .lobyte(strMkCycle), .hibyte(strMkCycle)
    .byte errCircularUnitReference
    .byte .lobyte(strMkBad), .hibyte(strMkBad)
    .byte errIncompatibleAssignment
.endif
    .byte $00, $00

; Programs that must compile and link without an error or warning. They
; are compiled after errorTests and aren't run or part of the chain.
compileOnlyTests:
.if TESTSET = 0 || TESTSET = 3
    ; The split runtime must leave fivedice room (see plans/runtime.md)
    .byte .lobyte(strFiveDice), .hibyte(strFiveDice)
    ; Uses the Sprites and SpriteMove libraries
    .byte .lobyte(strBubbles), .hibyte(strBubbles)
    ; $DynamicRuntime must make the same PRG as no directive. The
    ; Makefile compares them (see testset).
    .byte .lobyte(strRtDynA), .hibyte(strRtDynA)
    .byte .lobyte(strRtDynB), .hibyte(strRtDynB)
    ; Ends with a runtime error. rtdyntest.sh runs it.
    .byte .lobyte(strRtErrExit), .hibyte(strRtErrExit)
    ; Ends with a string overflow (an array of 256 Chars compared).
    ; rtdyntest.sh runs it.
    .byte .lobyte(strStrOvf), .hibyte(strStrOvf)
    ; Calls every routine in the Sound library
    .byte .lobyte(strSoundCalls), .hibyte(strSoundCalls)
    ; The Sound library's effects demo
    .byte .lobyte(strSfxDemo), .hibyte(strSfxDemo)
    ; The Sound library's sequencer demo
    .byte .lobyte(strTuneDemo), .hibyte(strTuneDemo)
    ; The Sound library's stereo demo
    .byte .lobyte(strStereoDemo), .hibyte(strStereoDemo)
    ; The Hangman game, with the Screen and Sound libraries
    .byte .lobyte(strHangman), .hibyte(strHangman)
.endif
    .byte $00, $00

.bss

testNum: .res 1
expectedError: .res 1       ; error the current test must report, or 0
sourceFn: .res 16           ; null-terminated source filename for the current test
nextTestPrg: .res 16        ; null-terminated PRG filename of the next test
mkPtr: .res 2               ; the make test step
mkExpected: .res 2          ; the units its compile must compile
mkGenExpected: .res 2       ; and generate the code of

.code

.proc compileTests
    lda #0
    sta makeRebuild
    jsr compileErrorTests
    jsr compileOnly
    jsr compileMakeTests

    lda #0
    sta testNum
    sta expectedError

    ; Loop through the tests
L1: lda testNum
    asl a
    tax
    tay

    ; Check for terminator
    lda tests,y
    iny
    ora tests,y
    beq DN

    ; Put current filename in ptr1
    lda tests,x
    sta ptr1
    inx
    lda tests,x
    sta ptr1+1

    ; Next filename in ptr2
    inx
    lda tests,x
    sta ptr2
    inx
    lda tests,x
    sta ptr2+1

    ; Format current source filename
    jsr makeSourceFilename

    ; Format next test filename
    jsr makeNextTestFilename

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: lda #13
    jsr CHROUT

    ldx #0
:   lda strRun1,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda tests
    sta ptr1
    lda tests+1
    sta ptr1+1
    ldy #0
:   lda (ptr1),y
    beq :+
    jsr CHROUT
    iny
    bne :-

:   ldx #0
:   lda strRun2,x
    beq :+
    jsr CHROUT
    inx
    bne :-

:   lda #13
    jsr CHROUT

    rts
.endproc

; This routine compiles the programs in errorTests. runCompiler fails the
; tests unless each reports exactly its expected error.
.proc compileErrorTests
    lda #0
    sta testNum

L1: lda testNum                 ; Y = testNum * 3
    asl a
    adc testNum
    tay

    ; Check for terminator
    lda errorTests,y
    ora errorTests+1,y
    beq DN

    lda errorTests,y
    sta ptr1
    lda errorTests+1,y
    sta ptr1+1
    lda errorTests+2,y
    sta expectedError

    jsr makeSourceFilename

    ; Not part of the chain
    lda #0
    sta nextTestPrg

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: rts
.endproc

; This routine runs the steps in makeTests. A compile fails the tests if
; it reports an error or a warning, or doesn't compile exactly the units
; expected (madeUnits in runcompiler.s).
.proc compileMakeTests
    lda #0
    sta expectedError
    sta nextTestPrg
    lda #<makeTests
    sta mkPtr
    lda #>makeTests
    sta mkPtr+1

L1: lda mkPtr
    sta ptr3
    lda mkPtr+1
    sta ptr3+1
    ldy #0
    lda (ptr3),y
    bne :+
    rts
:   cmp #MK_DOS
    bne CP
    iny
    lda (ptr3),y
    pha
    iny
    lda (ptr3),y
    tax
    pla
    jsr dosCommand
    lda #3
    bra NX

CP: cmp #MK_REBUILD
    bne :+
    sta makeRebuild
:   iny
    lda (ptr3),y
    sta ptr1
    iny
    lda (ptr3),y
    sta ptr1+1
    iny
    lda (ptr3),y
    sta mkExpected
    iny
    lda (ptr3),y
    sta mkExpected+1
    iny
    lda (ptr3),y
    sta mkGenExpected
    iny
    lda (ptr3),y
    sta mkGenExpected+1
    jsr makeSourceFilename
    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler
    jsr checkMade
    lda #7

NX: clc
    adc mkPtr
    sta mkPtr
    bcc L1
    inc mkPtr+1
    bra L1
.endproc

; This routine fails the tests unless madeUnits is the string at
; mkExpected, and prints both if it isn't
.proc checkMade
    lda mkExpected
    sta ptr4
    lda mkExpected+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    cmp madeUnits,y
    bne FL
    cmp #0
    beq :+
    iny
    bra :-

    ; The units whose code was generated
:   lda mkGenExpected
    sta ptr4
    lda mkGenExpected+1
    sta ptr4+1
    ldy #0
:   lda (ptr4),y
    cmp genUnits,y
    bne FL
    cmp #0
    beq :+
    iny
    bra :-
:   rts

FL: lda #13
    jsr CHROUT
    lda #<strMkExpected
    ldx #>strMkExpected
    jsr printStr
    lda mkExpected
    ldx mkExpected+1
    jsr printStr
    lda #13
    jsr CHROUT
    lda #<strMkMade
    ldx #>strMkMade
    jsr printStr
    lda #<madeUnits
    ldx #>madeUnits
    jsr printStr
    lda #13
    jsr CHROUT
    lda #<strMkExpected
    ldx #>strMkExpected
    jsr printStr
    lda mkGenExpected
    ldx mkGenExpected+1
    jsr printStr
    lda #13
    jsr CHROUT
    lda #<strMkGenerated
    ldx #>strMkGenerated
    jsr printStr
    lda #<genUnits
    ldx #>genUnits
    jsr printStr
    lda #13
    jsr CHROUT
    jmp failTests
.endproc

; This routine prints the null-terminated string at A/X
.proc printStr
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    jsr CHROUT
    iny
    bra :-
:   rts
.endproc

; This routine sends the null-terminated DOS command at A/X to the drive
.proc dosCommand
    sta ptr4
    stx ptr4+1
    ldy #0
:   lda (ptr4),y
    beq :+
    iny
    bra :-
:   tya
    ldx ptr4
    ldy ptr4+1
    jsr SETNAM
    lda #15
    ldx workDevice
    ldy #15
    jsr SETLFS
    jsr OPEN
    lda #15
    jmp CLOSE
.endproc

; This routine compiles and links the programs in compileOnlyTests.
; runCompiler fails the tests if any reports an error or a warning.
.proc compileOnly
    lda #0
    sta testNum
    sta expectedError

L1: lda testNum                 ; Y = testNum * 2
    asl a
    tay

    ; Check for terminator
    lda compileOnlyTests,y
    ora compileOnlyTests+1,y
    beq DN

    lda compileOnlyTests,y
    sta ptr1
    lda compileOnlyTests+1,y
    sta ptr1+1

    jsr makeSourceFilename

    ; Not part of the chain
    lda #0
    sta nextTestPrg

    lda #<sourceFn
    ldx #>sourceFn
    jsr runCompiler

    inc testNum
    bra L1

DN: rts
.endproc

; This routine expects ptr1 to point to the null-terminated test name.
; The routine copies characters until it reaches a null then appends ".pas".
.proc makeSourceFilename
    ldy #0
L1: lda (ptr1),y
    beq L2
    sta sourceFn,y
    iny
    bne L1
L2: ldx #0
L3: lda pascalSuffix,x
    sta sourceFn,y
    beq L4
    iny
    inx
    bne L3
L4: rts
.endproc

; This routine expects ptr2 to point to the null-terminated
; filename of the next test.
; The routine copies it into nextTestPrg.
; If ptr2 is null then it sets nextTestPrg to empty.
.proc makeNextTestFilename
    lda ptr2
    ora ptr2+1
    bne L1
    lda #0
    sta nextTestPrg
    rts

L1: ldy #0
L2: lda (ptr2),y
    sta nextTestPrg,y
    beq L3
    iny
    bne L2
L3: rts
.endproc
