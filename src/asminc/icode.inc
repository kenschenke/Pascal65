
ICODE_BASE = $5000

icodeWrite = ICODE_BASE
icodeFileErase = ICODE_BASE + 3
setIcodeUnitsList = ICODE_BASE + 6

LOCALVARS_RECORD = 2
LOCALVARS_DEL    = 1
LOCALVARS_FILE   = 4
LOCALVARS_ARRAY  = 5
LOCALVARS_STRING = 3

ARRAYDECL_SCALAR = 0
ARRAYDECL_REAL   = 1
ARRAYDECL_RECORD = 2
ARRAYDECL_STRING = 3
ARRAYDECL_FILE   = 4
ARRAYDECL_ARRAY  = 5

MAX_LOCAL_VARS   = 32
MAX_NUM_PARAMS   = 15

END_OF_PARAMS    = 127

; Literal operand types
IC_CHR          = $11  ; 0001 0001 : PETSCII character
IC_IBU          = $12  ; 0001 0010 : Unsigned 8-bit integer
IC_IBS          = $13  ; 0001 0011 : Signed 8-bit integer
IC_BOO          = $14  ; 0001 0100 : Boolean (1 byte)
IC_IWU          = $15  ; 0001 0101 : Unsigned 16-bit integer
IC_IWS          = $16  ; 0001 0110 : Signed 16-bit integer
IC_ILU          = $17  ; 0001 0111 : Unsigned 32-bit integer
IC_ILS          = $18  ; 0001 1000 : Signed 32-bit integer
IC_FLT          = $19  ; 0001 1001 : Real number
IC_STR          = $1a  ; 0001 1010 : String

; Variable operand types
IC_VDR          = $f1  ; 1111 0001  direct read
IC_VDW          = $f2  ; 1111 0010  direct write
IC_VVR          = $f3  ; 1111 0011  var (by ref) read
IC_VVW          = $f4  ; 1111 0100  var (by ref) write

; Non-literal operand types
IC_LBL          = $1b  ; 0001 1011
IC_RET          = $1d  ; 0001 1101  memory address of return value

; These instructions take no operands
IC_AND          = $01  ; 0000 0001
IC_ORA          = $02  ; 0000 0010
IC_ONL          = $03  ; 0000 0011
IC_ROU          = $04  ; 0000 0100  round
IC_TRU          = $05  ; 0000 0101  trunc
IC_POP          = $06  ; 0000 0110  pop (discard) value from runtime stack
IC_DEL          = $07  ; 0000 0111  pop and free memory address off rt stack
IC_CNL          = $08  ; 0000 1000  clear input to new line character
IC_NOT          = $09  ; 0000 1001  replace top of runtime stack with logical not
IC_SSR          = $0a  ; 0000 1010  string subscript read
IC_SSW          = $0b  ; 0000 1011  string subscript write
IC_FSO          = $0c  ; 0000 1100  flush string output
IC_DEF          = $0d  ; 0000 1101  pop and free a file handle and close file
IC_JRP          = $0e  ; 0000 1110  call a routine from a pointer on the stack
IC_RTS          = $0f  ; 0000 1111  return from a routine using the stack frame return addr

; These instructions take one operand
IC_MASK_UNARY   = $20  ; 0010 0000
IC_DIR          = $21  ; 0010 0001  1:record declaration chunknum
IC_NEG          = $22  ; 0010 0010  1:type
IC_ABS          = $23  ; 0010 0011  1:type
IC_PPF          = $24  ; 0010 0100  1:label
IC_DIA          = $25  ; 0010 0101  1:array declaration chunknum
IC_INP          = $26  ; 0010 0110  1:type
IC_PSH          = $27  ; 0010 0111  1:type
IC_PRE          = $28  ; 0010 1000  1:type
IC_SUC          = $29  ; 0010 1001  1:type
IC_OUT          = $2a  ; 0010 1010  1:type
IC_NEW          = $2b  ; 0010 1011  1:size  allocate heap for recs/arrays
IC_ARR          = $2c  ; 0010 1100  1:label for array init structures
IC_SST          = $2d  ; 0010 1101  1:pointer to string literal (or 0 for empty)
IC_LOC          = $2e  ; 0010 1110  1:label (define location)
IC_BRA          = $2f  ; 0010 1111  1:label
IC_BIT          = $30  ; 0011 0000  1:label
IC_BIF          = $31  ; 0011 0001  1:label
IC_LIN          = $32  ; 0011 0010  1:line number
IC_AIX          = $33  ; 0011 0011  1:indexType
                       ; address of array on stack (under index), address of elem left on stack
