CONFIG := compilertestasm.cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
TESTSDIR := tests
PETSCIIDIR := petscii
TOKENIZERDIR := ../../overlays/tokenizerasm
ICODEDIR := ../../overlays/icodeasm
PARSERDIR := ../../overlays/parserasm
RESOLVERDIR := ../../overlays/resolverasm
TYPECHECKDIR := ../../overlays/typecheckasm
LINKERDIR := ../../overlays/linkerasm
CODEGENDIR := ../../overlays/codegenasm
MEMINFODIR := ../../overlays/meminfo
TPUDIR := ../../overlays/tpuasm
ASMLIBDIR := ../../lib/asmlib
SYSTEMLIBDIR := ../../lib/system
DEMOLIBDIR := ../../lib/demolib
SCREENLIBDIR := ../../lib/screen
SPRITESLIBDIR := ../../lib/sprites
SPRITEMOVELIBDIR := ../../lib/spritemove
SOUNDLIBDIR := ../../lib/sound
RUNTIMEDIR := ../../lib/runtime

PROGRAM := compilertest
TARGET := mega65

# The test target builds and runs the tests in three sets (see
# compiletests.s) because the programs produced by the whole list do not fit
# on one disk image. A set's disk also needs room for the files its tests
# write (filetesta and filetestb in set 2).
TESTSETS := 1 2 3 4
FIRSTTEST1 := unitobjs
FIRSTTEST2 := subtract
FIRSTTEST3 := dynarraya
FIRSTTEST4 := unitobjs
# Set 4 runs with a work disk on unit 9 (plans/workdisks.md): the
# compiler, overlays, libraries and runtime are on the system disk (unit
# 8), and the sources, the marker and runtimeN on the work disk, where
# everything the compiles and the programs write goes. The system disk
# must be unchanged after the compile step and the run step (its
# SHA-256), and the run step starts the chain from unit 9 (mkboot.py).
WORKSETS := 4
WORKUNIT := 9
ifneq ($(filter $(TESTSET),$(WORKSETS)),)
WORKSET := 1
endif
# Programs are built for the dynamic runtime unless they say
# $StaticRuntime. Set 2 builds every program with the static runtime
# (FORCESTATIC in runcompiler.s), so static mode is tested as widely.
STATICSETS := 2
# Set 3 also tests the dynamic runtime's loader (rtdyntest.sh)
RTDYNSET := 3
ifdef TESTSET
PROGRAM := compilertest$(TESTSET)
endif

BINTARGETDIR = $(BINDIR)/$(TARGET)
ifdef TESTSET
OBJTARGETDIR = $(OBJDIR)/$(TARGET)-set$(TESTSET)
else
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
endif
D81FILE = $(BINTARGETDIR)/$(PROGRAM).d81
# A work set's work disk, the disk its programs are compiled to (OUTD81),
# the runtest.sh argument that mounts it and the system disk's SHA-256
ifdef WORKSET
WORKD81 = $(BINTARGETDIR)/$(PROGRAM)work.d81
OUTD81 = $(WORKD81)
UNIT9 = $(WORKD81)
SYSSUM = $(BINTARGETDIR)/$(PROGRAM)-sys.sha256
BOOTPRG = $(BINTARGETDIR)/$(PROGRAM)-boot.prg
WORKMARKER = $(OBJTARGETDIR)/p65work
else
OUTD81 = $(D81FILE)
endif
# The PRGs on the disk before the compile step, and the checksums the
# compiled ones must have (prgsums.sh)
PRGSBEFORE = $(BINTARGETDIR)/$(PROGRAM)-before.txt
PRGSUMS = prgsums/set$(TESTSET).txt

# The sources only set 3 compiles. Sets 1 and 2 leave them off their disks,
# which need the room for the programs they compile and the files their
# tests write (set 2's file tests hang on a full disk).
comma := ,
# Set 1's own sources. slots256, unitlib, unituses, unitrefs and unitobjs
# were each added as the set's first program, so no program's chain
# target changed.
# toomanyvars, toomanyimpl, mkcycle and mkbad are four of set 1's
# errorTests.
# The mk files are its makeTests; mkstale.tpu is a TPU of an old icode
# version.
SET1PAS = slots256 s256u toomanyvars tmvunit toomanyimpl tmvimpl unitlib \
	ulib unituses uusea uuseb unitrefs urefs mkprog mka1 mka2 mka3 mkb mkc \
	mkcycle cyca cycb mkbad mkerr unitobjs uobjs uobjl uobjr
