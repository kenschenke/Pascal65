/**
 * ast.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for AST
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef AST_H
#define AST_H

#include <chunks.h>
#include <misc.h>

typedef enum {
    DECL_CONST,             // Declared constant (Const section)
    DECL_TYPE,              // Defined type (Type section)
    DECL_USES,              // Unit identifier (Uses clause)
    DECL_VARIABLE,          // Variable (Var section)
} decl_t;

struct decl {
    char kind;
    CHUNKNUM name;          // Chunk containing declaration name
    CHUNKNUM type;          // The type of the declaration
    CHUNKNUM value;         // The value (expression)
    CHUNKNUM node;          // The symbol chunknum
    CHUNKNUM symtab;        // The root symbol table for this scope
    CHUNKNUM code;          // The first statement in a function/procedure (stmt)
    CHUNKNUM next;          // The next declaration in a linked list
    CHUNKNUM unitSymtab;    // Unit symtab if this is a routine in a unit/library
    char isLibrary;         // Non-zero if this is a library unit
    short lineNumber;
    char unused[CHUNK_LEN - 20];
};

/*
    The decl structure represents a declaration (variable, function/procedure,
        a unit, or the program itself).

    Variable:
        name  : chunk containing variable name
        type  : type (see below)
        value : expression containing initial value
        next  : next variable in declaration linked list

    Function/Procedure:
        name   : chunk containing function/procedure name
        type   : type (see below)
        code   : first statement in function/procedure
        next   : next function/procedure in scope
        symtab : symbol table root node

    Program:
        name  : chunk containing program name
        type  : type (see below)
        code  : first statement in program code block
        next  : global variable declarations in chain
    
    When a decl structure represents a program, the type is TYPE_PROGRAM and code
    links to a STMT_BLOCK node.  The stmt node contains global declarations,
    functions and procedures, declared types, constants, and any unit references.
    This would be the root of the AST and might look like this:

    +-----------------+
    |  TYPE_PROGRAM   |
    |        |  code  |
    +-----------------+
                   \
                    \
                   +-----------------+
                   |    STMT_BLOCK   |
                   |  decl  |  body  |
                   +-----------------+
                     /           \
                    /             \
     global declarations       stmts in main procedure
       and functions
       and procedures
    
    When a decl structure represents a unit, the type is TYPE_UNIT and code
    links to a STMT_BLOCK node.  Like a TYPE_PROGRAM declaration, the stmt node
    contains declarations, types, constants, additional unit references, plus
    the unit's external interface consisting of types, constants, variables,
    and procedures and functions.  The main difference is that a unit does not
    have a "main" procedure body.  The statement node's decl links to the unit's
    private declarations, and interfaceDecl links to declarations for the unit's
    public interface.

    +-----------------+
    |   TYPE_UNIT     |
    |        |  code  |
    +-----------------+
                   \
                    \
                   +--------------------------+
                   |        STMT_BLOCK        |
                   |  decl  |  interfaceDecl  |
                   +--------------------------+
                     /           \
                    /             \
     private declarations       declarations for the unit's
       and functions            public interface
       and procedures
    
    A unit is parsed as an entire AST and is added to the DECL_UNIT node, like this:

    +---------------+
    |   DECL_UNIT   |
    |      |  code  |
    +---------------+
                 \
                  \
                +-----------------+
                |   STMT_BLOCK    |
                |        |  decl  |
                +-----------------+
                              \
                               \
                            links to TYPE_UNIT
                            declaration
*/

typedef enum {
    STMT_EXPR,
    STMT_IF_ELSE,
    STMT_FOR,
    STMT_WHILE,
    STMT_REPEAT,
    STMT_CASE,
    STMT_CASE_LABEL,
    STMT_BLOCK
} stmt_t;

struct stmt {
    char kind;              // The kind of statement (from stmt_t)
    CHUNKNUM decl;          // First local declaration
    CHUNKNUM interfaceDecl; // First unit interface declaration
    CHUNKNUM init_expr;     // Starting value for loop
    CHUNKNUM expr;          // Loop expression for While or expression for Case
    CHUNKNUM to_expr;       // Ending value for loop
    char isDownTo;          // Non-zero if loop is a "DOWNTO" loop
    CHUNKNUM body;          // statement for If true or first statement in block
    CHUNKNUM else_body;     // statement for If false
    CHUNKNUM next;          // next statement in sequence
    short lineNumber;
    char unused[CHUNK_LEN - 20];
};

