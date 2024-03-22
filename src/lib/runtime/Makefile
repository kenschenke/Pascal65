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

SOURCES += $(SRCDIR)/addysp.s
SOURCES += $(SRCDIR)/clearinputbuf.s
SOURCES += $(SRCDIR)/decsp4.s
SOURCES += $(SRCDIR)/exit.s
SOURCES += $(SRCDIR)/fileio.s
SOURCES += $(SRCDIR)/getkey.s
SOURCES += $(SRCDIR)/incsp4.s
SOURCES += $(SRCDIR)/int8.s
SOURCES += $(SRCDIR)/int16.s
SOURCES += $(SRCDIR)/int16comp.s
SOURCES += $(SRCDIR)/int32.s
SOURCES += $(SRCDIR)/int32comp.s
SOURCES += $(SRCDIR)/int32sub.s
SOURCES += $(SRCDIR)/isalpha.s
SOURCES += $(SRCDIR)/jmptbl.s
SOURCES += $(SRCDIR)/leftpad.s
SOURCES += $(SRCDIR)/loadaddr.s
SOURCES += $(SRCDIR)/memheap.s
SOURCES += $(SRCDIR)/popax.s
SOURCES += $(SRCDIR)/popeax.s
SOURCES += $(SRCDIR)/printz.s
SOURCES += $(SRCDIR)/pusheax.s
SOURCES += $(SRCDIR)/rterror.s
SOURCES += $(SRCDIR)/rtstack.s
SOURCES += $(SRCDIR)/strcase.s
SOURCES += $(SRCDIR)/strcompare.s
SOURCES += $(SRCDIR)/tenstable.s
SOURCES += $(SRCDIR)/trim.s
SOURCES += $(SRCDIR)/uint32comp.s
SOURCES += $(SRCDIR)/writebool.s
SOURCES += $(SRCDIR)/writechar.s
SOURCES += $(SRCDIR)/writeint.s
SOURCES += $(SRCDIR)/writestring.s
SOURCES += $(SRCDIR)/writetostring.s
SOURCES += $(SRCDIR)/writevalue.s

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
