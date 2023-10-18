#include <stdio.h>
#include <codegen.h>
#include <ast.h>
#include <asm.h>
#include <string.h>
#include <error.h>

static void updateHeapOffset(short newOffset);

#define RECORD_DECL_SIZEL 1
#define RECORD_DECL_SIZEH 3
static unsigned char recordDeclCode[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
	JSR, WORD_LOW(RT_PUSHINT), WORD_HIGH(RT_PUSHINT),
};

#define PARENT_ARRAY_INIT1_ELEMENTSL 1
#define PARENT_ARRAY_INIT1_ELEMENTSH 5
#define PARENT_ARRAY_INIT1_ELEMSIZEL 9
#define PARENT_ARRAY_INIT1_ELEMSIZEH 11
static unsigned char parentArrayInit1[] = {
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_TMP1,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_TMP2,
	// Initialize this array's heap
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
};
static unsigned char parentArrayInit2[] = {
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
	LDA_ZEROPAGE, ZP_PTR1L,
	LDX_ZEROPAGE, ZP_PTR1H,
	JSR, WORD_LOW(RT_INITARRAYHEAP), WORD_HIGH(RT_INITARRAYHEAP),
};
#define PARENT_ARRAY_INIT3_BNE 3
#define PARENT_ARRAY_INIT3_JMP 11
static unsigned char parentArrayInit3[] = {
	DEC_ZEROPAGE, ZP_TMP1,
	BNE, 0,
	LDA_ZEROPAGE, ZP_TMP2,
	BEQ, 5,
	DEC_ZEROPAGE, ZP_TMP2,
	JMP, 0, 0,
};

#define NON_PARENT_ARRAY_INIT1_SIZEL 1
#define NON_PARENT_ARRAY_INIT1_SIZEH 3
static unsigned char nonParentArrayInit1[] = {
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_HEAPALLOC), WORD_HIGH(RT_HEAPALLOC),
	STA_ZEROPAGE, ZP_PTR1L,
	STX_ZEROPAGE, ZP_PTR1H,
	JSR, WORD_LOW(RT_PUSHINT), WORD_HIGH(RT_PUSHINT),
};
#define NON_PARENT_ARRAY_INIT2_SIZEL 4
#define NON_PARENT_ARRAY_INIT2_SIZEH 6
static unsigned char nonParentArrayInit2[] = {
	// keep the heap pointer
	PHA,
	TXA,
	PHA,
	// Array element size
	LDA_IMMEDIATE, 0,
	LDX_IMMEDIATE, 0,
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
};
static unsigned char nonParentArrayInit3[] = {
	JSR, WORD_LOW(RT_PUSHAX), WORD_HIGH(RT_PUSHAX),
	// heap address must be in A/X
	PLA,
	TAX,
	PLA,
	JSR, WORD_LOW(RT_INITARRAYHEAP), WORD_HIGH(RT_INITARRAYHEAP),
};

#define ARRAY_RECORD_INIT1_ELEMENTSL 1
#define ARRAY_RECORD_INIT1_ELEMENTSH 5
static unsigned char arrayRecordInit1[] = {
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_TMP1,
	LDA_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_TMP2,
};
#define ARRAY_RECORD_INIT2_BNE 3
#define ARRAY_RECORD_INIT2_JMP 11
static unsigned char arrayRecordInit2[] = {
	DEC_ZEROPAGE, ZP_TMP1,
	BNE, 0,
	LDA_ZEROPAGE, ZP_TMP2,
	BEQ, 5,
	DEC_ZEROPAGE, ZP_TMP2,
	JMP, 0, 0,
};

#define HEAP_OFFSET_LOW 4
#define HEAP_OFFSET_HIGH 10
static unsigned char heapOffsetCode[] = {
	LDA_ZEROPAGE, ZP_PTR1L,
	CLC,
	ADC_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1L,
	LDA_ZEROPAGE, ZP_PTR1H,
	ADC_IMMEDIATE, 0,
	STA_ZEROPAGE, ZP_PTR1H,
};