/*
    The stmt structure is represents a statement in the Pascal program.
    Different members are used for different kinds of statements.

    If / If-Else:
        kind      : STMT_IF_ELSE
        expr      : the boolean expression to evaluate
        body      : statement(s) to execute if expression is true
        else_body : statement(s) to execute if expression is false
                    or zero for If (no else)

    For:
        kind      : STMT_FOR
        init_expr : initial expression (i := 0)
        to_expr   : termination expression - like 10
        isDownTo  : non-zero if loop is DownTo
        body      : statement(s) to execute inside loop

    While:
        kind : STMT_WHILE
        expr : the boolean expression to evaluate prior to each loop iteration
        body : statement(s) to execute inside loop

    Repeat:
        kind : STMT_REPEAT
        expr : the boolean expression to evaluate after each loop iteration
        body : statement(s) to execute inside loop

    Case:
        kind : STMT_CASE
        expr : the expression to evaluate (the case variable)
        body : the first case label

    Case Label:
        kind      : STMT_CASE_LABEL
        expr      : expression to compare against case variable
                  : (the expr's right points to additional expressions for this label)
        body      : statement(s) to execute if expr matches case expr
        next      : the next case label or 0 if no more labels

        Example:
            Case i Of
                1, 2: ...
                3:    ...
            End;

               +-----------------+
               |    STMT_CASE    |
               |  expr  |  body  |
               +-----------------+
                  /          \
                 /            \
      +-------------+      +-------------------+
      |  EXPR_NAME  |      |  STMT_CASE_LABEL  |
      |      i      |      |  expr       next  |
      +-------------+      +-------------------+
                              /            \
                             /              \
                    +----------------+    +-------------------+
                    |  EXPR_INTEGER  |    |  STMT_CASE_LABEL  |
                    |  right  |  1   |    |     expr          |
                    +----------------+    +-------------------+
                        /                       /
                       /                       /
           +----------------+     +----------------+           
           |  EXPR_INTEGER  |     |  EXPR_INTEGER  |
           |       2        |     |       3        |
           +----------------+     +----------------+
*/

// CAUTION. Do not rearrange this list without also changing
// the values in expr.inc.
typedef enum {
    EXPR_ADD,
    EXPR_SUB,
    EXPR_MUL,
    EXPR_DIV,
    EXPR_DIVINT,
    EXPR_MOD,
    EXPR_NAME,
    EXPR_CALL,
    EXPR_ARG,
    EXPR_LT,
    EXPR_LTE,
    EXPR_GT,
    EXPR_GTE,
    EXPR_EQ,
    EXPR_NE,
    EXPR_OR,
    EXPR_AND,
    EXPR_NOT,
    EXPR_SUBSCRIPT,
    EXPR_FIELD,
    EXPR_ASSIGN,
    EXPR_BOOLEAN_LITERAL,
    EXPR_BYTE_LITERAL,
    EXPR_WORD_LITERAL,
    EXPR_DWORD_LITERAL,
    EXPR_STRING_LITERAL,
    EXPR_CHARACTER_LITERAL,
    EXPR_REAL_LITERAL,
    EXPR_ARRAY_LITERAL,
    EXPR_BITWISE_AND,
    EXPR_BITWISE_OR,
    EXPR_BITWISE_LSHIFT,
    EXPR_BITWISE_RSHIFT
} expr_t;

struct expr {
    char kind;
    CHUNKNUM left;
    CHUNKNUM right;
    CHUNKNUM name;
    CHUNKNUM node;      // Real symbol table node
    char neg;           // non-zero if unary neg
    CHUNKNUM width;     // for EXPR_ARG, field width
    CHUNKNUM precision; // for EXPR_ARG, precision
    CHUNKNUM evalType;  // The evaluated type from the semantic phase
    TDataValue value;
    short lineNumber;
    char unused[CHUNK_LEN - 22];
};

