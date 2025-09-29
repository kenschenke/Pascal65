BINDIR := bin
OBJDIR := obj
SRCDIR := src
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
ASMLIBDIR := ../../lib/asmlib
ASTLIBDIR := ../../lib/astlib

PROGRAM := treeviewer
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = $(ASMLIBDIR)/bin/$(TARGET)/asmlib
ASTLIB = $(ASTLIBDIR)/bin/$(TARGET)/astlib
TOKENIZER = $(TOKENIZERDIR)/bin/$(TARGET)/tokenizer
PARSER = $(PARSERDIR)/bin/$(TARGET)/parser
PRGFILE = $(BINTARGETDIR)/treeviewer

BINFILES += $(PRGFILE)
BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ASMLIB)
BINFILES += $(ASTLIB)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := source.petscii errormsgs.petscii

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

source.petscii: source.pas
	dos2unix < source.pas | petcat -w2 -text -o source.petscii

# abortmsgs.petscii: src/shared/abortmsgs.txt
# 	dos2unix < src/shared/abortmsgs.txt | petcat -w2 -text -o abortmsgs.petscii

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

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

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(ASTLIB): FORCE
	cd $(ASTLIBDIR) && $(MAKE) TARGET=$(TARGET)

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C treeviewer.cfg $(OBJECTS)

FORCE:

$(D81FILE): $(BINFILES) $(TXTFILES) FORCE
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) treeviewer,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(ASTLIB) ast.lib,prg \
	-write source.petscii source.pas,seq \
	-write errormsgs.petscii errormsgs.txt,seq

clean:
	$(RM) $(BINFILES)
	$(RM) $(OBJECTS)
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m tokenizer.d81 -r $(BINTARGETDIR)/tokenizertest
