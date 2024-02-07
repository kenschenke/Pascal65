#include <ast.h>
#include <symtab.h>
#include <resolver.h>
#include <error.h>
#include <common.h>
#include <membuf.h>
#include <string.h>

static void addEnumsToSymtab(CHUNKNUM firstChunkNum, CHUNKNUM enumType);
static void fixGlobalOffset(CHUNKNUM symtab);
static short getSubrangeLimit(CHUNKNUM chunkNum);
static short getTypeSize(struct type* pType);
static CHUNKNUM getEmbeddedArraySymtab(CHUNKNUM chunkNum, CHUNKNUM symtab);
static CHUNKNUM getEmbeddedRecordSymtab(CHUNKNUM recordExprChunk, CHUNKNUM fieldExprChunk, CHUNKNUM symtab);
static CHUNKNUM getRecordSymtab(CHUNKNUM exprChunk, CHUNKNUM symtab);
static void injectUnit(CHUNKNUM name);
static void resolveDeclaration(CHUNKNUM chunkNum, CHUNKNUM* memBuf, CHUNKNUM *symtab, char failIfExists);
static void setUnitDecl(CHUNKNUM declChunkNum, CHUNKNUM unitChunkNum);

static void addEnumsToSymtab(CHUNKNUM chunkNum, CHUNKNUM enumType)
{
	struct symbol sym;
	CHUNKNUM valueChunkNum;
	char name[CHUNK_LEN + 1];
	struct decl _decl;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);

		memset(name, 0, sizeof(name));
		retrieveChunk(_decl.name, name);

		valueChunkNum = typeCreate(TYPE_ENUMERATION_VALUE, 1, enumType, 0);
		sym.nodeChunkNum = symbol_create(SYMBOL_LOCAL, valueChunkNum, name);
		retrieveChunk(sym.nodeChunkNum, &sym);
		sym.decl = chunkNum;
		storeChunk(sym.nodeChunkNum, &sym);
		if (!scope_bind(name, &sym, 1)) {
			freeChunk(sym.nodeChunkNum);
			freeChunk(valueChunkNum);
			freeChunk(sym.name);
		}

		chunkNum = _decl.next;
	}
}

void decl_resolve(CHUNKNUM chunkNum, CHUNKNUM* symtab)
{
	struct decl _decl;
	CHUNKNUM memBuf = 0;

	while (chunkNum) {
		resolveDeclaration(chunkNum, &memBuf, symtab, 1);
		retrieveChunk(chunkNum, &_decl);
		chunkNum = _decl.next;
	}

	// If any of the declarations could not be resolved, they are stored in
	// a temporary buffer.  Go through those again and make another attempt.
	if (memBuf) {
		setMemBufPos(memBuf, 0);
		while (!isMemBufAtEnd(memBuf)) {
			readFromMemBuf(memBuf, &chunkNum, sizeof(CHUNKNUM));
			resolveDeclaration(chunkNum, 0, symtab, 0);
		}

		freeMemBuf(memBuf);
	}
}