MKSTALE = $(BINTARGETDIR)/mkstale.tpu
ifeq ($(filter $(TESTSET),2 3),)
SET1WRITE = $(foreach t,$(SET1PAS), \
	-write $(PETSCIIDIR)/$(t).pas $(t).pas$(comma)seq) \
	-write $(MKSTALE) mkstale.tpu$(comma)seq
SET1FILES = $(MKSTALE)
endif
SET3PAS = libtest2 soundtest soundfx soundseq irqcb soundcalls dynarraya \
	dynarrayb dynarrayc \
	rtpkgnone rtpkga rtpkgb rtpkgc rtdyn rtdyna rtdynb rterrexit
ifeq ($(filter $(TESTSET),1 2 4),)
SET3WRITE = -write fivedice.petscii fivedice.pas$(comma)seq \
	-write bubbles.petscii bubbles.pas$(comma)seq \
	-write sfxdemo.petscii sfxdemo.pas$(comma)seq \
	-write tunedemo.petscii tunedemo.pas$(comma)seq \
	-write stereodemo.petscii stereodemo.pas$(comma)seq \
	-write hangman.petscii hangman.pas$(comma)seq \
	$(foreach t,$(SET3PAS),-write $(PETSCIIDIR)/$(t).pas $(t).pas$(comma)seq)
endif
# The sources every set's disk has
COMMONPAS = add assign varinit bitwisea bitwiseb ifthen loops stdroutines \
	incdec strroutines strleak writewidth strtests recarray scopetest \
	casetest procfunc multiply forord declordr negate subrange unitinit \
	uinita uinitb subtract divint trig vartest filetesta filetestb \
	pointers unit unit1 libtest rtnarray rtnrecord rtnptrs strrecord \
	strarray constants typecast chararray exprclone namedidx done toolarge
SRCWRITE = $(foreach t,$(COMMONPAS), \
	-write $(PETSCIIDIR)/$(t).pas $(t).pas$(comma)seq) \
	$(SET1WRITE) $(SET3WRITE)
# A work set's sources are on the work disk, with wdsearch's unit, and
# the system disk has the other wdunit.pas, which must not be found
ifdef WORKSET
SYSSRC = -write $(PETSCIIDIR)/wdunitsys.pas wdunit.pas,seq
WORKSRC = $(SRCWRITE) -write $(PETSCIIDIR)/wdsearch.pas wdsearch.pas,seq \
	-write $(PETSCIIDIR)/wdunit.pas wdunit.pas,seq
else
SYSSRC = $(SRCWRITE)
endif

ASMLIB = ../../lib/asmlib/bin/$(TARGET)/asmlib
DEMOLIB = ../../lib/demolib/bin/$(TARGET)/demolib
DEMOLIB2 = ../../lib/demolib/bin/$(TARGET)/demolib2
SCREENLIB = ../../lib/screen/bin/$(TARGET)/screen
SPRITESLIB = ../../lib/sprites/bin/$(TARGET)/sprites
SPRITEMOVELIB = ../../lib/spritemove/bin/$(TARGET)/spritemove
SOUNDLIB = ../../lib/sound/bin/$(TARGET)/sound
TOKENIZER = ../../overlays/tokenizerasm/bin/$(TARGET)/tokenizer
PARSER = ../../overlays/parserasm/bin/$(TARGET)/parser
ICODE = ../../overlays/icodeasm/bin/$(TARGET)/icode
RESOLVER = ../../overlays/resolverasm/bin/$(TARGET)/resolver
TYPECHECK = ../../overlays/typecheckasm/bin/$(TARGET)/typecheck
MEMINFO = ../../overlays/meminfo/bin/$(TARGET)/meminfo
TPU = ../../overlays/tpuasm/bin/$(TARGET)/tpu
CODEGEN = ../../overlays/codegenasm/bin/$(TARGET)/codegen
LINKER = ../../overlays/linkerasm/bin/$(TARGET)/linker
SYSTEMLIB = ../../lib/system/bin/$(TARGET)/system
# The runtime core and package files (RUNTIME, RTWRITE)
include $(RUNTIMEDIR)/rtfiles.mk
PRGFILE = $(BINTARGETDIR)/$(PROGRAM)
SYSTEMPAS = ../../lib/system/system.pas
DEMOLIBPAS = ../../lib/demolib/demolib.pas
DEMOLIB2PAS = ../../lib/demolib/demolib2.pas
SOUNDPAS = ../../lib/sound/sound.pas
FIVEDICEPAS = ../../../examples/fivedice.pas
BUBBLESPAS = ../../../examples/bubbles.pas
SFXDEMOPAS = ../../../examples/sfxdemo.pas
TUNEDEMOPAS = ../../../examples/tunedemo.pas
STEREODEMOPAS = ../../../examples/stereodemo.pas
HANGMANPAS = ../../../examples/hangman.pas