void genArrayInit(struct type* pType, char isParentAnArray, char isParentHeapVar,
	int numElements, CHUNKNUM arrayNum)
{
	char label[15];
	unsigned short branchOffset;
	struct type indexType, elemType;
	short size = pType->size;

	retrieveChunk(pType->indextype, &indexType);
	retrieveChunk(pType->subtype, &elemType);
	if (isParentAnArray) {
		// Loop through and intialize each child array of the parent array
		// Parent is an array
		// Initialize number of elements in tmp1/tmp2
		parentArrayInit1[PARENT_ARRAY_INIT1_ELEMENTSL] = WORD_LOW(numElements);
		parentArrayInit1[PARENT_ARRAY_INIT1_ELEMENTSH] = WORD_HIGH(numElements);
		parentArrayInit1[PARENT_ARRAY_INIT1_ELEMSIZEL] = WORD_LOW(elemType.size);
		parentArrayInit1[PARENT_ARRAY_INIT1_ELEMSIZEH] = WORD_HIGH(elemType.size);
		branchOffset = codeOffset + 8;
		sprintf(label, "ARRAY%04x", arrayNum);
		linkAddressSet(label, branchOffset);
		writeCodeBuf(parentArrayInit1, 15);
		// Array upper bound
		genExpr(indexType.max, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// Array lower bound
		genExpr(indexType.min, 0, 1, 0);
		writeCodeBuf(parentArrayInit2, 10);
		// Advance ptr1 past array header
		updateHeapOffset(heapOffset + 6);

		// Check if the element is a record
		if (elemType.kind == TYPE_DECLARED) {
			char name[CHUNK_LEN + 1];
			struct symbol sym;
			memset(name, 0, sizeof(name));
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
			retrieveChunk(sym.type, &elemType);
		}
		if (elemType.kind == TYPE_RECORD) {
            int i;
			for (i = 0; i < numElements; ++i) {
				genRecordInit(&elemType);
			}
		}
		else {
			// Advance prt1 past array elements
			updateHeapOffset(heapOffset + size - 6);
		}

		// Decrement tmp1/tmp2
		parentArrayInit3[PARENT_ARRAY_INIT3_BNE] = 256 - (codeOffset - branchOffset) - 4;
		linkAddressLookup(label, codeOffset + PARENT_ARRAY_INIT3_JMP, 0, LINKADDR_BOTH);
		writeCodeBuf(parentArrayInit3, 13);
	}
	else {
		if (!isParentHeapVar) {
			// Allocate array heap
			nonParentArrayInit1[NON_PARENT_ARRAY_INIT1_SIZEL] = WORD_LOW(size);
			nonParentArrayInit1[NON_PARENT_ARRAY_INIT1_SIZEH] = WORD_HIGH(size);
			writeCodeBuf(nonParentArrayInit1, 14);
		}
		else {
			// Restore ptr1 from parent heap
			genTwo(LDA_ZEROPAGE, ZP_PTR1L);
			genTwo(LDX_ZEROPAGE, ZP_PTR1H);
		}
		nonParentArrayInit2[NON_PARENT_ARRAY_INIT2_SIZEL] = WORD_LOW(elemType.size);
		nonParentArrayInit2[NON_PARENT_ARRAY_INIT2_SIZEH] = WORD_HIGH(elemType.size);
		writeCodeBuf(nonParentArrayInit2, 10);
		// Array upper bound
		genExpr(indexType.max, 0, 1, 0);
		genThreeAddr(JSR, RT_PUSHAX);
		// Array lower bound
		genExpr(indexType.min, 0, 1, 0);
		writeCodeBuf(nonParentArrayInit3, 9);
		// Advance ptr1 past array header
		updateHeapOffset(heapOffset + 6);
		if (elemType.kind == TYPE_ARRAY) {
			int lowBound = getArrayLimit(indexType.min);
			int highBound = getArrayLimit(indexType.max);
			genArrayInit(&elemType, 1, 1, highBound - lowBound + 1, pType->subtype);
		}

		// Check if the element is a record
		if (elemType.kind == TYPE_DECLARED) {
			char name[CHUNK_LEN + 1];
			struct symbol sym;
			memset(name, 0, sizeof(name));
			retrieveChunk(elemType.name, name);
			if (!scope_lookup(name, &sym)) {
				Error(errUndefinedIdentifier);
				return;
			}
			retrieveChunk(sym.type, &elemType);
		}
		if (elemType.kind == TYPE_RECORD) {
			short offset = heapOffset + elemType.size;
			// Loop through and intialize each child array of the parent array
			// Array element is record
			// Store number of elements in tmp1/tmp2
			arrayRecordInit1[ARRAY_RECORD_INIT1_ELEMENTSL] = WORD_LOW(numElements);
			arrayRecordInit1[ARRAY_RECORD_INIT1_ELEMENTSH] = WORD_HIGH(numElements);
			writeCodeBuf(arrayRecordInit1, 8);
			sprintf(label, "ARRAY%04x", arrayNum);
			branchOffset = codeOffset;
			linkAddressSet(label, codeOffset);
			// Initialize record
			genRecordInit(&elemType);
			// Decrement tmp1/tmp2
			arrayRecordInit2[ARRAY_RECORD_INIT2_BNE] = 256 - (codeOffset - branchOffset) - 4;
			linkAddressLookup(label, codeOffset + ARRAY_RECORD_INIT2_JMP, 0, LINKADDR_BOTH);
			writeCodeBuf(arrayRecordInit2, 13);

			heapOffset += elemType.size * numElements;
		}
	}
}

void genRecordInit(struct type* pType)
{
	struct decl _decl;
	struct type _type;
	short offset = heapOffset;
	CHUNKNUM chunkNum = pType->paramsFields;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);
		retrieveChunk(_decl.type, &_type);

		if (_type.kind == TYPE_DECLARED) {
			struct symbol sym;
			retrieveChunk(_decl.node, &sym);
			retrieveChunk(sym.type, &_type);
		}

		if (_type.kind == TYPE_RECORD) {
			genRecordInit(&_type);
		}

		if (_type.kind == TYPE_ARRAY) {
			struct type indexType;
            int lowerBound, upperBound;
			retrieveChunk(_type.indextype, &indexType);
			lowerBound = getArrayLimit(indexType.min);
			upperBound = getArrayLimit(indexType.max);
			updateHeapOffset(offset);
			// Record field is an array
			genArrayInit(&_type, 0, 1, upperBound - lowerBound + 1, chunkNum);
		}

		offset += _type.size;
		chunkNum = _decl.next;
	}

	if (offset > heapOffset) {
		// Advance ptr1 the remainder of the record
		updateHeapOffset(offset);
	}
}