void expr_resolve(CHUNKNUM chunkNum, CHUNKNUM symtab, char isRtnCall)
{
	CHUNKNUM leftSymtab = 0;
	char name[CHUNK_LEN + 1];
	struct expr _expr;

	if (!chunkNum) {
		return;
	}

	// If this is a function call and the symbol
	// is the return value, need to look up the function
	// in the parent scope.

	retrieveChunk(chunkNum, &_expr);

	if (_expr.kind == EXPR_NAME) {
		struct symbol sym;

		memset(name, 0, sizeof(name));
		retrieveChunk(_expr.name, name);

		if (symtab) {
			if (!symtab_lookup(symtab, name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
		}
		else {
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
			if (isRtnCall) {
				struct type _type;
				retrieveChunk(sym.type, &_type);
				if (_type.flags & TYPE_FLAG_ISRETVAL) {
					if (!scope_lookup_parent(name, &sym)) {
						Error(errUndefinedIdentifier);
						return;
					}
				}
			}
		}

		_expr.node = sym.nodeChunkNum;
		storeChunk(chunkNum, &_expr);
	}
	else {
		// If this is a EXPR_FIELD we need to resolve the right child using
		// the record's symbol table instead of the scope stack.
		if (_expr.kind == EXPR_FIELD) {
			leftSymtab = getRecordSymtab(_expr.left, symtab);
		}

		expr_resolve(_expr.left, symtab, _expr.kind == EXPR_CALL ? 1 : 0);
		expr_resolve(_expr.right, leftSymtab, 0);
	}
}

static void fixGlobalOffset(CHUNKNUM symtab)
{
	struct decl _decl;
	struct type _type;
	struct symbol sym, unitSym;

	if (!symtab) {
		return;
	}

	retrieveChunk(symtab, &sym);
	retrieveChunk(sym.decl, &_decl);
	if (_decl.type) {
		retrieveChunk(_decl.type, &_type);
		if (_type.kind != TYPE_FUNCTION && _type.kind != TYPE_PROCEDURE &&
			sym.offset == 0 && sym.level == 0) {
			char name[CHUNK_LEN + 1];
			CHUNKNUM chunkNum = units;
			struct unit _unit;

			memset(name, 0, sizeof(name));
			retrieveChunk(sym.name, name);
			while (chunkNum) {
				retrieveChunk(chunkNum, &_unit);
				retrieveChunk(_unit.astRoot, &_decl);
				if (symtab_lookup(_decl.symtab, name, &unitSym)) {
					sym.level = unitSym.level;
					sym.offset = unitSym.offset;
					storeChunk(sym.nodeChunkNum, &sym);
					break;
				}

				chunkNum = _unit.next;
			}
		}
	}

	fixGlobalOffset(sym.leftChild);
	fixGlobalOffset(sym.rightChild);
}

/*
* This function fixes offsets for unit interface variables that been injected
* into the global namespace.  Since these injected symbol table entries were
* done without a declaration, their offsets are set by set_decl_offsets().
* 
* This function walks the global symbol table and if it finds any symbols
* with level and offset values of 0 it looks through the units for any
* matching variables in the interface declaration.  If it finds a match
* it updates the offset and level.
*/
void fix_global_offsets(CHUNKNUM astRoot)
{
	struct decl _decl;

	retrieveChunk(astRoot, &_decl);
	fixGlobalOffset(_decl.symtab);
}

// This function looks up the symbol table of a record within an array
static CHUNKNUM getEmbeddedArraySymtab(CHUNKNUM chunkNum, CHUNKNUM symtab)
{
	struct expr leftExpr;
	struct symbol sym;
	struct type _type;
	char name[CHUNK_LEN + 1];

	retrieveChunk(chunkNum, &leftExpr);
	if (leftExpr.kind == EXPR_FIELD) {
		return getRecordSymtab(chunkNum, symtab);
	}

	memset(name, 0, sizeof(name));
	retrieveChunk(leftExpr.name, name);
	if (symtab) {
		if (!symtab_lookup(symtab, name, &sym)) {
			Error(errUndefinedIdentifier);
			return 0;
		}
	}
	else {
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			return 0;
		}
	}
	retrieveChunk(sym.type, &_type);
	retrieveChunk(_type.subtype, &_type);
	if (_type.kind == TYPE_DECLARED) {
		memset(name, 0, sizeof(name));
		retrieveChunk(_type.name, name);
		if (symtab) {
			if (!symtab_lookup(symtab, name, &sym)) {
				Error(errUndefinedIdentifier);
				return 0;
			}
		}
		else {
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return 0;
			}
		}
		retrieveChunk(sym.type, &_type);
	}

	return _type.symtab;
}

