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

unsigned errorCount = 0;
unsigned errorArrowFlag = 1;
unsigned errorArrowOffset = 8;

static CHUNKNUM abortMsg[numAbortErrors];
static CHUNKNUM errorMessages[numParserErrors];
static CHUNKNUM runtimeErrorMessages[numRuntimeErrors];

static char msgbuf[CHUNK_LEN + 1];

static void getMessage(CHUNKNUM chunkNum);
static void readErrorFile(char *filename, CHUNKNUM *msgs, int numMsgs);

void abortTranslation(TAbortCode ac)
{
    if (!abortMsg[0]) {
        readErrorFile("abortmsgs", abortMsg, numAbortErrors);
    }

    getMessage(abortMsg[-ac - 1]);
    logFatalError(msgbuf);
    isFatalError = 1;
}

void Error(TErrorCode ec)
{
    const int maxSyntaxErrors = 25;

    if (!errorMessages[0]) {
        readErrorFile("errormsgs", errorMessages, numParserErrors);
    }

    getMessage(errorMessages[ec]);
    logError(msgbuf, currentLineNumber);
    if (++errorCount > maxSyntaxErrors) {
        abortTranslation(abortTooManySyntaxErrors);
    }
}

static void getMessage(CHUNKNUM chunkNum)
{
    char chunk[CHUNK_LEN];

    retrieveChunk(chunkNum, (unsigned char *)chunk);
    sprintf(msgbuf, "%.*s", CHUNK_LEN, chunk);
}

static void readErrorFile(char *filename, CHUNKNUM *msgs, int numMsgs) {
    FILE *fp;
    int i, x;

    fp = fopen(filename, "r");
    if (fp == NULL) {
        logFatalError("Error message file missing");
        isFatalError = 1;
        return;
    }

    for (i = 0; i < numMsgs; ++i) {
        x = 0;
        memset(msgbuf, 0, CHUNK_LEN);
        while (1) {
            if (x > CHUNK_LEN) {
                logFatalError("Error message too long");
                isFatalError = 1;
                fclose(fp);
                return;
            }

            if (fread(msgbuf + x, 1, 1, fp) != 1) {
                logFatalError("Error reading from error message file");
                isFatalError = 1;
                fclose(fp);
                return;
            }

            if (msgbuf[x] == '\r') {
                msgbuf[x] = 0;
                break;
            }

            ++x;
        }

        allocChunk(msgs + i);
        storeChunk(msgs[i], (unsigned char *)msgbuf);
    }

    fclose(fp);
}

void runtimeError(TRuntimeErrorCode ec)
{
    if (!runtimeErrorMessages[0]) {
        readErrorFile("runtimemsgs", runtimeErrorMessages, numRuntimeErrors);
    }

    getMessage(runtimeErrorMessages[ec]);
    logRuntimeError(msgbuf, currentLineNumber);
    isFatalError = 1;
}