/*
    The expr structure stores information on an expression, literal, or
    function/procedure call.

    Expression:
        kind: ADD, SUB, MUL, or DIV
        left: left side of operation
        right: right side of operation

        Example: 5 + 3
                           +--------------+
                           |   EXPR_ADD   |
                           | left | right |
                           +--------------+
                              /        \
                             /          \
                 +--------------+    +--------------+
                 | EXPR_INTEGER |    | EXPR_INTEGER |
                 |      5       |    |       3      |
                 +--------------+    +--------------+

    Subscript:
        kind: EXPR_SUBSCRIPT
        left: array identifier
        right: subscript

        Eample: arr[5]
                          +------------------+
                          |  EXPR_SUBSCRIPT  |
                          |  left  |  right  |
                          +------------------+
                              /         \
                             /           \
                   +-------------+   +--------------+
                   |  EXPR_NAME  |   | EXPR_INTEGER |
                   |     arr     |   |      5       |
                   +-------------+   +--------------+
        
        Example: arr[5,3] or arr[5][3]
                          +------------------+
                          |  EXPR_SUBSCRIPT  |
                          |  left  |  right  |
                          +------------------+
                              /         \
                             /           \
              +------------------+   +----------------+
              |  EXPR_SUBSCRIPT  |   |  EXPR_INTEGER  |
              |  left  | right   |   |       3        |
              +------------------+   +----------------+
                  /        \
                 /          \
       +-------------+   +----------------+
       |  EXPR_NAME  |   |  EXPR_INTEGER  |
       |     arr     |   |       5        |
       +-------------+   +----------------+

    Field (Record):
        kind: EXPR_FIELD
        left: record identifier
        right: field identifer

        Example: student.age
                         +------------------+
                         |    EXPR_FIELD    |
                         |  left  |  right  |
                         +------------------+
                             /         \
                            /           \
                +---------------+   +--------------+
                |   EXPR_NAME   |   |  EXPR_NAME   |
                |    student    |   |     age      |
                +---------------+   +--------------+

        Example: student.dob.month

                    +------------------+
                    |     EXPR_FIELD   |
                    |  left  |  right  |
                    +------------------+
                        /         \
                       /           \
          +------------------+   +-------------+
          |     EXPR_FIELD   |   |  EXPR_NAME  |
          |  left  |  right  |   |    month    |
          +------------------+   +-------------+
              /         \
             /           \
    +-------------+   +-------------+
    |  EXPR_NAME  |   |  EXPR_NAME  |
    |   student   |   |     dob     |
    +-------------+   +-------------+

    Assignment:
        kind: EXPR_ASSIGN
        left: lvalue identifier
        right: value to assign

        Example: pi := 3.14
                         +------------------+
                         |    EXPR_ASSIGN   |
                         |  left  |  right  |
                         +------------------+
                             /          \
                            /            \
                +--------------+    +-------------+
                |  EXPR_NAME   |    |  EXPR_REAL  |
                |     pi       |    |    3.14     |
                +--------------+    +-------------+

    Function/Procedure Call:
        kind: EXPR_CALL
        left: name of function/procedure
        right: first parameter expression

        Example: sum(123,456,789)
         +------------------+
         |     EXPR_CALL    |
         |  left  |  right  |
         +------------------+
             /          \
            /            \
    +-----------+    +------------------+
    | EXPR_NAME |    |     EXPR_ARG     |
    |    sum    |    |  left  |  right  |
    +-----------+    +------------------+
                         /          \
                        /            \
              +--------------+   +------------------+
              | EXPR_INTEGER |   |     EXPR_ARG     |
              |      123     |   |  left  |  right  |
              +--------------+   +------------------+
                                     /          \
                                    /            \
                          +--------------+   +------------------+
                          | EXPR_INTEGER |   |     EXPR_ARG     |
                          |      456     |   |  left  |  right  |
                          +--------------+   +------------------+
                                                 /
                                                /
                                    +--------------+
                                    | EXPR_INTEGER |
                                    |     789      |
                                    +--------------+
    Identifier:
        kind: EXPR_NAME
        name: identifier name

    Literals:
        kind: INTEGER_LITERAL, STRING_LITERAL, or REAL_LITERAL
        value: literal value
    
    Array Literals:
        kind: EXPR_ARRAY_LITERAL
        left: first element in array
        right: next array in literal chain (for nested arrays)
    
        Example: MyArray : ArrayType = (11, 44, 32)

               +--------------------+
               | EXPR_ARRAY_LITERAL |
               |  left       right  |
               +--------------------+
                  /
                 /
        +-------------------+
        | EXPR_BYTE_LITERAL |
        |        11         |
        |  left      right  |
        +-------------------+
                        \
                         \
                +-------------------+
                | EXPR_BYTE_LITERAL |
                |        44         |
                |  left      right  |
                +-------------------+
                                \
                                 \
                        +-------------------+
                        | EXPR_BYTE_LITERAL |
                        |        32         |
                        +-------------------+

        Example: ( (1, 2, 3), (4, 5, 6) )

               +--------------------+
               | EXPR_ARRAY_LITERAL |
               |  left       right  |
               +--------------------+
                  /             \ 
                 /               \
        +-------------------+   +--------------------+
        | EXPR_BYTE_LITERAL |   | EXPR_ARRAY_LITERAL |
        |         1         |   |  left       right  |
        |  left      right  |   +--------------------+
        +-------------------+         \
                        \              \
                         \              \
                +-------------------+   +-------------------+
                | EXPR_BYTE_LITERAL |   | EXPR_BYTE_LITERAL |
                |         2         |   |         4         |
                |  left      right  |   |  left      right  |
                +-------------------+   +-------------------+
                                \                        \
                                 \                        \
                        +-------------------+     +-------------------+
                        | EXPR_BYTE_LITERAL |     | EXPR_BYTE_LITERAL |
                        |         3         |     |         5         |
                        +-------------------+     |  left      right  |
                                                  +-------------------+
                                                                  \
                                                                   \
                                                         +-------------------+
                                                         | EXPR_BYTE_LITERAL |
                                                         |         6         |
                                                         +-------------------+
                                                         
    Function/Procedure Argument:
        kind: EXPR_ARG
        left: expression to pass as argument
        right: next argument

*/