// This function looks up the symbol table for a record within a record.
static CHUNKNUM getEmbeddedRecordSymtab(CHUNKNUM recExprChunk, CHUNKNUM fieldExprChunk, CHUNKNUM symtab)
{
	CHUNKNUM childSymtab;
	struct expr _expr;
	struct symbol sym;
	struct type _type;
	char name[CHUNK_LEN + 1];

	retrieveChunk(fieldExprChunk, &_expr);
	memset(name, 0, sizeof(name));
	retrieveChunk(_expr.name, name);
	childSymtab = getRecordSymtab(recExprChunk, symtab);
	if (!symtab_lookup(childSymtab, name, &sym)) {
		Error(errUndefinedIdentifier);
		return 0;
	}

	retrieveChunk(sym.type, &_type);
	if (_type.kind == TYPE_ARRAY) {
		retrieveChunk(_type.subtype, &_type);
	}

	if (_type.kind == TYPE_DECLARED) {
		memset(name, 0, sizeof(name));
		retrieveChunk(_type.name, name);
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			return 0;
		}
		retrieveChunk(sym.type, &_type);
	}

	return _type.symtab;
}

static CHUNKNUM getRecordSymtab(CHUNKNUM exprChunk, CHUNKNUM symtab)
{
	struct symbol sym;
	char name[CHUNK_LEN + 1];
	struct expr _expr;
	struct type _type;

	retrieveChunk(exprChunk, &_expr);

	if (_expr.kind == EXPR_FIELD) {
		return getEmbeddedRecordSymtab(_expr.left, _expr.right, symtab);
	}

	if (_expr.kind == EXPR_SUBSCRIPT) {
		return getEmbeddedArraySymtab(_expr.left, symtab);
	}

	if (!_expr.name) {
		return 0;
	}

	memset(name, 0, sizeof(name));
	retrieveChunk(_expr.name, name);

	if (symtab) {
		if (!symtab_lookup(symtab, name, &sym)) {
			Error(errUndefinedIdentifier);
			return 0;
		}
	}
	else {
		if (!scope_lookup(name, &sym)) {
			Error(errUndefinedIdentifier);
			return 0;
		}
	}

	retrieveChunk(sym.type, &_type);
	while (_type.kind == TYPE_DECLARED || _type.kind == TYPE_ARRAY) {
		if (_type.kind == TYPE_DECLARED && !_type.subtype && _type.name) {
			memset(name, 0, sizeof(name));
			retrieveChunk(_type.name, name);
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return 0;
			}
			retrieveChunk(sym.type, &_type);
		}
		else {
			retrieveChunk(_type.subtype, &_type);
		}
	}
	if (_type.kind != TYPE_RECORD) {
		Error(errInvalidIdentifierUsage);
		return 0;
	}

	return _type.symtab;
}

static short getSubrangeLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);

	if (_expr.kind == EXPR_BYTE_LITERAL) {
		if (_expr.neg) {
			return -_expr.value.shortInt;
		}
		return _expr.value.byte;
	}
	if (_expr.kind == EXPR_WORD_LITERAL) {
		if (_expr.neg) {
			return -_expr.value.integer;
		}
		return _expr.value.word;
	}
	if (_expr.kind == EXPR_CHARACTER_LITERAL) {
		return (short)_expr.value.character;
	}
	if (_expr.kind == EXPR_NAME) {
		char name[CHUNK_LEN + 1];
		struct symbol sym;
		struct decl _decl;
		retrieveChunk(_expr.name, name);
		if (!scope_lookup(name, &sym)) {
			return 0;
		}
		retrieveChunk(sym.decl, &_decl);
		return getSubrangeLimit(_decl.value);
	}

	return 0;
}

