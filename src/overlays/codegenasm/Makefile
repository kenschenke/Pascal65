CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/codegen

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

# make ALLPKGS=1 links every runtime package into every program, whatever
# the program uses (see genRuntime.s). It's for debugging. Any make without
# it, such as the one a test suite runs, builds without it again.
ALLPKGS ?= 0
ifeq ($(ALLPKGS),1)
ASFLAGS += -D ALLPKGS
endif

# The flags the objects were built with. Changing them rebuilds them all.
FLAGSFILE = $(OBJTARGETDIR)/asflags

SOURCES := $(wildcard $(SRCDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
DEPENDS := $(OBJECTS:.o=.d)
DEPFLAGS = --create-dep $(@:.o=.dep)
# ca65 is the Windows build, which names cc65's own headers by Windows
# paths. Their colons break make, and they never change, so drop them.
# sed writes a new file rather than renaming one (-i), which can fail on
# a OneDrive folder.
FIXDEP = sed -e 's/ [A-Za-z]:[^ :]*//g' $(@:.o=.dep) > $(@:.o=.d)

all: $(BINTARGETDIR) $(OBJTARGETDIR) $(LIBFILE)

$(BINDIR):
	mkdir -p $@

$(BINTARGETDIR): $(BINDIR)
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

$(OBJTARGETDIR): $(OBJDIR)
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(FLAGSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(ASFLAGS)" | cmp -s - $@ || echo "$(ASFLAGS)" > $@

FORCE:

$(LIBFILE): $(OBJECTS) $(CONFIG)
	ld65 -o $(LIBFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(LIBFILE) $(OBJECTS) $(FLAGSFILE)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)

-include $(DEPENDS)
