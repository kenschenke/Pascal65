#include <formatter.h>
#include <types.h>
#include <icode.h>
#include <membuf.h>

void fmtPrintBlock(CHUNKNUM routineId) {
    DEFN defn;
    TOKEN token;
    SYMBNODE node;

    // First print the definitions and declarations.
    fmtPrintDeclarations(routineId);
    fmtPutLine(" ");

    // Then print the statements in the icode.
    loadSymbNode(routineId, &node);
    resetMemBufPosition(defn.routine.Icode);
    fmtPrintCompound(defn.routine.Icode, &node, &token);
}

void fmtPrintProgram(CHUNKNUM programId) {
    DEFN defn;
    CHUNKNUM parmId;
    SYMTABNODE node;
    int saveMargin;

    fmtPut("PROGRAM ");
    retrieveChunk(programId, (unsigned char *)&node);
    fmtPutName(node.nameChunkNum);

    // print the program parameter list
    retrieveChunk(node.defnChunk, (unsigned char *)&defn);
    parmId = defn.routine.locals.parmIds;
    if (parmId) {
        fmtPut(" (");
        saveMargin = fmtSetMargin();

        // loop to print each program parameter
        do {
            retrieveChunk(parmId, (unsigned char *)&node);
            fmtPutName(node.nameChunkNum);
            parmId = node.nextNode;
            if (parmId) {
                fmtPut(", ");
            }
        } while (parmId);

        fmtPut(")");
        fmtResetMargin(saveMargin);
    }
    fmtPutLine(";");

    // Print the program's block followed by a period.
    fmtIndent();
    fmtPrintBlock(programId);
    fmtPutLine(".");
    fmtDetent();
}

void fmtPrintSubroutine(SYMTABNODE *pRoutineId) {
    fmtPrintSubroutineHeader(pRoutineId);
    fmtPutLine(";");

    // Print the routine's block followed by a semicolon
    fmtIndent();
    fmtPrintBlock(pRoutineId->nodeChunkNum);
    fmtPutLine(";");
    fmtDetent();
}

void fmtPrintSubroutineFormals(CHUNKNUM paramId) {
    SYMTABNODE node;
    TDefnCode commonDefnCode;
    DEFN defn, commonDefn;
    TTYPE commonType;
    int doneFlag, saveMargin;

    if (!paramId) {
        return;
    }

    fmtPut(" (");
    saveMargin = fmtSetMargin();

    // Loop to print each sublist of parameters with
    // common definition and type.
    retrieveChunk(paramId, (unsigned char *)&node);
    do {
        retrieveChunk(node.defnChunk, (unsigned char *)&commonDefn);
        commonDefnCode = commonDefn.how;
        retrieveChunk(node.typeChunk, (unsigned char *)&commonType);

        if (commonDefnCode == dcVarParm) {
            fmtPut("VAR ");
        }

        // Loop to print the params in the sublist.
        do {
            fmtPutName(node.nameChunkNum);
            paramId = node.nextNode;
            retrieveChunk(paramId, (unsigned char *)&node);
            retrieveChunk(node.defnChunk, (unsigned char *)&defn);

            doneFlag = (!paramId || commonDefnCode != defn.how
                || commonType.nodeChunkNum != node.typeChunk);
            if (!doneFlag) {
                fmtPut(", ");
            }
        } while (!doneFlag);

        // Print the sublist's common type.
        fmtPut(" : ");
        fmtPrintTypeSpec(commonType.nodeChunkNum, 0);

        if (paramId) {
            fmtPutLine(";");
        }
    } while (paramId);

    fmtPut(")");
    fmtResetMargin(saveMargin);
}

void fmtPrintSubroutineHeader(SYMTABNODE *pRoutineId) {
    DEFN defn;

    fmtPutLine(" ");

    retrieveChunk(pRoutineId->defnChunk, (unsigned char *)&defn);
    fmtPut(defn.how == dcProcedure ? "PROCEDURE " : "FUNCTION ");

    // Print the procedure or function name
    // followed by the formal parameter list.
    fmtPutName(pRoutineId->nameChunkNum);
    fmtPrintSubroutineFormals(defn.routine.locals.parmIds);

    // Print a function's return type
    if (defn.how == dcFunction) {
        fmtPut(" : ");
        fmtPrintTypeSpec(pRoutineId->typeChunk, 0);
    }
}

