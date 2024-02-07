#include <stdio.h>
#include <codegen.h>
#include <chunks.h>
#include <error.h>
#include <string.h>
#include <common.h>
#include <asm.h>
#include <membuf.h>
#include <int16.h>

#define BUFLEN 20

// Page number of the library
static unsigned char page;

// Base of library after relocation
static unsigned short libBase;

// Buffer to store library
static CHUNKNUM libBuf;

// Referenced imports
static CHUNKNUM imports;

static void addImportLibNums(CHUNKNUM chunkNum);
static int compExportRoutine(struct rtroutine *r1, struct rtroutine *r2);
static int compImportRoutine(struct rtroutine *r1, struct rtroutine *r2);
static void freeRoutines(CHUNKNUM chunkNum);
static char getRoutineNum(CHUNKNUM chunkNum, char libNum, char routineSeq);
static char getLibNum(CHUNKNUM chunkNum, char routineNum);
static char *getNextRoutine(char *buffer, unsigned char *exportNum, char *isExport);
static char isLibNeeded(char num);
static int processExportsTable(char libNum, int pos, FILE *fh);
static int processImportsTable(char libNum, int pos, FILE *fh);
static void readLibrary(FILE *fh, int length, char skip);
static void readRuntimeLib(FILE *fh, int libLength, char libNum);
static unsigned short relocate(unsigned char p, unsigned char o);
static void saveRoutine(unsigned char exportNum, char libNum,
    char routineSeq, CHUNKNUM *root,
    int (*comp)(struct rtroutine *, struct rtroutine *));

static void addImportLibNums(CHUNKNUM chunkNum)
{
    char libNum;
    struct rtroutine routine;

    if (!chunkNum) {
        return;
    }

    retrieveChunk(chunkNum, &routine);
    libNum = getLibNum(exports, routine.routineNum);
    libsNeeded[libNum / 8] |= (1 << (libNum % 8));
    addImportLibNums(routine.left);
    addImportLibNums(routine.right);
}

static int compExportRoutine(struct rtroutine *r1, struct rtroutine *r2)
{
    int st;

    if (r1->routineNum < r2->routineNum) {
        st = -1;
    } else if (r1->routineNum > r2->routineNum) {
        st = 1;
    } else {
        st = 0;
    }

    return st;
}

static int compImportRoutine(struct rtroutine *r1, struct rtroutine *r2)
{
    int st;

    if (r1->routineNum < r2->routineNum) {
        st = -1;
    } else if (r1->routineNum > r2->routineNum) {
        st = 1;
    } else if (r1->libNum < r2->libNum) {
        st = -1;
    } else if (r1->libNum > r2->libNum) {
        st = 1;
    } else if (r1->routineSeq < r2->routineSeq) {
        st = -1;
    } else if (r1->routineSeq > r2->routineSeq) {
        st = 1;
    } else {
        st = 0;
    }

    return st;
}

static void freeRoutines(CHUNKNUM chunkNum)
{
    if (chunkNum) {
        struct rtroutine routine;
        retrieveChunk(chunkNum, &routine);
        freeRoutines(routine.left);
        freeRoutines(routine.right);
        freeChunk(chunkNum);
    }
}

static char getRoutineNum(CHUNKNUM chunkNum, char libNum, char routineSeq)
{
    char routineNum;
    struct rtroutine routine;

    if (!chunkNum) {
        return 0;
    }

    retrieveChunk(chunkNum, &routine);
    if (routine.libNum == libNum && routine.routineSeq == routineSeq) {
        return routine.routineNum;
    }

    if (routineNum = getRoutineNum(routine.left, libNum, routineSeq)) {
        return routineNum;
    }
    if (routineNum = getRoutineNum(routine.right, libNum, routineSeq)) {
        return routineNum;
    }

    return 0;
}

static char getLibNum(CHUNKNUM chunkNum, char routineNum)
{
    char libNum;
    struct rtroutine routine;

    if (!chunkNum) {
        return 0;
    }

    retrieveChunk(chunkNum, &routine);
    if (routine.routineNum == routineNum) {
        return routine.libNum;
    }

    if (libNum = getLibNum(routine.left, routineNum)) {
        return libNum;
    }
    if (libNum = getLibNum(routine.right, routineNum)) {
        return libNum;
    }

    return 0;
}

