// This generates machine code that implements the Pascal code.

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <membuf.h>

CHUNKNUM stringLiterals;
int numStringLiterals;

CHUNKNUM codeBuf;
unsigned short codeOffset;
unsigned short codeBase;

// Used when initializing nested arrays and records
short heapOffset;

void genOne(unsigned char b)
{
	writeToMemBuf(codeBuf, &b, 1);
	++codeOffset;
}

void genTwo(unsigned char b1, unsigned char b2)
{
	unsigned char buf[2];

    buf[0] = b1;
    buf[1] = b2;

	writeToMemBuf(codeBuf, buf, 2);
	codeOffset += 2;
}

void genThreeAddr(unsigned char b, unsigned short addr)
{
	unsigned char buf[3];

    buf[0] = b;
    buf[1] = WORD_LOW(addr);
    buf[2] = WORD_HIGH(addr);

	writeToMemBuf(codeBuf, buf, 3);
	codeOffset += 3;
}

void genBoolValueA(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	genTwo(LDA_IMMEDIATE, _expr.value.character);
}

void genCharValueA(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	genTwo(LDA_IMMEDIATE, _expr.value.character);
	genTwo(LDX_IMMEDIATE, 0);
}

void genIntValueAX(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(TAX);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	if (_expr.neg) {
		_expr.value.integer = -_expr.value.integer;
	}
	genTwo(LDA_IMMEDIATE, WORD_LOW(_expr.value.integer));
	genTwo(LDX_IMMEDIATE, WORD_HIGH(_expr.value.integer));
}

// 15684
//    codegen: 5878 (5443)
//       updateHeapOffset: 15653
//       parentArrayInit: 15583
//       nonParentArrayInit: 15525
//       arrayRecordInit: 15489
//       freeVarHeaps: 15439
//       prgCleanup: 15377
//       chainCall: 15249
//    compsymtab: 832
//    genexpr: 3161
//    genrtn: 3796
//    genstmt: 1880
//    overhead: 137
void writeCodeBuf(unsigned char *buf, int len)
{
	writeToMemBuf(codeBuf, buf, len);
	codeOffset += len;
}