static short getTypeSize(struct type* pType)
{
	short size = 0;

	switch (pType->kind) {
	case TYPE_BOOLEAN: size = sizeof(short); break;
	case TYPE_SHORTINT:
	case TYPE_BYTE:
	case TYPE_CHARACTER: size = sizeof(char); break;
	case TYPE_INTEGER:
	case TYPE_WORD: size = sizeof(short); break;
	case TYPE_REAL: size = sizeof(FLOAT); break;
	case TYPE_LONGINT:
	case TYPE_CARDINAL: size = sizeof(long); break;
	case TYPE_ENUMERATION:
	case TYPE_ENUMERATION_VALUE:
		size = sizeof(short);
		break;
	case TYPE_STRING_LITERAL: size = sizeof(CHUNKNUM); break;

	case TYPE_ARRAY: {
		struct type _type, indexType;
		short min = 0, max = 0;
		retrieveChunk(pType->subtype, &_type);
		retrieveChunk(pType->indextype, &indexType);
		if (indexType.kind == TYPE_DECLARED) {
			struct symbol sym;
			char name[CHUNK_LEN + 1];
			memset(name, 0, sizeof(name));
			retrieveChunk(indexType.name, name);
			if (scope_lookup(name, &sym)) {
				struct type symType;
				retrieveChunk(sym.type, &symType);
				if (symType.kind == TYPE_ENUMERATION) {
					min = 0;
					max = getSubrangeLimit(symType.max);
				}
				else if (symType.kind == TYPE_SUBRANGE) {
					min = getSubrangeLimit(symType.min);
					max = getSubrangeLimit(symType.max);
				}
				symType.size = getTypeSize(&symType);
				storeChunk(sym.type, &symType);
			}
		}
		else {
			min = getSubrangeLimit(indexType.min);
			max = getSubrangeLimit(indexType.max);
		}
		_type.size = getTypeSize(&_type);
		storeChunk(pType->subtype, &_type);
		indexType.size = getTypeSize(&indexType);
		storeChunk(pType->indextype, &indexType);
		size = _type.size * (max - min + 1) + sizeof(short) * 3;
		break;
	}

	case TYPE_SUBRANGE: {
		struct type _type;
		retrieveChunk(pType->subtype, &_type);
		size = _type.size = getTypeSize(&_type);
		storeChunk(pType->subtype, &_type);
		break;
	}

	case TYPE_RECORD: {
		struct decl _decl;
		struct type _type;
		CHUNKNUM chunkNum = pType->paramsFields;
		while (chunkNum) {
			retrieveChunk(chunkNum, &_decl);
			retrieveChunk(_decl.type, &_type);
			size += getTypeSize(&_type);
			chunkNum = _decl.next;
		}
		break;
	}

	case TYPE_DECLARED: {
		struct symbol sym;
		struct type symType;
		char name[CHUNK_LEN + 1];
		memset(name, 0, sizeof(name));
		retrieveChunk(pType->name, name);
		if (scope_lookup(name, &sym)) {
			retrieveChunk(sym.type, &symType);
			size = getTypeSize(&symType);
		}
		else {
			size = 0;
		}
		break;
	}

	case TYPE_FUNCTION: {
		struct type subtype;
		retrieveChunk(pType->subtype, &subtype);
		subtype.size = getTypeSize(&subtype);
		storeChunk(pType->subtype, &subtype);
		break;
	}
	}

	return size;
}

