#include <parser.h>
#include <ast.h>
#include <common.h>
#include <misc.h>
#include <string.h>

CHUNKNUM parseBlock(void)
{
	struct stmt _stmt;
	CHUNKNUM stmtChunk, decl = parseDeclarations();

	resync(tlStatementStart, 0, 0);
	if (parserToken != tcBEGIN) Error(errMissingBEGIN);

	stmtChunk = stmtCreate(STMT_BLOCK, 0, parseCompound());
	retrieveChunk(stmtChunk, &_stmt);
	_stmt.decl = decl;
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
				case tcBOOLEAN: type = TYPE_BOOLEAN; break;
				case tcCHAR: type = TYPE_CHARACTER; break;
				case tcINTEGER: type = TYPE_INTEGER; break;
				case tcREAL: type = TYPE_REAL; break;
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
	if (stricmp(parserString, "forward")) {
		// Not a forward declaration
		_decl.code = parseBlock();
		storeChunk(subChunk, &_decl);
	}
	else {
		getToken();
		retrieveChunk(_decl.type, &_type);
		_type.flags |= TYPE_FLAG_ISFORWARD;
		storeChunk(_decl.type, &_type);
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

		// semicolon
		resync(tlDeclarationFollow, tlProcFuncStart, tlStatementStart);
		if (parserToken == tcSemicolon) {
			getToken();
		} else if (tokenIn(parserToken, tlProcFuncStart) ||
			tokenIn(parserToken, tlStatementStart)) {
			Error(errMissingSemicolon);
		}
	}

	return lastDecl;
}

CHUNKNUM parseProgram(void)
{
	struct decl _decl;
	CHUNKNUM progDecl = parseProgramHeader();

	// ;
	resync(tlHeaderFollow, tlDeclarationStart, tlStatementStart);
	if (parserToken == tcSemicolon) {
		getToken();
	}
	else if (tokenIn(parserToken, tlDeclarationStart) ||
		tokenIn(parserToken, tlStatementStart)) {
		Error(errMissingSemicolon);
	}

	// <block>
	retrieveChunk(progDecl, &_decl);
	_decl.code = parseBlock();
	storeChunk(progDecl, &_decl);

	// .
	resync(tlProgramEnd, 0, 0);
	condGetToken(tcPeriod, errMissingPeriod);

	return progDecl;
}

CHUNKNUM parseProgramHeader(void)
{
	CHUNKNUM paramList = 0, progName;

	condGetToken(tcPROGRAM, errMissingPROGRAM);

	if (parserToken != tcIdentifier) {
		Error(errMissingIdentifier);
	}

	// parserString contains name of program
	progName = name_create(parserString);

	// ( or ;
	getToken();
	resync(tlProgProcIdFollow, tlDeclarationStart, tlStatementStart);

	// Optional (file list)
	if (parserToken == tcLParen) {
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

	return declCreate(DECL_TYPE, progName,
		typeCreate(TYPE_PROGRAM, 0, 0, paramList),
		0);
}