#include <ast.h>
#include <common.h>
#include <string.h>

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
