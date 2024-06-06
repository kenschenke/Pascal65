/**
 * ast_free.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <ast.h>
#include <chunks.h>
#include <symtab.h>
#include <membuf.h>

void decl_free(CHUNKNUM chunkNum)
{
	struct decl _decl;

	while (chunkNum) {
		if (!isChunkAllocated(chunkNum)) {
			break;
		}

		if (!retrieveChunk(chunkNum, &_decl)) {
			return;
		}

		if (_decl.name) freeChunk(_decl.name);
		type_free(_decl.type);
		expr_free(_decl.value);
		stmt_free(_decl.code);
		symtab_free(_decl.symtab);
		symtab_free(_decl.node);

		if (isChunkAllocated(chunkNum))
			freeChunk(chunkNum);
		chunkNum = _decl.next;
	}
}

void expr_free(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		return;
	}

	if (!isChunkAllocated(chunkNum)) {
		return;
	}
	if (!retrieveChunk(chunkNum, &_expr)) {
		return;
	}

	if ((_expr.kind == EXPR_STRING_LITERAL || _expr.kind == EXPR_REAL_LITERAL) && _expr.value.stringChunkNum) {
		freeMemBuf(_expr.value.stringChunkNum);
	}

	if (_expr.name) freeChunk(_expr.name);
	expr_free(_expr.left);
	expr_free(_expr.right);
	expr_free(_expr.width);
	expr_free(_expr.precision);
	if (_expr.evalType) {
		freeChunk(_expr.evalType);
	}
	symtab_free(_expr.node);

	freeChunk(chunkNum);
}

void param_list_free(CHUNKNUM chunkNum)
{
	struct param_list param;

	while (chunkNum) {
		retrieveChunk(chunkNum, &param);

		type_free(param.type);

		if (param.name) freeChunk(param.name);

		freeChunk(chunkNum);
		chunkNum = param.next;
	}
}

void stmt_free(CHUNKNUM chunkNum)
{
	struct stmt _stmt;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_stmt);

		decl_free(_stmt.decl);
		decl_free(_stmt.interfaceDecl);
		expr_free(_stmt.expr);
		expr_free(_stmt.init_expr);
		expr_free(_stmt.to_expr);
		stmt_free(_stmt.body);
		stmt_free(_stmt.else_body);

		freeChunk(chunkNum);
		chunkNum = _stmt.next;
	}
}

void symtab_free(CHUNKNUM chunkNum)
{
	struct symbol sym;

	if (!chunkNum) {
		return;
	}

	if (!isChunkAllocated(chunkNum)) {
		return;
	}
	if (!retrieveChunk(chunkNum, &sym)) {
		return;
	}

	symtab_free(sym.leftChild);
	symtab_free(sym.rightChild);
	type_free(sym.type);

	if (sym.name && isChunkAllocated(sym.name)) freeChunk(sym.name);

	freeChunk(chunkNum);
}

void type_free(CHUNKNUM chunkNum)
{
	struct type _type;

	if (!chunkNum) {
		return;
	}

	if (!isChunkAllocated(chunkNum)) {
		return;
	}
	if (!retrieveChunk(chunkNum, &_type)) {
		return;
	}

	type_free(_type.subtype);
	type_free(_type.indextype);
	expr_free(_type.min);
	expr_free(_type.max);
	symtab_free(_type.symtab);

	if (_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE || _type.kind == TYPE_PROGRAM) {
		param_list_free(_type.paramsFields);
	}
	if (_type.kind == TYPE_RECORD || _type.kind == TYPE_ENUMERATION) {
		decl_free(_type.paramsFields);
	}

	if (_type.name) freeChunk(_type.name);
	freeChunk(chunkNum);
}
