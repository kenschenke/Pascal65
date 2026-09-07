
CODEGEN_BASE = $4000

objCodeGen = CODEGEN_BASE
setCodeGenStackSize = CODEGEN_BASE + 3
setCodeGenUnitList = CODEGEN_BASE + 6
setCodeGenProgramChain = CODEGEN_BASE + 9

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