// CAUTION. Do not rearrange this list without also changing
// the values in types.inc.
typedef enum {
    TYPE_VOID,
    TYPE_BYTE,
    TYPE_SHORTINT,
    TYPE_WORD,
    TYPE_INTEGER,
    TYPE_CARDINAL,
    TYPE_LONGINT,
    TYPE_REAL,
    TYPE_BOOLEAN,
    TYPE_CHARACTER,
    TYPE_STRING_LITERAL,
    TYPE_ARRAY,
    TYPE_FUNCTION,
    TYPE_PROCEDURE,
    TYPE_PROGRAM,
    TYPE_UNIT,
    TYPE_DECLARED,
    TYPE_SUBRANGE,
    TYPE_ENUMERATION,
    TYPE_ENUMERATION_VALUE,
    TYPE_RECORD,
    TYPE_STRING_VAR,
    TYPE_STRING_OBJ,
    TYPE_FILE,
    TYPE_TEXT,
    TYPE_SCALAR_BYTES,                 // Used to write to files
    TYPE_HEAP_BYTES,                   // Used to write to files
} type_t;
// CAUTION. Do not rearrange this list without also changing
// the values in types.inc.

#define TYPE_MASK_UINT8  0x01
#define TYPE_MASK_SINT8  0x11
#define TYPE_MASK_UINT16 0x02
#define TYPE_MASK_SINT16 0x22
#define TYPE_MASK_UINT32 0x04
#define TYPE_MASK_SINT32 0x44
#define TYPE_MASK_REAL   0x08
#define TYPE_MASK_CHAR   0x88

#define IS_TYPE_SIGNED(mask) (mask & 0xf0)
#define GET_TYPE_SIZE(mask) (mask & 0x0f)

char getTypeMask(char type);
char isTypeInteger(char type);

#define TYPE_FLAG_ISCONST 1
#define TYPE_FLAG_ISFORWARD 2
#define TYPE_FLAG_ISBYREF 4
#define TYPE_FLAG_ISSTD 8
#define TYPE_FLAG_ISRETVAL 16

struct type {
    char kind;
    CHUNKNUM subtype;
    CHUNKNUM indextype;
    char flags;
    char routineCode;                   // Routine code (rc*)
    CHUNKNUM paramsFields;
    CHUNKNUM symtab;            // Symbol table for record
    CHUNKNUM name;
    CHUNKNUM min;
    CHUNKNUM max;
    short size;
    short lineNumber;
    char unused[CHUNK_LEN - 21];
};

