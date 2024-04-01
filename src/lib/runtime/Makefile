SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

PROGRAM := runtime
CC65TARGET = c64

BINTARGETDIR = $(BINDIR)/$(TARGET)
OBJTARGETDIR = $(OBJDIR)/$(TARGET)
PRGFILE := $(BINTARGETDIR)/$(PROGRAM)

c64_CFLAGS =
c128_CFLAGS =
mega65_CFLAGS = -D __MEGA65__ -I ../../mega65-libc/include
ifeq ($(TARGET),mega65)
ASFLAGS = -I ../../asminc -D RUNTIME -D __MEGA65__
else
ASFLAGS = -I ../../asminc -D RUNTIME
endif
LDFLAGS = --mapfile runtime.map

SOURCES := $(wildcard $(SRCDIR)/*.s)

SOURCES += $(LIBCOMMONDIR)/int8.s
SOURCES += $(LIBCOMMONDIR)/int8add.s
SOURCES += $(LIBCOMMONDIR)/int8mult.s
SOURCES += $(LIBCOMMONDIR)/int8sub.s
SOURCES += $(LIBCOMMONDIR)/int16add.s
SOURCES += $(LIBCOMMONDIR)/int16comp.s
SOURCES += $(LIBCOMMONDIR)/int16mult.s
SOURCES += $(LIBCOMMONDIR)/int16sub.s
SOURCES += $(LIBCOMMONDIR)/int32add.s
SOURCES += $(LIBCOMMONDIR)/int32comp.s
SOURCES += $(LIBCOMMONDIR)/int32mult.s
SOURCES += $(LIBCOMMONDIR)/int32sqr.s
SOURCES += $(LIBCOMMONDIR)/int32sub.s
SOURCES += $(LIBCOMMONDIR)/uint16mult.s
SOURCES += $(LIBCOMMONDIR)/uint32comp.s
SOURCES += $(LIBCOMMONDIR)/uint32mult.s

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

vpath %.s $(LIBCOMMONDIR)
$(OBJTARGETDIR)/%.o: %.s | $(OBJTARGETDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(BINTARGETDIR)/$(PROGRAM): $(OBJECTS)
	ld65 $(LDFLAGS) -o $(BINTARGETDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PRGFILE)
	$(RM) $(BINTARGETDIR)/*
