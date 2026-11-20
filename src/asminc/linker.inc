LINKER_BASE = $4000

genPrgFile = LINKER_BASE

; These constants define how a linker tag reference is to be resolved.
; At the offset, the code needs to know the low byte, the high byte,
; or both.
LINKADDR_LOW = 1
LINKADDR_HIGH = 2
LINKADDR_BOTH = 3
; A level 1 offset in a variable reference: the target, a frame's first
; slot (the import "name.frame"), is added to the byte
LINKADDR_FRAME = 4

; A relocation's kind has this bit set when its target is an import's
; number rather than an offset in the module's code.
LINKADDR_IMPORT = $80

; The linker lays out the PRG (see rtlayout.inc).

; The object files, which code generation writes and the linker reads (see
; plans/objcode.md): one for each module, the program's (zztmp), then each
; Pascal unit's (<unit>.obj), which the program's lists. All words are low
; byte first. A name is its length in a byte, then that many characters,
; with no terminator, at most OBJ_NAME_MAX of them.
;
;    .byte OBJ_MAGIC0, OBJ_MAGIC1, OBJ_VERSION
;    .byte RT_ABI_VERSION       the runtime the code calls
;    .byte kind                 OBJ_KIND_*: the program's is the first
;    .byte flags                OBJ_FLAG_*
;    .word key source CRC       a unit's TPU's (OBJ_FLAG_CACHED; objcache.s
;    .word key stamp            in codegen): the CRC of the TPU's header
;                               and used units
;    .byte features             RTF_* (asm.inc), ORed into the program's
;    .byte runtime mode         RT_MODE_* (asm.inc), the program's
;    .word stack size           the runtime stack's size in bytes, the
;                               program's
;    name                       the module's name
;    .word global slots         the program's own level 1 slots
;    .word code length          the code's size in memory
;    .word BSS length           zero bytes the linker reserves after it
;    .word symbol count         then each: name, .word offset, .byte flags:
;                               the module's exports
;    .word import count         then each: name
;    .byte library count        then each library, in the order to place
;                               them: its name (the file is name.lib),
;                               .word its jump table's slot count, then
;                               each slot's kind: .byte OBJLIB_*
;    .byte frame count          then each unit or library with level 1
;                               slots, in the order the startup pushes
;                               them: its name, .word its slot count
;    .byte unit count           then each unit module, in the order to
;                               place them after the program: its name
;                               (its file is name.obj)
;    .word relocation count     then each: OBJRELOC
;    the code, to the end of the file
;
; A unit's object file has no libraries, frames or units: those counts
; are 0. The linker ORs every module's features. A unit's object file
; stays beside its TPU, and code generation makes it again only when the
; TPU's key, the object format or the runtime changes (objcache.s in
; codegen). The linker deletes only the program's.
;
; A relocation's target is an offset in the module's code, so a label that
; isn't exported needs no symbol. A label the module uses but doesn't set
; is an import, and a relocation for it has LINKADDR_IMPORT in its kind and
; the import's number (from 0, in the file's order) as its target. A
; module exports each entry it sets ("name.N", below), and another module
; imports it by name. The program module exports nothing.
;
; The linker resolves an import to a library slot or a linker symbol:
;
;    zpbackup, intbuf,       the runtime's BSS, after the last module
;    tenstable, inputbuf
;    heapbottom              the end of the image, where the heap starts
;    stacktop                the ceiling, where the runtime stack starts
;    heaptop                 the heap's top: ceiling - stack size - 4
;    rtinit                  the runtime's first call: RT_RUNTIMEERRORINIT,
;                            or LOADER_ADDR for a dynamic program
;
;    name.N                  slot N of the library, in decimal: the
;                            linker defines one at each slot. Or a unit's
;                            entry N, which its module exports.
;    name.frame              the first level 1 slot of a frame: the
;                            module's global slots, then each frame's
;                            count, in order
;
; An import that resolves to neither is errUndefinedLabel, with its name.
OBJ_MAGIC0 = 'O'
OBJ_MAGIC1 = 'B'
OBJ_VERSION = 6
OBJ_NAME_MAX = 23           ; the longest name, TAGTOFIND's label less one

OBJ_KIND_PROGRAM = 0
OBJ_KIND_UNIT = 1

OBJ_FLAG_OVERLAY = $01      ; an overlay unit (see plans/overlays.md)
OBJ_FLAG_CACHED = $02       ; a unit's object, kept for its TPU's key

OBJSYM_EXPORTED = $01       ; a symbol's flags

; A library's jump table slots: the first two are its init and cleanup
OBJLIB_ROUTINE = 1          ; a JMP to a routine, 3 bytes
OBJLIB_VARIABLE = 2         ; a variable's address, 2 bytes

.struct OBJRELOC
    offset .word            ; where in the code the address goes
    kind .byte              ; one of LINKADDR_*, maybe with LINKADDR_IMPORT
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
; each relocation in the object file, with the relocation's kind and target,
; and works out the address when it reaches the offset.
.struct TAGTOFIX
    type .byte
    offset .word
    address .word
.endstruct
