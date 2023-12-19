#include <ast.h>
#include <common.h>
#include <string.h>

char getTypeMask(char type) {
	char mask = TYPE_CHARACTER;

	switch (type) {
		case TYPE_REAL: mask=TYPE_MASK_REAL; break;
		case TYPE_SHORTINT: mask=TYPE_MASK_SINT8; break;
		case TYPE_BYTE: mask=TYPE_MASK_UINT8; break;
		case TYPE_INTEGER: mask=TYPE_MASK_SINT16; break;
		case TYPE_WORD: mask=TYPE_MASK_UINT16; break;
		case TYPE_LONGINT: mask=TYPE_MASK_SINT32; break;
		case TYPE_CARDINAL: mask=TYPE_MASK_UINT32; break;
	}

	return mask;
}

char isTypeInteger(char type)
{
	return (type == TYPE_SHORTINT || type == TYPE_BYTE ||
		type == TYPE_INTEGER || type == TYPE_WORD ||
		type == TYPE_LONGINT || type == TYPE_CARDINAL) ? 1 : 0;
}

CHUNKNUM name_clone(CHUNKNUM source) {
    CHUNKNUM chunkNum;
    char buf[CHUNK_LEN];

    retrieveChunk(source, buf);

    if (!allocChunk(&chunkNum)) {
        return 0;
    }

    storeChunk(chunkNum, buf);

    return chunkNum;
}

CHUNKNUM name_create(const char* name) {
    CHUNKNUM chunkNum;
    char buf[CHUNK_LEN];

    if (strlen(name) > CHUNK_LEN) {
        return 0;
    }

    memset(buf, 0, CHUNK_LEN);
    memcpy(buf, name, strlen(name));

    if (!allocChunk(&chunkNum)) {
        return 0;
    }

    storeChunk(chunkNum, (unsigned char*)buf);

    return chunkNum;
}

CHUNKNUM typeCreate(type_t kind, char isConst,
    CHUNKNUM subtype, CHUNKNUM params)
{
    CHUNKNUM chunkNum;
    struct type type;

    if (!allocChunk(&chunkNum)) {
        return 0;
    }

    memset(&type, 0, sizeof(struct type));
    type.kind = kind;
    if (isConst) {
        type.flags = TYPE_FLAG_ISCONST;
    }
    type.subtype = subtype;
    type.paramsFields = params;
    type.lineNumber = currentLineNumber;

    storeChunk(chunkNum, (unsigned char*)&type);

    return chunkNum;
}

CHUNKNUM symbol_create(symbol_t kind, CHUNKNUM type, const char* name)
{
    struct symbol _symbol;

    memset(&_symbol, 0, sizeof(struct symbol));
    if (!allocChunk(&_symbol.nodeChunkNum)) {
        return 0;
    }

    _symbol.kind = kind;
    _symbol.type = type;
    _symbol.name = name_create(name);

    storeChunk(_symbol.nodeChunkNum, &_symbol);

    return _symbol.nodeChunkNum;
}
