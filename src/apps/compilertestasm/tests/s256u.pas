// A unit for slots256.pas. Its 200 variables take the program's slots 56
// to 255, so u199 is in the last one.

Unit S256U;

Interface

Var
    u000, u001, u002, u003, u004, u005, u006, u007, u008, u009 : Integer;
    u010, u011, u012, u013, u014, u015, u016, u017, u018, u019 : Integer;
    u020, u021, u022, u023, u024, u025, u026, u027, u028, u029 : Integer;
    u030, u031, u032, u033, u034, u035, u036, u037, u038, u039 : Integer;
    u040, u041, u042, u043, u044, u045, u046, u047, u048, u049 : Integer;
    u050, u051, u052, u053, u054, u055, u056, u057, u058, u059 : Integer;
    u060, u061, u062, u063, u064, u065, u066, u067, u068, u069 : Integer;
    u070, u071, u072, u073, u074, u075, u076, u077, u078, u079 : Integer;
    u080, u081, u082, u083, u084, u085, u086, u087, u088, u089 : Integer;
    u090, u091, u092, u093, u094, u095, u096, u097, u098, u099 : Integer;
    u100, u101, u102, u103, u104, u105, u106, u107, u108, u109 : Integer;
    u110, u111, u112, u113, u114, u115, u116, u117, u118, u119 : Integer;
    u120, u121, u122, u123, u124, u125, u126, u127, u128, u129 : Integer;
    u130, u131, u132, u133, u134, u135, u136, u137, u138, u139 : Integer;
    u140, u141, u142, u143, u144, u145, u146, u147, u148, u149 : Integer;
    u150, u151, u152, u153, u154, u155, u156, u157, u158, u159 : Integer;
    u160, u161, u162, u163, u164, u165, u166, u167, u168, u169 : Integer;
    u170, u171, u172, u173, u174, u175, u176, u177, u178, u179 : Integer;
    u180, u181, u182, u183, u184, u185, u186, u187, u188, u189 : Integer;
    u190, u191, u192, u193, u194, u195, u196, u197, u198, u199 : Integer;

Procedure SetEnds(first, last : Integer);
Function GetFirst : Integer;
Function GetLast : Integer;

Implementation

Procedure SetEnds(first, last : Integer);
Begin
    u000 := first;
    u199 := last;
End;

Function GetFirst : Integer;
Begin
    GetFirst := u000;
End;

Function GetLast : Integer;
Begin
    GetLast := u199;
End;

End.
