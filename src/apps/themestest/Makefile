BINDIR := bin
OBJDIR := obj
SRCDIR := src

PROGRAM := themestest
TARGET := mega65

BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

ASMLIBDIR := ../../lib/asmlib
THEMESDIR := ../../overlays/themes
ASMLIB = $(ASMLIBDIR)/bin/$(TARGET)/asmlib
# The test build of the themes overlay (make THEMESTEST=1). It goes on the
# disk as "themes".
THEMES = $(THEMESDIR)/bin/$(TARGET)/themes-test
MKTHEMES := ../../shared/mkthemes.py

PRGFILE := $(BINTARGETDIR)/$(PROGRAM).prg
D81FILE := $(BINTARGETDIR)/$(PROGRAM).d81

# The theme files on the disk, made by mkthemes.py from files/*.txt. Before
# each test the program copies one to themes.dat and one to themes.def (see
# src/tests.inc). Keep the .txt files ASCII: mkthemes.py reads them, not
# petcat. <name>_ARGS is the generator's input and options for fixture
# <name>.
FIXDIR := $(OBJTARGETDIR)/files
FIXTURES := three three0 three2 sel9 partial onlysel defs builtin \
	numchg rgbchg bgchg bgui old oldpart version2 marker markerver \
	hdronly newcolors errchg warnchg errrgb bgerr
# The fixtures are version 1 files unless they say --format 0. A version 1
# three.txt is 3 + 3 * 60 bytes; version 0 is 1 + 3 * 52.
three_ARGS := files/three.txt
three0_ARGS := files/three.txt --selected 0
three2_ARGS := files/three.txt --selected 2
# A selected number past the end of the list
sel9_ARGS := files/three.txt --selected 9
# Two themes, then part of the third
partial_ARGS := files/three.txt --truncate 10
# A version 0 file with the selected number and no theme. A CBM disk can't
# hold an empty file (the DOS writes one byte), so this is the empty file
# too.
onlysel_ARGS := files/three.txt --format 0 --truncate 156
# Version 0 three, which the overlay upgrades to version 1
old_ARGS := files/three.txt --format 0
# Two version 0 themes, then part of the third
oldpart_ARGS := files/three.txt --format 0 --truncate 10
# A version the overlay can't read
version2_ARGS := files/three.txt --version 2
# The marker alone; the marker and the version; the whole header and no
# theme
marker_ARGS := files/three.txt --truncate 182
markerver_ARGS := files/three.txt --truncate 181
hdronly_ARGS := files/three.txt --truncate 180
newcolors_ARGS := files/newcolors.txt
defs_ARGS := files/defs.txt
builtin_ARGS := files/builtin.txt
numchg_ARGS := files/numchg.txt
rgbchg_ARGS := files/rgbchg.txt
bgchg_ARGS := files/bgchg.txt
bgui_ARGS := files/bgui.txt
errchg_ARGS := files/errchg.txt
warnchg_ARGS := files/warnchg.txt
errrgb_ARGS := files/errrgb.txt
bgerr_ARGS := files/bgerr.txt
FIXFILES := $(addprefix $(FIXDIR)/,$(FIXTURES))

DISKWRITES := -write $(ASMLIB) asm.lib,prg -write $(THEMES) themes,prg \
	$(foreach f,$(FIXTURES),-write $(FIXDIR)/$(f) $(f),seq)

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES:.s=.o)))
OBJECTS += $(OBJTARGETDIR)/testresult.o
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(OBJTARGETDIR) $(BINTARGETDIR) $(PRGFILE) $(D81FILE)

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

$(FIXDIR): | $(OBJTARGETDIR)
	mkdir -p $@

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(ASMLIB): FORCE
	cd $(ASMLIBDIR) && $(MAKE) TARGET=$(TARGET)

$(THEMES): FORCE
	cd $(THEMESDIR) && $(MAKE) TARGET=$(TARGET) THEMESTEST=1

.SECONDEXPANSION:
$(FIXDIR)/%: $$(firstword $$($$*_ARGS)) $(MKTHEMES) | $(FIXDIR)
	python3 $(MKTHEMES) $($*_ARGS) -o $@

include ../debug.mk

vpath %.s $(SRCDIR) ../testcommon
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS) $(PROGRAM).cfg | $(BINTARGETDIR)
	ld65 -o $@ -C $(PROGRAM).cfg $(OBJECTS)

$(D81FILE): $(PRGFILE) $(ASMLIB) $(THEMES) $(FIXFILES)
	$(RM) $@
	c1541 -format $(PROGRAM),8a d81 $@ -write $< $(PROGRAM),prg \
	$(DISKWRITES)

clean:
	$(RM) $(PRGFILE) $(D81FILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) -r $(FIXDIR)

# The disk is made fresh, since the tests change it
test:
	$(RM) $(D81FILE)
	$(MAKE) TARGET=$(TARGET) DEBUG=1 all
	../testcommon/runtest.sh $(PROGRAM) $(PRGFILE) $(D81FILE)

run: all
	xmega65 -besure -8 $(D81FILE)

.PHONY: all clean test run

-include $(DEPENDS)
