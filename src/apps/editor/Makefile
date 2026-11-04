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

# Add -D __DEBUG__ to enable F8 debug key in editor
ASFLAGS = -I ../../asminc -t c64 --cpu 4510 -D __MEGA65__

SOURCES := $(wildcard $(SRCDIR)/*.s)
SOURCES += $(wildcard $(EDITORDIR)/*.s)
SOURCES += $(wildcard $(FILESCREENSDIR)/*.s)
SOURCES += $(wildcard $(FILEIODIR)/*.s)
OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))
OBJECTS += $(OBJTARGETDIR)/hdrload.o $(OBJTARGETDIR)/hdrtables.o
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
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.s $(EDITORDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.s $(FILESCREENSDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

vpath %.s $(FILEIODIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

# Pre-compiled library header loader
vpath %.s ../../shared/hdr
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 $(ASFLAGS) $(DEPFLAGS) -o $@ $<
	$(FIXDEP)

$(PRGFILE): $(OBJECTS)
	ld65 -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(PRGFILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)

-include $(DEPENDS)
