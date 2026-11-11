CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/themes

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__
LDFLAGS =

# make THEMESTEST=1 builds the overlay for the themes tests
# (src/apps/themestest) as themes-test. It has the hooks in themestest.s
# and ten more jump table entries. Its objects are kept apart so the normal
# overlay never picks them up.
THEMESTEST ?= 0
ifeq ($(THEMESTEST),1)
ASFLAGS += -D __THEMESTEST__
LDFLAGS += -D __JMPTBLSIZE__=36
OBJTARGETDIR = $(OBJDIR)/$(TARGET)-test
LIBFILE := $(BINTARGETDIR)/themes-test
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
