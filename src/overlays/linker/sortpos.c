// This code takes the linker tags and sorts them in
// order by position.

#include <chunks.h>
#include <codegen.h>
#include <membuf.h>
#include <string.h>
#include <error.h>

#define SORTSTACK_SIZE 36

struct TREETAG {
    CHUNKNUM left, right;
    struct LINKTAG tag;
    char unused[CHUNK_LEN - 9];
};

static struct LINKTAG tag;
static struct TREETAG tg;

static CHUNKNUM tagTree;
static CHUNKNUM sortStack[SORTSTACK_SIZE];
static char sortStackTop;

static void addTagToTree(void);
static void freeTagTree(void);
static void pushSortStack(CHUNKNUM chunkNum);
static CHUNKNUM popSortStack(void);
static void saveSortedTags(void);

static void addTagToTree(void)
{
    CHUNKNUM chunkNum, newChunkNum, lastChunkNum;
    int comp;

    allocChunk(&newChunkNum);
    tg.left = tg.right = 0;
    memcpy(&tg.tag, &tag, sizeof(struct LINKTAG));
    storeChunk(newChunkNum, &tg);
    if (!tagTree) {
        tagTree = newChunkNum;
        return;
    }

    chunkNum = tagTree;
    while (chunkNum) {
        retrieveChunk(chunkNum, &tg);
        if (tag.position == tg.tag.position) {
            freeChunk(newChunkNum);
            return;
        }
        comp = tag.position < tg.tag.position ? -1 : 1;
        lastChunkNum = chunkNum;
        chunkNum = comp < 0 ? tg.left : tg.right;
    }

    retrieveChunk(lastChunkNum, &tg);
    if (comp < 0) {
        tg.left = newChunkNum;
    } else {
        tg.right = newChunkNum;
    }
    storeChunk(lastChunkNum, &tg);
}

static void freeTagTree(void)
{
    char done = 0;
    CHUNKNUM chunkNum = tagTree;
    sortStackTop = 0;

    while (!done) {
        if (chunkNum) {
            retrieveChunk(chunkNum, &tg);
            pushSortStack(chunkNum);
            chunkNum = tg.left;
        } else {
            if (sortStackTop) {
                chunkNum = popSortStack();
                retrieveChunk(chunkNum, &tg);
                freeChunk(chunkNum);
                chunkNum = tg.right;
            } else {
                done = 1;
            }
        }
    }
}

static void saveSortedTags(void)
{
    char done = 0;
    CHUNKNUM chunkNum = tagTree;
    sortStackTop = 0;

    while (!done) {
        if (chunkNum) {
            retrieveChunk(chunkNum, &tg);
            pushSortStack(chunkNum);
            chunkNum = tg.left;
        } else {
            if (sortStackTop) {
                chunkNum = popSortStack();
                retrieveChunk(chunkNum, &tg);
                writeToMemBuf(linkerTags, &tg.tag, sizeof(struct LINKTAG));
                chunkNum = tg.right;
            } else {
                done = 1;
            }
        }
    }
}

static void pushSortStack(CHUNKNUM chunkNum)
{
    if (sortStackTop >= SORTSTACK_SIZE) {
        runtimeError(rteStackOverflow);
    }
    sortStack[sortStackTop++] = chunkNum;
}

static CHUNKNUM popSortStack(void)
{
    return sortStack[--sortStackTop];
}

void sortLinkerTags(void)
{
    setMemBufPos(linkerTags, 0);
    tagTree = 0;
    while (!isMemBufAtEnd(linkerTags)) {
        readFromMemBuf(linkerTags, &tag, sizeof(struct LINKTAG));
        addTagToTree();
    }

    freeMemBuf(linkerTags);
    allocMemBuf(&linkerTags);
    saveSortedTags();
    freeTagTree();
}
