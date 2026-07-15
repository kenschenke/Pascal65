NAMELEN = 24

.enum
    DECL_CONST
    DECL_TYPE
    DECL_USES
    DECL_VARIABLE
.endenum

.struct decl
    kind .byte              ; one of DECL_
    name .res 24            ; null-terminated name
    type .dword             ; pointer to type structure
    value .dword            ; pointer to value expression
    node .dword             ; pointer to symbol structure
    symtab .dword           ; root symbol table for this scope
    code .dword             ; first statement in a function/procedure (stmt struct)
    next .dword             ; the next decl in a linked list
    unitSymtab .dword       ; Unit symtab if this is a routine in a unit/library
    isLibrary .byte         ; non-zero if this is a library unit
    lineNumber .word
.endstruct

; The decl structure represents a declaration (variable, function/procedure,
;    a unit, or the program itself).
;
; Variable:
;    name  : pointer to null-terminated variable name
;    type  : pointer to type structure
;    value : pointer to value expression containing initial value
;    next  : next variable in declaration linked list
;
; Function/Procedure:
;    name   : pointer to null-terminated function/procedure name
;    type   : pointer to type structure
;    code   : first statement in function/procedure
;    next   : next function/procedure in scope
;    symtab : symbol table for function/procedure scope
;
; Program:
;    name  : pointer to null-terminated program name
;    type  : pointer to type structure
;    code  : first statement in program code block
;    next  : global variable declarations in chain
;
; When a decl structure represents a program, the type is TYPE_PROGRAM and code
; links to a STMT_BLOCK node. The stmt node contains global declarations,
; functions and procedures, declared types, constants, and any unit references.
; This would be the root of the AST and might look like this:
;
;   +-----------------+
;   |  TYPE_PROGRAM   |
;   |        |  code  |
;   +-----------------+
;                  \
;                   \
;                  +-----------------+
;                  |    STMT_BLOCK   |
;                  |  decl  |  body  |
;                  +-----------------+
;                     /           \
;                    /             \
;     global declarations       stmts in main procedure
;       and functions
;       and procedures
;
;   When a decl structure represents a unit, the type is TYPE_UNIT and code
;   links to a STMT_BLOCK node.  Like a TYPE_PROGRAM declaration, the stmt node
;   contains declarations, types, constants, additional unit references, plus
;   the unit's external interface consisting of types, constants, variables,
;   and procedures and functions.  The main difference is that a unit does not
;   have a "main" procedure body.  The statement node's decl links to the unit's
;   private declarations, and interfaceDecl links to declarations for the unit's
;   public interface.
;
;    +-----------------+
;    |   TYPE_UNIT     |
;    |        |  code  |
;    +-----------------+
;                   \
;                    \
;                   +--------------------------+
;                   |        STMT_BLOCK        |
;                   |  decl  |  interfaceDecl  |
;                   +--------------------------+
;                     /           \
;                    /             \
;     private declarations       declarations for the unit's
;       and functions            public interface
;       and procedures
;    
;    A unit is parsed as an entire AST and is added to the DECL_UNIT node, like this:
;
;    +---------------+
;    |   DECL_UNIT   |
;    |      |  code  |
;    +---------------+
;                 \
;                  \
;                +-----------------+
;                |   STMT_BLOCK    |
;                |        |  decl  |
;                +-----------------+
;                              \
;                               \
;                            links to TYPE_UNIT
;                            declaration

.enum
    STMT_EXPR
    STMT_IF_ELSE
    STMT_FOR
    STMT_WHILE
    STMT_REPEAT
    STMT_CASE
    STMT_CASE_LABEL
    STMT_BLOCK
.endenum

.struct stmt
    kind .byte                  ; The kind of stmt from STMT_
    decl .dword                 ; First local declaration
    interfaceDecl .dword        ; First unit interface declaration
    init_expr .dword            ; Starting value for loop
    expr .dword                 ; Loop expression for While or expression for Case
    to_expr .dword              ; Ending value for loop
    isDownTo .byte              ; Non-zero if loop is a "DOWNTO" loop
    body .dword                 ; statement for If true or first statement in block
    else_body .dword            ; statement for If false
    next .dword                 ; next statement in sequence
    lineNumber .word
