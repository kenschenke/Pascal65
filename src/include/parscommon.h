/**
 * parscommon.h
 * Ken Schenke (kenschenke@gmail.com)
 * 
 * Definitions and declarations for parser stage
 * 
 * Copyright (c) 2024
 * Use of this source code is governed by an MIT-style
 * license that can be found in the LICENSE file or at
 * https://opensource.org/licenses/MIT
 */

#ifndef PARSCOMMON_H
#define PARSCOMMON_H

// Token Lists

extern const TTokenCode tlStatementStart[], tlStatementFollow[];
extern const TTokenCode tlStatementListNotAllowed[];
extern const TTokenCode tlCaseLabelStart[];

extern const TTokenCode tlExpressionStart[], tlExpressionFollow[];
extern const TTokenCode tlRelOps[], tlUnaryOps[],
                        tlAddOps[], tlMulOps[];

extern const TTokenCode tlProgramEnd[];

extern const TTokenCode tlColonEqual[];
extern const TTokenCode tlDO[];
extern const TTokenCode tlTHEN[];
extern const TTokenCode tlTODOWNTO[];
extern const TTokenCode tlOF[];
extern const TTokenCode tlColon[];
extern const TTokenCode tlEND[];

char tokenIn(TTokenCode tc, const TTokenCode *pList);

#endif // end of PARSCOMMON_H
