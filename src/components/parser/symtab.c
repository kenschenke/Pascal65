#include <stdio.h>
#include <symtab.h>
#include <error.h>
#include <common.h>
#include <string.h>
#include <stdlib.h>

extern int currentLineNumber;

static void freeSymtabLineList(SYMTABLINELIST *pLineList);
static void freeSymtabNode(SYMTABNODE *symtabNode);

static SYMTABLINELIST *makeSymtabLineList(void);
static SYMTABLINENODE *makeSymtabLineNode(void);
static SYMTABNODE *makeSymtabNode(const char *pString);

static void printSymtabLineList(SYMTABLINELIST *pLineList,
    int newLineFlag, int indent);
static void printSymtabNode(SYMTABNODE *pNode);

void addLineNumToSymtabList(SYMTABLINELIST *pLineList)
{
    SYMTABLINENODE *pNode;

    // If the line number is already there, it'll be at the tail
    if (pLineList->tail && pLineList->tail->number == currentLineNumber) {
        return;
    }

    // Append the new node
    pNode = makeSymtabLineNode();
    pLineList->tail->next = pNode;
    pLineList->tail = pNode;
}

void convertSymtab(SYMTAB *symtab, SYMTAB *vpSymtabs[])
{
    int size, i;
    // Point the appropriate entry of the symbol table point vector
    // to this symbol table.
    vpSymtabs[symtab->xSymtab] = symtab;

    // Allocate the symbol table node pointer vector
    for (i = 0, size = 0; i < symtab->cntNodes; i++, size += sizeof(SYMTAB *));
    symtab->vpNodes = malloc(size);
    convertSymtabNode(symtab->root, symtab->vpNodes);
}

void convertSymtabNode(SYMTABNODE *symtabNode, SYMTABNODE *vpNodes[])
{
    // First convert the left subtree
    if (symtabNode->left) {
        convertSymtabNode(symtabNode->left, vpNodes);
    }

    // Convert the node
    vpNodes[symtabNode->xNode] = symtabNode;

    // Finally, convert the right subtree
    if (symtabNode->right) {
        convertSymtabNode(symtabNode->right, vpNodes);
    }
}

SYMTABNODE *enterSymtab(SYMTAB *symtab, const char *pString)
{
    int comp;
    SYMTABNODE *pNode;
    SYMTABNODE **ppNode = &symtab->root;

    // Loop to search table for insertion point
    while ((pNode = *ppNode) != NULL) {
        comp = strcmp(pString, pNode->pString);
        if (comp == 0) {
            break;
        }

        // Not yet found: next search left or right subtree
        ppNode = comp < 0 ? &(pNode->left) : &(pNode->right);
    }

    // Create and insert a new node
    pNode = makeSymtabNode(pString);
    pNode->xSymtab = symtab->xSymtab;
    pNode->xNode = symtab->cntNodes++;
    *ppNode = pNode;
    return pNode;
}

void freeSymtab(SYMTAB *symtab)
{
    // First delete the nodes
    if (symtab->root) {
        freeSymtabNode(symtab->root);
    }

    if (symtab->vpNodes) {
        free(symtab->vpNodes);
    }

    // Then delete the table
    free(symtab);
}

static void freeSymtabLineList(SYMTABLINELIST *pLineList)
{
    SYMTABLINENODE *pNode, *pNext;

    pNode = pNext = pLineList->head;
    while (pNext) {
        pNext = pNode->next;
        free(pNode);
    }
}

static void freeSymtabNode(SYMTABNODE *symtabNode)
{
    // First the subtrees (if any)
    if (symtabNode->left) {
        freeSymtabNode(symtabNode->left);
    }
    if (symtabNode->right) {
        freeSymtabNode(symtabNode->right);
    }

    // Then delete this node's components
    freeSymtabLineList(symtabNode->lineNumList);
    free(symtabNode->pString);
    free(symtabNode);
}

SYMTABNODE *getSymtabNode(SYMTAB *symtab, short xCode)
{
    return symtab->vpNodes[xCode];
}

SYMTAB *makeSymtab(void)
{
    SYMTAB *symtab;

    symtab = malloc(sizeof(SYMTAB));
    if (symtab == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    symtab->cntNodes = 0;
    symtab->root = NULL;
    symtab->xSymtab = 0;
    symtab->vpNodes = NULL;
    symtab->xSymtab = cntSymtabs++;

    symtab->next = pSymtabList;
    pSymtabList = symtab;

    return symtab;
}

static SYMTABLINELIST *makeSymtabLineList(void)
{
    SYMTABLINELIST *pLineNumList;
    
    pLineNumList = malloc(sizeof(SYMTABLINELIST));
    if (pLineNumList == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    pLineNumList->head = pLineNumList->tail = makeSymtabLineNode();

    return pLineNumList;
}

static SYMTABLINENODE *makeSymtabLineNode(void)
{
    SYMTABLINENODE *pNode;

    pNode = malloc(sizeof(SYMTABLINENODE));
    if (pNode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    pNode->next = NULL;
    pNode->number = currentLineNumber;

    return pNode;
}

static SYMTABNODE *makeSymtabNode(const char *pString)
{
    SYMTABNODE *pNode;

    pNode = malloc(sizeof(SYMTABNODE));
    if (pNode == NULL) {
        abortTranslation(abortOutOfMemory);
    }

    pNode->left = pNode->right = NULL;
    pNode->xNode = 0;
    pNode->lineNumList = makeSymtabLineList();

    pNode->pString = malloc(strlen(pString) + 1);
    if (pNode->pString == NULL) {
        abortTranslation(abortOutOfMemory);
    }
    strcpy(pNode->pString, pString);

    return pNode;
}

void printSymtab(SYMTAB *symtab)
{
    printSymtabNode(symtab->root);
}

static void printSymtabLineList(SYMTABLINELIST *pLineList,
    int newLineFlag, int indent)
{
    const int maxLineNumberPrintWidth = 4;
    const int maxLineNumbersPerLine = 10;

    int n;
    SYMTABLINENODE *pNode;

    n = newLineFlag ? 0 : maxLineNumbersPerLine;

    // Loop over line number nodes in the list
    for (pNode = pLineList->head; pNode; pNode = pNode->next) {
        // Start a new line if the current one is full
        if (n == 0) {
            printf("\n%*s", indent, " ");
            n = maxLineNumbersPerLine;
        }

        printf("%*d", maxLineNumberPrintWidth, pNode->number);
        --n;
    }

    printf("\n");
}

static void printSymtabNode(SYMTABNODE *pNode)
{
    const int maxNamePrintWidth = 16;

    // First, print the left subtree
    if (pNode->left) {
        printSymtabNode(pNode->left);
    }

    // Print the node: first the name then the list of line numbers
    printf("%*s\n", maxNamePrintWidth, pNode->pString);
    if (pNode->lineNumList) {
        printSymtabLineList(pNode->lineNumList, 1, maxNamePrintWidth);
    }

    // Finally, print the right subtree
    if (pNode->right) {
        printSymtabNode(pNode->right);
    }
}

SYMTABNODE *searchSymtab(SYMTAB *symtab, const char *pString)
{
    int comp;
    SYMTABNODE *pNode = symtab->root;

    while (pNode) {
        comp = strcmp(pString, pNode->pString);
        if (comp == 0) {
            break;
        }

        // Not yet found: next search left or right substree
        pNode = comp < 0 ? pNode->left : pNode->right;
    }

    if (pNode) {
        addLineNumToSymtabList(pNode->lineNumList);
    }

    return pNode;
}

