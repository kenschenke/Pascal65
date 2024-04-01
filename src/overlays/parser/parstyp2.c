/**
 * parsrtyp2.c
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

CHUNKNUM parseArrayType(void)
{
	struct type arrayType;
	CHUNKNUM outerArray, arrayTypeChunkNum;
	int indexFlag;  // non-zero if another array index, 0 if done.

	// Start with the outer-most array.
	// The element type and index type will be filled in later.
	arrayTypeChunkNum = outerArray = typeCreate(TYPE_ARRAY, 0, 0, 0);
	retrieveChunk(arrayTypeChunkNum, &arrayType);

	// [
	getToken();
	condGetToken(tcLBracket, errMissingLeftBracket);

	// Loop to parse each type spec in the index type list, separated by commas.
	do {
		arrayType.indextype = parseTypeSpec();
		storeChunk(arrayTypeChunkNum, &arrayType);

		// ,
		resync(tlIndexFollow, tlIndexStart, 0);
		if (parserToken == tcComma || tokenIn(parserToken, tlIndexStart)) {
			// For each type spec after the first, create an element type object
			CHUNKNUM newTypeChunkNum = typeCreate(TYPE_ARRAY, 0, 0, 0);
			arrayType.subtype = newTypeChunkNum;
			storeChunk(arrayTypeChunkNum, &arrayType);
			arrayTypeChunkNum = newTypeChunkNum;
			retrieveChunk(arrayTypeChunkNum, &arrayType);
			condGetToken(tcComma, errMissingComma);
			indexFlag = 1;
		}
		else {
			indexFlag = 0;
		}

	} while (indexFlag);

	// ]
	condGetToken(tcRBracket, errMissingRightBracket);

	// OF
	resync(tlIndexListFollow, tlDeclarationStart, tlStatementStart);
	condGetToken(tcOF, errMissingOF);

	// Final element type
	arrayType.subtype = parseTypeSpec();
	storeChunk(arrayTypeChunkNum, &arrayType);

	return outerArray;
}

CHUNKNUM parseRecordType(void)
{
	struct type _type;
	CHUNKNUM newTypeChunkNum;

	getToken();

	newTypeChunkNum = typeCreate(TYPE_RECORD, 0, 0, 0);
	retrieveChunk(newTypeChunkNum, &_type);
	_type.paramsFields = parseFieldDeclarations();
	storeChunk(newTypeChunkNum, &_type);


	// END
	condGetToken(tcEND, errMissingEND);

	return newTypeChunkNum;
}
