;
; buildresult.inc
; Ken Schenke (kenschenke@gmail.com)
;
; Copyright (c) 2026
; Use of this source code is governed by an MIT-style
; license that can be found in the LICENSE file or at
; https://opensource.org/licenses/MIT
;
; The result of the last build in the IDE (builderrors.s in the editor
; app). The compiler's errors and warnings are kept in the order they are
; reported, up to MAX_BUILD_ENTRIES. Past that they are counted but not
; kept.
;
; Each entry names its file by an index into the files table. A file gets
; a slot the first time an entry kept is in it. When the table is full, or
; the compiler has no filename, the entry gets BUILD_FILE_UNKNOWN, a slot
; after the others that holds an empty name.

.ifndef BUILDRESULT_INC
BUILDRESULT_INC = 1

MAX_BUILD_ENTRIES = 32
MAX_BUILD_FILES = 8
BUILD_FILENAME_SIZE = 17            ; 16 characters and a zero
BUILD_FILE_UNKNOWN = MAX_BUILD_FILES

; BUILDRESULT::state
BUILD_NONE = 0                      ; No build yet
BUILD_SUCCESS = 1                   ; No errors (there may be warnings)
BUILD_FAILED = 2                    ; At least one error

; BUILDENTRY::kind
BUILD_ERROR = 0
BUILD_WARNING = 1

; BUILDRESULT::current when the summary is shown
BUILD_SUMMARY = $ff

; BUILDRESULT::hlState. Going to an entry sets BUILD_HL_NEW. The first time
; its file is current, hlLines gets the file's numLines (BUILD_HL_KEPT).
; When numLines changes, a line was added or deleted, so the entry's line
; may have moved: the highlight is stale and isn't drawn (BUILD_HL_STALE)
; until another entry is gone to.
BUILD_HL_NEW = 0
BUILD_HL_KEPT = 1
BUILD_HL_STALE = 2

.struct BUILDENTRY
    msg      .dword     ; pointer to the message in the error buffer
    line     .word      ; source line, 0 if the error has no line
    fileIdx  .byte      ; index into BUILDRESULT::files
    kind     .byte      ; BUILD_ERROR or BUILD_WARNING
.endstruct

BUILD_FILES_SIZE = (MAX_BUILD_FILES + 1) * BUILD_FILENAME_SIZE
BUILD_ENTRIES_SIZE = MAX_BUILD_ENTRIES * .sizeof(BUILDENTRY)

.struct BUILDRESULT
    state      .byte    ; BUILD_NONE, BUILD_SUCCESS or BUILD_FAILED
    numErrors  .word    ; every error reported, even past the cap
    numWarns   .word    ; every warning reported, even past the cap
    numEntries .byte    ; entries kept, at most MAX_BUILD_ENTRIES
    numFiles   .byte    ; file slots used, at most MAX_BUILD_FILES
    current    .byte    ; entry the status line shows, BUILD_SUMMARY
    hlState    .byte    ; BUILD_HL_NEW, BUILD_HL_KEPT or BUILD_HL_STALE
    hlLines    .word    ; the file's numLines, if BUILD_HL_KEPT
    ; Null-terminated names, the last BUILD_FILE_UNKNOWN (always empty)
    files      .res ::BUILD_FILES_SIZE
    entries    .res ::BUILD_ENTRIES_SIZE
.endstruct

.endif
