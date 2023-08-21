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
		valueChunkNum = exprCreate(EXPR_INTEGER_LITERAL, 0, 0, 0, &value);
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
	_type.max = exprCreate(EXPR_INTEGER_LITERAL, 0, 0, 0, &constValue);
	storeChunk(typeChunkNum, &_type);

	return typeChunkNum;
}

type_t parseSubrangeLimit(CHUNKNUM name, CHUNKNUM* limit)
{
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
		if (parserType == tyInteger) {
			value.integer = sign == tcMinus ? -parserValue.integer :
				parserValue.integer;
			limitType = TYPE_INTEGER;
			*limit = exprCreate(EXPR_INTEGER_LITERAL, 0, 0, 0, &value);
		}
		else {
			Error(errInvalidSubrangeType);
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

	switch (parserToken) {
	case tcBOOLEAN:
		type = typeCreate(TYPE_BOOLEAN, 0, 0, 0);
		getToken();
		break;

	case tcCHAR:
		type = typeCreate(TYPE_CHARACTER, 0, 0, 0);
		getToken();
		break;

	case tcINTEGER:
		type = typeCreate(TYPE_INTEGER, 0, 0, 0);
		getToken();
		break;

	case tcREAL:
		type = typeCreate(TYPE_REAL, 0, 0, 0);
		getToken();
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

	case tcPlus:
	case tcMinus:
	case tcNumber:
	case tcString:
		type = parseSubrangeType(0);
		break;

	default:
		Error(errInvalidType);
		type = 0;
		break;
	}

	return type;
}
