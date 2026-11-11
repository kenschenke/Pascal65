BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := editortest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

# The tests don't fit in one program. Program N runs the tests in
# src/testsN.s, from its own disk: bin/$(TARGET)/editortestN.prg and .d81.
TESTPROGS := 1 2 3 4 5

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIBDIR := ../../lib/asmlib
EDITORDIR := ../../overlays/editorasm
ASMLIB = $(ASMLIBDIR)/bin/$(TARGET)/asmlib
# The test build of the editor overlay (make EDITORTEST=1). It goes on the
# disk as "editor".
EDITOR = $(EDITORDIR)/bin/$(TARGET)/editor-test

PRGFILES := $(foreach n,$(TESTPROGS),$(BINTARGETDIR)/$(PROGRAM)$(n).prg)
D81FILES := $(PRGFILES:.prg=.d81)

# The files on each disk. The editor reads title.txt when it starts, and
# the help key opens help.txt. Each file in files/ is written as a SEQ file
# of the same name. The tests change the disk, so a test run makes the
# disks fresh.
FILEDIR := $(OBJTARGETDIR)/files
TITLETXT := $(FILEDIR)/title.txt
HELPTXT := $(FILEDIR)/help.txt
# In this order on the disk (see OPENFILE in src/tests.inc)
FIXNAMES := hello.txt lines200.txt noeol.txt prog.pas save.txt long.txt
FIXFILES := $(addprefix $(FILEDIR)/,$(FIXNAMES))
# Enough small files to fill the directory screen's two columns
MANYFILE := $(FILEDIR)/many
MANY := 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 \
	21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
DISKFILES := $(ASMLIB) $(TITLETXT) $(HELPTXT) $(FIXFILES) $(MANYFILE)
DISKWRITES := -write $(ASMLIB) asm.lib,prg \
	-write $(TITLETXT) title.txt,seq -write $(HELPTXT) help.txt,seq \
	$(foreach f,$(FIXNAMES),-write $(FILEDIR)/$(f) $(f),seq) \
	$(foreach i,$(MANY),-write $(MANYFILE) m$(i).txt,seq)
# $(call MKDISK,d81,program,editor overlay)
MKDISK = c1541 -format $(PROGRAM),8a d81 $(1) -write $(2) $(PROGRAM),prg \
	-write $(3) editor,prg $(DISKWRITES)