IC_BWC          = $34  ; 0011 0100  1:type (bitwise complement)
IC_SQR          = $35  ; 0011 0101  1:type
IC_CPY          = $36  ; 0011 0110  1:size -- clone memory at top of stack and replace
IC_SCV          = $37  ; 0011 0111  1:type -- string convert for routine parameters
IC_ASF          = $38  ; 0011 1000  1:routineLevel - activate stack frame
IC_SSP          = $39  ; 0011 1001  1:label - store stack pointer at label
IC_MEM          = $3a  ; 0011 1010  1:type

; These instructions take two operands
IC_MASK_BINARY  = $40  ; 0100 0000
IC_SET          = $41  ; 0100 0001  1:varType, 2:rightType (value on stack, then variable)
IC_MOD          = $42  ; 0100 0010  1:leftType, 2:rightType (values on stack)
IC_DIV          = $43  ; 0100 0011  1:leftType, 2:rightType
IC_GRT          = $44  ; 0100 0100  1:leftType, 2:rightType
IC_GTE          = $45  ; 0100 0101  1:leftType, 2:rightType
IC_LST          = $46  ; 0100 0110  1:leftType, 2:rightType
IC_LSE          = $47  ; 0100 0111  1:leftType, 2:rightType
IC_EQU          = $48  ; 0100 1000  1:leftType, 2:rightType
IC_NEQ          = $49  ; 0100 1001  1:leftType, 2:rightType
IC_CCT          = $4a  ; 0100 1010  1:leftType, 2:rightType concatenate
IC_PUF          = $4b  ; 0100 1011  1:routineLevel, 2:returnLabel -- push stack frame
IC_POF          = $4c  ; 0100 1100  1:isFunc, 2:isLibrary -- pop stack frame and return to caller
IC_DCC          = $4e  ; 0100 1110  1:label, 2:type - clone declaration (array or record)
IC_SFH          = $4f  ; 0100 1111  Set file handle 1:file handle 2:0/output 1/input
IC_CVI          = $50  ; 0101 0000  1:from type, 2:to type
IC_DCF          = $51  ; 0101 0001  1:label, 2:type - free declaration (array or record)

; These instructions take three operands
IC_MASK_TRINARY = $80
IC_ADD          = $81  ; 1000 0001  1:leftType, 2:rightType, 3:resultType
IC_SUB          = $82  ; 1000 0010  1:leftType, 2:rightType, 3:resultType
IC_MUL          = $83  ; 1000 0011  1:leftType, 2:rightType, 3:resultType
IC_DVI          = $84  ; 1000 0100  1:leftType, 2:rightType, 3:resultType
IC_BWA          = $85  ; 1000 0101  1:leftType, 2:rightType, 3:resultType (bitwise and)
IC_BWO          = $86  ; 1000 0110  1:leftType, 2:rightType, 3:resultType (bitwise or)
IC_BSL          = $87  ; 1000 0111  1:leftType, 2:rightType, 3:resultType (bitwise left-shift)
IC_BSR          = $88  ; 1000 1000  1:leftType, 2:rightType, 3:resultType (bitwise right-shift)
IC_JSR          = $89  ; 1000 1001  1:routineLabel, 2:routineLevel, 3:isLibraryRtn
IC_PRP          = $8a  ; 1000 1010  1:routineLabel, 2:routineLevel, 3:isLibraryRtn
IC_BWX          = $8b  ; 1000 1011  1:leftType, 2:rightType, 3:resultType (bitwise xor)
IC_DAT          = $8c  ; 1000 1100  1:type, 2:label, 3:length - data segment
