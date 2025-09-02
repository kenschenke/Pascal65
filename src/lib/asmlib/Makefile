CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
MEMBUFDIR := $(SRCDIR)/membuf

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/asmlib

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

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
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

vpath %.s $(MEMBUFDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(LIBFILE): $(OBJECTS) $(CONFIG)
	ld65 -o $(LIBFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(LIBFILE) $(OBJECTS)
