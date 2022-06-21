#ifndef OVRLCOMMON_H
#define OVRLCOMMON_H

void log(const char *module, const char *message);
void logFatalError(const char *message);
void logError(const char *message, unsigned lineNumber);
void logRuntimeError(const char *message, unsigned lineNumber);
void outputLine(const char *str);

#endif // end of OVRLCOMMON_H
