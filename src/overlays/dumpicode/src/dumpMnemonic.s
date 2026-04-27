.include "icode.inc"
.include "asmlib.inc"
.include "zeropage.inc"
.include "4510macros.inc"

.export dumpMnemonic

.import memBuf

.data

strIC_CHR: .byte "CHR"
strIC_IBU: .byte "IBU"
strIC_IBS: .byte "IBS"
strIC_BOO: .byte "BOO"
strIC_IWU: .byte "IWU"
strIC_IWS: .byte "IWS"
strIC_ILU: .byte "ILU"
strIC_ILS: .byte "ILS"
strIC_FLT: .byte "FLT"
strIC_STR: .byte "STR"
strIC_VDR: .byte "VDR"
strIC_VDW: .byte "VDW"
strIC_VVR: .byte "VVR"
strIC_VVW: .byte "VVW"
strIC_LBL: .byte "LBL"
strIC_RET: .byte "RET"
strIC_AND: .byte "AND"
strIC_ORA: .byte "ORA"
strIC_ONL: .byte "ONL"
strIC_ROU: .byte "ROU"
strIC_TRU: .byte "TRU"
strIC_POP: .byte "POP"
strIC_DEL: .byte "DEL"
strIC_CNL: .byte "CNL"
strIC_NOT: .byte "NOT"
strIC_SSR: .byte "SSR"
strIC_SSW: .byte "SSW"
strIC_FSO: .byte "FSO"
strIC_DEF: .byte "DEF"
strIC_JRP: .byte "JRP"
strIC_RTS: .byte "RTS"
strIC_DIR: .byte "DIR"
strIC_NEG: .byte "NEG"
strIC_ABS: .byte "ABS"
strIC_PPF: .byte "PPF"
strIC_DIA: .byte "DIA"
strIC_INP: .byte "INP"
strIC_PSH: .byte "PSH"
strIC_PRE: .byte "PRE"
strIC_SUC: .byte "SUC"
strIC_OUT: .byte "OUT"
strIC_NEW: .byte "NEW"
strIC_ARR: .byte "ARR"
strIC_SST: .byte "SST"
strIC_LOC: .byte "LOC"
strIC_BRA: .byte "BRA"
strIC_BIT: .byte "BIT"
strIC_BIF: .byte "BIF"
strIC_LIN: .byte "LIN"
strIC_AIX: .byte "AIX"
strIC_BWC: .byte "BWC"
strIC_SQR: .byte "SQR"
strIC_CPY: .byte "CPY"
strIC_SCV: .byte "SCV"
strIC_ASF: .byte "ASF"
strIC_SSP: .byte "SSP"
strIC_MEM: .byte "MEM"
strIC_SET: .byte "SET"
strIC_MOD: .byte "MOD"
strIC_DIV: .byte "DIV"
strIC_GRT: .byte "GRT"
strIC_GTE: .byte "GTE"
strIC_LST: .byte "LST"
strIC_LSE: .byte "LSE"
strIC_EQU: .byte "EQU"
strIC_NEQ: .byte "NEQ"
strIC_CCT: .byte "CCT"
strIC_PUF: .byte "PUF"
strIC_POF: .byte "POF"
strIC_DCC: .byte "DCC"
strIC_SFH: .byte "SFH"
strIC_CVI: .byte "CVI"
strIC_DCF: .byte "DCF"
strIC_ADD: .byte "ADD"
strIC_SUB: .byte "SUB"
strIC_MUL: .byte "MUL"
strIC_DVI: .byte "DVI"
strIC_BWA: .byte "BWA"
strIC_BWO: .byte "BWO"
strIC_BSL: .byte "BSL"
strIC_BSR: .byte "BSR"
strIC_JSR: .byte "JSR"
strIC_PRP: .byte "PRP"
strIC_BWX: .byte "BWX"
strIC_DAT: .byte "DAT"

