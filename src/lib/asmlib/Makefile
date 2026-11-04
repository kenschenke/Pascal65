CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
MEMBUFDIR := $(SRCDIR)/membuf

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/asmlib

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

# The flags the objects were built with. Changing MEMCHECK rebuilds them all.
FLAGSFILE = $(OBJTARGETDIR)/asflags

# make MEMCHECK=1 builds the runtime memory checks (__DEBUG__): freeing
# memory that is not allocated, such as a double free, executes BRK. The test
# suites need them. make MEMCHECK=0 builds without them, for normal use.
#
# Without MEMCHECK on the command line the setting of the last build is kept,
# so the test suites, which run make here, do not change it. A clean build has
# no checks.
ifeq ($(origin MEMCHECK),undefined)
MEMCHECK := $(if $(findstring __DEBUG__,$(shell cat $(FLAGSFILE) 2>/dev/null)),1,0)
endif
ifeq ($(MEMCHECK),1)
ASFLAGS += -D __DEBUG__
endif

SOURCES := $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(MEMBUFDIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

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
	ca65 $(ASFLAGS) -o $@ $<

vpath %.s $(MEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.s $(FLAGSFILE) | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(FLAGSFILE): FORCE | $(OBJTARGETDIR)
	@echo "$(ASFLAGS)" | cmp -s - $@ || echo "$(ASFLAGS)" > $@

FORCE:

$(LIBFILE): $(OBJECTS) $(CONFIG)
	ld65 -o $(LIBFILE) -C $(CONFIG) $(OBJECTS)

.PHONY: all clean FORCE

clean:
	$(RM) $(LIBFILE) $(OBJECTS) $(FLAGSFILE)
