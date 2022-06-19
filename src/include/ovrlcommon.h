#ifndef OVRLCOMMON_H
#define OVRLCOMMON_H

void log(const char *module, const char *message);
void logFatalError(const char *message);
void logError(const char *message, int lineNumber);

#endif // end of OVRLCOMMON_H