static char *getNextRoutine(char *buffer, unsigned char *exportNum, char *isExport)
{
	char *p, *start = buffer;
    char buf[15];

	// Skip spaces

	while (1) {
		if (*start == 0 || *start == '#') {
			return 0;
		}
		if (*start == ' ') {
			++start;
		}
		else {
			break;
		}
	}

	p = start;
	while (*p) {
		if (*p == ' ') {
			break;
		}

		++p;
	}

    if (*start == '<') {
        *isExport = 1;
    }
    else if (*start == '>') {
        *isExport = 0;
    }
    else {
        return 0;
    }

	strncpy(buf, start + 1, p - start - 1);
    buf[p - start - 1] = 0;
    *exportNum = (unsigned char) parseInt16(buf);

	return p;
}

static char isLibNeeded(char num)
{
    if (num > MAX_LIBS) {
        abortTranslation(abortRuntimeError);
    }

    return libsNeeded[num / 8] & (1 << (num % 8));
}

void linkerWriteRuntime(void)
{
    unsigned char buffer[2];
    FILE *fh;
    int modLength;  // length of module in runtime.lib
    char libNum = 0; // module number

    addImportLibNums(imports);

    fh = fopen("runtime.lib", "rb");
    if (!fh) {
        abortTranslation(abortRuntimeError);
    }

    // Go through each of the modules in the runtime.lib file
    // and add the ones referenced to the executable.
    while(1) {
        // Read the module length
        if (fread(buffer, 1, 2, fh) != 2) {
            fclose(fh);
            abortTranslation(abortRuntimeError);
        }

        if (!buffer[0] && !buffer[1]) {
            // End of runtime.lib
            break;
        }

        modLength = (int)(buffer[1]) * 256 + buffer[0];
        if (!isLibNeeded(libNum)) {
            // This module is not referenced - skip it.
            readLibrary(fh, modLength, 1);
        } else {
            readRuntimeLib(fh, modLength, libNum);
        }

        ++libNum;
    }

    fclose(fh);

    freeRoutines(exports);
    freeRoutines(imports);
    exports = 0;
    imports = 0;
    memset(libsNeeded, 0, sizeof(libsNeeded));
}

static int processExportsTable(char libNum, int pos, FILE *fh)
{
    unsigned char buffer[3];
    char name[16 + 1], exportSeq = 0;
    unsigned short relocAddr;

    while (1) {
        if (fread(buffer, 1, 3, fh) != 3) {
            return 0;
        }
        pos += 3;
        if (!buffer[0] && !buffer[1] && !buffer[2]) {
            writeCodeBuf(buffer, 3);
            break;
        }

        if (buffer[0] != JMP) {
            return 0;
        }

        relocAddr = relocate(buffer[2], buffer[1]);
        buffer[1] = WORD_LOW(relocAddr);
        buffer[2] = WORD_HIGH(relocAddr);

        strcpy(name, "rt_");
        strcat(name, formatInt16(getRoutineNum(exports, libNum, exportSeq)));
        linkAddressSet(name, codeOffset);
        writeCodeBuf(buffer, 3);

        ++exportSeq;
    }

    return pos;
}

static int processImportsTable(char libNum, int pos, FILE *fh)
{
    unsigned char buffer[3];
    char name[16 + 1], importSeq = 0;

    while (1) {
        if (fread(buffer, 1, 3, fh) != 3) {
            return 0;
        }
        pos += 3;
        if (!buffer[0] && !buffer[1] && !buffer[2]) {
            writeCodeBuf(buffer, 3);
            break;
        }

        if (buffer[0] != JMP) {
            return 0;
        }

        strcpy(name, "rt_");
        strcat(name, formatInt16(getRoutineNum(imports, libNum, importSeq)));
        linkAddressLookup(name, codeOffset + 1, 0, LINKADDR_BOTH);
        writeCodeBuf(buffer, 3);

        ++importSeq;
    }

    return pos;
}

void readRuntimeDefFile(void)
{
    int i;
    char isExport, num = 0;
    char *p;
    char buffer[128 + 1];
    unsigned char exportNum;
    char exportSeq, importSeq;
    FILE *fh;

    fh = fopen("runtime.def", "r");
    if (fh == NULL) {
        abortTranslation(abortRuntimeError);
    }

    while (!feof(fh)) {
        fgets(buffer, sizeof(buffer), fh);

        // remove end of line chars
        i = strlen(buffer) - 1;
        while (i >= 0) {
            if (buffer[i] == '\r' || buffer[i] == '\n') {
                buffer[i--] = 0;
            } else {
                break;
            }
        }

        p = buffer;
        exportSeq = importSeq = 0;
        while (p) {
            p = getNextRoutine(p, &exportNum, &isExport);
            if (!p) {
                break;
            }

            saveRoutine(exportNum, num, isExport ? exportSeq : importSeq,
                isExport ? &exports : &imports,
                isExport ? compExportRoutine : compImportRoutine);
            if (isExport) {
                ++exportSeq;
            } else {
                ++importSeq;
            }
        }

        if (exportSeq || importSeq) {
            ++num;
        }
    }

    fclose(fh);
}

