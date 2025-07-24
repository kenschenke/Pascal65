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

A literal is a value such as a number or string. See the [literals](../literals)
topic for more information.

### Variable

A variable reference is used when to designate a variable. This operand
includes enough information for the intermediate code to either read the
value of the variable or locate the address to update the value.

### Label

The label operand is used to define the target of a branch or routine. This
operand can be used to define the location of a label or to look up the
location of the label.

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
|[AND](../mne/and)    |01       |0000 0001   |Perform a boolean AND operation|
|[CNL](../mne/cnl)    |08       |0000 1000   |Clear input buffer to newline  |
|[DEF](../mne/def)    |0d       |0000 1101   |Pops and frees file handle     |
|[DEL](../mne/del)    |07       |0000 0111   |Pops and frees address         |
|[FSO](../mne/fso)    |0c       |0000 1100   |Flush string output buffer     |
|[RTS](../mne/rts)    |0f       |0000 1111   |Returns to a routine's caller  |
|[NOT](../mne/not)    |09       |0000 1001   |Logical not top of stack       |
|[ORA](../mne/ora)    |02       |0000 0010   |Perform a boolean OR operation |
|[ONL](../mne/onl)    |03       |0000 0011   |Output a newline character     |
|[POP](../mne/pop)    |06       |0000 0110   |Pops value off runtime stack   |
|[ROU](../mne/rou)    |04       |0000 0100   |Round a real number            |
|[SSR](../mne/ssr)    |0a       |0000 1010   |Read a string at a subscript   |
|[SSW](../mne/ssw)    |0b       |0000 1011   |Write a string at a subscript  |
|[TRU](../mne/tru)    |05       |0000 0101   |Truncate a real number         |

### Unary Instructions

The following instructions take one operand.

|Mnemonic             |Hex Value|Binary Value|Description                          |
|---------------------|---------|------------|-------------------------------------|
|[ABS](../mne/abs)    |23       |0010 0011   |Calculate absolute value             |
|[AIX](../mne/aix)    |33       |0011 0011   |Calculate address of array element   |
|[ARR](../mne/arr)    |2c       |0010 1100   |Initialize array(s)                  |
|[ASF](../mne/asf)    |38       |0011 1000   |Activate stack frame                 |
|[BIF](../mne/bif)    |31       |0011 0001   |Branch to the label if false         |
|[BIT](../mne/bit)    |30       |0011 0000   |Branch to the label if true          |
|[BRA](../mne/bra)    |2f       |0010 1111   |Branch unconditionally to the label  |
|[BWC](../mne/bwc)    |34       |0011 0100   |Calculate bitwise complement         |
|[CPY](../mne/cpy)    |36       |0011 0110   |Clones memory                        |
|[DIA](../mne/dia)    |25       |0010 0101   |Initializes an array                 |
|[DIR](../mne/dir)    |21       |0010 0001   |Initializes a record                 |
|[INP](../mne/inp)    |26       |0010 0110   |Reads and stores a value from input  |
|[LOC](../mne/loc)    |2e       |0010 1110   |Sets the target for the label        |
|[MEM](../mne/mem)    |3a       |0011 1010   |Reads a value from a memory location |
|[NEG](../mne/neg)    |22       |0010 0010   |Negate value at top of stack         |
|[NEW](../mne/new)    |2b       |0010 1011   |Allocate memory from the heap        |
|[OUT](../mne/out)    |2a       |0010 1010   |Output a value                       |
|[PPF](../mne/ppf)    |24       |0010 0100   |Push stack frame for a routine ptr   |
|[PRE](../mne/pre)    |28       |0010 1000   |Calcuate the predecessor of the value|
|[PSH](../mne/psh)    |27       |0010 0111   |Push the operand to the runtime stack|
|[SCV](../mne/scv)    |37       |0011 0111   |Converts to a string object          |
|[SQR](../mne/sqr)    |35       |0011 0101   |Calculate the square of a number     |
|[SSP](../mne/ssp)    |39       |0011 1001   |Save the stack pointer               |
|[SST](../mne/sst)    |2d       |0010 1101   |Initialize a string variable         |
|[SUC](../mne/suc)    |29       |0010 1001   |Calcuate the successor of the value  |

### Binary Instructions

The following instructions take two operands.

|Mnemonic             |Hex Value|Binary Value|Description                               |
|---------------------|---------|------------|------------------------------------------|
|[CCT](../mne/cct)    |4a       |0100 1010   |Concatenate two values into a string obj  |
|[CVI](../mne/cvi)    |50       |0101 0000   |Convert the integer at top of the stack   |
|[DCF](../mne/dcf)    |4d       |0101 0001   |Free an array or record declaration       |
|[DIV](../mne/div)    |43       |0100 0011   |Perform floating point division           |
|[EQU](../mne/equ)    |48       |0100 1000   |Perform an equality comparison            |
|[GRT](../mne/grt)    |44       |0100 0100   |Perform a greater-than comparison         |
|[GTE](../mne/gte)    |45       |0100 0101   |Perform a greater-than-or-equal comparison|
|[LSE](../mne/lse)    |47       |0100 1111   |Perform a less-than-or-equal comparison   |
|[LST](../mne/lst)    |46       |0100 1110   |Perform a less-than comparison            |
|[MOD](../mne/mod)    |42       |0100 0010   |Perform modulus                           |
|[NEQ](../mne/neq)    |49       |0100 1001   |Perform an inequality comparison          |
|[POF](../mne/pof)    |4c       |0100 1100   |Pop the stack frame for a routine         |
|[PUF](../mne/puf)    |4b       |0100 1011   |Push the stack frame for a routine        |
|[SET](../mne/set)    |41       |0100 0001   |Set the value of a variable               |
|[SFH](../mne/sfh)    |4f       |0100 1111   |Set input/output file number              |

### Trinary Instructions

The following instructions take three operands.

|Mnemonic             |Hex Value|Binary Value|Description                               |
|---------------------|---------|------------|------------------------------------------|
|[ADD](../mne/add)    |81       |1000 0001   |Add two numbers                           |
|[BSL](../mne/bsl)    |87       |1000 0111   |Bitwise left-shift                        |
|[BSR](../mne/bsr)    |88       |1000 1000   |Bitwise right-shift                       |
|[BWA](../mne/bwa)    |85       |1000 0101   |Bitwise and two numbers                   |
|[BWO](../mne/bwo)    |86       |1000 0110   |Bitwise or two numbers                    |
|[DVI](../mne/dvi)    |84       |1000 0100   |Integer divide two numbers                |
|[JSR](../mne/jsr)    |89       |1000 1001   |Call a routine                            |
|[MUL](../mne/mul)    |83       |1000 0011   |Multiply two numbers                      |
|[SUB](../mne/sub)    |82       |1000 0010   |Subtract two numbers                      |