COMMONSRC := $(filter-out $(SRCDIR)/tests%.s,$(wildcard $(SRCDIR)/*.s))
COMMONOBJS := $(addprefix $(OBJTARGETDIR)/,$(notdir $(COMMONSRC:.s=.o)))
COMMONOBJS += $(OBJTARGETDIR)/testresult.o
TESTOBJS := $(foreach n,$(TESTPROGS),$(OBJTARGETDIR)/tests$(n).o)
DEPENDS := $(COMMONOBJS:.o=.d) $(TESTOBJS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

# The coverage build. make coverage runs the tests against instrumented
# copies of the editor overlay (see cov/mkcov.py) and lists the lines that
# never ran in bin/$(TARGET)/coverage.txt. Like test, it needs asmlib built
# with MEMCHECK=1.
#
# The probes make the overlay much bigger, and they don't all fit at once.
# Each set instruments some of the files and every test program runs once
# for each set. A set's map is COVSIZE bytes at COVMAP, above the test
# program.
COVMAP := 15360
COVSIZE := 1024
COVSETS := 1 2 3 4 5 6 7
COVSET ?= 1
COVFILES1 := editor.s
COVFILES2 := editbuf.s clipboard.s
COVFILES3 := screen.s
COVFILES4 := dirscreen.s filescreen.s
COVFILES5 := syntaxhl.s syntaxBinary.s syntaxCharCode.s syntaxComment.s \
	syntaxHex.s syntaxNumber.s syntaxString.s syntaxWord.s
COVFILES6 := keybuf.s editorInsertLine.s editorEnterKey.s \
	editorCombineLines.s filefree.s fileclose.s
COVFILES7 := fileread.s editorstate.s filesaveas.s filewrite.s \
	filesavetoexisting.s diskdir.s

EDSRCDIR := $(EDITORDIR)/src
EDSOURCES := $(wildcard $(EDSRCDIR)/*.s)
EDASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ \
	-D __EDITORTEST__ -D COVMAP=$(COVMAP)
COVDIR := $(OBJTARGETDIR)/cov$(COVSET)
COVEDOBJS := $(addprefix $(COVDIR)/,$(notdir $(EDSOURCES:.s=.o)))
COVEDITOR := $(COVDIR)/editor
COVPRGDIR := $(OBJTARGETDIR)/cov
COVPRGS := $(foreach n,$(TESTPROGS),$(COVPRGDIR)/$(PROGRAM)$(n).prg)
COVPRGOBJS := $(COVPRGDIR)/main.o $(COVPRGDIR)/covsave.o
COVPRGOBJS += $(filter-out $(OBJTARGETDIR)/main.o,$(COMMONOBJS))
COVD81 := $(BINTARGETDIR)/editortestcov.d81
COVLIST := $(BINTARGETDIR)/coverage.txt
# The map of a set and the coverage files of its runs
COVARGS = $(foreach s,$(COVSETS),-m $(OBJTARGETDIR)/cov$(s)/editor.map \
	$(foreach n,$(TESTPROGS),$(BINTARGETDIR)/editor$(s)-$(n).cov))

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILES) $(D81FILES)

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(FILEDIR): | $(OBJTARGETDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(EDITOR): FORCE
	cd $(EDITORDIR) && $(MAKE) TARGET=$(TARGET) EDITORTEST=1

# The text files on the disks, in PETSCII
$(TITLETXT): ../../shared/title.txt | $(FILEDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(HELPTXT): ../../shared/help.txt | $(FILEDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(FILEDIR)/%: files/% | $(FILEDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(MANYFILE): | $(FILEDIR)
	printf 'x\n' | petcat -w2 -text -o $@

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(BINTARGETDIR)/$(PROGRAM)%.prg: $(COMMONOBJS) $(OBJTARGETDIR)/tests%.o \
	| $(BINTARGETDIR)
	ld65 -o $@ -C $(PROGRAM).cfg $(COMMONOBJS) $(OBJTARGETDIR)/tests$*.o

$(BINTARGETDIR)/$(PROGRAM)%.d81: $(BINTARGETDIR)/$(PROGRAM)%.prg \
	$(EDITOR) $(DISKFILES)
	$(RM) $@
	$(call MKDISK,$@,$<,$(EDITOR))

# Every file of the overlay is copied, then the set's files are replaced by
# instrumented copies.
$(COVDIR)/stamp: $(EDSOURCES) cov/mkcov.py
	mkdir -p $(COVDIR)
	cp $(EDSOURCES) $(COVDIR)
	python3 cov/mkcov.py -D __MEGA65__ -D __EDITORTEST__ -m $(COVSIZE) \
	$(COVDIR) $(COVDIR)/editor.map \
	$(addprefix $(EDSRCDIR)/,$(COVFILES$(COVSET)))
	touch $@

$(COVDIR)/%.o: $(COVDIR)/stamp
	ca65 $(EDASFLAGS) -o $@ $(@:.o=.s)

$(COVEDITOR): $(COVEDOBJS)
	ld65 -D __JMPTBLSIZE__=12 -o $@ -C cov/editorcov.cfg $(COVEDOBJS)

$(COVPRGDIR)/main.o: $(SRCDIR)/main.s $(FLAGSFILE)
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVERAGE -o $@ $<

$(COVPRGDIR)/covsave.o: cov/covsave.s
	mkdir -p $(COVPRGDIR)
	ca65 $(ASFLAGS) -D COVMAP=$(COVMAP) -D COVSIZE=$(COVSIZE) -o $@ $<

$(COVPRGDIR)/$(PROGRAM)%.prg: $(COVPRGOBJS) $(OBJTARGETDIR)/tests%.o
	ld65 -o $@ -C $(PROGRAM).cfg $(COVPRGOBJS) $(OBJTARGETDIR)/tests$*.o

# Runs every test program against one set. The disk is made fresh for each
# run because the tests change it, and the test saves the map to it.
covrun: $(COVEDITOR) $(COVPRGS) $(DISKFILES) | $(BINTARGETDIR)
	for n in $(TESTPROGS); do \
	$(RM) $(COVD81) && \
	$(call MKDISK,$(COVD81),$(COVPRGDIR)/$(PROGRAM)$$n.prg,$(COVEDITOR)) && \
	../testcommon/runtest.sh editortestcov$(COVSET)-$$n \
	$(COVPRGDIR)/$(PROGRAM)$$n.prg $(COVD81) && \
	c1541 -attach $(COVD81) \
	-read editor.cov $(BINTARGETDIR)/editor$(COVSET)-$$n.cov || exit 1; \
	done

# The copies are made fresh each time: they don't track the includes.
coverage:
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(BINTARGETDIR)/editor*.cov
	for s in $(COVSETS); do \
	$(MAKE) TARGET=$(TARGET) DEBUG=1 COVSET=$$s covrun || exit 1; \
	done
	python3 cov/covreport.py $(COVLIST) $(COVARGS)

clean:
	$(RM) $(PRGFILES) $(D81FILES) $(COMMONOBJS) $(TESTOBJS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) -r $(FILEDIR)
	$(RM) -r $(COVPRGDIR) $(addprefix $(OBJTARGETDIR)/cov,$(COVSETS))
	$(RM) $(COVD81) $(COVLIST) $(BINTARGETDIR)/editor*.cov

# The disks are made fresh, since the tests change them
test:
	$(RM) $(D81FILES)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	for n in $(TESTPROGS); do \
	../testcommon/runtest.sh $(PROGRAM)$$n $(BINTARGETDIR)/$(PROGRAM)$$n.prg \
	$(BINTARGETDIR)/$(PROGRAM)$$n.d81 || exit 1; \
	done

run: all
	xmega65 -besure -8 $(BINTARGETDIR)/$(PROGRAM)1.d81

.PHONY: all clean test run coverage covrun

# Keep the test objects, which make would otherwise delete as intermediate
.SECONDARY: $(TESTOBJS)

-include $(DEPENDS)