static void readLibrary(FILE* fh, int length, char skip)
{
    int toRead;
    unsigned char buffer[BUFLEN];

    while (length) {
        toRead = length < BUFLEN ? length : BUFLEN;
        if (fread(buffer, 1, toRead, fh) != toRead) {
            fclose(fh);
            abortTranslation(abortRuntimeError);
        }

        if (!skip) {
            writeToMemBuf(libBuf, buffer, toRead);
        }

        length -= toRead;
    }
}

static void readRuntimeLib(FILE *fh, int libLength, char libNum)
{
    char pages;             // number of pages in the library file
    int i, n, pos;
    unsigned char buffer[BUFLEN];

    libBase = codeBase + codeOffset;

    if (fread(buffer, sizeof(char), 2, fh) != 2) {
        abortTranslation(abortRuntimeError);
    }
    pos = 2;

    if (buffer[0]) {
        return;
    }

    page = buffer[1];
    pages = libLength / 256 + (libLength % 256 ? 1 : 0);

    pos = processExportsTable(libNum, pos, fh);
    if (!pos) {
        return;
    }

    pos = processImportsTable(libNum, pos, fh);
    if (!pos) {
        return;
    }

    // This loop reads object code from the library file.
    // It loads bytes into the buffer and searches for addresses
    // to relocate.  Because addresses are two bytes, it doesn't
    // want to miss an address that might be in the last byte of
    // a read cycle.  For this reason it always retains the
    // last byte from the previous cycle.

    // prime the buffer
    if (fread(buffer, 1, 1, fh) != 1) {
        abortTranslation(abortRuntimeError);
    }
    ++pos;
    while (pos < libLength) {
        n = (pos + BUFLEN < (libLength+1) ? (BUFLEN - 1) : libLength - pos);
        if (fread(buffer + 1, 1, n, fh) != n) {
            abortTranslation(abortRuntimeError);
        }

        for (i = 0; i <= n; ++i) {
            if (i < n && buffer[i + 1] >= page && buffer[i + 1] <= page + pages - 1) {
                short relocAddr = relocate(buffer[i + 1], buffer[i]);
                buffer[i] = WORD_LOW(relocAddr);
                buffer[i + 1] = WORD_HIGH(relocAddr);
                ++i;
            }
        }
        writeCodeBuf(buffer, n);

        buffer[0] = buffer[n];
        pos += n;
    }

    writeCodeBuf(buffer, 1);
}

// This function returns the relocated address from the
// page (p) and the offset (o) of the supplied address.
static unsigned short relocate(unsigned char p, unsigned char o)
{
    return libBase + ((unsigned short)p - page) * 256 + o;
}

static void saveRoutine(unsigned char routineNum, char libNum,
    char routineSeq, CHUNKNUM *root,
    int (*compare)(struct rtroutine *, struct rtroutine *))
{
    CHUNKNUM newChunkNum, chunkNum;
    struct rtroutine routine, newRoutine;
    int comp;

    allocChunk(&newChunkNum);
    memset(&newRoutine, 0, sizeof(struct rtroutine));
    newRoutine.routineNum = routineNum;
    newRoutine.libNum = libNum;
    newRoutine.routineSeq = routineSeq;
    storeChunk(newChunkNum, &newRoutine);

    if (!(*root)) {
        *root = newChunkNum;
        return;
    }

    chunkNum = *root;
    while (chunkNum) {
        retrieveChunk(chunkNum, &routine);
        comp = compare(&newRoutine, &routine);
        if (comp == 0) {
            freeChunk(newChunkNum);
            abortTranslation(abortRuntimeError);
            return; // routine already in tree
        }
        if (comp < 0) {
            if (routine.left) {
                chunkNum = routine.left;
                continue;
            }
        }
        else if(routine.right) {
            chunkNum = routine.right;
            continue;
        }

        break;
    }

    if (routineNum < routine.routineNum)
        routine.left = newChunkNum;
    else
        routine.right = newChunkNum;
    storeChunk(chunkNum, &routine);
}

