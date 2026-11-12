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
DUMPASTDIR := ../../overlays/dumpast
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
DUMPAST = ../../overlays/dumpast/bin/$(TARGET)/dumpast
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
PRGFILE = $(BINTARGETDIR)/resolvertest
SYSTEMPAS = ../../lib/system/system.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(SHOWTREE)
BINFILES += $(DUMPSYMTAB)
BINFILES += $(DUMPAST)
BINFILES += $(RESOLVER)
BINFILES += $(MEMINFO)
BINFILES += $(ASMLIB)
BINFILES += $(PRGFILE)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(OBJTARGETDIR)/testresult.o
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

TXTFILES := errormsgs.petscii system.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))
comma := ,

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

$(DUMPAST): FORCE
	cd $(DUMPASTDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.pas $(TESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

vpath %.pas $(ERRORTESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C resolvertest.cfg $(OBJECTS)

FORCE:

# Makes a disk: $(1) is the D81, $(2) the test program and $(3) the
# resolver
define MKDISK
c1541 -format $(PROGRAM),8a d81 $(1) \
	-write $(2) resolvertest,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(PARSER) parser,prg \
	-write $(3) resolver,prg \
	-write $(DUMPSYMTAB) dumpsymtab,prg \
	-write $(DUMPAST) dumpast,prg \
	-write $(SHOWTREE) showtree,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(ASMLIB) asm.lib,prg \
	$(foreach f,$(notdir $(TESTS) $(ERRORTESTS)), \
	-write $(PETSCIIDIR)/$(f) $(f)$(comma)seq) \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq
endef

$(D81FILE): $(BINFILES) $(TXTFILES)
	$(call MKDISK,$(D81FILE),$(PRGFILE),$(RESOLVER))

# The coverage build. make coverage runs the tests against instrumented
# copies of the resolver overlay (see ../editortest/cov/mkcov.py) and lists
# the lines that never ran in bin/$(TARGET)/coverage.txt. Like test, it
# needs asmlib built with MEMCHECK=1.
#
# The probes make the overlay much bigger, and they may not all fit at
# once. Each set instruments some of the files and the tests run once for
# each set. A set's map is COVSIZE bytes at COVMAP, above the test program.
# A set that no longer fits fails to link and must be split.
COVTOOLS := ../editortest/cov
COVMAP := 14336
COVSIZE := 2048
COVSETS := 1
COVSET ?= 1
RESOLVERSRCDIR := $(RESOLVERDIR)/src
RESOLVERSOURCES := $(wildcard $(RESOLVERSRCDIR)/*.s)
COVFILES1 := $(filter-out jmptbl.s loadaddr.s,$(notdir $(RESOLVERSOURCES)))

COVASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ \
	-D COVMAP=$(COVMAP)
COVDIR := $(OBJTARGETDIR)/cov$(COVSET)
COVRESOLVEROBJS := $(addprefix $(COVDIR)/,$(notdir $(RESOLVERSOURCES:.s=.o)))
COVRESOLVER := $(COVDIR)/resolver
COVPRGDIR := $(OBJTARGETDIR)/cov
COVPRG := $(COVPRGDIR)/$(PROGRAM)
COVPRGOBJS := $(COVPRGDIR)/main.o $(COVPRGDIR)/covsave.o
COVPRGOBJS += $(filter-out $(OBJTARGETDIR)/main.o,$(OBJECTS))
COVD81 := $(BINTARGETDIR)/resolvertestcov.d81
COVLIST := $(BINTARGETDIR)/coverage.txt
# The map and the coverage file of each set
COVARGS = $(foreach s,$(COVSETS),-m $(OBJTARGETDIR)/cov$(s)/resolver.map \
	$(BINTARGETDIR)/resolver$(s).cov)

# Every file of the overlay is copied, then the set's files are replaced by
# instrumented copies.
$(COVDIR)/stamp: $(RESOLVERSOURCES) $(COVTOOLS)/mkcov.py
	mkdir -p $(COVDIR)
	cp $(RESOLVERSOURCES) $(COVDIR)
	python3 $(COVTOOLS)/mkcov.py -D __MEGA65__ -m $(COVSIZE) \
	$(COVDIR) $(COVDIR)/resolver.map \
	$(addprefix $(RESOLVERSRCDIR)/,$(COVFILES$(COVSET)))
	touch $@

$(COVDIR)/%.o: $(COVDIR)/stamp
	ca65 $(COVASFLAGS) -o $@ $(@:.o=.s)

$(COVRESOLVER): $(COVRESOLVEROBJS)
	ld65 -o $@ -C cov/resolvercov.cfg $(COVRESOLVEROBJS)

$(COVPRGDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVPRGDIR)/covsave.o: cov/covsave.s
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRG): $(COVPRGOBJS)
	ld65 -o $@ -C resolvertest.cfg $(COVPRGOBJS)

# Runs the tests against one set. The test saves the map to the disk.
covrun: $(COVRESOLVER) $(COVPRG) $(BINFILES) $(TXTFILES) | $(BINTARGETDIR)
	$(RM) $(COVD81)
	$(call MKDISK,$(COVD81),$(COVPRG),$(COVRESOLVER))
	../testcommon/runtest.sh resolvertestcov$(COVSET) $(COVPRG) $(COVD81)
	c1541 -attach $(COVD81) \
	-read resolver.cov $(BINTARGETDIR)/resolver$(COVSET).cov

# The copies are made fresh each time: they don't track the includes.
coverage:
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(BINTARGETDIR)/resolver*.cov
	for s in $(COVSETS); do \
	$(MAKE) TARGET=$(TARGET) DEBUG=1 COVSET=$$s covrun || exit 1; \
	done
	python3 $(COVTOOLS)/covreport.py $(COVLIST) $(COVARGS)

.PHONY: covrun coverage

clean:
	$(RM) $(TXTFILES)
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(D81FILE)
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(COVD81) $(COVLIST) $(BINTARGETDIR)/resolver*.cov

test:
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

.PHONY: test

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

load: $(D81FILE)
	mega65_ftp -e -c 'put $(D81FILE)' -c 'exit'
	etherload -m resolvertest.d81 -r $(BINTARGETDIR)/resolvertest

-include $(DEPENDS)
