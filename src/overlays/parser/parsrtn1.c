/**
 * parsrtn1.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Parse routines
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <parser.h>
#include <ast.h>
#include <common.h>
#include <misc.h>
#include <string.h>
#include <parscommon.h>

CHUNKNUM parseBlock(char isProgramOrUnitBlock, char *isLibrary)
{
	char dummy;
	struct stmt _stmt;
	CHUNKNUM stmtChunk, body = 0;
	CHUNKNUM interfaceDecl = 0, decl = parseDeclarations(isProgramOrUnitBlock);

	// So callers can pass NULL for second parameter
	if (isLibrary == 0) {
		isLibrary = &dummy;
	}

	*isLibrary = 0;

	if (isProgramOrUnitBlock && isInUnitInterface) {
		if (parserToken != tcIMPLEMENTATION) {
			Error(errMissingIMPLEMENTATION);
		}
		isInUnitInterface = 0;
		interfaceDecl = decl;
		getToken();
		if (!stricmp(parserString, "library")) {
			getToken();
			*isLibrary = 1;
			decl = 0;
		} else {
			decl = parseDeclarations(1);
		}
	}

	if (!(*isLibrary)) {
		if (parserModuleType == TYPE_UNIT && parserToken == tcEND) {
			body = 0;
		} else {
			resync(tlStatementStart, 0, 0);
			if (parserToken != tcBEGIN) Error(errMissingBEGIN);
			body = parseCompound();
		}
	}

	stmtChunk = stmtCreate(STMT_BLOCK, 0, body);
	retrieveChunk(stmtChunk, &_stmt);
	_stmt.decl = decl;
	_stmt.interfaceDecl = interfaceDecl;
	storeChunk(stmtChunk, &_stmt);
	return stmtChunk;
}

CHUNKNUM parseFuncOrProcHeader(char isFunc)
{
	struct type _type;
	CHUNKNUM name = 0, params = 0, returnChunk = 0;

	getToken();

	// <id>
	if (parserToken == tcIdentifier) {
		name = name_create(parserString);
		getToken();
	}
	else {
		Error(errMissingIdentifier);
	}

	// ( or : or ;
	resync(isFunc ? tlFuncIdFollow : tlProgProcIdFollow,
		tlDeclarationStart, tlStatementStart);

	// Optional (<id-list>)
	if (parserToken == tcLParen) {
		params = parseFormalParmList();
	}

	if (isFunc) {
		if (parserToken == tcColon) {
			getToken();
			if (parserToken == tcIdentifier) {
				// The return type must be a declared type
				returnChunk = typeCreate(TYPE_DECLARED, 0, 0, 0);
				retrieveChunk(returnChunk, &_type);
				_type.name = name_create(parserString);
				storeChunk(returnChunk, &_type);
			}
			else {
				// The return type should be one of the pre-defined Pascal types.
				type_t type = 0;
				switch (parserToken) {
				case tcBYTE: type = TYPE_BYTE; break;
				case tcSHORTINT: type = TYPE_SHORTINT; break;
				case tcBOOLEAN: type = TYPE_BOOLEAN; break;
				case tcCHAR: type = TYPE_CHARACTER; break;
				case tcWORD: type = TYPE_WORD; break;
				case tcINTEGER: type = TYPE_INTEGER; break;
				case tcLONGINT: type = TYPE_LONGINT; break;
				case tcCARDINAL: type = TYPE_CARDINAL; break;
				case tcREAL: type = TYPE_REAL; break;
				case tcSTRING: type = TYPE_STRING_VAR; break;
				default:
					Error(errIncompatibleTypes);
				}
				returnChunk = typeCreate(type, 0, 0, 0);
			}

			getToken();
		}
		else {
			Error(errMissingColon);
		}
	}

	return declCreate(DECL_TYPE, name,
		typeCreate(isFunc ? TYPE_FUNCTION : TYPE_PROCEDURE, 0, returnChunk, params),
		0);
}

CHUNKNUM parseSubroutine(void)
{
	CHUNKNUM subChunk;
	struct decl _decl;
	struct type _type;
	char isFunc;

	// <routine-header>
	isFunc = parserToken == tcFUNCTION;
	subChunk = parseFuncOrProcHeader(isFunc);

	// ;
	resync(tlHeaderFollow, tlDeclarationStart, tlStatementStart);
	if (parserToken == tcSemicolon) {
		getToken();
	}
	else if (tokenIn(parserToken, tlDeclarationStart) ||
		tokenIn(parserToken, tlStatementStart)) {
		Error(errMissingSemicolon);
	}

	retrieveChunk(subChunk, &_decl);

	_type.flags = 0;
	// <block> or forward
	if (isInUnitInterface || !stricmp(parserString, "forward")) {
		if (!isInUnitInterface) {
			getToken();
		}
		retrieveChunk(_decl.type, &_type);
		_type.flags |= TYPE_FLAG_ISFORWARD;
		storeChunk(_decl.type, &_type);
	} else {
		// Not a forward declaration
		_decl.code = parseBlock(0, 0);
		storeChunk(subChunk, &_decl);
	}

	// If a function, add a variable to the function's local scope for the
	// return value.

	if (isFunc && !(_type.flags & TYPE_FLAG_ISFORWARD)) {
		char name[CHUNK_LEN + 1];
		CHUNKNUM declChunk, retDeclChunk, retnTypeChunk;
		struct stmt _stmt;
		struct decl subDecl;
		struct type retnType;
		retrieveChunk(_decl.code, &_stmt);

		// Create a new declaration for the return variable
		retrieveChunk(_decl.name, name);
		retrieveChunk(_decl.type, &_type);
		retrieveChunk(_type.subtype, &_type);
		retnTypeChunk = typeCreate(_type.kind, 0, _type.subtype, 0);
		retrieveChunk(retnTypeChunk, &retnType);
		retnType.flags = TYPE_FLAG_ISRETVAL;
		retnType.name = _type.name == 0 ? 0 : name_clone(_type.name);
		storeChunk(retnTypeChunk, &retnType);
		retDeclChunk = declCreate(DECL_VARIABLE, name_create(name), retnTypeChunk, 0);

		if (_stmt.decl == 0) {
			_stmt.decl = retDeclChunk;
			storeChunk(_decl.code, &_stmt);
		}
		else {
			declChunk = _stmt.decl;
			while (1) {
				retrieveChunk(declChunk, &subDecl);
				if (!subDecl.next) {
					subDecl.next = retDeclChunk;
					storeChunk(declChunk, &subDecl);
					break;
				}
				declChunk = subDecl.next;
			}
		}
	}

	return subChunk;
}

CHUNKNUM parseSubroutineDeclarations(CHUNKNUM* firstDecl, CHUNKNUM lastDecl)
{
	struct decl _decl;

	// Loop to parse procedure and function definitions
	while (tokenIn(parserToken, tlProcFuncStart)) {
		CHUNKNUM subChunk = parseSubroutine();

		// Link the routine to the rest of the declarations
		if (*firstDecl) {
			retrieveChunk(lastDecl, &_decl);
			_decl.next = subChunk;
			storeChunk(lastDecl, &_decl);
		}
		else {
			*firstDecl = subChunk;
		}
		lastDecl = subChunk;

		if (isInUnitInterface && parserToken == tcIMPLEMENTATION) {
			break;
		}

		// semicolon
		resync(tlDeclarationFollow, tlProcFuncStart, tlStatementStart);
		if (parserToken == tcSemicolon) {
			getToken();
		} else if (!isInUnitInterface && (tokenIn(parserToken, tlProcFuncStart) ||
			tokenIn(parserToken, tlStatementStart))) {
			Error(errMissingSemicolon);
		}
	}

	return lastDecl;
}

CHUNKNUM parseModule(void)
{
	struct decl _decl;
	CHUNKNUM progDecl = parseModuleHeader();

	// ;
	resync(tlHeaderFollow, tlDeclarationStart, tlStatementStart);
	if (parserToken == tcSemicolon) {
		getToken();
	}
	else if (tokenIn(parserToken, tlDeclarationStart) ||
		tokenIn(parserToken, tlStatementStart)) {
		Error(errMissingSemicolon);
	}

	if (parserModuleType == TYPE_UNIT) {
		condGetToken(tcINTERFACE, errMissingINTERFACE);
		isInUnitInterface = 1;
	}

	// <block>
	retrieveChunk(progDecl, &_decl);
	_decl.code = parseBlock(1, &_decl.isLibrary);
	storeChunk(progDecl, &_decl);

	if (parserModuleType == TYPE_UNIT) {
		condGetToken(tcEND, errMissingEND);
	}

	// .
	resync(tlProgramEnd, 0, 0);
	condGetToken(tcPeriod, errMissingPeriod);

	return progDecl;
}

CHUNKNUM parseModuleHeader(void)
{
	CHUNKNUM paramList = 0, moduleName;

	isInUnitInterface = 0;

	if (parserToken == tcPROGRAM) {
		parserModuleType = TYPE_PROGRAM;
	} else if (parserToken == tcUNIT) {
		parserModuleType = TYPE_UNIT;
	} else {
		Error(errMissingPROGRAM);
	}

	getToken();

	if (parserToken != tcIdentifier) {
		Error(errMissingIdentifier);
	}

	// parserString contains name of program
	moduleName = name_create(parserString);

	// ( or ;
	getToken();
	resync(tlProgProcIdFollow, tlDeclarationStart, tlStatementStart);

	// Optional (file list)
	if (parserModuleType == TYPE_PROGRAM && parserToken == tcLParen) {
		CHUNKNUM lastArg = 0;
		do {
			struct param_list param;
			CHUNKNUM argChunk;

			getToken();
			argChunk = param_list_create(parserString, 0, 0);
			if (!paramList) {
				paramList = argChunk;
				lastArg = paramList;
			}
			else {
				retrieveChunk(lastArg, &param);
				param.next = argChunk;
				storeChunk(lastArg, &param);
				lastArg = argChunk;
			}
			getToken();
		} while (parserToken == tcComma);

		// )
		resync(tlFormalParmsFollow, tlDeclarationStart, tlStatementStart);
		condGetToken(tcRParen, errMissingRightParen);
	}

	return declCreate(DECL_TYPE, moduleName,
		typeCreate(parserModuleType, 0, 0, paramList),
		0);
}