BINFILES += $(TOKENIZER)
BINFILES += $(PARSER)
BINFILES += $(ICODE)
BINFILES += $(RESOLVER)
BINFILES += $(TYPECHECK)
BINFILES += $(MEMINFO)
BINFILES += $(TPU)
BINFILES += $(ASMLIB)
BINFILES += $(DEMOLIB)
BINFILES += $(DEMOLIB2)
BINFILES += $(SCREENLIB)
BINFILES += $(SPRITESLIB)
BINFILES += $(SPRITEMOVELIB)
BINFILES += $(SOUNDLIB)
BINFILES += $(PRGFILE)
BINFILES += $(CODEGEN)
BINFILES += $(LINKER)
BINFILES += $(SYSTEMLIB)
BINFILES += $(RUNTIME)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__
ifdef TESTSET
ASFLAGS += -D TESTSET=$(TESTSET)
ifneq ($(filter $(TESTSET),$(STATICSETS)),)
ASFLAGS += -D FORCESTATIC
endif
ifdef WORKSET
ASFLAGS += -D WORKUNIT=$(WORKUNIT)
endif
endif

HDRSHAREDDIR := ../../shared/hdr
# Pre-compiled library headers, generated by the mkhdr app. A library with no
# header here is parsed from its .pas file at compile time.
HDRFILES := $(wildcard ../../lib/hdr/*.hdr)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(OBJTARGETDIR)/hdrload.o $(OBJTARGETDIR)/hdrtables.o $(OBJTARGETDIR)/testresult.o
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

TXTFILES := errormsgs.petscii system.petscii demolib.petscii fivedice.petscii
TXTFILES += demolib2.petscii
TXTFILES += bubbles.petscii
TXTFILES += sfxdemo.petscii
TXTFILES += tunedemo.petscii
TXTFILES += stereodemo.petscii
TXTFILES += hangman.petscii
TXTFILES += sound.petscii

TESTS := $(wildcard $(TESTSDIR)/*.pas)
ERRORTESTS := $(wildcard $(ERRORTESTSDIR)/*.pas)
TXTFILES += $(patsubst $(TESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(TESTS))
TXTFILES += $(patsubst $(ERRORTESTSDIR)/%.pas, $(PETSCIIDIR)/%.pas, $(ERRORTESTS))

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE) $(D81FILE) $(WORKD81) \
	$(BOOTPRG)

errormsgs.petscii: ../../shared/errormsgs.txt
	dos2unix < ../../shared/errormsgs.txt | petcat -w2 -text -o errormsgs.petscii

system.petscii: $(SYSTEMPAS)
	dos2unix < $(SYSTEMPAS) | petcat -w2 -text -o system.petscii

demolib.petscii: $(DEMOLIBPAS)
	dos2unix < $(DEMOLIBPAS) | petcat -w2 -text -o demolib.petscii

demolib2.petscii: $(DEMOLIB2PAS)
	dos2unix < $(DEMOLIB2PAS) | petcat -w2 -text -o demolib2.petscii

sound.petscii: $(SOUNDPAS)
	dos2unix < $(SOUNDPAS) | petcat -w2 -text -o sound.petscii

# Compiled, but not run, to check the runtime leaves it room
fivedice.petscii: $(FIVEDICEPAS)
	dos2unix < $(FIVEDICEPAS) | petcat -w2 -text -o fivedice.petscii

# Compiled, but not run, to check the Sprites and SpriteMove libraries
bubbles.petscii: $(BUBBLESPAS)
	dos2unix < $(BUBBLESPAS) | petcat -w2 -text -o bubbles.petscii

sfxdemo.petscii: $(SFXDEMOPAS)
	dos2unix < $(SFXDEMOPAS) | petcat -w2 -text -o sfxdemo.petscii

tunedemo.petscii: $(TUNEDEMOPAS)
	dos2unix < $(TUNEDEMOPAS) | petcat -w2 -text -o tunedemo.petscii

stereodemo.petscii: $(STEREODEMOPAS)
	dos2unix < $(STEREODEMOPAS) | petcat -w2 -text -o stereodemo.petscii

# Compiled, but not run, to check the game still fits with Screen and Sound
hangman.petscii: $(HANGMANPAS)
	dos2unix < $(HANGMANPAS) | petcat -w2 -text -o hangman.petscii

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(PETSCIIDIR):
	mkdir -p $@

$(PARSER): FORCE
	cd $(PARSERDIR) && $(MAKE) TARGET=$(TARGET)

$(RESOLVER): FORCE
	cd $(RESOLVERDIR) && $(MAKE) TARGET=$(TARGET)

$(TYPECHECK): FORCE
	cd $(TYPECHECKDIR) && $(MAKE) TARGET=$(TARGET)

$(TOKENIZER): FORCE
	cd $(TOKENIZERDIR) && $(MAKE) TARGET=$(TARGET)

$(ICODE): FORCE
	cd $(ICODEDIR) && $(MAKE) TARGET=$(TARGET)

$(CODEGEN): FORCE
	cd $(CODEGENDIR) && $(MAKE) TARGET=$(TARGET)

$(LINKER): FORCE
	cd $(LINKERDIR) && $(MAKE) TARGET=$(TARGET)

$(MEMINFO): FORCE
	cd $(MEMINFODIR) && $(MAKE) TARGET=$(TARGET)

$(TPU): FORCE
	cd $(TPUDIR) && $(MAKE) TARGET=$(TARGET)

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(DEMOLIB): FORCE
	cd $(DEMOLIBDIR) && $(MAKE) TARGET=$(TARGET)

# Built with DEMOLIB
$(DEMOLIB2): $(DEMOLIB)

$(SCREENLIB): FORCE
	cd $(SCREENLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SPRITESLIB): FORCE
	cd $(SPRITESLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SPRITEMOVELIB): FORCE
	cd $(SPRITEMOVELIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SOUNDLIB): FORCE
	cd $(SOUNDLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(SYSTEMLIB): FORCE
	cd $(SYSTEMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(RUNTIME): FORCE
	cd $(RUNTIMEDIR) && $(MAKE) TARGET=$(TARGET)

include ../debug.mk

vpath %.s $(SRCDIR) $(HDRSHAREDDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.pas $(TESTSDIR)
$(PETSCIIDIR)/%.pas: %.pas | $(PETSCIIDIR)
	dos2unix < $< | petcat -w2 -text -o $@

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

FORCE:

# "TP", TPU_VERSION 1 and ICODE_VERSION 0 (tpu.inc): enough for the make
# walk to find it out of date
$(MKSTALE): | $(BINTARGETDIR)
	printf 'TP\001\000' > $@

$(D81FILE): $(BINFILES) $(TXTFILES) $(SET1FILES)
	c1541 -format $(PROGRAM),8a d81 $(D81FILE) \
	-write $(PRGFILE) compiler,prg \
	-write $(TOKENIZER) tokenizer,prg \
	-write $(ICODE) icode,prg \
	-write $(PARSER) parser,prg \
	-write $(RESOLVER) resolver,prg \
	-write $(TYPECHECK) typecheck,prg \
	-write $(CODEGEN) codegen,prg \
	-write $(LINKER) linker,prg \
	-write $(MEMINFO) meminfo,prg \
	-write $(TPU) tpu,prg \
	-write $(ASMLIB) asm.lib,prg \
	-write $(DEMOLIB) demolib.lib,prg \
	-write $(DEMOLIB2) demolib2.lib,prg \
	-write $(SCREENLIB) screen.lib,prg \
	-write $(SPRITESLIB) sprites.lib,prg \
	-write $(SPRITEMOVELIB) spritemove.lib,prg \
	-write $(SOUNDLIB) sound.lib,prg \
	-write $(SYSTEMLIB) system.lib,prg \
	$(RTWRITE) \
	-write errormsgs.petscii errormsgs.txt,seq \
	-write system.petscii system.pas,seq \
	-write demolib.petscii demolib.pas,seq \
	-write demolib2.petscii demolib2.pas,seq \
	-write sound.petscii sound.pas,seq \
	$(SYSSRC) \
	$(foreach h,$(HDRFILES),-write $(h) $(notdir $(h)),prg)

ifdef WORKSET
$(WORKMARKER): ../../shared/mkmarker.py ../../asminc/workdisk.inc \
	| $(OBJTARGETDIR)
	python3 ../../shared/mkmarker.py ../../asminc/workdisk.inc $@

# A work disk as wdCreate makes one (the marker and runtimeN), with the
# sources. It has no themes.dat, which the compiler doesn't read.
$(WORKD81): $(WORKMARKER) $(RUNTIME) $(TXTFILES) $(SET1FILES)
	$(RM) $@
	c1541 -format work,9a d81 $@ \
	-write $(RUNTIMEDIR)/bin/$(TARGET)/runtime$(RTABI) runtime$(RTABI),prg \
	-write $(WORKMARKER) p65work,seq \
	$(WORKSRC)

# The run step's PRG: RUN "first",U9
$(BOOTPRG): mkboot.py | $(BINTARGETDIR)
	python3 mkboot.py $(FIRSTTEST$(TESTSET)) $(WORKUNIT) $@

# Fails unless the system disk is the same as before the compile step
CHECKSYS = sha256sum -c --quiet $(SYSSUM) || \
	{ echo "$(PROGRAM): FAIL (the system disk changed)"; exit 1; }
endif

clean:
	$(RM) $(TXTFILES)
	$(RM) $(D81FILE) $(WORKD81) $(BOOTPRG) $(SYSSUM) $(WORKMARKER)
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
ifndef TESTSET
	@for s in $(TESTSETS); do \
		$(MAKE) TARGET=$(TARGET) TESTSET=$$s clean || exit 1; \
	done
endif

run: $(D81FILE)
	xmega65 -besure -8 $(D81FILE)

# Builds the disk images of all the test sets, as the test target does, and
# copies them to a MEGA65 to run the tests on real hardware. On each disk,
# RUN "COMPILER" compiles the set, then RUN the set's first program
# (FIRSTTESTn) to start the chain. The loader checks in rtdyntest.sh only
# run in the emulator. A work set's work disk goes on unit 9 and its first
# program is run from there.
load: hwimages
	mega65_ftp -e $(foreach s,$(TESTSETS), \
		-c 'put $(BINTARGETDIR)/compilertest$(s).d81') \
		$(foreach s,$(WORKSETS), \
		-c 'put $(BINTARGETDIR)/compilertest$(s)work.d81') -c 'exit'
	@$(foreach s,$(filter-out $(WORKSETS),$(TESTSETS)), \
		echo "compilertest$(s).d81: \
		RUN \"COMPILER\", then RUN \"$(FIRSTTEST$(s))\"";)
	@$(foreach s,$(WORKSETS),echo "compilertest$(s).d81 on unit 8 and \
		compilertest$(s)work.d81 on unit $(WORKUNIT): RUN \"COMPILER\", \
		then RUN \"$(FIRSTTEST$(s))\",U$(WORKUNIT)";)

# Builds a fresh debug disk image for each set with asmlib's memory checks,
# then rebuilds asmlib without them, whether or not the images were built.
hwimages:
	$(MAKE) -C $(ASMLIBDIR) TARGET=$(TARGET) MEMCHECK=1
	@status=0; for s in $(TESTSETS); do \
		$(MAKE) TARGET=$(TARGET) TESTSET=$$s hwimage || \
			{ status=1; break; }; \
	done; \
	$(MAKE) -C $(ASMLIBDIR) TARGET=$(TARGET) MEMCHECK=0; \
	exit $$status

# Builds one set's (TESTSET) disk image. It is rebuilt so it doesn't hold
# programs or a testfailed file from an earlier run.
hwimage:
	$(RM) $(D81FILE) $(WORKD81)
	$(MAKE) TARGET=$(TARGET) TESTSET=$(TESTSET) DEBUG=1 all

# Compiles the first set of tests, runs the chain of programs it produced, then
# does the same for the second set. A warning or error from any compile fails
# the run, and so does a failure in any of the compiled programs.
test:
	@for s in $(TESTSETS); do \
		$(MAKE) TARGET=$(TARGET) TESTSET=$$s testset || exit 1; \
	done

# Runs one set (TESTSET) of the tests. The disk image is rebuilt first so it
# does not hold programs from an earlier run. The compile step reports
# PASS/FAIL like the other test suites, then the first program in the chain is
# run from the disk image. Each program loads the next, and the last one
# ("done") prints PASS. A test that finds a problem records its name and error
# numbers in the "testfailed" file on the disk, which "done" prints before FAIL. A
# runtime error ends the chain early, so the result line is never printed.
#
# After the compile step, each compiled program must match the checksum in
# prgsums/setN.txt (prgsums.sh), so a change that must not change the
# programs (plans/objcode.md) is checked.
#
# A work set (WORKSETS) compiles to its work disk, which runtest.sh mounts
# on unit 9, and its checksums are of the programs there. The system
# disk's SHA-256 must be the same after each step as before the first.
# The run step's PRG is BOOTPRG, which runs the first program from the
# work disk.
testset:
	$(RM) $(D81FILE) $(WORKD81)
	$(MAKE) TARGET=$(TARGET) TESTSET=$(TESTSET) DEBUG=1 all
	sh prgsums.sh list $(OUTD81) > $(PRGSBEFORE)
	$(if $(WORKSET),sha256sum $(D81FILE) > $(SYSSUM))
	../testcommon/runtest.sh $(PROGRAM)-compile $(PRGFILE) $(D81FILE) $(UNIT9)
	$(if $(WORKSET),$(CHECKSYS))
	sh prgsums.sh check $(OUTD81) $(PRGSBEFORE) $(PRGSUMS)
	$(if $(filter $(TESTSET),$(RTDYNSET)),sh rtdyntest.sh $(D81FILE) $(RTABI))
ifdef WORKSET
	../testcommon/runtest.sh $(PROGRAM)-run $(BOOTPRG) $(D81FILE) $(UNIT9)
	$(CHECKSYS)
else
	c1541 $(D81FILE) -read $(FIRSTTEST$(TESTSET)) $(BINTARGETDIR)/$(PROGRAM)-first.prg
	../testcommon/runtest.sh $(PROGRAM)-run $(BINTARGETDIR)/$(PROGRAM)-first.prg $(D81FILE)
endif

# Compiles each set and records its programs' checksums in prgsums/setN.txt,
# for a change that is meant to change the programs. Check that it does only
# what it should first. Like test, it needs asmlib built with MEMCHECK=1.
savesums:
	@for s in $(TESTSETS); do \
		$(MAKE) TARGET=$(TARGET) TESTSET=$$s savesumsset || exit 1; \
	done

savesumsset:
	$(RM) $(D81FILE) $(WORKD81)
	$(MAKE) TARGET=$(TARGET) TESTSET=$(TESTSET) DEBUG=1 all
	sh prgsums.sh list $(OUTD81) > $(PRGSBEFORE)
	../testcommon/runtest.sh $(PROGRAM)-compile $(PRGFILE) $(D81FILE) $(UNIT9)
	sh prgsums.sh save $(OUTD81) $(PRGSBEFORE) $(PRGSUMS)

.PHONY: test testset load hwimages hwimage savesums savesumsset

-include $(DEPENDS)