/*
*	This function injects a unit's interface declarations into the current
*	scope.  It does this by looping through the unit's interface symbol table
*	and looking up the corresponding entry in the unit's implementation
*	symbol table then adding those into the current scope's symbol table.
*/
static void injectUnit(CHUNKNUM nameChunk)
{
	CHUNKNUM declChunkNum, symChunkNum;
	struct unit _unit;
	char name[CHUNK_LEN + 1];
	struct stmt _stmt;
	struct type _type;
	struct symbol sym, newSym;
	struct decl usesDecl, _decl, symDecl;

	if (!findUnit(nameChunk, &_unit)) {
		return;
	}
	retrieveChunk(_unit.astRoot, &usesDecl);

	retrieveChunk(usesDecl.code, &_stmt);

	declChunkNum = _stmt.interfaceDecl;
	while (declChunkNum) {
		retrieveChunk(declChunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);
		memset(name, 0, sizeof(name));
		retrieveChunk(_decl.name, name);
		if (!symtab_lookup(usesDecl.symtab, name, &sym)) {
			Error(errMissingUnitDeclaration);
		}
		else {
			symChunkNum = symbol_create(SYMBOL_GLOBAL, sym.type, name);
			retrieveChunk(symChunkNum, &newSym);
			retrieveChunk(sym.decl, &symDecl);
			symDecl.isLibrary = usesDecl.isLibrary;
			storeChunk(sym.decl, &symDecl);
			newSym.decl = sym.decl;
			storeChunk(symChunkNum, &newSym);
			scope_bind(name, &newSym, 1);

			if (_type.kind == TYPE_ENUMERATION) {
				addEnumsToSymtab(_type.paramsFields, _decl.type);
			}
		}

		declChunkNum = _decl.next;
	}
}

void param_list_resolve(CHUNKNUM chunkNum)
{
	char name[CHUNK_LEN + 1];
	struct param_list param;
	struct symbol sym;
	struct type _type;
	CHUNKNUM symChunk;
	short offset = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &param);

		memset(name, 0, sizeof(name));
		retrieveChunk(param.name, name);

		retrieveChunk(param.type, &_type);
		_type.size = getTypeSize(&_type);
		storeChunk(param.type, &_type);

		symChunk = symbol_create(SYMBOL_LOCAL, param.type, name);
		retrieveChunk(symChunk, &sym);
		sym.offset = offset++;
		sym.level = scope_level();
		storeChunk(symChunk, &sym);
		scope_bind(name, &sym, 1);

		chunkNum = param.next;
	}
}

void resolve_units(void)
{
	struct decl _decl;
	struct stmt _stmt;
	struct unit _unit;
	CHUNKNUM chunkNum = units;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);

		decl_resolve(_unit.astRoot, 0);

		retrieveChunk(_unit.astRoot, &_decl);
		retrieveChunk(_decl.code, &_stmt);
		setUnitDecl(_stmt.decl, _decl.symtab);

		chunkNum = _unit.next;
	}
}