mne:
.byte IC_CHR, .LOBYTE(strIC_CHR), .HIBYTE(strIC_CHR)
.byte IC_IBU, .LOBYTE(strIC_IBU), .HIBYTE(strIC_IBU)
.byte IC_IBS, .LOBYTE(strIC_IBS), .HIBYTE(strIC_IBS)
.byte IC_BOO, .LOBYTE(strIC_BOO), .HIBYTE(strIC_BOO)
.byte IC_IWU, .LOBYTE(strIC_IWU), .HIBYTE(strIC_IWU)
.byte IC_IWS, .LOBYTE(strIC_IWS), .HIBYTE(strIC_IWS)
.byte IC_ILU, .LOBYTE(strIC_ILU), .HIBYTE(strIC_ILU)
.byte IC_ILS, .LOBYTE(strIC_ILS), .HIBYTE(strIC_ILS)
.byte IC_FLT, .LOBYTE(strIC_FLT), .HIBYTE(strIC_FLT)
.byte IC_STR, .LOBYTE(strIC_STR), .HIBYTE(strIC_STR)
.byte IC_VDR, .LOBYTE(strIC_VDR), .HIBYTE(strIC_VDR)
.byte IC_VDW, .LOBYTE(strIC_VDW), .HIBYTE(strIC_VDW)
.byte IC_VVR, .LOBYTE(strIC_VVR), .HIBYTE(strIC_VVR)
.byte IC_VVW, .LOBYTE(strIC_VVW), .HIBYTE(strIC_VVW)
.byte IC_LBL, .LOBYTE(strIC_LBL), .HIBYTE(strIC_LBL)
.byte IC_RET, .LOBYTE(strIC_RET), .HIBYTE(strIC_RET)
.byte IC_AND, .LOBYTE(strIC_AND), .HIBYTE(strIC_AND)
.byte IC_ORA, .LOBYTE(strIC_ORA), .HIBYTE(strIC_ORA)
.byte IC_ONL, .LOBYTE(strIC_ONL), .HIBYTE(strIC_ONL)
.byte IC_ROU, .LOBYTE(strIC_ROU), .HIBYTE(strIC_ROU)
.byte IC_TRU, .LOBYTE(strIC_TRU), .HIBYTE(strIC_TRU)
.byte IC_POP, .LOBYTE(strIC_POP), .HIBYTE(strIC_POP)
.byte IC_DEL, .LOBYTE(strIC_DEL), .HIBYTE(strIC_DEL)
.byte IC_CNL, .LOBYTE(strIC_CNL), .HIBYTE(strIC_CNL)
.byte IC_NOT, .LOBYTE(strIC_NOT), .HIBYTE(strIC_NOT)
.byte IC_SSR, .LOBYTE(strIC_SSR), .HIBYTE(strIC_SSR)
.byte IC_SSW, .LOBYTE(strIC_SSW), .HIBYTE(strIC_SSW)
.byte IC_FSO, .LOBYTE(strIC_FSO), .HIBYTE(strIC_FSO)
.byte IC_DEF, .LOBYTE(strIC_DEF), .HIBYTE(strIC_DEF)
.byte IC_JRP, .LOBYTE(strIC_JRP), .HIBYTE(strIC_JRP)
.byte IC_RTS, .LOBYTE(strIC_RTS), .HIBYTE(strIC_RTS)
.byte IC_DIR, .LOBYTE(strIC_DIR), .HIBYTE(strIC_DIR)
.byte IC_NEG, .LOBYTE(strIC_NEG), .HIBYTE(strIC_NEG)
.byte IC_ABS, .LOBYTE(strIC_ABS), .HIBYTE(strIC_ABS)
.byte IC_PPF, .LOBYTE(strIC_PPF), .HIBYTE(strIC_PPF)
.byte IC_DIA, .LOBYTE(strIC_DIA), .HIBYTE(strIC_DIA)
.byte IC_INP, .LOBYTE(strIC_INP), .HIBYTE(strIC_INP)
.byte IC_PSH, .LOBYTE(strIC_PSH), .HIBYTE(strIC_PSH)
.byte IC_PRE, .LOBYTE(strIC_PRE), .HIBYTE(strIC_PRE)
.byte IC_SUC, .LOBYTE(strIC_SUC), .HIBYTE(strIC_SUC)
.byte IC_OUT, .LOBYTE(strIC_OUT), .HIBYTE(strIC_OUT)
.byte IC_NEW, .LOBYTE(strIC_NEW), .HIBYTE(strIC_NEW)
.byte IC_ARR, .LOBYTE(strIC_ARR), .HIBYTE(strIC_ARR)
.byte IC_SST, .LOBYTE(strIC_SST), .HIBYTE(strIC_SST)
.byte IC_LOC, .LOBYTE(strIC_LOC), .HIBYTE(strIC_LOC)
.byte IC_BRA, .LOBYTE(strIC_BRA), .HIBYTE(strIC_BRA)
.byte IC_BIT, .LOBYTE(strIC_BIT), .HIBYTE(strIC_BIT)
.byte IC_BIF, .LOBYTE(strIC_BIF), .HIBYTE(strIC_BIF)
.byte IC_LIN, .LOBYTE(strIC_LIN), .HIBYTE(strIC_LIN)
.byte IC_AIX, .LOBYTE(strIC_AIX), .HIBYTE(strIC_AIX)
.byte IC_BWC, .LOBYTE(strIC_BWC), .HIBYTE(strIC_BWC)
.byte IC_SQR, .LOBYTE(strIC_SQR), .HIBYTE(strIC_SQR)
.byte IC_CPY, .LOBYTE(strIC_CPY), .HIBYTE(strIC_CPY)
.byte IC_SCV, .LOBYTE(strIC_SCV), .HIBYTE(strIC_SCV)
.byte IC_ASF, .LOBYTE(strIC_ASF), .HIBYTE(strIC_ASF)
.byte IC_SSP, .LOBYTE(strIC_SSP), .HIBYTE(strIC_SSP)
.byte IC_MEM, .LOBYTE(strIC_MEM), .HIBYTE(strIC_MEM)
.byte IC_SET, .LOBYTE(strIC_SET), .HIBYTE(strIC_SET)
.byte IC_MOD, .LOBYTE(strIC_MOD), .HIBYTE(strIC_MOD)
.byte IC_DIV, .LOBYTE(strIC_DIV), .HIBYTE(strIC_DIV)
.byte IC_GRT, .LOBYTE(strIC_GRT), .HIBYTE(strIC_GRT)
.byte IC_GTE, .LOBYTE(strIC_GTE), .HIBYTE(strIC_GTE)
.byte IC_LST, .LOBYTE(strIC_LST), .HIBYTE(strIC_LST)
.byte IC_LSE, .LOBYTE(strIC_LSE), .HIBYTE(strIC_LSE)
.byte IC_EQU, .LOBYTE(strIC_EQU), .HIBYTE(strIC_EQU)
.byte IC_NEQ, .LOBYTE(strIC_NEQ), .HIBYTE(strIC_NEQ)
.byte IC_CCT, .LOBYTE(strIC_CCT), .HIBYTE(strIC_CCT)
.byte IC_PUF, .LOBYTE(strIC_PUF), .HIBYTE(strIC_PUF)
.byte IC_POF, .LOBYTE(strIC_POF), .HIBYTE(strIC_POF)
.byte IC_DCC, .LOBYTE(strIC_DCC), .HIBYTE(strIC_DCC)
.byte IC_SFH, .LOBYTE(strIC_SFH), .HIBYTE(strIC_SFH)
.byte IC_CVI, .LOBYTE(strIC_CVI), .HIBYTE(strIC_CVI)
.byte IC_DCF, .LOBYTE(strIC_DCF), .HIBYTE(strIC_DCF)
.byte IC_ADD, .LOBYTE(strIC_ADD), .HIBYTE(strIC_ADD)
.byte IC_SUB, .LOBYTE(strIC_SUB), .HIBYTE(strIC_SUB)
.byte IC_MUL, .LOBYTE(strIC_MUL), .HIBYTE(strIC_MUL)
.byte IC_DVI, .LOBYTE(strIC_DVI), .HIBYTE(strIC_DVI)
.byte IC_BWA, .LOBYTE(strIC_BWA), .HIBYTE(strIC_BWA)
.byte IC_BWO, .LOBYTE(strIC_BWO), .HIBYTE(strIC_BWO)
.byte IC_BSL, .LOBYTE(strIC_BSL), .HIBYTE(strIC_BSL)
.byte IC_BSR, .LOBYTE(strIC_BSR), .HIBYTE(strIC_BSR)
.byte IC_JSR, .LOBYTE(strIC_JSR), .HIBYTE(strIC_JSR)
.byte IC_PRP, .LOBYTE(strIC_PRP), .HIBYTE(strIC_PRP)
.byte IC_BWX, .LOBYTE(strIC_BWX), .HIBYTE(strIC_BWX)
.byte IC_DAT, .LOBYTE(strIC_DAT), .HIBYTE(strIC_DAT)

.code

; This routine dumps the mnemonic in A as a string, i.e. "BRA"
.proc dumpMnemonic
    ldx #0
L1: cmp mne,x
    beq L2
    inx
    inx
    inx
    bne L1

L2: inx
    lda mne,x
    sta ptr2
    lda mne+1,x
    sta ptr2+1

    ldq memBuf
    stq ptr1

    lda #3                  ; a mnemonic string is 6 chars
    ldx #0
    stx ptr2+2
    stx ptr2+3
    jsr writeToMemBuf

    rts
.endproc
