
CODEGEN_BASE = $4000

objCodeGen = CODEGEN_BASE
setCodeGenUnitList = CODEGEN_BASE + 3
setCodeGenProgramChain = CODEGEN_BASE + 6
; The runtime mode, stack size and features come from the icode file
; (icode.inc). Set them in icode (setIcodeRuntimeMode, setIcodeStackSize).

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

