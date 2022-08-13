/**
 * doscmd.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for sending DOS commands.
 * 
 * Copyright (c) 2022
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef DOSCMD_H
#define DOSCMD_H

char getCurrentDrive(void);
void removeFile(char *filename);
void renameFile(char *oldName, char *newName);

#endif // end of DOSCMD_H
