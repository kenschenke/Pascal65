CONFIG := editor.cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin
EDITORDIR := $(SRCDIR)/editor
FILESCREENSDIR := $(SRCDIR)/filescreens
FILEIODIR := $(SRCDIR)/fileio

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)

PROGRAM := editor
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)

ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

SOURCES := $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(EDITORDIR)/*.s)
SOURCES += $(wildcard $(FILESCREENSDIR)/*.s)
SOURCES += $(wildcard $(FILEIODIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

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
	ca65 $(ASFLAGS) -o $@ $<

vpath %.s $(EDITORDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

vpath %.s $(FILESCREENSDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

vpath %.s $(FILEIODIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) -o $@ $<

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(PRGFILE) $(OBJECTS)
