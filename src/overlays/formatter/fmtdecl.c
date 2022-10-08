#include <stdio.h>
#include <formatter.h>
#include <symtab.h>
#include <misc.h>
#include <types.h>

static char buf[80];

void fmtPrintArrayType(TTYPE *pType) {
    TTYPE type;

    fmtPut("ARRAY [");
    fmtPrintTypeSpec(pType->array.indexType, 0);
    fmtPut("] OF ");

    retrieveChunk(pType->array.elemType, (unsigned char *)&type);
    if (type.typeId || (type.form != fcArray && type.form != fcRecord)) {
        fmtPrintTypeSpec(pType->array.elemType, 0);
    } else {
        // Cascade array of unnamed arrays or records over multiple lines
        fmtPutLine("");
        fmtIndent();
        fmtPrintTypeSpec(pType->array.elemType, 0);
        fmtDetent();
    }
}

void fmtPrintConstantDefinitions(CHUNKNUM constId) {
    int saveMargin;
    DEFN defn;
    TTYPE type;
    SYMTABNODE node;

    fmtPutLine(" ");
    fmtPutLine("CONST");
    fmtIndent();

    // Loop to print constant definitions, one per line
    do {
        retrieveChunk(constId, (unsigned char *)&node);
        retrieveChunk(node.typeChunk, (unsigned char *)&type);
        retrieveChunk(node.defnChunk, (unsigned char *)&defn);

        // Print the constant identifier followed by = .
        fmtPutName(node.nameChunkNum);
        fmtPut(" = ");
        saveMargin = fmtSetMargin();

        // Print the constant value
        if (type.form == fcArray) {  // string
            fmtPut("'");
            fmtPutName(defn.constant.value.stringChunkNum);
            fmtPut("'");
        } else if (type.nodeChunkNum == integerType) {
            sprintf(buf, "%d", defn.constant.value.integer);
            fmtPut(buf);
        } else if (type.nodeChunkNum == charType) {
            sprintf(buf, "'%c'", defn.constant.value.character);
            fmtPut(buf);
        }

        fmtPutLine(";");
        fmtResetMargin(saveMargin);

        constId = node.nextNode;
    }
    while (constId);

    fmtDetent();
}

void fmtPrintDeclarations(CHUNKNUM routineId) {
    DEFN defn;
    SYMTABNODE node;

    retrieveChunk(routineId, (unsigned char *)&node);
    retrieveChunk(node.defnChunk, (unsigned char *)&defn);

    if (defn.routine.locals.constantIds) {
        fmtPrintConstantDefinitions(defn.routine.locals.constantIds);
    }

    if (defn.routine.locals.typeIds) {
        fmtPrintTypeDefinitions(defn.routine.locals.typeIds);
    }

    if (defn.routine.locals.variableIds) {
        fmtPrintVariableDeclarations(defn.routine.locals.variableIds);
    }

    if (defn.routine.locals.routineIds) {
        fmtPrintSubroutineDeclarations(defn.routine.locals.routineIds);
    }
}

void fmtPrintEnumType(TTYPE *pType) {
    SYMTABNODE node;
    int saveMargin = fmtSetMargin();
    CHUNKNUM constId = pType->enumeration.constIds;

    fmtPut("(");

    // Loop to print the enumeration constant identifiers.
    do {
        retrieveChunk(constId, (unsigned char *)&node);
        fmtPutName(node.nameChunkNum);
        constId = node.nextNode;
        if (constId) fmtPut(", ");
    } while (constId);
    fmtPut(")");
    fmtResetMargin(saveMargin);
}

void fmtPrintRecordType(TTYPE *pType) {
    SYMTAB symtab;

    fmtPutLine("RECORD");

    fmtIndent();

    retrieveChunk(pType->record.symtab, (unsigned char *)&symtab);
    fmtPrintVarsOrFields(symtab.rootChunkNum);

    fmtDetent();

    fmtPut("END");
}

