BINDIR := bin
OBJDIR := obj
SRCDIR := src
TESTSDIR := tests
ERRORTESTSDIR := errortests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
PARSERDIR := ../../overlays/parserasm
DUMPASTDIR := ../../overlays/dumpast
MEMINFODIR := ../../overlays/meminfo
SHOWTREEDIR := ../../overlays/showtree
ASMLIBDIR := ../../lib/asmlib

PROGRAM := parsertest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
DUMPAST = ../../overlays/dumpast/bin/$(TARGET)/dumpast
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
SHOWTREE = ../../overlays/showtree/bin/$(TARGET)/showtree
PRGFILE = $(BINTARGETDIR)/parsertest

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(DUMPAST)
BINFILES += $(ASMLIB)
BINFILES += $(MEMINFO)
BINFILES += $(SHOWTREE)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

TXTFILES := errormsgs.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(PETSCIIDIR):
	mkdir -p $@

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(DUMPAST): FORCE
	cd $(DUMPASTDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(SHOWTREE): FORCE
	cd $(SHOWTREEDIR) && $(MAKE) TARGET=$(TARGET)

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
	ld65 -o $(PRGFILE) -C parsertest.cfg $(OBJECTS)

FORCE:

$(D81FILE): $(BINFILES) $(TXTFILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) parsertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(DUMPAST) dumpast,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(PETSCIIDIR)/test1.pas test1.pas,seq \
	-write $(PETSCIIDIR)/test2.pas test2.pas,seq \
	-write $(PETSCIIDIR)/test3.pas test3.pas,seq \
	-write $(PETSCIIDIR)/test4.pas test4.pas,seq \
	-write $(PETSCIIDIR)/test5.pas test5.pas,seq \
	-write $(PETSCIIDIR)/test6.pas test6.pas,seq \
	-write $(PETSCIIDIR)/test7.pas test7.pas,seq \
	-write $(PETSCIIDIR)/test8.pas test8.pas,seq \
	-write $(PETSCIIDIR)/test9.pas test9.pas,seq \
	-write $(PETSCIIDIR)/test10.pas test10.pas,seq \
	-write $(PETSCIIDIR)/test11.pas test11.pas,seq \
	-write $(PETSCIIDIR)/test12.pas test12.pas,seq \
	-write $(PETSCIIDIR)/test13.pas test13.pas,seq \
	-write $(PETSCIIDIR)/test14.pas test14.pas,seq \
	-write $(PETSCIIDIR)/test15.pas test15.pas,seq \
	-write $(PETSCIIDIR)/error1.pas error1.pas,seq \
	-write $(PETSCIIDIR)/error2.pas error2.pas,seq \
	-write $(PETSCIIDIR)/error3.pas error3.pas,seq \
	-write $(PETSCIIDIR)/error4.pas error4.pas,seq \
	-write $(PETSCIIDIR)/error5.pas error5.pas,seq \
	-write $(PETSCIIDIR)/error6.pas error6.pas,seq \
	-write $(PETSCIIDIR)/error7.pas error7.pas,seq \
	-write $(PETSCIIDIR)/error8.pas error8.pas,seq \
	-write $(PETSCIIDIR)/error9.pas error9.pas,seq \
	-write $(PETSCIIDIR)/error10.pas error10.pas,seq \
	-write $(PETSCIIDIR)/error11.pas error11.pas,seq \
	-write $(PETSCIIDIR)/error12.pas error12.pas,seq \
	-write errormsgs.petscii errormsgs.txt,seq

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(D81FILE)

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m parsertest.d81 -r $(BINTARGETDIR)/parsertest