/*
    The type structure stores information on data types, both built-in and defined.
    It describes the data types of variables and functions/procedures.

    Built-In Data Type:
        kind : kind of variable

    Defined Data Type (Declaration):
        kind    : TYPE_DECLARED
        name    : Chunk containing datatype name
        subtype : built-in type

    Function/Procedure:
        kind    : TYPE_FUNCTION
        subtype : If a function, return type.  If procedure, 0.
        params  : First parameter

    Program:
        kind    : TYPE_PROGRAM
        params  : First parameter (program file list)

    Record:
        kind    : TYPE_RECORD
        name    : name (if declared) or 0 (if anonymously defined)
        fields  : Linked list of fields (decl structures)

    Subrange:
        kind      : TYPE_SUBRANGE
        name      : name (if declared) or 0 (if anonymously defined)
        subtype   : type of the subrange values
                    if TYPE_DECLARED, subrange limits are identifiers and min/max are
                    stringChunkNums of the identifier names
        min       : expression low value of subrange
        max       : expression high value of subrange

    Array:
        kind      : TYPE_ARRAY
        name      : name (if declared) or 0 (if anonymously defined)
        min       : low index value
        max       : high index value
        subtype   : element type
        indextype : index type

    Enumeration:
        kind    : TYPE_ENUMERATION
        name    : name (if declared) or 0 (if anonymously defined)
        max     : max value
        params  : list of enumeration identifiers
*/

struct param_list {
    CHUNKNUM name;
    CHUNKNUM type;
    CHUNKNUM next;
    short lineNumber;
    char unused[CHUNK_LEN - 8];
};

typedef enum {
    SYMBOL_LOCAL,
    SYMBOL_PARAM,
    SYMBOL_GLOBAL
} symbol_t;

struct symbol {
    char kind;
    CHUNKNUM nodeChunkNum;      // This node's chunknum
    CHUNKNUM type;
    CHUNKNUM name;
    CHUNKNUM decl;
    CHUNKNUM leftChild;
    CHUNKNUM rightChild;
    short which;
    short offset;           // Offset from stack frame base
    short level;            // Nesting level
    char unused[CHUNK_LEN - 19];
};

struct unit {
    char name[12 + 1];
    CHUNKNUM astRoot;
    CHUNKNUM next;
    char unused[CHUNK_LEN - 17];
};

CHUNKNUM name_clone(CHUNKNUM source);
CHUNKNUM name_create(const char* name);

CHUNKNUM declCreate(
    char kind,
    CHUNKNUM name,
    CHUNKNUM type,
    CHUNKNUM value);
CHUNKNUM stmtCreate(stmt_t kind, CHUNKNUM expr, CHUNKNUM body);
CHUNKNUM exprCreate(expr_t kind,
    CHUNKNUM left, CHUNKNUM right,
    CHUNKNUM name, TDataValue* value);
CHUNKNUM typeCreate(type_t kind, char isConst,
    CHUNKNUM subtype, CHUNKNUM params);
CHUNKNUM param_list_create(char* name, CHUNKNUM type, CHUNKNUM next);

void decl_free(CHUNKNUM chunkNum);
void expr_free(CHUNKNUM chunkNum);
void param_list_free(CHUNKNUM chunkNum);
void stmt_free(CHUNKNUM chunkNum);
void symtab_free(CHUNKNUM chunkNum);
void type_free(CHUNKNUM chunkNum);

CHUNKNUM symbol_create(symbol_t kind, CHUNKNUM type, const char* name);

void scope_enter(void);
CHUNKNUM scope_exit(void);  // Returns root of symbol table
short scope_level(void);
void free_scope_stack(void);
void init_scope_stack(void);
void scope_enter_symtab(CHUNKNUM symtab);

// Return zero if symbol already exists
char scope_bind(const char* name, struct symbol* sym, char failIfExists);
char scope_bind_symtab(const char* name, struct symbol* sym, CHUNKNUM symtab, char failIfExists);

// Look up a symbol in all scopes
char scope_lookup(const char* name, struct symbol* sym);  // 1 returned on success

// Look up a symbol in all scopes above the current scope
char scope_lookup_parent(const char* name, struct symbol* sym);  // 1 returned on success

// Look up a symbol table only in the current scope
char scope_lookup_current(const char* name, struct symbol* sym);

// Look up a symbol in the supplied symbol table
char symtab_lookup(CHUNKNUM symtab, const char* name, struct symbol* sym);

void getBaseType(struct type* pType);

#endif // end of AST_H
