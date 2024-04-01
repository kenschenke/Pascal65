// This generates machine code that implements the Pascal code.

#include <codegen.h>
#include <asm.h>
#include <ast.h>
#include <membuf.h>

CHUNKNUM stringLiterals;
int numStringLiterals;

FILE *codeFh;
unsigned short codeOffset;
unsigned short codeBase;

// Used when initializing nested arrays and records
short heapOffset;

void genOne(unsigned char b)
{
	fwrite(&b, 1, 1, codeFh);
	++codeOffset;
}

void genTwo(unsigned char b1, unsigned char b2)
{
	unsigned char buf[2];

    buf[0] = b1;
    buf[1] = b2;

	fwrite(buf, 1, 2, codeFh);
	codeOffset += 2;
}

void genThreeAddr(unsigned char b, unsigned short addr)
{
	unsigned char buf[3];

    buf[0] = b;
    buf[1] = WORD_LOW(addr);
    buf[2] = WORD_HIGH(addr);

	fwrite(buf, 1, 3, codeFh);
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

void genIntValueEAX(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		genOne(TAX);
		genTwo(STA_ZEROPAGE, ZP_SREGL);
		genTwo(STA_ZEROPAGE, ZP_SREGH);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	if (_expr.neg) {
		_expr.value.longInt = -_expr.value.longInt;
	}
	genTwo(LDA_IMMEDIATE, DWORD_NMSB(_expr.value.longInt));
	genTwo(STA_ZEROPAGE, ZP_SREGL);
	genTwo(LDA_IMMEDIATE, DWORD_MSB(_expr.value.longInt));
	genTwo(STA_ZEROPAGE, ZP_SREGH);
	genTwo(LDA_IMMEDIATE, DWORD_LSB(_expr.value.longInt));
	genTwo(LDX_IMMEDIATE, DWORD_NLSB(_expr.value.longInt));
}

void genShortValueA(CHUNKNUM chunkNum)
{
	struct expr _expr;

	if (!chunkNum) {
		genTwo(LDA_IMMEDIATE, 0);
		return;
	}

	retrieveChunk(chunkNum, &_expr);
	if (_expr.neg) {
		_expr.value.shortInt = -_expr.value.shortInt;
	}
	genTwo(LDA_IMMEDIATE, _expr.value.shortInt);
	genTwo(LDX_IMMEDIATE, _expr.neg ? 0xff : 0);
}

void genRuntimeCall(unsigned char routine)
{
	setRuntimeRef(routine, codeOffset + 1);
	genThreeAddr(JSR, 0);
}

void writeCodeBuf(unsigned char *buf, int len)
{
	fwrite(buf, 1, len, codeFh);
	codeOffset += len;
}

