SRCDIR := src
OBJDIR := obj
BINDIR := bin
LIBCOMMONDIR := ../common

PROGRAM := runtime
PRGFILE := $(BINDIR)/$(PROGRAM)
TARGET := c64
CC65TARGET = c64

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
SOURCES += $(SRCDIR)/array.s
SOURCES += $(SRCDIR)/decsp4.s
SOURCES += $(SRCDIR)/exit.s
SOURCES += $(SRCDIR)/incsp4.s
SOURCES += $(SRCDIR)/inputbuf.s
SOURCES += $(SRCDIR)/jmptbl.s
SOURCES += $(SRCDIR)/loadaddr.s
SOURCES += $(SRCDIR)/memcopy.s
SOURCES += $(SRCDIR)/memheap.s
SOURCES += $(SRCDIR)/popax.s
SOURCES += $(SRCDIR)/popeax.s
SOURCES += $(SRCDIR)/printz.s
SOURCES += $(SRCDIR)/pushax.s
SOURCES += $(SRCDIR)/pusheax.s
SOURCES += $(SRCDIR)/record.s
SOURCES += $(SRCDIR)/rterror.s
SOURCES += $(SRCDIR)/rtstack.s
SOURCES += $(LIBCOMMONDIR)/float.s
SOURCES += $(LIBCOMMONDIR)/floatabs.s
SOURCES += $(LIBCOMMONDIR)/floatadd.s
SOURCES += $(LIBCOMMONDIR)/floatcomp.s
SOURCES += $(LIBCOMMONDIR)/floatdiv.s
SOURCES += $(LIBCOMMONDIR)/floatinput.s
SOURCES += $(LIBCOMMONDIR)/floatmult.s
SOURCES += $(LIBCOMMONDIR)/floatnorm.s
SOURCES += $(LIBCOMMONDIR)/floatoutput.s
SOURCES += $(LIBCOMMONDIR)/floatround.s
SOURCES += $(LIBCOMMONDIR)/floatsub.s
SOURCES += $(LIBCOMMONDIR)/floatutil.s
SOURCES += $(LIBCOMMONDIR)/getline.s
SOURCES += $(LIBCOMMONDIR)/int16.s
SOURCES += $(LIBCOMMONDIR)/int16add.s
SOURCES += $(LIBCOMMONDIR)/int16comp.s
SOURCES += $(LIBCOMMONDIR)/int16div.s
SOURCES += $(LIBCOMMONDIR)/int16mod.s
SOURCES += $(LIBCOMMONDIR)/int16mult.s
SOURCES += $(LIBCOMMONDIR)/int16sqr.s
SOURCES += $(LIBCOMMONDIR)/int16sub.s
SOURCES += $(LIBCOMMONDIR)/leftpad.s
SOURCES += $(LIBCOMMONDIR)/readint16.s
SOURCES += $(LIBCOMMONDIR)/writeint16.s

CONFIG := cfg-$(TARGET).cfg

OBJECTS := $(addsuffix .o,$(basename $(addprefix $(OBJDIR)/,$(notdir $(SOURCES)))))

DEPENDS := $(OBJECTS:.o=.d)

all: $(BINDIR) $(OBJDIR) $(BINDIR)/$(PROGRAM)

$(BINDIR):
	mkdir -p $@

$(OBJDIR):
	mkdir -p $@

vpath %.s $(SRCDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

vpath %.s $(LIBCOMMONDIR)
$(OBJDIR)/%.o: %.s | $(OBJDIR)
	ca65 -t $(CC65TARGET) $(ASFLAGS) -o $@ $<

$(BINDIR)/$(PROGRAM): $(OBJECTS)
	ld65 $(LDFLAGS) -o $(BINDIR)/$(PROGRAM) -C $(CONFIG) $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(DEPENDS)
	$(RM) $(PROGRAM)
	$(RM) $(BINDIR)/*
