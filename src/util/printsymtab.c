#include <stdio.h>
#include <symtab.h>
#include <types.h>
#include <common.h>

static void printArrayType(FILE *fh, TTYPE *typeNode);
static void printConstantNode(FILE *fh, CHUNKNUM typeChunkNum, TTYPE *typeNode);
static void printEnumType(FILE *fh, TTYPE *pType);
static void printFormName(FILE *fh, TFormCode form);
static void printRecordType(FILE *fh, TTYPE *pType);
static void printStringChunks(FILE *fh, CHUNKNUM firstChunkNum);
static void printSubrangeType(FILE *fh, TTYPE *pType);
static void printSymtabNode(FILE *fh, CHUNKNUM chunkNum);
static void printTypeNode(FILE *fh, TTYPE *pType);
static void printTypeSpec(FILE *fh, TTYPE *pType);
static void printVarOrField(FILE *fh, SYMTABNODE *pNode);

// entry point is printGlobalSymtab(FILE *fh);

static char symbolName[CHUNK_LEN];
static DEFN defn;
static STRVALCHUNK strValChunk;
static SYMTABNODE symtabNode;

static void printArrayType(FILE *fh, TTYPE *typeNode) {
    TTYPE indexType;

    fprintf(fh, "%d elements\n", typeNode->array.elemCount);
    
    if (typeNode->array.indexType) {
        fprintf(fh, "--- INDEX TYPE ---\n");
        retrieveChunk(typeNode->array.indexType, (unsigned char *)&indexType);
        printTypeSpec(fh, &indexType);
    }

    if (typeNode->array.elemType) {
        fprintf(fh, "--- ELEMENT TYPE ---\n");
        retrieveChunk(typeNode->array.elemType, (unsigned char *)&indexType);
        printTypeSpec(fh, &indexType);
    }
}

static void printConstantNode(FILE *fh, CHUNKNUM typeChunkNum, TTYPE *typeNode) {
    fprintf(fh, "Defined constant\n");

    if (typeChunkNum == integerType || typeNode->form == fcEnum) {
        fprintf(fh, "Value = %d\n", defn.constant.value.integer);
    } else if (typeChunkNum == charType) {
        fprintf(fh, "Value = '%c'\n", defn.constant.value.character);
    } else if (typeNode->form == fcArray) {
        fprintf(fh, "Value = '");
        printStringChunks(fh, defn.constant.value.stringChunkNum);
        fprintf(fh, "'\n");
    }

    printTypeSpec(fh, typeNode);
}

static void printEnumType(FILE *fh, TTYPE *pType) {
    DEFN defn;
    char name[CHUNK_LEN];
    SYMTABNODE node;
    CHUNKNUM chunkNum;

    // Print the names and values of the enumeration constant identifiers
    fprintf(fh, "--- Enumeration Constant Identifiers (value = name) ---\n");

    chunkNum = pType->enumeration.constIds;
    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&node);
        retrieveChunk(node.defnChunk, (unsigned char *)&defn);
        retrieveChunk(node.nameChunkNum, (unsigned char *)name);
        fprintf(fh, "    %d = %.*s\n", defn.constant.value.integer, CHUNK_LEN, name);
        chunkNum = node.nextNode;
    }
}

static void printFormName(FILE *fh, TFormCode form) {
    switch (form) {
        case fcNone: fprintf(fh, "*** Error ***"); break;
        case fcScalar: fprintf(fh, "Scalar"); break;
        case fcEnum: fprintf(fh, "Enumeration"); break;
        case fcSubrange: fprintf(fh, "Subrange"); break;
        case fcArray: fprintf(fh, "Array"); break;
        case fcRecord: fprintf(fh, "Record"); break;
    }
}

void printGlobalSymtab(FILE *fh) {
    SYMTAB symtab;

    retrieveChunk(globalSymtab, (unsigned char *)&symtab);
    printSymtabNode(fh, symtab.rootChunkNum);
}

static void printRecordType(FILE *fh, TTYPE *pType) {
    DEFN defn;
    SYMTAB symtab;
    SYMTABNODE node;
    char name[CHUNK_LEN];
    CHUNKNUM nodeChunkNum;

    retrieveChunk(pType->record.symtab, (unsigned char *)&symtab);

    // Print the names and values of the record field identifiers.
    fprintf(fh, "--- Record Field Identifiers (offset : name) ---\n\n");
    for (nodeChunkNum = symtab.rootChunkNum; nodeChunkNum; nodeChunkNum = node.nextNode) {
        retrieveChunk(nodeChunkNum, (unsigned char *)&node);
        retrieveChunk(node.nameChunkNum, (unsigned char *)name);
        retrieveChunk(node.defnChunk, (unsigned char *)&defn);
        fprintf(fh, "    %d: %.*s\n", defn.data.offset, CHUNK_LEN, name);
        printVarOrField(fh, &node);
    }
}