.endstruct

;    The stmt structure is represents a statement in the Pascal program.
;    Different members are used for different kinds of statements.
;
;    If / If-Else:
;        kind      : STMT_IF_ELSE
;        expr      : the boolean expression to evaluate
;        body      : statement(s) to execute if expression is true
;        else_body : statement(s) to execute if expression is false
;                    or zero for If (no else)
;
;    For:
;        kind      : STMT_FOR
;        init_expr : initial expression (i := 0)
;        to_expr   : termination expression - like 10
;        isDownTo  : non-zero if loop is DownTo
;        body      : statement(s) to execute inside loop
;
;    While:
;        kind : STMT_WHILE
;        expr : the boolean expression to evaluate prior to each loop iteration
;        body : statement(s) to execute inside loop
;
;    Repeat:
;        kind : STMT_REPEAT
;        expr : the boolean expression to evaluate after each loop iteration
;        body : statement(s) to execute inside loop
;
;    Case:
;        kind : STMT_CASE
;        expr : the expression to evaluate (the case variable)
;        body : the first case label
;
;    Case Label:
;        kind      : STMT_CASE_LABEL
;        expr      : expression to compare against case variable
;                  : (the expr's right points to additional expressions for this label)
;        body      : statement(s) to execute if expr matches case expr
;        next      : the next case label or 0 if no more labels
;
;        Example:
;            Case i Of
;                1, 2: ...
;                3:    ...
;            End;
;
;               +-----------------+
;               |    STMT_CASE    |
;               |  expr  |  body  |
;               +-----------------+
;                  /          \
;                 /            \
;      +-------------+      +-------------------+
;      |  EXPR_NAME  |      |  STMT_CASE_LABEL  |
;      |      i      |      |  expr       next  |
;      +-------------+      +-------------------+
;                              /            \
;                             /              \
;                    +----------------+    +-------------------+
;                    |  EXPR_INTEGER  |    |  STMT_CASE_LABEL  |
;                    |  right  |  1   |    |     expr          |
;                    +----------------+    +-------------------+
;                        /                       /
;                       /                       /
;           +----------------+     +----------------+           
;           |  EXPR_INTEGER  |     |  EXPR_INTEGER  |
;           |       2        |     |       3        |
;           +----------------+     +----------------+

.enum
    EXPR_ADD
    EXPR_SUB
    EXPR_MUL
    EXPR_DIV
    EXPR_DIVINT
    EXPR_MOD
    EXPR_NAME
    EXPR_CALL
    EXPR_ARG
    EXPR_LT
    EXPR_LTE
    EXPR_GT
    EXPR_GTE
    EXPR_EQ
    EXPR_NE
    EXPR_OR
    EXPR_AND
    EXPR_NOT
    EXPR_SUBSCRIPT
    EXPR_FIELD
    EXPR_ASSIGN
    EXPR_BOOLEAN_LITERAL
    EXPR_BYTE_LITERAL
    EXPR_WORD_LITERAL
    EXPR_DWORD_LITERAL
    EXPR_STRING_LITERAL
    EXPR_CHARACTER_LITERAL
    EXPR_REAL_LITERAL
    EXPR_ARRAY_LITERAL
    EXPR_BITWISE_AND
    EXPR_BITWISE_OR
    EXPR_BITWISE_LSHIFT
    EXPR_BITWISE_RSHIFT
    EXPR_BITWISE_XOR
    EXPR_ADDRESS_OF
    EXPR_POINTER
.endenum

.struct expr
    kind .byte                  ; One of EXPR_
    left .dword                 ; Expression left node
    right .dword                ; Expression right node
    name .dword                 ; Null-terminated name
    node .dword                 ; Symbol table node
    neg .byte                   ; Non-zero if unary neg
    width .dword                ; for EXPR_ARG, field width
    precision .dword            ; for EXPR_ARG, precision
    evalType .dword             ; The evaluated type from the semantic phase
    evalTypeKind .byte          ; The evaluated type kind (TYPE_*)
    evalTypeSize .word          ; The evaluated type size
    evalTypeFlags .byte         ; The evaluated type flags
    value .dword                ; The value (byte, word, dword, real, char, boolean)
    lineNumber .word
.endstruct

;    The expr structure stores information on an expression, literal, or
;    function/procedure call.
;
;    Expression:
;        kind: ADD, SUB, MUL, or DIV
;        left: left side of operation
;        right: right side of operation
;
;        Example: 5 + 3
;                           +--------------+
;                           |   EXPR_ADD   |
;                           | left | right |
;                           +--------------+
;                              /        \
;                             /          \
;                 +--------------+    +--------------+
;                 | EXPR_INTEGER |    | EXPR_INTEGER |
;                 |      5       |    |       3      |
;                 +--------------+    +--------------+
;
;    Subscript:
;        kind: EXPR_SUBSCRIPT
;        left: array identifier
;        right: subscript
;
;        Example: arr[5]
;                          +------------------+
;                          |  EXPR_SUBSCRIPT  |
;                          |  left  |  right  |
;                          +------------------+
;                              /         \
;                             /           \
;                   +-------------+   +--------------+
;                   |  EXPR_NAME  |   | EXPR_INTEGER |
;                   |     arr     |   |      5       |
;                   +-------------+   +--------------+
;        
;        Example: arr[5,3] or arr[5][3]
;                          +------------------+
;                          |  EXPR_SUBSCRIPT  |
;                          |  left  |  right  |
;                          +------------------+
;                              /         \
;                             /           \
;              +------------------+   +----------------+
;              |  EXPR_SUBSCRIPT  |   |  EXPR_INTEGER  |
;              |  left  | right   |   |       3        |
;              +------------------+   +----------------+
;                  /        \
;                 /          \
;       +-------------+   +----------------+
;       |  EXPR_NAME  |   |  EXPR_INTEGER  |
;       |     arr     |   |       5        |
;       +-------------+   +----------------+
;
;    Field (Record):
;        kind: EXPR_FIELD
;        left: record identifier
;        right: field identifer
;
;        Example: student.age
;                         +------------------+
;                         |    EXPR_FIELD    |
;                         |  left  |  right  |
;                         +------------------+
;                             /         \
;                            /           \
;                +---------------+   +--------------+
;                |   EXPR_NAME   |   |  EXPR_NAME   |
;                |    student    |   |     age      |
;                +---------------+   +--------------+
;
;        Example: student.dob.month
;
;                    +------------------+
;                    |     EXPR_FIELD   |
;                    |  left  |  right  |
;                    +------------------+
;                        /         \
;                       /           \
;          +------------------+   +-------------+
;          |     EXPR_FIELD   |   |  EXPR_NAME  |
;          |  left  |  right  |   |    month    |
;          +------------------+   +-------------+
;              /         \
;             /           \
;    +-------------+   +-------------+
;    |  EXPR_NAME  |   |  EXPR_NAME  |
;    |   student   |   |     dob     |
;    +-------------+   +-------------+
;
;    Assignment:
;        kind: EXPR_ASSIGN
;        left: lvalue identifier
;        right: value to assign
;
;        Example: pi := 3.14
;                         +------------------+
;                         |    EXPR_ASSIGN   |
;                         |  left  |  right  |
;                         +------------------+
;                             /          \
;                            /            \
;                +--------------+    +-------------+
;                |  EXPR_NAME   |    |  EXPR_REAL  |
;                |     pi       |    |    3.14     |
;                +--------------+    +-------------+
;
;    Function/Procedure Call:
;        kind: EXPR_CALL
;        left: name of function/procedure
;        right: first parameter expression
;
;        Example: sum(123,456,789)
;         +------------------+
;         |     EXPR_CALL    |
;         |  left  |  right  |
;         +------------------+
;             /          \
;            /            \
;    +-----------+    +------------------+
;    | EXPR_NAME |    |     EXPR_ARG     |
;    |    sum    |    |  left  |  right  |
;    +-----------+    +------------------+
;                         /          \
;                        /            \
;              +--------------+   +------------------+
;              | EXPR_INTEGER |   |     EXPR_ARG     |
;              |      123     |   |  left  |  right  |
;              +--------------+   +------------------+
;                                     /          \
;                                    /            \
;                          +--------------+   +------------------+
;                          | EXPR_INTEGER |   |     EXPR_ARG     |
;                          |      456     |   |  left  |  right  |
;                          +--------------+   +------------------+
;                                                 /
;                                                /
;                                    +--------------+
;                                    | EXPR_INTEGER |
;                                    |     789      |
;                                    +--------------+
;    Identifier:
;        kind: EXPR_NAME
;        name: identifier name
;
;    Literals:
;        kind: INTEGER_LITERAL, STRING_LITERAL, or REAL_LITERAL
;        value: literal value
;   
;    Array Literals:
;        kind: EXPR_ARRAY_LITERAL
;        left: first element in array
;        right: next array in literal chain (for nested arrays)
;    
;        Example: MyArray : ArrayType = (11, 44, 32)
;
;               +--------------------+
;               | EXPR_ARRAY_LITERAL |
;               |  left       right  |
;               +--------------------+
;                  /
;                 /
;        +-------------------+
;        | EXPR_BYTE_LITERAL |
;        |        11         |
;        |  left      right  |
;        +-------------------+
;                        \
;                         \
;                +-------------------+
;                | EXPR_BYTE_LITERAL |
;                |        44         |
;                |  left      right  |
;                +-------------------+
;                                \
;                                 \
;                        +-------------------+
;                        | EXPR_BYTE_LITERAL |
;                        |        32         |
;                        +-------------------+
;
;        Example: ( (1, 2, 3), (4, 5, 6) )
;
;               +--------------------+
;               | EXPR_ARRAY_LITERAL |
;               |  left       right  |
;               +--------------------+
;                  /             \ 
;                 /               \
;        +-------------------+   +--------------------+
;        | EXPR_BYTE_LITERAL |   | EXPR_ARRAY_LITERAL |
;        |         1         |   |  left       right  |
;        |  left      right  |   +--------------------+
;        +-------------------+         \
;                        \              \
;                         \              \
;                +-------------------+   +-------------------+
;                | EXPR_BYTE_LITERAL |   | EXPR_BYTE_LITERAL |
;                |         2         |   |         4         |
;                |  left      right  |   |  left      right  |
;                +-------------------+   +-------------------+
;                                \                        \
;                                 \                        \
;                        +-------------------+     +-------------------+
;                        | EXPR_BYTE_LITERAL |     | EXPR_BYTE_LITERAL |
;                        |         3         |     |         5         |
;                        +-------------------+     |  left      right  |
;                                                  +-------------------+
;                                                                  \
;                                                                   \
;                                                         +-------------------+
;                                                         | EXPR_BYTE_LITERAL |
;                                                         |         6         |
;                                                         +-------------------+
;                                                         
;    Function/Procedure Argument:
;        kind: EXPR_ARG
;        left: expression to pass as argument
;        right: next argument
;    
;    Pointers:   identifier^
;        kind: EXPR_POINTER
;        name: name of pointer identifier
;        node: symbol table node of identifier
;    
;    Address-Of:  @identifier
;        kind: EXPR_ADDRESS_OF
;        left: identifier expression

.enum
    TYPE_VOID
    TYPE_BYTE
    TYPE_SHORTINT
    TYPE_WORD
    TYPE_INTEGER
    TYPE_CARDINAL
    TYPE_LONGINT
    TYPE_REAL
    TYPE_BOOLEAN
    TYPE_CHARACTER
    TYPE_STRING_LITERAL
    TYPE_ARRAY
    TYPE_FUNCTION
    TYPE_PROCEDURE
    TYPE_PROGRAM
    TYPE_UNIT
    TYPE_DECLARED
    TYPE_SUBRANGE
    TYPE_ENUMERATION
    TYPE_ENUMERATION_VALUE
    TYPE_RECORD
    TYPE_STRING_VAR
    TYPE_STRING_OBJ
    TYPE_FILE
    TYPE_TEXT
    TYPE_SCALAR_BYTES                   ; Used to write to files
    TYPE_HEAP_BYTES                     ; Used to write to files
    TYPE_POINTER
    TYPE_ADDRESS                        ; An address to a variable
    TYPE_ROUTINE_ADDRESS                ; An address to a routine
    TYPE_ROUTINE_POINTER                ; A pointer to a routine
.endenum

TYPE_MASK_UINT8  = $01
TYPE_MASK_SINT8  = $11
TYPE_MASK_UINT16 = $02
TYPE_MASK_SINT16 = $22
TYPE_MASK_UINT32 = $04
TYPE_MASK_SINT32 = $44
TYPE_MASK_REAL   = $08
TYPE_MASK_CHAR   = $88

TYPE_FLAG_ISCONST   = %00000001
TYPE_FLAG_ISFORWARD = %00000010
TYPE_FLAG_ISBYREF   = %00000100
TYPE_FLAG_ISSTD     = %00001000
TYPE_FLAG_ISRETVAL  = %00010000
TYPE_FLAG_ISCLONED  = %00100000
TYPE_FLAG_ISTEMP    = %01000000

SHRT_MAX = $7fff
LONG_MAX = $7fffffff

.struct type
    kind .byte
    subtype .dword
    indextype .dword
    flags .byte
    routineCode .byte               ; Routine code (rc*)
    paramFields .dword
    symtab .dword                   ; Symbol table for record
    name .dword
    min .dword
    max .dword
    size .word
    lineNumber .word
.endstruct

;    The type structure stores information on data types, both built-in and defined.
;    It describes the data types of variables and functions/procedures.
;
;    Built-In Data Type:
;        kind : kind of variable
;
;    Defined Data Type (Declaration):
;        kind    : TYPE_DECLARED
;        name    : Chunk containing datatype name
;        subtype : built-in type
;
;    Function/Procedure:
;        kind    : TYPE_FUNCTION
;        subtype : If a function, return type.  If procedure, 0.
;        params  : First parameter
;
;    Program:
;        kind    : TYPE_PROGRAM
;        params  : First parameter (program file list)
;
;    Record:
;        kind    : TYPE_RECORD
;        name    : name (if declared) or 0 (if anonymously defined)
;        fields  : Linked list of fields (decl structures)
;
;    Subrange:
;        kind      : TYPE_SUBRANGE
;        name      : name (if declared) or 0 (if anonymously defined)
;        subtype   : type of the subrange values
;                    if TYPE_DECLARED, subrange limits are identifiers and min/max are
;                    stringChunkNums of the identifier names
;        min       : expression low value of subrange
;        max       : expression high value of subrange
;
;    Array:
;        kind      : TYPE_ARRAY
;        name      : name (if declared) or 0 (if anonymously defined)
;        min       : low index value
;        max       : high index value
;        subtype   : element type
;        indextype : index type
;
;    Enumeration:
;        kind    : TYPE_ENUMERATION
;        name    : name (if declared) or 0 (if anonymously defined)
;        max     : max value
;        params  : list of enumeration identifiers

.struct param_list
    name .res 24
    type .dword
    next .dword
    lineNumber .word
.endstruct

.enum
    SYMBOL_LOCAL
    SYMBOL_PARAM
    SYMBOL_GLOBAL
.endenum

.struct symbol
    kind .byte
    node .dword
    type .dword
    name .res 24
    decl .dword
    which .word
    offset .word
    level .word
.endstruct

.struct unit
    name .res 13
    astRoot .dword
    next .dword
.endstruct
