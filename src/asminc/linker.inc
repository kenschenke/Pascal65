LINKER_BASE = $4000

genPrgFile = LINKER_BASE

; These constants define how a linker tag reference is to be resolved.
; At the offset, the code needs to know the low byte, the high byte,
; or both.
LINKADDR_LOW = 1
LINKADDR_HIGH = 2
LINKADDR_BOTH = 3

; This one marks where the rest of a static runtime goes (see genRuntime.s
; in codegen). The object file has a list of the runtime files to copy
; there, which isn't part of the program:
;
;    .byte number of files
;    Then for each file:
;       .byte length of its name
;       the name to open it with, such as "trig1c,p,r"
;       .word bytes to skip at its start
;       .word bytes to copy after them
;
; The linker copies the files straight into the PRG. The offsets of the
; tags after this one count the bytes copied, but not the list.
LINKADDR_RUNTIME = 4

; The program's code starts here, just after the PRG's load address. The
; object file's offsets count from it.
LINK_CODE_BASE = $2001

; The object file (zztmp), which code generation writes and the linker reads
; (see plans/objcode.md). All words are low byte first. A name is its length
; in a byte, then that many characters, with no terminator.
;
;    .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION
;    .byte RT_ABI_VERSION       the runtime the code calls
;    .byte kind                 OBJ_KIND_*
;    .byte flags                OBJ_FLAG_*
;    .byte features             RTF_* (asm.inc), ORed into the program's
;    name                       the module's name
;    .word global slots         unit variables (see plans/tpu.md)
;    .word code length          the code's size in memory
;    .word BSS length           zero bytes the linker reserves after it
;    .word symbol count         then each: name, .word offset, .byte flags
;    .word import count         then each: name
;    .word relocation count     then each: OBJRELOC
;    the code, to the end of the file
;
; A relocation's target is an offset in the module's code, so a label that
; isn't exported needs no symbol. Code generation resolves those itself
; (writeObjFile in codegen). The symbols are the exported ones, which the
; program module doesn't have yet, and nothing is imported.
;
; The code is the bytes codegen wrote, in order. A LINKADDR_RUNTIME
; relocation's list of files is in it but isn't counted in its offsets or
; the code length (see LINKADDR_RUNTIME above).
OBJ_MAGIC0 = 'O'
OBJ_MAGIC1 = 'B'
OBJ_VERSION = 1

OBJ_KIND_PROGRAM = 0
OBJ_KIND_UNIT = 1

OBJ_FLAG_OVERLAY = $01      ; an overlay unit (see plans/overlays.md)

OBJSYM_EXPORTED = $01       ; a symbol's flags

.struct OBJRELOC
    offset .word            ; where in the code the address goes
    kind .byte              ; one of LINKADDR_*
    target .word            ; the offset in the code it is the address of
.endstruct

; This structure defines a location that needs to be resolved by the linker.
; The label is the location being referenced. The offset is the location
; of the reference in the object code. Code generation keeps them in the
; heap until it writes the object file.
.struct TAGTOFIND
    label .res 24           ; Null-terminated label
    type .byte             ; One of LINKADDR_*
    offset .word            ; offset of reference in generated code
.endstruct

; This structure defines a location that needs to be updated by the linker.
; The type is one of LINKADDR_*, the offset is the offset in the object file.
; The address is the 16-bit address to write there. The linker makes one for
; each relocation in the object file.
.struct TAGTOFIX
    type .byte
    offset .word
    address .word
.endstruct
