CONFIG := cfg-$(TARGET).cfg

SRCDIR := src
OBJDIR := obj
BINDIR := bin

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
LIBFILE := $(BINTARGETDIR)/dumpicode

# Add -D __DEBUG__ to the ASFLAGS line to:
#    1) Leave IC_LINE instructions in the dump
#    2) Leave labels unmodified.
#
# These two items make unit testing unbearable or impossible
# because labels are dependant on memory addresses and line numbers
# change as code is modified in the test files.
#
# With debugging disabled, labels are changed to "xxxxx".
ASFLAGS = -I ../../asminc -t c64 --cpu 4510

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
	ld65 -o $(LIBFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(LIBFILE) $(OBJECTS)
	$(RM) $(DEPENDS) $(DEPENDS:.d=.dep)

-include $(DEPENDS)
