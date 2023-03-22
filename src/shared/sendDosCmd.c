/**
 * sendDosCmd.c
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * C front-end for sending DOS commands.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#include <stdio.h>
#include <doscmd.h>
#include <unistd.h>
#include <string.h>

void __fastcall__ sendDosCmd(char *cmd, char device);

// Returns current drive as a number - NOT '8' or '9'
char getCurrentDrive(void) {
    char buf[10];

    if (getcwd(buf, sizeof(buf)) == NULL) {
        return 8;
    }

    return buf[0] - '0';
}

void removeFile(char *filename) {
    char cmd[20];

    strcpy(cmd, "s0:");
    strcat(cmd, filename);
    sendDosCmd(cmd, getCurrentDrive());
}

void renameFile(char *oldName, char *newName) {
    char cmd[40];

    strcpy(cmd, "r0:");
    strcat(cmd, newName);
    strcat(cmd, "=0:");
    strcat(cmd, oldName);
    sendDosCmd(cmd, getCurrentDrive());
}
