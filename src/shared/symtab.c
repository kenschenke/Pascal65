/**
 * symtab.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Symbol table.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <symtab.h>
#include <error.h>
#include <common.h>
#include <string.h>
#include <stdlib.h>
#include <types.h>

#define MAX_NESTING_LEVEL 8

extern short currentLineNumber;

int currentNestingLevel;

static CHUNKNUM symtabStack[MAX_NESTING_LEVEL];

static int compNodeIdentifier(const char *identifier, CHUNKNUM other);
// buffer is caller-supplied and is at least CHUNK_LEN in length
static void freeSymtabNode(CHUNKNUM nodeChunkNum, unsigned char *buffer);

static char makeSymtabNode(SYMTABNODE *pNode, const char *identifier, TDefnCode dc);
static void setCurrentSymtab(CHUNKNUM symtabChunkNum);

static int compNodeIdentifier(const char *identifier, CHUNKNUM other) {
    char otherIdent[CHUNK_LEN];

    if (retrieveChunk(other, (unsigned char *)otherIdent) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return strncmp(identifier, otherIdent, CHUNK_LEN);
}

char enterNew(CHUNKNUM symtabChunkNum, SYMTABNODE *pNode, const char *identifier, TDefnCode dc) {
    if (searchSymtab(symtabChunkNum, pNode, identifier)) {
        Error(errRedefinedIdentifier);
    }

    return enterSymtab(symtabChunkNum, pNode, identifier, dc);
}

char enterSymtab(CHUNKNUM symtabChunkNum, SYMTABNODE *pNode, const char *identifier, TDefnCode dc) {
    int comp;
    SYMTAB symtab;
    CHUNKNUM chunkNum;
    SYMTABNODE node;

    retrieveChunk(symtabChunkNum, (unsigned char *)&symtab);

    chunkNum = symtab.rootChunkNum;

    // Loop to search table for insertion point
    node.nodeChunkNum = 0;
    while (chunkNum != 0) {
        if (retrieveChunk(chunkNum, (unsigned char *)&node) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }
        comp = compNodeIdentifier(identifier, node.nameChunkNum);
        if (comp == 0) {
            memcpy(pNode, &node, sizeof(SYMTABNODE));
            return 1;
        }

        // Not yet found: next search left or right subtree
        chunkNum = comp < 0 ? node.leftChunkNum : node.rightChunkNum;
    }

    // Create and insert a new node
    if (makeSymtabNode(pNode, identifier, dc) == 0) {
        return 0;
    }

    // Update the parent chunk to point to this one
    if (node.nodeChunkNum == 0) {
        symtab.rootChunkNum = pNode->nodeChunkNum;
    } else {
        // Don't need to retrieve node since it is still
        // populated from the loop.
        if (comp < 0) {
            node.leftChunkNum = pNode->nodeChunkNum;
        }
        else {
            node.rightChunkNum = pNode->nodeChunkNum;
        }
        if (storeChunk(node.nodeChunkNum, (unsigned char *)&node) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }
    }

    if (storeChunk(symtab.symtabChunkNum, (unsigned char *)&symtab) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    if (storeChunk(pNode->nodeChunkNum, (unsigned char *)pNode) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    return 1;
}

void freeDefn(DEFN *pDefn) {
    switch(pDefn->how) {
        case dcProgram:
        case dcProcedure:
        case dcFunction:
            if (pDefn->routine.which == rcDeclared) {
                freeChunk(pDefn->routine.symtab);
                freeChunk(pDefn->routine.Icode);
            }
            break;
        
        default:
            break;
    }
}

void freeSymtab(CHUNKNUM symtabChunkNum) {
    CHUNKNUM chunkNum = firstSymtabChunk, lastChunkNum = 0;
    CHUNKNUM nextChunkNum, rootNodeChunkNum;
    SYMTAB symtab;

    while (chunkNum) {
        if (retrieveChunk(chunkNum, (unsigned char *)&symtab) == 0) {
            return;
        }

        nextChunkNum = symtab.nextSymtabChunk;
        rootNodeChunkNum = symtab.rootChunkNum;
        if (chunkNum == symtabChunkNum) {
            if (lastChunkNum) {
                if (retrieveChunk(lastChunkNum, (unsigned char *)&symtab) == 0) {
                    return;
                }
                symtab.nextSymtabChunk = nextChunkNum;
                if (storeChunk(symtab.symtabChunkNum, (unsigned char *)&symtab) == 0) {
                    return;
                }
            } else {
                firstSymtabChunk = nextChunkNum;
            }

            freeSymtabNode(rootNodeChunkNum, (unsigned char *)&symtab);
            freeChunk(chunkNum);

            break;
        }

        lastChunkNum = chunkNum;
        chunkNum = nextChunkNum;
    }
}

// Buffer is caller-supplied and at least CHUNK_LEN in length
static void freeSymtabNode(CHUNKNUM nodeChunkNum, unsigned char *buffer)
{
    CHUNKNUM leftChunkNum, rightChunkNum, nameChunkNum, defnChunkNum;
    SYMTABNODE *pNode = (SYMTABNODE *)buffer;
    DEFN defn;

    if (retrieveChunk(nodeChunkNum, buffer) == 0) {
        return;
    }

    leftChunkNum = pNode->leftChunkNum;
    rightChunkNum = pNode->rightChunkNum;
    nameChunkNum = pNode->nameChunkNum;
    defnChunkNum = pNode->defnChunk;

    // First the subtrees (if any)
    if (leftChunkNum) {
        freeSymtabNode(leftChunkNum, buffer);
    }
    if (rightChunkNum) {
        freeSymtabNode(rightChunkNum, buffer);
    }

    if (retrieveChunk(defnChunkNum, (unsigned char *)&defn)) {
        freeDefn(&defn);
        freeChunk(defnChunkNum);
    }

    freeChunk(nameChunkNum);
    freeChunk(nodeChunkNum);
}

char makeSymtab(CHUNKNUM *symtabChunkNum)
{
    SYMTAB symtab;

    if (allocChunk(symtabChunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    symtab.symtabChunkNum = *symtabChunkNum;
    symtab.cntNodes = 0;
    symtab.rootChunkNum = 0;
    symtab.xSymtab = cntSymtabs++;

    symtab.nextSymtabChunk = firstSymtabChunk;
    firstSymtabChunk = *symtabChunkNum;

    if (storeChunk(*symtabChunkNum, (unsigned char *)&symtab) == 0) {
        return 0;
    }

    return 1;
}

static char makeSymtabNode(SYMTABNODE *pNode, const char *identifier, TDefnCode dc)
{
    unsigned char identChunk[CHUNK_LEN];
    DEFN defn;

    // Make sure the identifier isn't too long
    if (strlen(identifier) > CHUNK_LEN) {
        Error(errIdentifierTooLong);
        return 0;
    }

    // Allocate a chunk for the node
    if (allocChunk(&pNode->nodeChunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    // Allocate a chunk to store the node's identifier
    if (allocChunk(&pNode->nameChunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    // Store the identifier
    memset(identChunk, 0, sizeof(identChunk));
    memcpy(identChunk, identifier, strlen(identifier));
    if (storeChunk(pNode->nameChunkNum, identChunk) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    // Allocate a chunk for the type definition
    if (allocChunk(&pNode->defnChunk) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }
    memset(&defn, 0, sizeof(DEFN));
    defn.how = dc;
    if (storeChunk(pNode->defnChunk, (unsigned char *)&defn) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    pNode->leftChunkNum = pNode->rightChunkNum = 0;
    pNode->nextNode = pNode->typeChunk = 0;

    return 1;
}

char searchSymtab(CHUNKNUM symtabChunkNum, SYMTABNODE *pNode, const char *identifier) {
    int comp;
    SYMTAB symtab;
    CHUNKNUM chunkNum;

    retrieveChunk(symtabChunkNum, (unsigned char *)&symtab);
    
    chunkNum = symtab.rootChunkNum;

    while (chunkNum) {
        if (retrieveChunk(chunkNum, (unsigned char *)pNode) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }

        comp = compNodeIdentifier(identifier, pNode->nameChunkNum);
        if (comp == 0) {
            break;
        }

        // Not found yet: next search left or right subtree
        chunkNum = comp < 0 ? pNode->leftChunkNum : pNode->rightChunkNum;
    }

    if (chunkNum) {
        // Add line number to symbol list
    }

    return chunkNum ? 1 : 0;
}

void initSymtabs(void) {
    int i;

    currentNestingLevel = 0;
    for (i = 1; i < MAX_NESTING_LEVEL; ++i) symtabStack[i] = 0;

    makeSymtab(&globalSymtab);

    symtabStack[0] = globalSymtab;

    initPredefinedTypes(&symtabStack[0]);
    // initStandardRoutines(&symtabStack[0]);
}

static void setCurrentSymtab(CHUNKNUM symtabChunkNum) {
    symtabStack[currentNestingLevel] = symtabChunkNum;
}

void symtabStackEnterScope(void) {
    CHUNKNUM chunkNum;

    if (++currentNestingLevel > MAX_NESTING_LEVEL) {
        Error(errNestingTooDeep);
        abortTranslation(abortNestingTooDeep);
    }

    makeSymtab(&chunkNum);
    setCurrentSymtab(chunkNum);
}

void symtabExitScope(CHUNKNUM *symtabChunkNum) {
    *symtabChunkNum = symtabStack[currentNestingLevel--];
}

void symtabStackFind(const char *pString, SYMTABNODE *pNode) {
    if (symtabStackSearchAll(pString, pNode) == 0) {
        Error(errUndefinedIdentifier);
        enterSymtab(symtabStack[currentNestingLevel], pNode, pString, dcUndefined);
    }
}

char symtabStackSearchAll(const char *pString, SYMTABNODE *pNode) {
    int i;

    for (i = currentNestingLevel; i >= 0; --i) {
        if (searchSymtab(symtabStack[i], pNode, pString)) {
            return 1;
        }
    }

    return 0;
}

char symtabSearchLocal(SYMTABNODE *pNode, const char *pString) {
    return searchSymtab(symtabStack[currentNestingLevel], pNode, pString);
}

char symtabEnterLocal(SYMTABNODE *pNode, const char *pString, TDefnCode dc) {
    return enterSymtab(symtabStack[currentNestingLevel], pNode, pString, dc);
}

char symtabEnterNewLocal(SYMTABNODE *pNode, const char *pString, TDefnCode dc) {
    return enterNew(symtabStack[currentNestingLevel], pNode, pString, dc);
}

CHUNKNUM getCurrentSymtab(void) {
    return symtabStack[currentNestingLevel];
}
