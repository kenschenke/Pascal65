/**
 * parsrtyp1.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Parse data types
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <ast.h>
#include <common.h>
#include <string.h>

CHUNKNUM parseEnumerationType(void)
{
	TDataValue constValue;
	CHUNKNUM firstEnum = 0, thisEnum, lastEnum, valueChunkNum, typeChunkNum;
	struct decl _decl;
	struct type _type;

	constValue.integer = -1;

	getToken();
	resync(tlEnumConstStart, 0, 0);

	while (parserToken == tcIdentifier) {
		TDataValue value;

		value.integer = ++constValue.integer;
		valueChunkNum = exprCreate(EXPR_WORD_LITERAL, 0, 0, 0, &value);
		thisEnum = declCreate(DECL_TYPE, name_create(parserString), 0, valueChunkNum);

		if (firstEnum == 0) {
			firstEnum = thisEnum;
			lastEnum = firstEnum;
		}
		else {
			retrieveChunk(lastEnum, &_decl);
			_decl.next = thisEnum;
			storeChunk(lastEnum, &_decl);
			lastEnum = thisEnum;
		}

		// ,
		getToken();
		resync(tlEnumConstFollow, NULL, NULL);
		if (parserToken == tcComma) {
			// Saw comma.  Skip extra commas and look for an identifier
			do {
				getToken();
				resync(tlEnumConstStart, tlEnumConstFollow, NULL);
				if (parserToken == tcComma) Error(errMissingIdentifier);
			} while (parserToken == tcComma);
			if (parserToken != tcIdentifier) Error(errMissingIdentifier);
		}
		else if (parserToken == tcIdentifier) Error(errMissingComma);
	}

	// )
	condGetToken(tcRParen, errMissingRightParen);

	typeChunkNum = typeCreate(TYPE_ENUMERATION, 0, 0, firstEnum);
	retrieveChunk(typeChunkNum, &_type);
	_type.max = exprCreate(EXPR_WORD_LITERAL, 0, 0, 0, &constValue);
	storeChunk(typeChunkNum, &_type);

	return typeChunkNum;
}

type_t parseSubrangeLimit(CHUNKNUM name, CHUNKNUM* limit)
{
	char exprKind;
	type_t limitType = 0;
	TTokenCode sign = tcDummy;
	TDataValue value;

	if (name) {
		*limit = exprCreate(EXPR_NAME, 0, 0, name_create(parserString), 0);
		return TYPE_DECLARED;
	}

	// Unary + or -
	if (tokenIn(parserToken, tlUnaryOps)) {
		if (parserToken == tcMinus) sign = tcMinus;
		getToken();
	}

	switch (parserToken) {
	case tcNumber:
		switch (parserType) {
			case tyByte:
				value.byte = parserValue.byte;
				exprKind = EXPR_BYTE_LITERAL;
				limitType = TYPE_BYTE;
				break;
			case tyShortInt:
				value.shortInt = sign == tcMinus ? -parserValue.shortInt :
					parserValue.shortInt;
				exprKind = EXPR_BYTE_LITERAL;
				limitType = TYPE_SHORTINT;
				break;
			case tyWord:
				value.word = parserValue.word;
				exprKind = EXPR_WORD_LITERAL;
				limitType = TYPE_WORD;
				break;
			case tyInteger:
				value.integer = sign == tcMinus ? -parserValue.integer :
					parserValue.integer;
				exprKind = EXPR_WORD_LITERAL;
				limitType = TYPE_INTEGER;
				break;
			case tyCardinal:
				value.cardinal = parserValue.cardinal;
				exprKind = EXPR_DWORD_LITERAL;
				limitType = TYPE_CARDINAL;
				break;
			case tyLongInt:
				value.longInt = sign == tcMinus ? -parserValue.longInt :
					parserValue.longInt;
				exprKind = EXPR_DWORD_LITERAL;
				limitType = TYPE_LONGINT;
				break;
			default:
				Error(errInvalidSubrangeType);
				exprKind = EXPR_DWORD_LITERAL;
				limitType = TYPE_VOID;
				break;
		}
		*limit = exprCreate(exprKind, 0, 0, 0, &value);
		if (sign == tcMinus) {
			struct expr _expr;
			retrieveChunk(*limit, &_expr);
			_expr.neg = 1;
			storeChunk(*limit, &_expr);
		}
		break;

	case tcString:
		if (sign != tcDummy) {
			Error(errInvalidConstant);
		}

		if (strlen(parserString) != 3) {
			// length includes quotes
			Error(errInvalidSubrangeType);
		}

		limitType = TYPE_CHARACTER;
		value.character = parserString[1];
		*limit = exprCreate(EXPR_CHARACTER_LITERAL, 0, 0, 0, &value);
		break;

	case tcIdentifier:
		*limit = exprCreate(EXPR_NAME, 0, 0, name_create(parserString), 0);
		limitType = TYPE_DECLARED;
		break;

	default:
		Error(errMissingConstant);
		break;
	}

	getToken();

	return limitType;
}

CHUNKNUM parseSubrangeType(CHUNKNUM name)
{
	CHUNKNUM subrangeType;
	type_t minType, maxType;
	struct type _type;
	CHUNKNUM subrangeMin, subrangeMax;

	// If name is non-zero then this function was called when an identifier
	// was encountered.  The identifier is the low limit of the subrange
	// and is an enumeration value.

	// <min-const>
	minType = parseSubrangeLimit(name, &subrangeMin);

	// ..
	resync(tlSubrangeLimitFollow, tlDeclarationStart, 0);
	condGetToken(tcDotDot, errMissingDotDot);

	// <max-const>
	maxType = parseSubrangeLimit(0, &subrangeMax);

	if (minType != maxType) {
		Error(errIncompatibleTypes);
	}

	subrangeType = typeCreate(TYPE_SUBRANGE, 0, 0, 0);
	retrieveChunk(subrangeType, &_type);
	_type.min = subrangeMin;
	_type.max = subrangeMax;
	if (name) {
		_type.name = name;
	}

	// If the lower limit is a declared value (a constant),
	// look up the underlying type and use that for the
	// subrange's subtype.
	if (minType == TYPE_DECLARED) {
		char name[CHUNK_LEN + 1];
		struct expr exprType;
		struct type t;
		retrieveChunk(subrangeMin, &exprType);
		memset(name, 0, sizeof(name));
		retrieveChunk(exprType.name, name);
		_type.subtype = typeCreate(TYPE_DECLARED, 1, 0, 0);
		retrieveChunk(_type.subtype, &t);
		t.name = name_create(name);
		storeChunk(_type.subtype, &t);
	}
	else {
		_type.subtype = typeCreate(minType, 0, 0, 0);
	}
	storeChunk(subrangeType, &_type);

	return subrangeType;
}

CHUNKNUM parseTypeDefinitions(CHUNKNUM* firstDecl, CHUNKNUM lastDecl)
{
	CHUNKNUM decl;

	// Loop to parse a list of type definitions
	// separated by semicolons
	while (parserToken == tcIdentifier) {
		// <id>
		CHUNKNUM name = name_create(parserString);

		// =
		getToken();
		condGetToken(tcEqual, errMissingEqual);

		// <type>
		decl = declCreate(DECL_TYPE, name, parseTypeSpec(), 0);

		if (*firstDecl == 0) {
			*firstDecl = decl;
		}
		else {
			struct decl _decl;
			retrieveChunk(lastDecl, &_decl);
			_decl.next = decl;
			storeChunk(lastDecl, &_decl);
		}
		lastDecl = decl;

		// ;
		resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
		condGetToken(tcSemicolon, errMissingSemicolon);

		// Skip extra semicolons
		while (parserToken == tcSemicolon) getToken();
		resync(tlDeclarationFollow, tlDeclarationStart, tlStatementStart);
	}

	return lastDecl;
}

CHUNKNUM parseTypeSpec(void)
{
	CHUNKNUM name, type;
	type_t typeKind = 0;

	switch (parserToken) {
	case tcBOOLEAN:
		typeKind = TYPE_BOOLEAN;
		break;

	case tcCHAR:
		typeKind = TYPE_CHARACTER;
		break;

	case tcBYTE:
		typeKind = TYPE_BYTE;
		break;

	case tcSHORTINT:
		typeKind = TYPE_SHORTINT;
		break;

	case tcINTEGER:
		typeKind = TYPE_INTEGER;
		break;

	case tcWORD:
		typeKind = TYPE_WORD;
		break;

	case tcLONGINT:
		typeKind = TYPE_LONGINT;
		break;

	case tcCARDINAL:
		typeKind = TYPE_CARDINAL;
		break;

	case tcREAL:
		typeKind = TYPE_REAL;
		break;

	case tcSTRING:
		typeKind = TYPE_STRING_VAR;
		break;

	case tcIdentifier:
		name = name_create(parserString);
		getToken();
		if (parserToken == tcDotDot) {
			type = parseSubrangeType(name);
		}
		else {
			struct type _type;
			type = typeCreate(TYPE_DECLARED, 0, 0, 0);
			retrieveChunk(type, &_type);
			_type.name = name;
			storeChunk(type, &_type);
		}
		break;

	case tcLParen:
		type = parseEnumerationType();
		break;

	case tcARRAY:
		type = parseArrayType();
		break;

	case tcRECORD:
		type = parseRecordType();
		break;
	
	case tcFILE:
		type = parseFileType();
		break;
	
	case tcTEXT:
		typeKind = TYPE_TEXT;
		break;

	case tcPlus:
	case tcMinus:
	case tcNumber:
	case tcString:
		type = parseSubrangeType(0);
		break;

	default:
		Error(errInvalidType);
		typeKind = TYPE_VOID;
		break;
	}

	if (typeKind) {
		type = typeCreate(typeKind, 0, 0, 0);
		getToken();
	}

	return type;
}