static void resolveDeclaration(CHUNKNUM chunkNum, CHUNKNUM* memBuf, CHUNKNUM *symtab, char failIfExists)
{
	char name[CHUNK_LEN + 1];
	struct decl _decl;
	struct type _type;
	struct symbol sym;
	symbol_t kind;

	retrieveChunk(chunkNum, &_decl);
	currentLineNumber = _decl.lineNumber;
	retrieveChunk(_decl.type, &_type);
	memset(name, 0, sizeof(name));
	if (_decl.name) {
		retrieveChunk(_decl.name, name);
		kind = scope_level() > 1 ? SYMBOL_LOCAL : SYMBOL_GLOBAL;

		if ((_type.kind == TYPE_PROCEDURE || _type.kind == TYPE_FUNCTION) &&
			scope_lookup(name, &sym)) {
			// Forward declaration : nothing to do.
			if (_decl.code) {
				sym.decl = chunkNum;
				storeChunk(sym.nodeChunkNum, &sym);
				_decl.node = sym.nodeChunkNum;
				storeChunk(chunkNum, &_decl);
			}
		}
		else if (_type.kind == TYPE_UNIT) {
			// Unit declaration: nothing to do.
		}
		else {
			_decl.node = symbol_create(kind, _decl.type, name);
			retrieveChunk(_decl.node, &sym);
			sym.decl = chunkNum;
			if (symtab) {
				if (*symtab) {
					scope_bind_symtab(name, &sym, *symtab, failIfExists);
				}
				else {
					*symtab = _decl.node;
				}
			}
			else {
				scope_bind(name, &sym, failIfExists);
			}
			storeChunk(_decl.node, &sym);
		}
	}

	if (_type.kind == TYPE_RECORD && _type.symtab == 0) {
		struct decl fieldDecl;
		struct symbol fieldSymbol;
		struct type fieldType;
		CHUNKNUM fieldChunk;
		short offset = 0;

		decl_resolve(_type.paramsFields, &_type.symtab);
		fieldChunk = _type.paramsFields;
		while (fieldChunk) {
			retrieveChunk(fieldChunk, &fieldDecl);
			retrieveChunk(fieldDecl.node, &fieldSymbol);
			retrieveChunk(fieldDecl.type, &fieldType);
			fieldSymbol.offset = offset;
			storeChunk(fieldDecl.node, &fieldSymbol);

			offset += fieldType.size;
			fieldChunk = fieldDecl.next;
		}
	}
	if (_type.kind == TYPE_ENUMERATION) {
		if (_type.name) {
			struct type t;
			memset(name, 0, sizeof(name));
			retrieveChunk(_type.name, name);
			if (!scope_lookup(name, &sym)) {
				Error(errInvalidType);
			}
			retrieveChunk(sym.type, &t);
			_type.paramsFields = t.paramsFields;
		}
		else {
			addEnumsToSymtab(_type.paramsFields, _decl.type);
		}
	}

	if (_type.kind == TYPE_DECLARED) {
		struct symbol declSym;
		memset(name, 0, sizeof(name));
		retrieveChunk(_type.name, name);
		if (!scope_lookup(name, &declSym)) {
			if (!memBuf) {
				Error(errInvalidType);
			}
			else {
				if (!(*memBuf)) {
					allocMemBuf(memBuf);
				}
				writeToMemBuf(*memBuf, &chunkNum, sizeof(CHUNKNUM));
				return;
			}
		}
		else {
			CHUNKNUM name = _type.name;
			char typeFlags = _type.flags;
			retrieveChunk(declSym.type, &_type);
			if (_type.kind == TYPE_ENUMERATION) {
				_type.subtype = declSym.type;
			}
			_type.name = name;
			_type.flags = typeFlags;
		}
	}

	// Make sure the array indextype is 1 or 2 bytes
	if (_type.kind == TYPE_ARRAY) {
		struct type indextype;
		retrieveChunk(_type.indextype, &indextype);
		if (getTypeSize(&indextype) > 2) {
			Error(errInvalidIndexType);
		}
	}

	_type.size = getTypeSize(&_type);
	storeChunk(_decl.type, &_type);

	expr_resolve(_decl.value, 0, 0);

	if (_decl.kind == DECL_USES) {
		// Inject the unit's interface declarations into the current scope
		injectUnit(_decl.name);
	}

	if (_decl.code) {
		scope_enter();
		if (_type.kind != TYPE_PROGRAM) {
			param_list_resolve(_type.paramsFields);
		}
		stmt_resolve(_decl.code);
		_decl.symtab = scope_exit();
	}

	storeChunk(chunkNum, &_decl);
}

