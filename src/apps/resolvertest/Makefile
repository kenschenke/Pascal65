BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
ERRORTESTSDIR := errortests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
SHOWTREEDIR := ../../overlays/showtree
DUMPSYMTABDIR := ../../overlays/dumpsymtab
RESOLVERDIR := ../../overlays/resolverasm
MEMINFODIR := ../../overlays/meminfo
ASMLIBDIR := ../../lib/asmlib

PROGRAM := resolvertest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
SHOWTREE = ../../overlays/showtree/bin/$(TARGET)/showtree
DUMPSYMTAB = ../../overlays/dumpsymtab/bin/$(TARGET)/dumpsymtab
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
PRGFILE = $(BINTARGETDIR)/resolvertest
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(SHOWTREE)
BINFILES += $(DUMPSYMTAB)
BINFILES += $(RESOLVER)
BINFILES += $(MEMINFO)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := errormsgs.petscii system.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

system.petscii: $(SYSTEMPAS)
	dos2unix < $(SYSTEMPAS) | petcat -w2 -text -o system.petscii

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

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(SHOWTREE): FORCE
	cd $(SHOWTREEDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPSYMTAB): FORCE
	cd $(DUMPSYMTABDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

vpath %.pas $(TESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

vpath %.pas $(ERRORTESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C resolvertest.cfg $(OBJECTS)

FORCE:

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) resolvertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(DUMPSYMTAB) dumpsymtab,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(PETSCIIDIR)/test0.pas test0.pas,seq \
	-write $(PETSCIIDIR)/test1.pas test1.pas,seq \
	-write $(PETSCIIDIR)/test2.pas test2.pas,seq \
	-write $(PETSCIIDIR)/test3.pas test3.pas,seq \
	-write $(PETSCIIDIR)/test4.pas test4.pas,seq \
	-write $(PETSCIIDIR)/test5.pas test5.pas,seq \
	-write $(PETSCIIDIR)/test6.pas test6.pas,seq \
	-write $(PETSCIIDIR)/test7.pas test7.pas,seq \
	-write $(PETSCIIDIR)/test8.pas test8.pas,seq \
	-write $(PETSCIIDIR)/test8unit.pas test8unit.pas,seq \
	-write $(PETSCIIDIR)/error1.pas error1.pas,seq \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m tokenizer.d81 -r $(BINTARGETDIR)/tokenizertest
