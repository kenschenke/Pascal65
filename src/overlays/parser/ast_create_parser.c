/**
 * ast_create_parser.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * AST creation routines for parser
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <ast.h>
#include <string.h>
#include <common.h>

CHUNKNUM declCreate(
    char kind,
    CHUNKNUM name,
    CHUNKNUM type,
    CHUNKNUM value)
{
    CHUNKNUM chunkNum;
    struct decl decl;

    allocChunk(&chunkNum);

    memset(&decl, 0, sizeof(struct decl));

    decl.kind = kind;
    decl.name = name;
    decl.type = type;
    decl.value = value;
    decl.lineNumber = currentLineNumber;

    storeChunk(chunkNum, (unsigned char*)&decl);

    return chunkNum;
}

CHUNKNUM stmtCreate(stmt_t kind, CHUNKNUM expr, CHUNKNUM body)
{
    CHUNKNUM chunkNum;
    struct stmt stmt;

    allocChunk(&chunkNum);

    memset(&stmt, 0, sizeof(struct stmt));

    stmt.kind = kind;
    stmt.expr = expr;
    stmt.body = body;
    stmt.lineNumber = currentLineNumber;

    storeChunk(chunkNum, (unsigned char*)&stmt);

    return chunkNum;
}

CHUNKNUM exprCreate(expr_t kind,
    CHUNKNUM left, CHUNKNUM right,
    CHUNKNUM name, TDataValue* value)
{
    CHUNKNUM chunkNum;
    struct expr expr;

    allocChunk(&chunkNum);

    memset(&expr, 0, sizeof(struct expr));

    expr.kind = kind;
    expr.left = left;
    expr.right = right;
    expr.name = name;
    expr.lineNumber = currentLineNumber;
    if (value) memcpy(&expr.value, value, sizeof(TDataValue));

    storeChunk(chunkNum, &expr);

    return chunkNum;
}

CHUNKNUM param_list_create(char* name, CHUNKNUM type, CHUNKNUM next)
{
    CHUNKNUM chunkNum;
    struct param_list param_list;

    allocChunk(&chunkNum);

    param_list.name = name_create(name);
    param_list.type = type;
    param_list.next = next;
    param_list.lineNumber = currentLineNumber;

    storeChunk(chunkNum, (unsigned char*)&param_list);

    return chunkNum;
}

