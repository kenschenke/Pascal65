/**
 * ovrlcommon.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Header for functions shared between main code and overlays
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef OVRLCOMMON_H
#define OVRLCOMMON_H

#include <error.h>

void log(const char *module, const char *message);
void logFatalError(const char *message);
void logError(const char *message, unsigned lineNumber, TErrorCode code);
void logRuntimeError(const char *message, unsigned lineNumber);
void outputLine(const char *str);

#endif // end of OVRLCOMMON_H
