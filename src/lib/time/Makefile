SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

PROGRAM := time
CC65TARGET = c64

BINTARGETDIR := $(BINDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)
OBJTARGETDIR := $(OBJDIR)/$(TARGET)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D __MEGA65__
SOURCES += $(wildcard $(SRCDIR)/mega65/*.s)
else
ASFLAGS = -I ../../asminc
endif
LDFLAGS =

SOURCES += $(wildcard $(SRCDIR)/*.s)

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJTARGETDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

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
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

ifeq ($(TARGET),mega65)
vpath %.s $(SRCDIR)/mega65
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<
endif

$(PRGFILE): $(OBJECTS) $(CONFIG)
	ld65 $(LDFLAGS) -o $(PRGFILE) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PRGFILE)
	$(RM) $(BINTARGETDIR)/*
