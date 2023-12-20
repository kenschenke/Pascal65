#include <symtab.h>
#include <common.h>
#include <error.h>

static void initSymtabs(void);

void initSemantic(void)
{
    initSymtabs();
}

static void initSymtabs(void)
{
#if 0
    int i;

    for (i = 1; i < MAX_NESTING_LEVEL; ++i) symtabStack[i] = 0;

    makeSymtab(&globalSymtab);

    symtabStack[0] = globalSymtab;

    initPredefinedTypes(symtabStack[0]);
#endif
}

