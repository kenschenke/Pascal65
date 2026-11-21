CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/workdisk

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__ -D WORKDISK_OVERLAY
LDFLAGS =

# make WORKDISKTEST=1 builds the overlay for the workdisk tests
# (src/apps/workdisktest) as workdisk-test. It has the hooks in wdtest.s
# and three more jump table entries. Its objects are kept apart so the
# normal overlay never picks them up.
WORKDISKTEST ?= 0
ifeq ($(WORKDISKTEST),1)
ASFLAGS += -D __WORKDISKTEST__
LDFLAGS += -D __JMPTBLSIZE__=24
OBJTARGETDIR = $(OBJDIR)/$(TARGET)-test
LIBFILE := $(BINTARGETDIR)/workdisk-test
endif

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
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(LIBFILE): $(OBJECTS) $(CONFIG)
	ld65 $(LDFLAGS) -o $(LIBFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(LIBFILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)

-include $(DEPENDS)
