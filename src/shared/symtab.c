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

extern short currentLineNumber;

static int compNodeIdentifier(const char *identifier, CHUNKNUM other);
// buffer is caller-supplied and is at least CHUNK_LEN in length
static void freeSymtabNode(CHUNKNUM nodeChunkNum, unsigned char *buffer);

static char makeSymtabNode(SYMTABNODE *pNode, const char *identifier);

static int compNodeIdentifier(const char *identifier, CHUNKNUM other) {
    char otherIdent[CHUNK_LEN];

    if (retrieveChunk(other, (unsigned char *)otherIdent) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    return strncmp(identifier, otherIdent, CHUNK_LEN);
}

char enterSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier) {
    int comp;
    CHUNKNUM chunkNum = symtab->rootChunkNum;
    SYMTABNODE node;

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
    if (makeSymtabNode(pNode, identifier) == 0) {
        return 0;
    }
    pNode->xSymtab = symtab->xSymtab;
    pNode->xNode = symtab->cntNodes++;

    // Update the parent chunk to point to this one
    if (node.nodeChunkNum == 0) {
        symtab->rootChunkNum = pNode->nodeChunkNum;
    } else {
        // Don't need to retrieve node since it is still
        // populated from the loop.
        if (comp < 0)
            node.leftChunkNum = pNode->nodeChunkNum;
        else
            node.rightChunkNum = pNode->nodeChunkNum;
        if (storeChunk(node.nodeChunkNum, (unsigned char *)&node) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }
    }

    if (storeChunk(symtab->symtabChunkNum, (unsigned char *)symtab) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    if (storeChunk(pNode->nodeChunkNum, (unsigned char *)pNode) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    return 1;
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
    CHUNKNUM leftChunkNum, rightChunkNum, stringChunkNum, nameChunkNum;
    SYMTABNODE *pNode = (SYMTABNODE *)buffer;
    STRVALCHUNK *pStrVal;

    if (retrieveChunk(nodeChunkNum, buffer) == 0) {
        return;
    }

    leftChunkNum = pNode->leftChunkNum;
    rightChunkNum = pNode->rightChunkNum;
    nameChunkNum = pNode->nameChunkNum;

    if (pNode->valueType == valString) {
        memcpy(&stringChunkNum, pNode->value + 2, sizeof(CHUNKNUM));
        pStrVal = (STRVALCHUNK *)buffer;
        while (stringChunkNum) {
            if (retrieveChunk(stringChunkNum, buffer) == 0) {
                return;
            }
            freeChunk(stringChunkNum);
            stringChunkNum = pStrVal->nextChunkNum;
        }
    }

    // First the subtrees (if any)
    if (leftChunkNum) {
        freeSymtabNode(leftChunkNum, buffer);
    }
    if (rightChunkNum) {
        freeSymtabNode(rightChunkNum, buffer);
    }

    freeChunk(nameChunkNum);
    freeChunk(nodeChunkNum);
}

char makeSymtab(SYMTAB *pSymtab)
{
    CHUNKNUM chunkNum;

    if (allocChunk(&chunkNum) == 0) {
        abortTranslation(abortOutOfMemory);
    }

    pSymtab->symtabChunkNum = chunkNum;
    pSymtab->cntNodes = 0;
    pSymtab->cntNodes = 0;
    pSymtab->xSymtab = cntSymtabs++;

    pSymtab->nextSymtabChunk = firstSymtabChunk;
    firstSymtabChunk = chunkNum;

    if (storeChunk(chunkNum, (unsigned char *)pSymtab) == 0) {
        return 0;
    }

    return 1;
}

static char makeSymtabNode(SYMTABNODE *pNode, const char *identifier)
{
    unsigned char identChunk[CHUNK_LEN];

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

    // Allocate a chunk to store the node's identifier (variable name)
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

    pNode->leftChunkNum = pNode->rightChunkNum = 0;
    pNode->xNode = 0;
    memset(pNode->value, 0, sizeof(pNode->value));

    return 1;
}

char searchSymtab(SYMTAB *symtab, SYMTABNODE *pNode, const char *identifier) {
    int comp;
    CHUNKNUM chunkNum = symtab->rootChunkNum;

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

char setSymtabInt(SYMTABNODE *pNode, int value) {
    pNode->valueType = (char) valInteger;
    memcpy(pNode->value, &value, sizeof(value));

    if (storeChunk(pNode->nodeChunkNum, (unsigned char *)pNode) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    return 1;
}

char setSymtabString(SYMTABNODE *pNode, const char *value) {
    CHUNKNUM chunkNum, nextChunkNum;
    const char *p = value;
    char isAlloc;  // non-zero if the next chunk is new
    STRVALCHUNK chunk;
    int toCopy, len = strlen(value);

    pNode->valueType = (char) valString;
    memcpy(pNode->value, &len, sizeof(len));

    // Store the string as one or more chunks

    // If there is already a string value for this node, replace it.
    memcpy(&chunkNum, pNode->value + 2, sizeof(CHUNKNUM));
    if (chunkNum) {
        // There's already a chunk - retrieve it
        if (retrieveChunk(chunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }
    } else {
        // No value assigned yet - allocate a new chunk
        if (allocChunk(&chunkNum) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }
        // Store the chunkNum in the node as the first value chunk
        memcpy(pNode->value + 2, &chunkNum, sizeof(CHUNKNUM));
        chunk.nextChunkNum = 0;
    }

    while (len) {
        memset(chunk.value, 0, sizeof(chunk.value));
        toCopy = len > sizeof(chunk.value) ? sizeof(chunk.value) : len;
        memcpy(chunk.value, p, toCopy);
        len -= toCopy;
        p += toCopy;

        nextChunkNum = chunk.nextChunkNum;
        if (len) {
            if (nextChunkNum == 0) {
                if (allocChunk(&nextChunkNum) == 0) {
                    abortTranslation(abortOutOfMemory);
                    return 0;
                }
                isAlloc = 1;
                chunk.nextChunkNum = nextChunkNum;
            } else {
                isAlloc = 0;
            }
        } else {
            chunk.nextChunkNum = 0;
        }

        if (storeChunk(chunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }

        chunkNum = nextChunkNum;
        if (chunkNum) {
            if (isAlloc) {
                memset(&chunk, 0, sizeof(chunk));
            } else {
                if (retrieveChunk(chunkNum, (unsigned char *)&chunk) == 0) {
                    abortTranslation(abortOutOfMemory);
                    return 0;
                }
            }
        }
    }

    while (nextChunkNum) {
        if (retrieveChunk(nextChunkNum, (unsigned char *)&chunk) == 0) {
            abortTranslation(abortOutOfMemory);
            return 0;
        }

        freeChunk(nextChunkNum);
        nextChunkNum = chunk.nextChunkNum;
    }

    if (storeChunk(pNode->nodeChunkNum, (unsigned char *)pNode) == 0) {
        abortTranslation(abortOutOfMemory);
        return 0;
    }

    return 1;
}

