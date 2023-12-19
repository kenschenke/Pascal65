#include <parser.h>
#include <ast.h>
#include <common.h>

CHUNKNUM parseActualParm(char isWriteWriteln)
{
	// Create a new expr node.  The left is an expression tree and
	// the right is zero.  The type is EXPR_ARG.

	CHUNKNUM exprChunk = exprCreate(EXPR_ARG, parseExpression(), 0, 0, 0);

	if (isWriteWriteln && parserToken == tcColon) {
		struct expr _expr;

		retrieveChunk(exprChunk, &_expr);
		getToken();
		_expr.width = parseExpression();

		if (parserToken == tcColon) {
			getToken();
			_expr.precision = parseExpression();
		}

		storeChunk(exprChunk, &_expr);
	}

	return exprChunk;
}

CHUNKNUM parseActualParmList(char isWriteWriteln)
{
	struct expr _expr;
	CHUNKNUM argChunk, firstArg = 0, lastArg = 0;

	do {
		getToken();

		if (parserToken == tcRParen) {
			break;
		}

		argChunk = parseActualParm(isWriteWriteln);
		if (!firstArg) {
			firstArg = argChunk;
		}
		else {
			retrieveChunk(lastArg, &_expr);
			_expr.right = argChunk;
			storeChunk(lastArg, &_expr);
		}
		lastArg = argChunk;
	} while (parserToken == tcComma);

	if (parserToken == tcRParen) {
		getToken();
	}
	else {
		Error(errMissingRightParen);
	}

	return firstArg;
}

CHUNKNUM parseFormalParmList(void)
{
	char isByRef;
	struct param_list param;
	struct type _type;
	CHUNKNUM paramType;
	// These are the complete list of subroutine parameters
	CHUNKNUM firstParam = 0, lastParam = 0, paramChunk;
	// These are the parameters in the current sublist
	// comma separated with the same type
	CHUNKNUM firstId, lastId;

	getToken();

	// Loop to parse parameter declarations separated by semicolons
	// i, j, k : integer; a, b, c : character, r, s, t: real
	while (parserToken == tcIdentifier || parserToken == tcVAR) {
		if (parserToken == tcVAR) {
			isByRef = 1;
			getToken();
		}
		else {
			isByRef = 0;
		}

		// Loop to parse the comma-separated sublist of parameter ids
		firstId = lastId = 0;
		while (parserToken == tcIdentifier) {
			paramChunk = param_list_create(parserString, 0, 0);
			if (firstId) {
				retrieveChunk(lastId, &param);
				param.next = paramChunk;
				storeChunk(lastId, &param);
			}
			else {
				firstId = paramChunk;
			}
			lastId = paramChunk;

			// comma
			getToken();
			resync(tlIdentifierFollow, 0, 0);
			if (parserToken == tcComma) {
				// Saw comma.
				// Skip extra commas and look for an identifier.
				do {
					getToken();
					resync(tlIdentifierStart, tlIdentifierFollow, 0);
					if (parserToken == tcComma) {
						Error(errMissingIdentifier);
					}
				} while (parserToken == tcComma);
				if (parserToken != tcIdentifier) {
					Error(errMissingIdentifier);
				}
			}
			else if (parserToken == tcIdentifier) {
				Error(errMissingComma);
			}
		}

		// colon
		resync(tlSublistFollow, tlDeclarationFollow, 0);
		condGetToken(tcColon, errMissingColon);

		// <id-type>
		if (parserToken == tcIdentifier) {
			paramType = typeCreate(TYPE_DECLARED, 0, 0, 0);
			retrieveChunk(paramType, &_type);
			_type.name = name_create(parserString);
			if (isByRef) {
				_type.flags |= TYPE_FLAG_ISBYREF;
			}
			else {
				_type.flags &= ~TYPE_FLAG_ISBYREF;
			}
			storeChunk(paramType, &_type);
			getToken();
		}
		else if (parserToken == tcARRAY) {
			paramType = parseArrayType();
			retrieveChunk(paramType, &_type);
			if (isByRef) {
				_type.flags |= TYPE_FLAG_ISBYREF;
			}
			else {
				_type.flags &= ~TYPE_FLAG_ISBYREF;
			}
			storeChunk(paramType, &_type);
		}
		else {
			type_t tc = 0;
			switch (parserToken) {
			case tcBOOLEAN: tc = TYPE_BOOLEAN; break;
			case tcCHAR: tc = TYPE_CHARACTER; break;
			case tcBYTE: tc = TYPE_BYTE; break;
			case tcSHORTINT: tc = TYPE_SHORTINT; break;
			case tcWORD: tc = TYPE_WORD; break;
			case tcINTEGER: tc = TYPE_INTEGER; break;
			case tcCARDINAL: tc = TYPE_CARDINAL; break;
			case tcLONGINT: tc = TYPE_LONGINT; break;
			case tcREAL: tc = TYPE_REAL; break;
			default:
				Error(errInvalidType);
				break;
			}
			paramType = typeCreate(tc, 0, 0, 0);
			retrieveChunk(paramType, &_type);
			if (isByRef) {
				_type.flags |= TYPE_FLAG_ISBYREF;
			}
			else {
				_type.flags &= ~TYPE_FLAG_ISBYREF;
			}
			storeChunk(paramType, &_type);
			getToken();
		}

		// Loop to assign the offset and type to each
		// parm id in the sublist.
		for (paramChunk = firstId; paramChunk; paramChunk = param.next) {
			retrieveChunk(paramChunk, &param);
			param.type = paramType;
			storeChunk(paramChunk, &param);
		}

		// Link this sublist to the previous sublist
		if (firstParam) {
			retrieveChunk(lastParam, &param);
			param.next = firstId;
			storeChunk(lastParam, &param);
		}
		else {
			firstParam = firstId;
		}
		lastParam = lastId;

		// Semicolon or )
		resync(tlFormalParmsFollow, tlDeclarationFollow, 0);
		if (parserToken == tcIdentifier || parserToken == tcVAR) {
			Error(errMissingSemicolon);
		}
		else {
			while (parserToken == tcSemicolon) {
				getToken();
			}
		}
	}

	// right paren
	condGetToken(tcRParen, errMissingRightParen);

	return firstParam;
}

CHUNKNUM parseSubroutineCall(CHUNKNUM name, char isWriteWriteln)
{
	return exprCreate(EXPR_CALL, exprCreate(EXPR_NAME, 0, 0, name, 0),
		parserToken == tcLParen ? parseActualParmList(isWriteWriteln) : 0, 0, 0);
}

