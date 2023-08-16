SRCDIR := src
OBJDIR := obj
BINDIR := bin
PROGRAM = simtest.bin
BINFILE = $(BINDIR)/$(PROGRAM)
LIBCOMMONDIR = ../../lib/common
LIBRUNTIMEDIR = ../../lib/runtime

PROGRAM := simtest
TARGET := sim6502

ASFLAGS = -I ../../asminc
# LDFLAGS = -u __EXEHDR__ --lib c64.lib
LDFLAGS = -C sim6502.cfg --lib sim6502.lib

SOURCES += $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(LIBCOMMONDIR)/*.s)
SOURCES += $(wildcard $(LIBRUNTIMEDIR)/*.s)

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(BINFILE)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(TARGET) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(TARGET) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBRUNTIMEDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(TARGET) $(ASFLAGS) -o $@ $<

$(BINFILE): $(OBJECTS)
	ld65 $(LDFLAGS) -o $(BINFILE) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(BINDIR)/*

run: $(BINFILE)
	sim65 $(BINFILE)
