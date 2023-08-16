#include <stdio.h>
#include <stdlib.h>

struct MATENT
{
    short size;
    void *ptr;
};

void *heapAlloc(short size);
void heapFree(void *p);
void heapInit(void);

extern void *heapPtr;

static void allocateBlock(void);
static void dumpMAT(void);
static void freeBlock(void);
static void printOptions(void);

static void allocateBlock(void)
{
    void *p;
    char buf[99];
    int num;

    printf("Size to allocate: ");
    fgets(buf, sizeof(buf), stdin);
    num = atoi(buf);
    p = heapAlloc(num);

    printf("\nAllocated buffer at %04x\n", p);
}

static void dumpMAT(void)
{
    char free;
    int i = 0;
    short size;

    struct MATENT *pEnt;

    pEnt = (struct MATENT *)heapPtr;
    while (pEnt->size || pEnt->ptr) {
        ++i;
        size = pEnt->size;
        if (size & 0x8000) {
            free = 0;
            size &= 0x7ff;
        } else {
            free = 1;
        }
        printf("%2d: %4d  %04x  free: %s\n", i, size, pEnt->ptr, free ? "Yes" : "No");

        --pEnt;
    }

    printf("\n%d entr%s found\n", i, i == 1 ? "y" : "ies");
}

static void freeBlock(void)
{
    char buf[99];
    int num, i = 0;
    struct MATENT *pEnt;

    printf("Block number to free: ");
    fgets(buf, sizeof(buf), stdin);
    num = atoi(buf);
    
    pEnt = (struct MATENT *)heapPtr;
    while (pEnt->size || pEnt->ptr) {
        if (++i == num) {
            heapFree(pEnt->ptr);
            break;
        }

        --pEnt;
    }
}

static void printOptions(void)
{
    printf("\n  A. Allocate a block\n");
    printf("  F. Free a block\n");
    printf("\nChoice: ");
}

int main()
{
    char ch;

    printf("Initializing heap\n");
    heapInit();
    printf("heapTop = %p\n", heapPtr);

    while (1) {
        printf("\n");
        dumpMAT();
        printOptions();
        ch = getchar();
        printf("\n\n");
        if (ch == 'a') {
            // Allocate
            allocateBlock();
        } else if (ch == 'f') {
            // Free
            freeBlock();
        } else {
            printf("Unrecognized option '%c'\n", ch);
        }
    }

    return 0;
}
