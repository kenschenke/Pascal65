
PARSER_BASE = $4000

parserInit = PARSER_BASE
parse = PARSER_BASE + 3
setParserUnitsList = PARSER_BASE + 6
getParserUnitsList = PARSER_BASE + 9
getParserStackSize = PARSER_BASE + 12
registerExpectWarnHandler = PARSER_BASE + 15
registerExpectErrorHandler = PARSER_BASE + 18

.macro resync list1, list2, list3
    lda #<list1
    sta ptr1
    lda #>list1
    stx ptr1+1

    .ifblank list2
    lda #0
    sta ptr2
    stx ptr2+1
    .endif
    .ifnblank list2
    lda #<list2
    sta ptr2
    lda #>list2
    sta ptr2+1
    .endif

    .ifblank list3
    lda #0
    sta ptr3
    sta ptr3+1
    .endif
    .ifnblank list3
    lda #<list3
    sta ptr3
    lda #>list3
    sta ptr3+1
    .endif

    jsr doResync
.endmacro
