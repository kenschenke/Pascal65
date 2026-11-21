
CODEGEN_BASE = $4000

objCodeGen = CODEGEN_BASE              ; takes no AST: all from the icode
; A/X: the PRG to chain to (0 for none), Y: CHAIN_FLAG_* bits, Z: the
; device to load it from
setCodeGenProgramChain = CODEGEN_BASE + 3
CHAIN_FLAG_PROMPT = $01     ; "Press a key." before loading the next PRG
CHAIN_FLAG_HANDOFF = $02    ; hand the work device to the editor (asm.inc)
getCodeGenUnits = CODEGEN_BASE + 6      ; A/X: the units generated (objcache.s)
; The runtime mode, stack size, libraries and features come from the icode
; file (icode.inc). Set the mode and stack size in icode
; (setIcodeRuntimeMode, setIcodeStackSize).

.macro genOne opcode
    lda #opcode
    jsr genOneInstruction
.endmacro

.macro genTwoImmediate opcode, operand
    lda #opcode
    ldx #operand
    jsr genTwoInstruction
.endmacro

.macro genTwoAbsolute opcode, operand
    lda #opcode
    ldx operand
    jsr genTwoInstruction
.endmacro

.macro genThree opcode, routine
    lda #opcode
    ldx #.lobyte(routine)
    ldy #.hibyte(routine)
    jsr genThreeAddr
.endmacro

