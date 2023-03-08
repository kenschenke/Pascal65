/**
 * error.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Code for raising errors.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>

#include <error.h>
#include <ovrlcommon.h>
#include <common.h>
#include <string.h>
#include <chunks.h>
#include <ctype.h>

unsigned errorCount = 0;
unsigned errorArrowFlag = 1;
unsigned errorArrowOffset = 8;

static CHUNKNUM abortMsg;
static CHUNKNUM errorMessages;
static CHUNKNUM runtimeErrorMessages;

static char msgbuf[CHUNK_LEN + 1];

static void getMessage(CHUNKNUM chunkNum, int msgNum);
static void readErrorFile(char *filename, CHUNKNUM *msgs, int numMsgs);

void abortTranslation(TAbortCode ac)
{
    if (!abortMsg) {
        readErrorFile("abortmsgs", &abortMsg, numAbortErrors);
    }

    getMessage(abortMsg, (int) (-ac) - 1);
    logFatalError(msgbuf);
    isFatalError = 1;
#if 1
    exit(0);
#endif
}

void Error(TErrorCode ec)
{
    const int maxSyntaxErrors = 25;

    if (!errorMessages) {
        readErrorFile("errormsgs", &errorMessages, numParserErrors);
    }

    getMessage(errorMessages, (int) ec);
    logError(msgbuf, currentLineNumber, ec);
    if (++errorCount > maxSyntaxErrors) {
        abortTranslation(abortTooManySyntaxErrors);
    }
}

static void getMessage(CHUNKNUM chunkNum, int msgNum)
{
    char chunk[CHUNK_LEN];

    setMemBufPos(chunkNum, msgNum * CHUNK_LEN);
    readFromMemBuf(chunkNum, chunk, CHUNK_LEN);
    sprintf(msgbuf, "%.*s", CHUNK_LEN, chunk);
}

static void readErrorFile(char *filename, CHUNKNUM *msgs, int numMsgs) {
    FILE *fp;
    int i;
    char buf[40];

    allocMemBuf(msgs);
    reserveMemBuf(*msgs, numMsgs * CHUNK_LEN);
    setMemBufPos(*msgs, 0);

    fp = fopen(filename, "r");
    if (fp == NULL) {
        logFatalError("Error message file missing");
        isFatalError = 1;
        return;
    }

    for (i = 0; i < numMsgs; ++i) {
        if (!fgets(buf, sizeof(buf), fp)) {
            logFatalError("Error reading from error message file");
            isFatalError = 1;
            fclose(fp);
            return;
        }

        while (isspace(buf[strlen(buf)-1])) {
            buf[strlen(buf)-1] = 0;
        }

        if (strlen(buf) > CHUNK_LEN) {
            logFatalError("Error message too long");
            isFatalError = 1;
            fclose(fp);
            return;
        }

        writeToMemBuf(*msgs, buf, CHUNK_LEN);
    }

    fclose(fp);
}

void runtimeError(TRuntimeErrorCode ec)
{
    if (!runtimeErrorMessages) {
        readErrorFile("runtimemsgs", &runtimeErrorMessages, numRuntimeErrors);
    }

    getMessage(runtimeErrorMessages, (int) ec);
    logRuntimeError(msgbuf, currentLineNumber);
    isFatalError = 1;
}

