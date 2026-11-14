SRCDIR := src
OBJDIR := obj
BINDIR := bin

PROGRAM := demolib
BINTARGETDIR := $(BINDIR)/$(TARGET)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
CC65TARGET = c64

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
else
ASFLAGS = -I ../../asminc
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

# DemoLib2, the twin of DemoLib in the v2 library format (a relocation
# table, see docs/docs/libraries/objfile.md). It has DemoLib's routines,
# its own jump table and the routines in src2 that test the format.
SRC2DIR := src2
SOURCES2 := $(wildcard $(SRC2DIR)/*.s)
OBJECTS2 := $(filter-out $(OBJTARGETDIR)/demolib.o,$(OBJECTS))
OBJECTS2 += $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES2)))))
PRGFILE2 := $(BINTARGETDIR)/demolib2
MKRELOC := ../mkreloc.py

DEPENDS := $(sort $(OBJECTS:.o=.d) $(OBJECTS2:.o=.d))
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(PRGFILE) $(PRGFILE2)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJTARGETDIR):
	mkdir -p $@

vpath %.s $(SRCDIR) $(SRC2DIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS) demolib.cfg
	ld65 $(LDFLAGS) -o $(PRGFILE) -C demolib.cfg $(OBJECTS)

$(PRGFILE2): $(OBJECTS2) demolib2.cfg $(MKRELOC)
	python3 $(MKRELOC) -C demolib2.cfg -S 0x3000 -o $(PRGFILE2) $(OBJECTS2)

clean:
	$(RM) $(OBJECTS) $(OBJECTS2)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)
	$(RM) $(PROGRAM)
	$(RM) $(BINTARGETDIR)/*

-include $(DEPENDS)