int genVariableDeclarations(CHUNKNUM chunkNum, short* heapOffsets)
{
	char name[CHUNK_LEN + 1];
	struct decl _decl;
	struct type _type;
	struct symbol sym;
	int num = 0, heapVar = 0;

	while (chunkNum) {
		retrieveChunk(chunkNum, &_decl);

		if (_decl.kind == DECL_CONST || _decl.kind == DECL_VARIABLE) {
			retrieveChunk(_decl.type, &_type);

			if (_type.flags & TYPE_FLAG_ISRETVAL) {
				chunkNum = _decl.next;
				continue;
			}

			memset(name, 0, sizeof(name));
			retrieveChunk(_decl.name, name);

			if (_decl.node) {
				retrieveChunk(_decl.node, &sym);
			}
			else {
				sym.offset = -1;
			}

			switch (_type.kind) {
			case TYPE_INTEGER:
			case TYPE_BOOLEAN:
			case TYPE_ENUMERATION:
				genIntValueAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHINT);
				break;

			case TYPE_CHARACTER:
				genCharValueA(_decl.value);
				genTwo(LDX_IMMEDIATE, 0);
				genThreeAddr(JSR, RT_PUSHINT);
				break;

			case TYPE_REAL:
				genRealValueEAX(_decl.value);
				genThreeAddr(JSR, RT_PUSHREAL);
				break;

			case TYPE_ARRAY: {
				struct type indexType;
                int lowerBound, upperBound;
				retrieveChunk(_type.indextype, &indexType);
				lowerBound = getArrayLimit(indexType.min);
				upperBound = getArrayLimit(indexType.max);
				heapOffset = 0;
				genArrayInit(&_type, 0, 0, upperBound - lowerBound + 1, chunkNum);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			case TYPE_RECORD:
				recordDeclCode[RECORD_DECL_SIZEL] = WORD_LOW(_type.size);
				recordDeclCode[RECORD_DECL_SIZEH] = WORD_HIGH(_type.size);
				writeCodeBuf(recordDeclCode, 14);
				heapOffset = 0;
				genRecordInit(&_type);
				heapOffsets[heapVar++] = sym.offset;
				break;
			}

			++num;
		}

		chunkNum = _decl.next;
	}

	heapOffsets[heapVar] = -1;

	return num;
}

int getArrayLimit(CHUNKNUM chunkNum)
{
	struct expr _expr;

	retrieveChunk(chunkNum, &_expr);
	if (_expr.kind == EXPR_INTEGER_LITERAL) {
		return _expr.value.integer;
	}
	else {
		Error(rteUnimplementedRuntimeFeature);
	}

	return 0;
}

static void updateHeapOffset(short newOffset)
{
	if (newOffset != heapOffset) {
		int offset = newOffset - heapOffset;
		heapOffsetCode[HEAP_OFFSET_LOW] = WORD_LOW(offset);
		heapOffsetCode[HEAP_OFFSET_HIGH] = WORD_HIGH(offset);
		writeCodeBuf(heapOffsetCode, 13);

		heapOffset = newOffset;
	}
}