void fmtPrintSubrangeLimit(int limit, TTYPE *pBaseType) {
    CHUNKNUM constId;
    SYMTABNODE node;

    if (pBaseType->nodeChunkNum == integerType) {
        sprintf(buf, "%d", limit);
        fmtPut(buf);
    } else if (pBaseType->nodeChunkNum == charType) {
        sprintf(buf, "'%c'", limit);
        fmtPut(buf);
    }

    // Enumeration:  Find the appropriate enumeration constant id
    else {
        constId = pBaseType->enumeration.constIds;
        retrieveChunk(constId, (unsigned char *)&node);
        while (limit-- > 0) {
            constId = node.nextNode;
            retrieveChunk(constId, (unsigned char *)&node);
        }
        fmtPutName(node.nameChunkNum);
    }
}

void fmtPrintSubrangeType(TTYPE *pType) {
    TTYPE baseType;

    retrieveChunk(pType->subrange.baseType, (unsigned char *)&baseType);
    fmtPrintSubrangeLimit(pType->subrange.min, &baseType);
    fmtPut("..");
    fmtPrintSubrangeLimit(pType->subrange.max, &baseType);
}

void fmtPrintSubroutineDeclarations(CHUNKNUM routineId) {
    SYMTABNODE node;

    do {
        retrieveChunk(routineId, (unsigned char *)&node);
        fmtPrintSubroutine(&node);
        routineId = node.nextNode;
    } while (routineId);
}

void fmtPrintTypeSpec(CHUNKNUM typeNum, char defnFlag) {
    TTYPE type;
    SYMTABNODE node;

    retrieveChunk(typeNum, (unsigned char *)&type);

    // Name type that is part of a type specification:
    // Just print the type identifier.
    if (!defnFlag && type.typeId) {
        retrieveChunk(type.typeId, (unsigned char *)&node);
        fmtPutName(node.nameChunkNum);
    }

    // Otherwise, print the type spec completely
    else {
        switch (type.form) {
            case fcEnum:     fmtPrintEnumType(&type);     break;
            case fcSubrange: fmtPrintSubrangeType(&type); break;
            case fcArray:    fmtPrintArrayType(&type);    break;
            case fcRecord:   fmtPrintRecordType(&type);   break;
        }
    }
}

void fmtPrintTypeDefinitions(CHUNKNUM typeId) {
    TTYPE type;
    int saveMargin;
    SYMTABNODE node;

    fmtPutLine(" ");
    fmtPutLine("TYPE");
    fmtIndent();

    // Loop to print type definitions, one per line.
    do {
        // Print the type identifier followed by = .
        retrieveChunk(typeId, (unsigned char *)&node);
        retrieveChunk(node.typeChunk, (unsigned char *)&type);
        fmtPutName(node.nameChunkNum);
        fmtPut(" = ");
        saveMargin = fmtSetMargin();
        // Print the type specification
        fmtPrintTypeSpec(node.typeChunk, typeId == type.typeId ? 1 : 0);

        fmtPutLine(";");
        fmtResetMargin(saveMargin);

        typeId = node.nextNode;
    } while (typeId);

    fmtDetent();
}

void fmtPrintVarsOrFields(CHUNKNUM variableId) {
    TTYPE type;
    int saveMargin;
    SYMTABNODE node;

    retrieveChunk(variableId, (unsigned char *)&node);
    retrieveChunk(node.typeChunk, (unsigned char *)&type);

    do {
        fmtPutName(node.nameChunkNum);
        variableId = node.nextNode;
        retrieveChunk(variableId, (unsigned char *)&node);

        if (variableId && (node.typeChunk == type.nodeChunkNum)) {
            fmtPut(", ");
        } else {
            // End of sublist:  Print the common type and begin a new sublist.
            fmtPut(" : ");
            saveMargin = fmtSetMargin();
            fmtPrintTypeSpec(type.nodeChunkNum, 0);

            fmtPutLine(";");
            fmtResetMargin(saveMargin);

            if (variableId) {
                retrieveChunk(node.typeChunk, (unsigned char *)&type);
            }
        }
    } while (variableId);
}

void fmtPrintVariableDeclarations(CHUNKNUM variableId) {
    fmtPutLine(" ");
    fmtPutLine("VAR");
    fmtIndent();
    fmtPrintVarsOrFields(variableId);
    fmtDetent();
}
