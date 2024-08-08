# Intermediate Code

The Pascal65 compiler uses intermediate code during the code generation
phase of compilation. Intermediate code is a mid-level language that
bridges the gap between the syntax tree produced by the parser and the
low-level object code in the finished program. Intermediate code is
similar to assembly language.

It is not necessary to understand intermediate code to use the Pascal65
compiler. This is documented for those curious but mostly as a future
reference for compiler maintenance and language developers.

## Structure

The Pascal65 intermediate code consists of instructions followed by
operands. The type of instruction defines the number of expected operands.

## Operands

An operand can be one of four categories: a literal, a variable reference,
a label, or a memory dereference.

### Literal

A literal is a value such as a number or string. See the [literals](/icode/literals)
topic for more information.

### Variable

A variable reference is used when to designate a variable. This operand
includes enough information for the intermediate code to either read the
value of the variable or locate the address to update the value.

### Label

The label operand is used to define the target of a branch or routine. This
operand can be used to define the location of a label or to look up the
location of the label.

### Memory Dereference

The memory rereference operand instructs the instruction to use the value
in the address at the top of the runtime stack. This operand is often used
by the [PSH](/icode/mne/psh) instruction. This combination will replace the address at
the top of the runtime stack with the value at that address.

## Intructions

Instructions in intermediate code are very similar to instructions in assembly
language. Most of the instructions perform a task using operands and data on the
runtime stack and leave the result on the runtime stack.

The instructions are represented by a mnemonic, like assembly language. The mnenomics
are grouped by the number of operands, making processing more efficient.

### Instructions With No Operands

The following instructions do not take an operand.

|Mnemonic             |Hex Value|Binary Value|Description                    |
|---------------------|---------|------------|-------------------------------|
|[AND](/icode/mne/and)|01       |0000 0001   |Perform a boolean AND operation|
|[CNL](/icode/mne/cnl)|08       |0000 1000   |Clear input buffer to newline  |
|[DEL](/icode/mne/del)|07       |0000 0111   |Pops and frees address         |
|[FSO](/icode/mne/not)|0c       |0000 1100   |Flush string output buffer     |
|[NOT](/icode/mne/not)|09       |0000 1001   |Logical not top of stack       |
|[ORA](/icode/mne/ora)|02       |0000 0010   |Perform a boolean OR operation |
|[ONL](/icode/mne/onl)|03       |0000 0011   |Output a newline character     |
|[POP](/icode/mne/pop)|06       |0000 0110   |Pops value off runtime stack   |
|[ROU](/icode/mne/rou)|04       |0000 0100   |Round a real number            |
|[SSR](/icode/mne/ssr)|0a       |0000 1010   |Read a string at a subscript   |
|[SSW](/icode/mne/ssw)|0b       |0000 1011   |Write a string at a subscript  |
|[TRU](/icode/mne/tru)|05       |0000 0101   |Truncate a real number         |

### Unary Instructions

The following instructions take one operand.

|Mnemonic             |Hex Value|Binary Value|Description                          |
|---------------------|---------|------------|-------------------------------------|
|[ABS](/icode/mne/abs)|23       |0010 0011   |Calculate absolute value             |
|[AIX](/icode/mne/aix)|33       |0011 0011   |Calculate address of array element   |
|[ARR](/icode/mne/arr)|2c       |0010 1100   |Initialize array(s)                  |
|[ASF](/icode/mne/asf)|38       |0011 1000   |Activate stack frame                 |
|[BIF](/icode/mne/bif)|31       |0011 0001   |Branch to the label if false         |
|[BIT](/icode/mne/bit)|30       |0011 0000   |Branch to the label if true          |
|[BRA](/icode/mne/bra)|2f       |0010 1111   |Branch unconditionally to the label  |
|[BWC](/icode/mne/bwc)|34       |0011 0100   |Calculate bitwise complement         |
|[CPY](/icode/mne/cpy)|36       |0011 0110   |Clones memory                        |
|[INP](/icode/mne/inp)|26       |0010 0110   |Reads and stores a value from input  |
|[LOC](/icode/mne/loc)|2e       |0010 1110   |Sets the target for the label        |
|[NEG](/icode/mne/neg)|22       |0010 0010   |Negate value at top of stack         |
|[NEW](/icode/mne/new)|2b       |0010 1011   |Allocate memory from the heap        |
|[OUT](/icode/mne/out)|2a       |0010 1010   |Output a value                       |
|[PRE](/icode/mne/pre)|28       |0010 1000   |Calcuate the predecessor of the value|
|[PSH](/icode/mne/psh)|27       |0010 0111   |Push the operand to the runtime stack|
|[SCV](/icode/mne/sqr)|37       |0011 0111   |Converts to a string object          |
|[SOF](/icode/mne/sof)|21       |0010 0001   |Set output file number               |
|[SQR](/icode/mne/sqr)|35       |0011 0101   |Calculate the square of a number     |
|[SSP](/icode/mne/ssp)|39       |0011 1001   |Save the stack pointer               |
|[SST](/icode/mne/sst)|2d       |0010 1101   |Initialize a string variable         |
|[SUC](/icode/mne/suc)|29       |0010 1001   |Calcuate the successor of the value  |

### Binary Instructions

The following instructions take two operands.

|Mnemonic             |Hex Value|Binary Value|Description                               |
|---------------------|---------|------------|------------------------------------------|
|[CCT](/icode/mne/cct)|4a       |0100 1010   |Concatenate two values into a string obj  |
|[DIV](/icode/mne/div)|43       |0100 0011   |Perform floating point division           |
|[EQU](/icode/mne/equ)|48       |0100 1000   |Perform an equality comparison            |
|[GRT](/icode/mne/grt)|44       |0100 0100   |Perform a greater-than comparison         |
|[GTE](/icode/mne/gte)|45       |0100 0101   |Perform a greater-than-or-equal comparison|
|[LSE](/icode/mne/lse)|47       |0100 1111   |Perform a less-than-or-equal comparison   |
|[LST](/icode/mne/lst)|46       |0100 1110   |Perform a less-than comparison            |
|[MOD](/icode/mne/mod)|42       |0100 0010   |Perform modulus                           |
|[NEQ](/icode/mne/neq)|49       |0100 1001   |Perform an inequality comparison          |
|[POF](/icode/mne/pof)|4c       |0100 1100   |Pop the stack frame for a routine         |
|[PUF](/icode/mne/puf)|4b       |0100 1011   |Push the stack frame for a routine        |
|[SET](/icode/mne/set)|41       |0100 0001   |Set the value of a variable               |

### Trinary Instructions

The following instructions take three operands.

|Mnemonic             |Hex Value|Binary Value|Description                               |
|---------------------|---------|------------|------------------------------------------|
|[ADD](/icode/mne/add)|81       |1000 0001   |Add two numbers                           |
|[BSL](/icode/mne/bsl)|87       |1000 0111   |Bitwise left-shift                        |
|[BSR](/icode/mne/bsr)|88       |1000 1000   |Bitwise right-shift                       |
|[BWA](/icode/mne/bwa)|85       |1000 0101   |Bitwise and two numbers                   |
|[BWO](/icode/mne/bwo)|86       |1000 0110   |Bitwise or two numbers                    |
|[DVI](/icode/mne/dvi)|84       |1000 0100   |Integer divide two numbers                |
|[JSR](/icode/mne/jsr)|89       |1000 1001   |Call a routine                            |
|[MUL](/icode/mne/mul)|83       |1000 0011   |Multiply two numbers                      |
|[SUB](/icode/mne/sub)|82       |1000 0010   |Subtract two numbers                      |

