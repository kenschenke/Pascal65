SRCDIR := src
OBJDIR := obj
BINDIR := bin

PROGRAM := sound
CC65TARGET = c64

BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

ASFLAGS = -I ../../asminc -I $(SRCDIR) -D __MEGA65__

SOURCES := $(wildcard $(SRCDIR)/*.s)

# The library is in the v2 format (a relocation table, see
# docs/docs/libraries/objfile.md), linked by mkreloc.py.
CONFIG := sound.cfg
MKRELOC := ../mkreloc.py

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS) $(CONFIG) $(MKRELOC)
	python3 $(MKRELOC) -C $(CONFIG) -S 0x3000 -o $(PRGFILE) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(BINTARGETDIR)/*

-include $(DEPENDS)