static void printSubrangeType(FILE *fh, TTYPE *pType) {
    TTYPE subType;

    // Subrange minimum and maximum values
    fprintf(fh, "Minimum value = %d, maximum value = %d\n",
        pType->subrange.min, pType->subrange.max);

    if (pType->subrange.baseType) {
        fprintf(fh, "--- Base Type ---\n");
        retrieveChunk(pType->subrange.baseType, (unsigned char *)&subType);
        printTypeSpec(fh, &subType);
    }
}

static void printStringChunks(FILE *fh, CHUNKNUM firstChunkNum) {
    CHUNKNUM chunkNum = firstChunkNum;

    while (chunkNum) {
        retrieveChunk(chunkNum, (unsigned char *)&strValChunk);
        fprintf(fh, "%.*s", sizeof(strValChunk.value), strValChunk.value);
        chunkNum = strValChunk.nextChunkNum;
    }
}

static void printSymtabNode(FILE *fh, CHUNKNUM chunkNum) {
    CHUNKNUM left, right, nameChunkNum, defnChunkNum, typeChunkNum;
    TTYPE typeNode;

    retrieveChunk(chunkNum, (unsigned char *)&symtabNode);
    left = symtabNode.leftChunkNum;
    right = symtabNode.rightChunkNum;
    nameChunkNum = symtabNode.nameChunkNum;
    defnChunkNum = symtabNode.defnChunk;
    typeChunkNum = symtabNode.typeChunk;

    if (left) printSymtabNode(fh, left);

    retrieveChunk(defnChunkNum, (unsigned char *)&defn);
    retrieveChunk(nameChunkNum, (unsigned char *)symbolName);
    if (typeChunkNum) {
        retrieveChunk(typeChunkNum, (unsigned char *)&typeNode);
    } else {
        typeNode.form = 0;
    }

    fprintf(fh, "\n============================================================\n\n");
    fprintf(fh, "%04x \"%.*s\"\n\n", chunkNum, CHUNK_LEN, symbolName);

    switch (defn.how) {
        case dcConstant: printConstantNode(fh, typeChunkNum, &typeNode); break;
        case dcType: printTypeNode(fh, &typeNode); break;
        case dcVariable:
        case dcField:
            retrieveChunk(chunkNum, (unsigned char *)&symtabNode);
            printVarOrField(fh, &symtabNode);
            break;
        default:
            printf(" *** unrecognized definition code: %d -- %.*s\n", defn.how, CHUNK_LEN, symbolName);
    }

    if (right) printSymtabNode(fh, right);
}

static void printTypeSpec(FILE *fh, TTYPE *pType) {
    SYMTABNODE type2;
    char name[CHUNK_LEN];

    printFormName(fh, pType->form);
    fprintf(fh, ", size %d bytes.  Type identifier: ", pType->size);

    // type identifier
    if (pType->form == fcNone) {
        fprintf(fh, "<unnamed>\n");
    } else {
        retrieveChunk(pType->typeId, (unsigned char *)&type2);
        retrieveChunk(type2.nameChunkNum, (unsigned char *)name);
        fprintf(fh, "%.*s\n", CHUNK_LEN, name);
    }

    switch(pType->form) {
        case fcEnum: printEnumType(fh, pType); break;
        case fcSubrange: printSubrangeType(fh, pType); break;
        case fcArray: printArrayType(fh, pType); break;
        case fcRecord: printRecordType(fh, pType); break;
    }
}

static void printTypeNode(FILE *fh, TTYPE *pType) {
    fprintf(fh, "\nDefined type\n");
    printTypeSpec(fh, pType);
}

static void printVarOrField(FILE *fh, SYMTABNODE *pNode) {
    DEFN defn;
    TTYPE typeNode;

    retrieveChunk(pNode->defnChunk, (unsigned char *)&defn);
    fprintf(fh, defn.how == dcVariable ? "Declared variable\n" : "Declared record field\n");

    if (pNode->typeChunk) {
        retrieveChunk(pNode->typeChunk, (unsigned char *)&typeNode);
        printTypeSpec(fh, &typeNode);
    }

    if (defn.how == dcVariable || pNode->nextNode) {
        fprintf(fh, "\n");
    }
}