short set_decl_offsets(CHUNKNUM chunkNum, short offset, short level)
{
	struct decl _decl;
	struct type _type;
	struct stmt _stmt;
	struct symbol sym;
	struct unit _unit;
	struct param_list param;
	CHUNKNUM paramChunk, rootChunk = chunkNum;
	short childOffset;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		if (_type.kind == TYPE_PROGRAM) {
			retrieveChunk(_decl.code, &_stmt);
			offset += set_decl_offsets(_stmt.decl, 0, level + 1);
		}
		else if (_type.kind == TYPE_UNIT) {
			struct decl unitDecl;
			findUnit(_decl.name, &_unit);
			retrieveChunk(_unit.astRoot, &unitDecl);
			retrieveChunk(unitDecl.code, &_stmt);
			childOffset = set_decl_offsets(_stmt.decl, offset, level + 1);
			set_decl_offsets(_stmt.interfaceDecl, childOffset, level + 1);
		}
		else if ((_type.kind == TYPE_FUNCTION || _type.kind == TYPE_PROCEDURE)
			&& !(_type.flags & TYPE_FLAG_ISFORWARD)) {
			childOffset = 0;
			paramChunk = _type.paramsFields;
			while (paramChunk) {
				retrieveChunk(paramChunk, &param);
				++childOffset;
				paramChunk = param.next;
			}

			if (_decl.node) {
				retrieveChunk(_decl.node, &sym);
				sym.level = level + 1;
				storeChunk(_decl.node, &sym);
			}

			retrieveChunk(_decl.code, &_stmt);
			set_decl_offsets(_stmt.decl, childOffset, level + 1);
		}
		else {
			switch (_type.kind) {
			case TYPE_BOOLEAN:
			case TYPE_CHARACTER:
			case TYPE_BYTE:
			case TYPE_SHORTINT:
			case TYPE_INTEGER:
			case TYPE_WORD:
			case TYPE_LONGINT:
			case TYPE_CARDINAL:
			case TYPE_ENUMERATION:
			case TYPE_REAL:
			case TYPE_STRING_LITERAL:
			case TYPE_STRING_VAR:
			case TYPE_ARRAY:
			case TYPE_DECLARED:
			case TYPE_RECORD:
			case TYPE_SUBRANGE:
				retrieveChunk(_decl.node, &sym);
				if (_decl.kind == DECL_CONST || _decl.kind == DECL_VARIABLE) {
					sym.offset = offset++;
				}
				sym.level = level;
				storeChunk(_decl.node, &sym);
				break;
			}
		}

		chunkNum = _decl.next;
	}

	return offset;
}

static void setUnitDecl(CHUNKNUM declChunkNum, CHUNKNUM unitSymtab)
{
	struct decl _decl;
	while (declChunkNum) {
		retrieveChunk(declChunkNum, &_decl);
		_decl.unitSymtab = unitSymtab;
		storeChunk(declChunkNum, &_decl);

		declChunkNum = _decl.next;
	}
}

void set_unit_offsets(CHUNKNUM firstUnit, short rootOffset)
{
	struct unit _unit;
	CHUNKNUM chunkNum = firstUnit;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_unit);
		rootOffset = set_decl_offsets(_unit.astRoot, rootOffset, 0);
		chunkNum = _unit.next;
	}
}

void stmt_resolve(CHUNKNUM chunkNum)
{
	struct stmt _stmt;

	if (!chunkNum) {
		return;
	}

	while (chunkNum) {
		retrieveChunk(chunkNum, &_stmt);
		currentLineNumber = _stmt.lineNumber;

		if (_stmt.kind == STMT_CASE_LABEL) {
			struct stmt labelStmt;
			CHUNKNUM exprChunkNum;
			struct expr _expr;

			CHUNKNUM labelChunkNum = _stmt.body;
			while (labelChunkNum) {
				retrieveChunk(labelChunkNum, &labelStmt);
				expr_resolve(labelStmt.expr, 0, 0);
				stmt_resolve(labelStmt.body);

				labelChunkNum = labelStmt.next;
			}

			exprChunkNum = _stmt.expr;
			while (exprChunkNum) {
				retrieveChunk(exprChunkNum, &_expr);
				expr_resolve(exprChunkNum, 0, 0);
				exprChunkNum = _expr.right;
			}
		}
		else {
			decl_resolve(_stmt.interfaceDecl, NULL);
			decl_resolve(_stmt.decl, NULL);
			expr_resolve(_stmt.expr, 0, 0);
			expr_resolve(_stmt.init_expr, 0, 0);
			expr_resolve(_stmt.to_expr, 0, 0);
			stmt_resolve(_stmt.body);
			stmt_resolve(_stmt.else_body);
		}

		chunkNum = _stmt.next;
	}
}
