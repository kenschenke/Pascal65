BINDIR := bin
OBJDIR := obj
SRCDIR := src
DRVDIR := drv

PROGRAM := tokenizertest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PRGFILE = $(BINTARGETDIR)/tokenizertest

BINFILES += $(TOKENIZER)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := test.petscii

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

test.petscii: test.pas
	dos2unix < test.pas | petcat -w2 -text -o test.petscii

# abortmsgs.petscii: src/shared/abortmsgs.txt
# 	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

# errormsgs.petscii: src/shared/errormsgs.txt
# 	dos2unix < src/shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

# runtimemsgs.petscii: src/shared/runtimemsgs.txt
# 	dos2unix < src/shared/runtimemsgs.txt | petcat -w2 -text -o runtimemsgs.petscii

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C tokenizertest.cfg $(OBJECTS)

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) tokenizertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write test.petscii test.pas,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m tokenizer.d81 -r $(BINTARGETDIR)/tokenizertest
